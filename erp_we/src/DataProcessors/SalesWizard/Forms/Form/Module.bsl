#Region Variables

&AtClient
Var ClosingInProgress;

&AtClient
Var CachedValues; //current nomenclature to be passed to wait handlers

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	EmbeddingParameters = DataProcessors.SalesWizard.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Raise NStr("vi = 'Trợ giúp bán hàng không có sẵn trong phiên bản cơ bản của chương trình.';
					|ru = 'Помощник продаж недоступен в базовой версии программы.';
					|en = 'Sales wizard is not available in the basic version of the application.'; fa = 'Sales wizard is not available in the basic version of the application.';
					|it = 'L''assistente di vendite non è disponibile nella versione base del programma.';
					|pl = 'Asystent sprzedaży nie jest dostępny w podstawowej wersji programu.';
					|tr = 'Satış sihirbazı programın temel sürümünde mevcut değil.'");
	EndIf;
	
	ToUseTheTransferOfGoodsToStorage             = False;
	ToUseTheTransferOfGoodsToStorage             = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	UseBusinessUnits                         = GetFunctionalOption("UseBusinessUnits");
	UseDiscountAdjustmentsInSales                 = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseDiscountsMarkupsInSales         = GetFunctionalOption("UseDiscountsMarkupsInSales");
	UseSalesOrders                        = GetFunctionalOption("UseSalesOrders");
	UseStandardTermsOfSalesWithCustomers           = GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales    = GetFunctionalOption("UseCustomerTermsOfSales");
	ToUseTermsOfSales                  = GetFunctionalOption("ToUseTermsOfSales");
	UsePeripherals              = GetFunctionalOption("UsePeripherals");
	UseShipmentByRowsInSalesOrder      = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	UseAdvancedFeaturesOfSalesOrder   = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UsePaymentSchedules                         = GetFunctionalOption("UsePaymentSchedules");
	UseSimplifiedPaymentScheme                 = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UseStatusesOfGoodsServicesSales         = GetFunctionalOption("UseStatusesOfGoodsServicesSales");
	UseWarehouseManagementSystem                        = GetFunctionalOption("UseWarehouseManagementSystem");
	UseLinesOfBusiness               = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers  = GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers");
	UseDeliveryManagement                   = GetFunctionalOption("UseDeliveryManagement");
	UseSalesCommission                   = GetFunctionalOption("UseSalesCommission");
	UseShipmentWithDeferredTransferOfTitle =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	UseShipmentWithDeferredTransferOfTitle2_5 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
		
	DisplayDiscountsInPrintForms = Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get() <> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts;
	
	DebtClassificationOption = GeneralPurposeTMServerCall.DefaultDebtClassificationOption();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.SalesWizard));
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	OnlyStandard        = UseStandardTermsOfSalesWithCustomers
							And Not UseCustomerTermsOfSales;
	OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers
							And UseCustomerTermsOfSales;

	UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
	SetVisibilityOfElementsOfLoyaltyBonusProgram();
	
	HideUnavailableAdditionalBankingDetails();
	SetTitleOfPrintDetails();
	CheckAvailabilityOfICOPrinting();
	CheckAvailabilityOfPowerOfAttorneySeal();
	InitializeSalesAssistant();
	SetVisibilityOfItemsBySettings();
	SetContractAvailability();
	SetVisibilityOfCommandToFillInContractPriceView();

	TMCommonUse.CustomizePeripherals(ThisObject, "Goods");
	
	If UseDeliveryManagement Then
		Object.DeliveryMethod = Enums.TransportMethods.SelfPickup;
		
		If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
			Items.PagesCarrier.CurrentPage = Items.CarrierPageIsEmpty;
			Items.DeliveryPages.CurrentPage   = Items.PageDeliveryQuotation;
		Else
			GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
		EndIf;
	EndIf;
	
	SetVisibilityOfElementsByOperationServer();
	
	GoodsIssueNoteGenerationMode = Constants.GoodsIssueNoteGenerationMode.Get();
	GoodsIssueNoteCreationIsAvailable  = GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.ByManager
										And AccessRight("Insert", Metadata.Documents.GoodsIssueNote);
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
	ElementsToFillIn.Add(Items.DeliveryTimeTo1);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
		Items.HeaderGroup.BackColor = New Color();
		Items.MainGroup2CommandBar.BackColor = New Color();
	EndIf;
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
		TotalWarehouses_);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	
	FillParameters = DataProcessors.SalesWizard.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues); 
	
	FillInListOfOptionsForRegistrationOfSalesDocuments();
	
	FiscalizationIsAvailable = RetailSalesServerCall.FiscalizationIsAvailable();
	OperationImplementationToClient = Enums.BusinessTransactions.SaleToCustomer;
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");
	
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If UseAdvancedFeaturesOfSalesOrder Then
		SavedStatus = Settings.Get("Object.SalesOrderStatus");
		
		If ValueIsFilled(SavedStatus) Then
			AvailableStatuses = New ValueList;
			
			Enums.SalesOrderStatuses.FillChoiceList(AvailableStatuses,
																		Enums.SalesOrderStatuses.NotApproved);
			
			If AvailableStatuses.FindByValue(SavedStatus) = Undefined Then
				ListSize               = AvailableStatuses.Count();
				Object.SalesOrderStatus = AvailableStatuses[ListSize - 1].Value;
				
				Settings.Delete("Object.SalesOrderStatus");
			EndIf;
		EndIf;
	Else
		
		Object.SupplyOption = Enums.SupplyOptions.NotRequired;
		If Object.SimplifiedFulfillment And ToUseTermsOfSales Then
			
			OptionAndFlag = New Structure("SupplyOption,WithAssignment", Object.SupplyOption, Undefined);
			
			SecurityOptionAndFlagSeparately  = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
				Object.Terms,
				Object.SalesOrderStatus,
				OptionAndFlag);
				
		EndIf
		
	EndIf;
	
	If Not ValueIsFilled(Object.SupplyOption) Then
		Object.SupplyOption = Enums.SupplyOptions.ToSupply;
	EndIf;
	
	If Object.ForecastingMethod = Enums.SalesForecastingMethods.BySalesPlans 
		And Not AccessRight("Read", Metadata.AccumulationRegisters.SalesPlans) Then
		Object.ForecastingMethod = Undefined;
	EndIf; 

	SetDefaultOptionForIssuingSalesDocuments();
	DocumentCreationOptionOnChangeServer();
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	
	ManagingCreationOfWaybills();
	ManagingCreationOfPowerOfAttorney();
	
	SetMarkIncompleteWarehouse();
	SetVisibilityOfItemsBySettings();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingInProgress
		And Modified
		And Not Exit Then
		
		Cancel = True;
		
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText       = NStr("vi = 'Trợ giúp sẽ kết thúc công việc, tất cả dữ liệu đã nhập sẽ bị mất. Đóng trợ giúp?';
								|ru = 'Работа помощника будет завершена, все введенные данные будут потеряны. Закрыть помощник?';
								|en = 'The wizard will be closed and all entered data will be lost. Do you want to close the wizard?'; fa = 'The wizard will be closed and all entered data will be lost. Do you want to close the wizard?';
								|it = 'Il lavoro dell''assistente sarà completato, tutti i dati inseriti andranno persi. Chiudere assistente?';
								|pl = 'Praca asystenta będzie zakończona, wszystkie wprowadzone dane zostaną utracone. Zamknąć asystenta?';
								|tr = 'Sihirbazın çalışması sonlandırılacak ve girilen tüm veriler kaybolacaktır. Sihirbaz kapatılsın mı?'");
		
		ButtonsList = New ValueList;
		ButtonsList.Add("Close",     NStr("vi = 'Đóng';
											|ru = 'Закрыть';
											|en = 'Close'; fa = 'بستن';
											|it = 'Chiudere';
											|pl = 'Zamknij';
											|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	ClosingInProgress = False;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	If EventName = "LoyaltyCardIsRead"
		And Parameter.OwnerForm = UUID
		And Not ThisIsTransferOperation(Object.BusinessOperation) Then
		
		AdditionalParameters = AdditionalCompletionProcessingParameters();
		AdditionalParameters.EventName = EventName;
		AdditionalParameters.Source = Source;
		AdditionalParameters.Parameter = Parameter;
		
		CallbackDescription  = New CallbackDescription("NotificationProcessingCompletion", ThisObject, AdditionalParameters);
		
		LoyaltyCardIsRead(CallbackDescription, Parameter.LoyaltyCard);
		
		Return;
		
	EndIf;
	
	
	HandlingFragmentAlerts(EventName, Source, Parameter);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
	DataProcessorObject               = FormAttributeToValue("Object");
	ThisIsCustomerOrderOperation      = ThisIsCustomerOrderOperation(Object.DocumentCreationOption);
	ThisIsTransferOperation = ThisIsTransferOperation(Object.BusinessOperation)
							Or (ThisIsOperationOfShippingGoods(Object.BusinessOperation)
								And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee
									Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer));
						
	CreationOptionIsNotCommercialOffer = 
		Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	NotCheckedAttributeArray = New Array;
	
#Region VerificationOfHeaderDetails
	
	If Not ValueIsFilled(Object.Partner) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Khách hàng""';
												|ru = 'Поле ""Клиент"" не заполнено';
												|en = 'The ""Customer"" field is required'; fa = 'The ""Customer"" field is required';
												|it = 'Il campo ""Cliente"" non è compilato';
												|pl = 'Nie wypełniono pole ""Клиент""';
												|tr = '""Müşteri"" alanı doldurulmadı'"), , "Object.Partner", ,
			Cancel);
	EndIf;
	
	If ToUseTermsOfSales
		And Not ValueIsFilled(Object.Terms)
		And CreationOptionIsNotCommercialOffer Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
						|ru = 'Поле ""Соглашение"" не заполнено';
						|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
						|it = 'Il campo ""Accordo"" non è compilato';
						|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
						|tr = '""Anlaşma"" alanı doldurulmamış'");
		CommonClientServer.MessageToUser(ErrorText, ,"Object.Terms", , Cancel);
		
	EndIf;
	
	If Not CreationOptionIsNotCommercialOffer
		And Not ValueIsFilled(Object.ValidityPeriod) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Thời hạn""';
						|ru = 'Поле ""Срок действия"" не заполнено';
						|en = '""Validity period"" is required'; fa = '""Validity period"" is required';
						|it = 'Il campo ""Scadenza"" dell''esecuzione non è compilato.';
						|pl = 'Nie wypełniono pola ""Termin ważności""';
						|tr = '""Geçerlilik süresi"" alanı doldurulmamış'");
		Common.MessageToUser(ErrorText, ,"ValidityPeriod", "Object", Cancel);
		
	EndIf;
	
	If Not CreationOptionIsNotCommercialOffer Then
		
		If ValueIsFilled(Object.Manager)Then
			ManagerContactInformation = CommercialProposalsDocuments.ManagerContactInformation(Object.Manager);
			
			If IsBlankString(ManagerContactInformation.Email) Then
				
				MessageText = StrTemplate(NStr("vi = 'Người quản lý %1 không có địa chỉ email.';
												|ru = 'Для менеджера %1 не указан адрес электронной почты.';
												|en = 'The email address is not specified for the %1 manager.'; fa = 'The email address is not specified for the %1 manager.';
												|it = 'Per il manager%1 non è specificato l''indirizzo della posta elettronica.';
												|pl = 'U menedżera %1 nie jest podany adres e-mail.';
												|tr = '%1 Yönetici için e-posta adresi belirtilmemiştir.'"), Object.Manager);
				Common.MessageToUser(MessageText, , "Manager", , Cancel);
				
			ElsIf Not ManagerContactInformation.EmailMeetsRequirements_ Then
				
				MessageText = StrTemplate(NStr("vi = 'Người quản lý %1 có địa chỉ email không hợp lệ ""%2"".';
												|ru = 'Для менеджера %1 указан некорректный адрес электронной почты ""%2"".';
												|en = 'Incorrect email address ""%2"" is specified for the sales person %1.'; fa = 'Incorrect email address ""%2"" is specified for the sales person %1.';
												|it = 'Per il manager %1 l''indirizzo della posta elettronica indicato non è valido ""%2"".';
												|pl = 'U menedżera %1 został podany nieprawidłowy adres e-mail ""%2"".';
												|tr = '%1 Yönetici için yanlış e-posta adresi ""%2"" belirtilmiştir.'"), Object.Manager, ManagerContactInformation.Email);
				Common.MessageToUser(MessageText, , "Manager", , Cancel);
				
			EndIf;
		
		EndIf;
		
	EndIf;
	
	If Not CreationOptionIsNotCommercialOffer
		And ValueIsFilled(Object.ValidityPeriod)
		And Object.ValidityPeriod < BegOfDay(CurrentSessionDate()) Then
		
		ErrorText = NStr("vi = '""Thời hạn hiệu lực"" không được nhỏ hơn ngày hiện tại';
						|ru = '""Срок действия"" должен быть не меньше чем текущая дата';
						|en = '""Validity period"" must not be less than the current date'; fa = '""Validity period"" must not be less than the current date';
						|it = '""Periodo di validità"" non deve essere inferiore alla data corrente';
						|pl = '""Termin ważności"" musi być nie mniejszy niż bieżąca data';
						|tr = '""Son kullanma tarihi"" güncel tarihten önce olmamalıdır'");
		Common.MessageToUser(ErrorText, ,"ValidityPeriod", "Object", Cancel);
		
	EndIf;
	
	ProductSelectionParameters_ = New Structure("ItemsType", Enums.ItemsTypes.OwnGoods);
	TareSelectionParameters    = New Structure("ItemsType", Enums.ItemsTypes.ReusablePackage);
	
	ThereAreProducts_ = Object.Goods.FindRows(ProductSelectionParameters_).Count() > 0;
	ThereIsPackage   = Object.Goods.FindRows(TareSelectionParameters).Count() > 0;
	
	If DateOfShipmentRequired_ 
		And Not ValueIsFilled(Object.DateOfShipment)
		And Object.NotShipInInstallments
		And ThisIsCustomerOrderOperation Then
	
		ErrorText = NStr("vi = 'Chưa điền trường ""Ngày giao hàng""';
						|ru = 'Поле ""Дата отгрузки"" не заполнено';
						|en = '""Shipment date"" is not filled in'; fa = '""Shipment date"" is not filled in';
						|it = 'Il campo ""Data di spedizione"" non è compilato';
						|pl = 'Nie wypełniono pole ""Data отгрузки""';
						|tr = '""Sevkiyat tarihi"" alanı doldurulmamış'");
		CommonClientServer.MessageToUser(ErrorText,,"Object.DateOfShipment", ,Cancel);
	
	EndIf; 
	
	If WarehouseIsRequired
		And Not WarehouseGroup_
		And Not ValueIsFilled(Object.Warehouse)
		And CreationOptionIsNotCommercialOffer Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
						|ru = 'Поле ""Склад"" не заполнено';
						|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
						|it = 'Il campo ""Magazzino"" non è compilato';
						|pl = 'Nie wypełniono pola ""Magazyn""';
						|tr = '""Ambar"" alanı doldurulmamış'");
		CommonClientServer.MessageToUser(ErrorText, ,"Object.Warehouse", , Cancel);
		
	ElsIf (ThereAreProducts_ Or ThereIsPackage)
		And WarehouseGroup_
		And CreationOptionIsNotCommercialOffer
		And ValueIsFilled(Object.Warehouse) Then
		
		SelectGroup = Common.ObjectAttributeValue(Object.Warehouse, "SelectGroup");
		
		If (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice)
			And SelectGroup = Enums.SelectWarehouseGroup.Disable Then
			
			ErrorText = NStr("vi = 'Cần chỉ ra nhóm kho bãi được phép để chọn vào đơn hàng';
							|ru = 'Необходимо указать группу складов, разрешенную для выбора в заказах';
							|en = 'Specify a warehouse group allowed for selection in orders'; fa = 'Specify a warehouse group allowed for selection in orders';
							|it = 'È necessario specificare il gruppo dei magazzini autorizzato per essere selezionato negli ordini';
							|pl = 'Należy określić grupę magazynów, dopuszczalną dla wyboru w zamówieniach';
							|tr = 'Siparişlerde seçilmesine izin verilen depo grubu belirtilmelidir'");
			
			CommonClientServer.MessageToUser(ErrorText, , "Object.Warehouse", , Cancel);
			
		ElsIf (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee)
			And (SelectGroup = Enums.SelectWarehouseGroup.Disable
				Or SelectGroup = Enums.SelectWarehouseGroup.AllowInOrders) Then
			
			ErrorText = NStr("vi = 'Cần chỉ ra nhóm kho bãi được phép để chọn vào các chứng từ bán hàng';
							|ru = 'Необходимо указать группу складов, разрешенную для выбора в реализациях';
							|en = 'Specify a warehouse group allowed for selection in sales'; fa = 'Specify a warehouse group allowed for selection in sales';
							|it = 'È necessario specificare il gruppo dei magazzini autorizzato per essere selezionato nei realizzi';
							|pl = 'Należy określić grupę magazynów, dopuszczalną dla wyboru w sprzedażach';
							|tr = 'Satışlarda seçilmesine izin verilen depo grubu belirtilmelidir'");
			
			CommonClientServer.MessageToUser(ErrorText, , "Object.Warehouse", , Cancel);
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Department)
		And GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
		And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice) Then
			
		ErrorText = NStr("vi = 'Chưa điền trường ""Bộ phận""';
						|ru = 'Поле ""Подразделение"" не заполнено';
						|en = '""Business unit"" is required'; fa = '""Business unit"" is required';
						|it = 'Il campo ""Reparto"" non è compilato';
						|pl = 'Nie wypełniono pola ""Dział""';
						|tr = '""Departman"" alanı doldurulmamış'");
		CommonClientServer.MessageToUser(ErrorText, , "Object.Department", , Cancel);
		
	EndIf;
	
#EndRegion

#Region CheckingTabularPartOfGoods
	
	ThereAreErrorsGoods = False;
	
	If Object.Goods.Count() = 0 Then
		
		ErrorText = NStr("vi = 'Chưa nhập bất kỳ một dòng nào trong danh sách ""Hàng hóa""';
						|ru = 'Не введено ни одной строки в список ""Товары""';
						|en = 'No line entered into the Item list'; fa = 'No line entered into the Item list';
						|it = 'Non è stata inserita una singola riga nell''elenco ""Merci""';
						|pl = 'Nie wprowadzono ani jednego wiersza do listy ""Wiersze pozycji""';
						|tr = '""Ürünler"" listesine herhangi bir satır girilmedi'");
		CommonClientServer.MessageToUser(ErrorText, , "Object.Goods", , ThereAreErrorsGoods);
		
	EndIf;
	
	For CurIndex__ = 0 To Object.Goods.Count()-1 Do
		
		CurrentRow = Object.Goods[CurIndex__]; // LineOfATabularSection
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Sản phẩm""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", CurrentRow.LineNumber);
		
		If Not ValueIsFilled(CurrentRow.Products) Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Cột ""Sản phẩm"" không được điền vào';
					|ru = 'Не заполнена колонка ""Номенклатура""';
					|en = 'Column ""Items"" is not filled in'; fa = 'Column ""Items"" is not filled in';
					|it = 'La colonna ""articolo"" non è compilata';
					|pl = 'Nie wypełniono kolumny ""Номенклатура""';
					|tr = '""Öğe"" sütunu doldurulmadı'") + ErrorAddress,
				,
				"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Products"),
				,
				ThereAreErrorsGoods);
		EndIf;
		
		If Not ValueIsFilled(CurrentRow.NumberOfPackages)
			And Not ValueIsFilled(CurrentRow.NumberOfPackagesDueToReturn) Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Cột ""Số lượng gói"" không được điền';
					|ru = 'Не заполнена колонка ""Количество упаковок""';
					|en = 'Column ""Quantity"" is not filled in'; fa = 'Column ""Quantity"" is not filled in';
					|it = 'La colonna ""Numero di imballaggi"" non è compilata';
					|pl = 'Nie została wypełniona kolumna ""Ilość opakowań""';
					|tr = '""Paket miktarı"" sütunu eksik'") + ErrorAddress,
				,
				"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "NumberOfPackages"),
				,
				ThereAreErrorsGoods);
			
		EndIf;
		
		If Not ValueIsFilled(CurrentRow.Price)
			And ?(Object.ToReturnReusablePackage And Not Object.PackageDepositIsRequired,
				CurrentRow.ItemsType <> Enums.ItemsTypes.ReusablePackage,
				True) Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền cột ""Đơn giá""';
					|ru = 'Не заполнена колонка ""Цена""';
					|en = 'Column ""Price"" is not filled in'; fa = 'Column ""Price"" is not filled in';
					|it = 'La colonna ""Prezzo"" non è compilata';
					|pl = 'Nie wypełniona kolumna ""Cena""';
					|tr = '""Fiyat"" sütunu eksik'") + ErrorAddress,
				,
				"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Price"),
				,
				ThereAreErrorsGoods);
			
		EndIf;
		
		If Not ValueIsFilled(CurrentRow.Sum)
			And Not ValueIsFilled(Object.Goods[CurIndex__].NumberOfPackagesDueToReturn)
			And ?(Object.ToReturnReusablePackage
					And Not Object.PackageDepositIsRequired,
				CurrentRow.ItemsType <> Enums.ItemsTypes.ReusablePackage,
				True) Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền cột ""Số tiền""';
					|ru = 'Не заполнена колонка ""Сумма""';
					|en = 'Column ""Amount"" is not filled in'; fa = 'Column ""Amount"" is not filled in';
					|it = 'La colonna ""Totale"" non è compilata';
					|pl = 'Nie wypełniona kolumna ""Wartość""';
					|tr = '""Tutar"" sütunu eksik'") + ErrorAddress,
				,
				"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Sum"),
				,
				ThereAreErrorsGoods);
			
		EndIf;
		
		If Not ValueIsFilled(CurrentRow.VATRate)
			And Not ThisIsTransferOperation Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền cột ""Thuế suất GTGT""';
					|ru = 'Не заполнена колонка ""Ставка НДС""';
					|en = '""VAT rate"" is not filled in'; fa = '""VAT rate"" is not filled in';
					|it = 'La colonna ""Aliquota IVA"" non è compilata';
					|pl = 'Kolumna ""Stawka VAT"" nie jest wypełniona';
					|tr = '""KDV Oranı"" sütunu eksik'") + ErrorAddress,
				,
				"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "VATRate"),
				,
				ThereAreErrorsGoods);
			
		EndIf;
		
		If CurrentRow.WarehouseIsRequired
			And Not ValueIsFilled(CurrentRow.Warehouse)
			And CreationOptionIsNotCommercialOffer 
			And WarehouseGroup_ Then
			
			MessageText = NStr("vi = 'Chưa điền cột ""%1""%2';
								|ru = 'Не заполнена колонка ""%1""%2';
								|en = 'Column ""%1"" is not filled in%2'; fa = 'Column ""%1"" is not filled in%2';
								|it = 'Не заполнена колонка ""%1""%2';
								|pl = 'Column ""%1"" is not filled in%2';
								|tr = '""%1"" sütunu doldurulmadı%2'");
			
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, Items.ProductsGroupSender.Title, ErrorAddress),
				,
				"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Warehouse"),
				,
				ThereAreErrorsGoods);
			
		EndIf;
		
		If Not ValueIsFilled(CurrentRow.RegistrationOption)
			And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer) Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền cột ""Lập chứng từ""';
					|ru = 'Не заполнена колонка ""Оформить""';
					|en = '""Register"" is not filled in'; fa = '""Register"" is not filled in';
					|it = 'La colonna ""Formalizzare"" non è compilata';
					|pl = 'Nie wypełniona kolumna ""Sporządzić""';
					|tr = '""Düzenle"" sütunu eksik'") + ErrorAddress,
				,
				"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "RegistrationOption"),
				,
				ThereAreErrorsGoods);
			
		EndIf;
		
		If (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice) Then
			
			If CurrentRow.DateOfShipmentRequired_
				And Not ValueIsFilled(CurrentRow.DateOfShipment)
				And Not Object.NotShipInInstallments Then
				
				CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền cột ""Ngày giao hàng""';
						|ru = 'Не заполнена колонка ""Дата отгрузки""';
						|en = 'Column ""Shipment date"" is not filled in'; fa = 'Column ""Shipment date"" is not filled in';
						|it = 'La colonna ""Data di spedizione"" non è compilata';
						|pl = 'Nie wypełniono kolumny ""Дата отгрузки""';
						|tr = '""Sevkiyat tarihi"" sütunu eksik'") + ErrorAddress,
					,
					"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "DateOfShipment"),
					,
					ThereAreErrorsGoods);
				
			EndIf;
			
			// The date of shipment in pm Goods must be at least the date of the document
			If Not Object.NotShipInInstallments
				And ValueIsFilled(CurrentRow.DateOfShipment)
				And CurrentRow.DateOfShipment < BegOfDay(Object.Date) Then
			
				ErrorText = NStr("vi = 'Ngày giao hàng cần nhỏ hơn ngày bán hàng ""%Date%""';
								|ru = 'Дата отгрузки должна быть не меньше даты продажи ""%Date%""';
								|en = 'Shipment date cannot be less than date of sale ""%Date%""'; fa = 'Shipment date cannot be less than date of sale ""%Date%""';
								|it = 'La data della spedizione non deve essere inferiore alla data di vendita ""%Date%""';
								|pl = 'Data wysyłki powinna być nie mniejsza daty sprzedaży ""%Date%""';
								|tr = 'Sevkiyat tarihi, ""%Date%"" satış tarihinden daha önce olmamalıdır'");
				ErrorText = StrReplace(ErrorText,"%Date%", Format(Object.Date, "DLF=DD"));
				
				CommonClientServer.MessageToUser(
					ErrorText + ErrorAddress,
					,
					"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "DateOfShipment"),
					,
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ProductsServer.CheckQuantityFilling(DataProcessorObject, CheckedAttributes, ThereAreErrorsGoods);
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(DataProcessorObject, NotCheckedAttributeArray, ThereAreErrorsGoods);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.SalesWizard);
	
	If ThisIsImplementation(Object.DocumentCreationOption)
		Or ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		
		ProductsServer.CheckSeriesCompletion(Object, SeriesSpecificationParameters.SaleOfGoodsAndServices, ThereAreErrorsGoods);
		
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		ProductsServer.CheckSeriesCompletion(Object, SeriesSpecificationParameters.OrderDocument, ThereAreErrorsGoods);
	EndIf;
	
	ProductsServer.CheckContentCompletion(DataProcessorObject, ThereAreErrorsGoods, "Goods");
	
#EndRegion

#Region VerificationOfPaymentAndShipmentDetailsAndTabularPartOfPaymentStages
	
	ThereAreErrorsPaymentShipment = False;
	
	If Not ValueIsFilled(Object.Organization) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.Organization", , ThereAreErrorsPaymentShipment);
	EndIf;
	
	If GetFunctionalOption("UsePartnersAndCounterparties")
		And Not ValueIsFilled(Object.Counterparty) Then
		
		ErrorText = NStr("vi = 'Trường ""Đối tác"" chưa điền';
						|ru = 'Поле ""Контрагент"" не заполнено';
						|en = '""Counterparty"" is not filled in'; fa = '""Counterparty"" is not filled in';
						|it = 'Il campo ""Contraente"" non è compilato';
						|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
						|tr = '""Cari hesap"" alanı doldurulmadı'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.Counterparty", , ThereAreErrorsPaymentShipment);
		
	EndIf;
	
	If CreationOptionIsNotCommercialOffer 
		And GetFunctionalOption("UseCustomerContracts")
		And Not ValueIsFilled(Object.Contract) 
		And (Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale 
			Or (Object.ConsignmentSales25
				And Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent)
			Or (ToUseTermsOfSales
				And ValueIsFilled(Object.Terms)
				And Common.ObjectAttributeValue(Object.Terms, "ContractsAreUsed"))) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Hợp đồng""';
						|ru = 'Поле ""Договор"" не заполнено';
						|en = 'The ""Contract"" field is required'; fa = 'The ""Contract"" field is required';
						|it = 'Il campo ""Accordo"" non è compilato';
						|pl = 'Pole ""Umowa"" nie jest wypełnione';
						|tr = '""Sözleşme"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.Contract", , ThereAreErrorsPaymentShipment);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Manager) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Người quản lý""';
						|ru = 'Поле ""Менеджер"" не заполнено';
						|en = '""Manager"" is not filled in'; fa = '""Manager"" is not filled in';
						|it = 'Il campo ""Manager"" non è compilato';
						|pl = 'Pole ""Menedżer"" nie jest wypełniony';
						|tr = '""Yönetici"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.Manager", , ThereAreErrorsPaymentShipment);
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Tiền tệ""';
						|ru = 'Поле ""Валюта"" не заполнено';
						|en = '""Currency"" is required'; fa = '""Currency"" is required';
						|it = 'Il campo ""Valuta"" non è compilato';
						|pl = 'Pole ""Waluta"" nie jest wypełnione';
						|tr = '""Para Birimi"" alanı doldurulmadı'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.Currency", , ThereAreErrorsPaymentShipment);
	EndIf;
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		ErrorText = NStr("vi = 'Trường ""Giao dịch"" chưa điền';
						|ru = 'Поле ""Операция"" не заполнено';
						|en = '""Operation"" is not filled in'; fa = '""Operation"" is not filled in';
						|it = 'Il campo ""Operazione"" non è compilato';
						|pl = 'Pole ""Operacja"" nie zostało wypełnione';
						|tr = '""İşlem"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.BusinessOperation", ,
			ThereAreErrorsPaymentShipment);
	EndIf;
	
	If Not ValueIsFilled(Object.VATTaxation)
		And Not (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
			Or ThisIsTransferOperation) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Tính thuế GTGT""';
						|ru = 'Поле ""Налогообложение НДС"" не заполнено';
						|en = '""VAT taxation"" is not filled in'; fa = '""VAT taxation"" is not filled in';
						|it = 'Il campo ""Tassazione IVA"" non è compilato';
						|pl = 'Pole ""Opodatkowanie VAT"" nie jest wypełnione';
						|tr = '""KDV vergilendirmesi"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.VATTaxation", ,
			ThereAreErrorsPaymentShipment);
		
	EndIf;
	
	// The date of shipment in the header must be at least the date of the document
	If Object.NotShipInInstallments
		And ValueIsFilled(DataProcessorObject.DateOfShipment)
		And ThisIsCustomerOrderOperation
		And DataProcessorObject.DateOfShipment < BegOfDay(DataProcessorObject.Date) Then
		
		ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
						|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
						|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Sevkiyat tarihi, belgenin %Date% tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(DataProcessorObject.Date,"DLF=DD"));
		
		CommonClientServer.MessageToUser(ErrorText, , "Object.DateOfShipment", , ThereAreErrorsPaymentShipment);
		
	EndIf;
	
	If CreationOptionIsNotCommercialOffer
		And Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_
		And Object.CreateCashAccountReceiptNote
		And Not ThisIsTransferOperation
		And Not ValueIsFilled(Object.CashAccount) Then
		
		ErrorText = NStr("vi = 'Trường ""Quỹ tiền mặt"" chưa điền';
						|ru = 'Поле ""Касса"" не заполнено';
						|en = '""Cash account"" is not filled in'; fa = '""Cash account"" is not filled in';
						|it = 'Il campo ""Cassa"" non è compilato';
						|pl = 'Pole ""Kasa"" nie zostało wypełnione';
						|tr = '""Kasa"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, , "PaymentStepsText", , ThereAreErrorsPaymentShipment);
		
	EndIf;
	
	OrderCalculationsOnInvoices = (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder 
		And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments);

	If CreationOptionIsNotCommercialOffer
		And ValueIsFilled(Object.BusinessOperation)
		And Not OrderCalculationsOnInvoices
		And Not ThisIsTransferOperation Then
		
		PaymentAmountAgainstTheDocument = Object.Goods.Total("AmountIncludingVATWithoutReusablePackages");
		PackageDepositValue      = ?(Object.PackageDepositIsRequired, Object.Goods.Total("AmountIncludingVAT") - PaymentAmountAgainstTheDocument, 0);
		
		If Not ExecutionScheduleIsSpecified
			Or Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts Then
			
			StructureOfVerificationParameters = PaymentStepsServer.ParametersForCheckingWhetherStagesAreFilledInCorrectly();
			StructureOfVerificationParameters.Date                   = BegOfDay(CurrentSessionDate());
			StructureOfVerificationParameters.Currency                 = DocumentCurrency;
			StructureOfVerificationParameters.ThisIsOrder               = 
				Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice;
			StructureOfVerificationParameters.InvoiceSourceOfGraph = 
				Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
					And Not ExecutionScheduleIsSpecified;
			StructureOfVerificationParameters.PaymentStepsText     = "DecorationPaymentSteps";
			StructureOfVerificationParameters.PaymentAmountAgainstTheDocument = PaymentAmountAgainstTheDocument;
			StructureOfVerificationParameters.DepositAmountUnderTheDocument = PackageDepositValue;
			
			PaymentStepsServer.CheckCorrectnessOfPaymentScheduleStages(
				Object.PaymentScheduleSteps,
				ThereAreErrorsPaymentShipment, 
				StructureOfVerificationParameters);
			
		EndIf;
		
	EndIf;
	
	// Checking the shipment ban
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
		And Object.SalesOrderStatus <> Enums.SalesOrderStatuses.NotApproved Then
		
		SalesServer.CheckShipmentBan(Object.Partner, Cancel);
		
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
		Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee Then
		
		ActSelectionParameters = New Structure("SaleRegistrationOption",
											 Enums.SalesRegistrationOptions.CustomerInvoiceServices);
		ProductsAct          = Object.Goods.Unload(ActSelectionParameters);
		
		If (ProductsAct.Count() > 0
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee
			Or Object.StatusOfCustomerInvoice <> Enums.StatusesOfCustomerInvoices.ForPrepayment
			Or AmountPrepaymentBeforeGoodsIssue + AmountOfPrepaymentBeforeShipment = 0) Then
			
			SalesServer.CheckShipmentBan(Object.Partner, Cancel);
			
		EndIf;
		
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
		Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
		
		SelectionParametersOrder = New Structure("RegistrationOption",
												Enums.OptionsOfRegisteringSalesDocuments.SalesOrder);
		SelectionParametersOrder = Object.Goods.Unload(SelectionParametersOrder);
		
		If SelectionParametersOrder.Count() = Object.Goods.Count()
			And Object.SalesOrderStatus <> Enums.SalesOrderStatuses.NotApproved Then
			
			SalesServer.CheckShipmentBan(Object.Partner, Cancel);
			
		EndIf;
		
		SelectionParametersSale = New Structure("RegistrationOption",
												Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
		SalesLines          = Object.Goods.FindRows(SelectionParametersSale);
		TransferFilterParameters = New Structure("RegistrationOption",
												Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
		TransferLines          = Object.Goods.FindRows(TransferFilterParameters);
		
		If SalesLines.Count() > 0
			Or TransferLines.Count() > 0 Then
			
			SalesServer.CheckShipmentBan(Object.Partner, Cancel);
			
		EndIf;
		
	EndIf;
	
	// Checking delivery details
	ThereAreDeliveryErrors = False;
	
	If UseDeliveryManagement
		And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice) Then
		
		If Not ValueIsFilled(Object.DeliveryMethod) Then
			 ErrorText = NStr("vi = 'Chưa điền trường ""Phương thức giao hàng""';
								|ru = 'Поле ""Способ доставки"" не заполнено';
								|en = 'The ""Delivery method"" field is not filled'; fa = 'The ""Delivery method"" field is not filled';
								|it = 'Поле ""Способ доставки"" не заполнено';
								|pl = 'The ""Delivery method"" field is not filled';
								|tr = '""Transfer yöntemi"" alanı doldurulmamış'");
			 CommonClientServer.MessageToUser(ErrorText, , "Object.DeliveryMethod", , ThereAreDeliveryErrors);
		EndIf;
		
		If Object.DeliveryMethod <> Enums.TransportMethods.SelfPickup Then
			If Not ValueIsFilled(Object.DeliveryAddress) Then
				If Object.DeliveryMethod = Enums.TransportMethods.ToCustomer Then
					ErrorText = NStr("vi = 'Chưa điền trường ""Địa chỉ giao hàng""';
									|ru = 'Поле ""Адрес доставки"" не заполнено';
									|en = '""Delivery address"" is not filled in'; fa = '""Delivery address"" is not filled in';
									|it = 'Il campo ""Indirizzo della consegna"" non è compilato';
									|pl = 'Pole ""Adres dostawy"" nie zostało wypełnione';
									|tr = '""Teslimat adresi"" alanı doldurulmamış'");
				Else
					ErrorText = NStr("vi = 'Chưa điền trường ""Địa chỉ giao hàng đến người nhận""';
									|ru = 'Поле ""Адрес доставки до получателя"" не заполнено';
									|en = '""Delivery address to consignee"" is not filled in'; fa = '""Delivery address to consignee"" is not filled in';
									|it = 'Il campo ""Indirizzo della consegna al destinatario"" non è compilato';
									|pl = 'Pole ""Adres dostawy do odbiorcy"" nie zostało wypełnione';
									|tr = '""Alıcı teslimat adresi"" alanı doldurulmamış'");
				EndIf;
				
				CommonClientServer.MessageToUser(ErrorText, , "Object.DeliveryAddress", , ThereAreDeliveryErrors);
			EndIf;
			
			If (Object.DeliveryMethod = Enums.TransportMethods.ByCarrier
					Or Object.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress)
				And Not ValueIsFilled(Object.CarrierPartner) Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Người vận chuyển""';
								|ru = 'Поле ""Перевозчик"" не заполнено';
								|en = '""Carrier"" is not filled in'; fa = '""Carrier"" is not filled in';
								|it = 'Il campo ""Trasportatore"" non è compilato';
								|pl = 'Pole ""Przewoźnik"" nie zostało wypełnione';
								|tr = '""Taşıyıcı"" alanı doldurulmamış'");
				
				CommonClientServer.MessageToUser(ErrorText, , "Object.CarrierPartner", , ThereAreDeliveryErrors);
				
			EndIf;
			
			If Object.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress
				And Not ValueIsFilled(Object.DeliveryAddressOfCarrier) Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Địa chỉ giao hàng đến người vận chuyển""';
								|ru = 'Поле ""Адрес доставки до перевозчика"" не заполнено';
								|en = 'The ""Delivery address to carrier"" field is required'; fa = 'The ""Delivery address to carrier"" field is required';
								|it = 'Il campo ""Indirizzo di consegna al trasportatore"" non è compilato';
								|pl = 'Pole ""Adres dostawy do przewoźnika"" nie zostało wypełnione';
								|tr = '""Taşıyıcı teslimat adresi"" alanı doldurulmamış'");
				
				CommonClientServer.MessageToUser(ErrorText, , "Object.DeliveryAddressOfCarrier", ,
					ThereAreDeliveryErrors);
				
			EndIf;
		EndIf;
		
	EndIf;
	
	If ToUseTermsOfSales
		And ThisIsTransferOperation
		And ValueIsFilled(Object.Terms)
		And ValueIsFilled(Object.BusinessOperation)
		And ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
		
		DetailsOfAgreement = Common.ObjectAttributesValues(Object.Terms,
			"SaleWithDeferredTransferOfTitleIsAllowed, Presentation");
	
		If Not DetailsOfAgreement.SaleWithDeferredTransferOfTitleIsAllowed Then
			
			ErrorText = NStr("vi = 'Theo thỏa thuận ""%1"" không thể giao hàng mà chưa chuyển giao quyền sở hữu.';
							|ru = 'По соглашению ""%1"" невозможна отгрузка товаров без перехода права собственности.';
							|en = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.'; fa = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.';
							|it = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.';
							|pl = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.';
							|tr = '""%1"" anlaşmasına göre ürünler, mülkiyet hakkı devri olmaksızın sevkiyata alınamaz.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, DetailsOfAgreement.Presentation);

			Common.MessageToUser(ErrorText,,,, Cancel);
		EndIf;
	EndIf;
	
	If ThereAreErrorsGoods Then
		ResetTagsAndCaps(Items);
		
		Items.GoShoppingCart.Check   = True;
		Items.Pages.CurrentPage = Items.PageShoppingCart;
	ElsIf ThereAreErrorsPaymentShipment Then
		ResetTagsAndCaps(Items);
		
		Items.GoToShipmentPayment.Check = True;
		Items.Pages.CurrentPage      = Items.PagePaymentShipment;
	ElsIf ThereAreDeliveryErrors Then
		ResetTagsAndCaps(Items);
		
		Items.GoShipping.Check  = True;
		Items.Pages.CurrentPage = Items.DeliveryPage;
	ElsIf Cancel Then
		ResetTagsAndCaps(Items);
		
		Items.GoPartner.Check = True;
		Items.Pages.CurrentPage = Items.PagePartner;
	EndIf;
	
	If ThereAreErrorsGoods
		Or ThereAreErrorsPaymentShipment
		Or ThereAreDeliveryErrors Then
		
		Cancel = True;
		
	EndIf;
	
#EndRegion
	
	If Not Cancel Then
		ObjectFormPropsValue = FormAttributeToValue("Object");
		ObjectFormPropsValue.DocumentAmount = 1;
		SalesServer.CheckCorrectnessOfSalesDocument(ObjectFormPropsValue, Cancel);
	EndIf;
		
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.SalesWizard.Form.Form.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SalesWizard.Form.Setting" Then
		
		If ValueSelected <> Undefined Then
			ProcessChangesToServerParameters(ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SalesWizard.Form.AttributesForCertificatePrinting" Then
		
		If ValueSelected <> Undefined Then
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			FillInAndSetDeliveryAttributes = Object.GoodsRecipient <> ValueSelected.GoodsRecipient;
			FillPropertyValues(Object, ValueSelected);
			If FillInAndSetDeliveryAttributes Then
				FillInDeliveryDetails("GoodsRecipient");
			EndIf;
			Object.BankAccount = ValueSelected.CompanyBankAccount;
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SalesWizard.Form.AdditionalAttributes" Then
		
		If ValueSelected <> Undefined Then
			DownloadAdditionalBankingDetailsFromStorageServer(ValueSelected);
		EndIf;
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject,
													DefineSeriesParametersOnClient(ValueSelected.CurrentRowID),
													ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
	
		SalesClient.ProcessingUnitSelection(Object.Goods, Items.Goods.SelectedRows, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If OnlyPersonal
		Or ValueIsFilled(Object.Partner) Then
		
		AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
		
		AgreementSelectionParameters.Item              = Item;
		AgreementSelectionParameters.Partner              = Object.Partner;
		AgreementSelectionParameters.Document             = Object.Terms;
		AgreementSelectionParameters.DocumentDate        = Object.Date;
		AgreementSelectionParameters.FormDataStructure = Object;
		
		If ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
			AgreementSelectionParameters.OnlyTransferOperations = True;
			If UseShipmentWithDeferredTransferOfTitle2_5 Then
				AgreementSelectionParameters.TransferShipmentOperations = True;
			EndIf;
		EndIf;
		
		SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
		
	Else
		StandardProcessing = False;
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("DocumentDate", Object.Date);
		OpeningParameters.Insert("OnlyStandard", True);
		OpeningParameters.Insert("CurrentRow", Object.Terms);
		
		If UseShipmentWithDeferredTransferOfTitle2_5 And ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
			OpeningParameters.Insert("ShipmentWithDeferredTransferOfTitle25", True);
		ElsIf ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
			OpeningParameters.Insert("OnlyTransferOperations", True);
		EndIf;
		
		OpenForm("Catalog.TermsOfSale.ChoiceForm", OpeningParameters, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.SalesWizard.Form.Form.CustomerTermsOfSales.OnChange");
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	TermsOnChangeServer();
	AskQuestionSupply();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure


&AtClient
Procedure PartnerOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.SalesWizard.Form.Item.Partner.OnChange");
	
	PartnerOnChangeServer();
	
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	UpdateTextOfInformationLabelGeneratedDocuments();
	SetDivisionDesign();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	BasisChanged = BasisChanged
						And ValueIsFilled(Object.Basis);
	
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure DocumentCurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		WhenChangingCurrencyServer(Object.Currency,
								PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency));
								PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	DocumentCurrency = Object.Currency;
	
	UpdateTextOfInformationLabelGeneratedDocuments();
		
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInSalesVATTaxation();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer(CachedValues);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification );
EndProcedure

&AtClient
Procedure LabelGeneratedDocumentsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	GoToDocuments(Undefined);
	
EndProcedure

&AtClient
Procedure LabelTotalItemsSelectedClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	GoShoppingCart(Undefined);
	
EndProcedure

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	
	NotShipInInstallmentsOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInShipmentDateServer(Object.DateOfShipment, Undefined);
	
EndProcedure

&AtClient
Procedure ToReturnReusablePackageOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	
EndProcedure

&AtClient
Procedure PackageDepositIsRequiredOnChange(Item)
	
	CalculateTotals_(ThisObject);
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If Not PartnerChanged_ Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
	Else
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		
		If ToUseTermsOfSales
			And ValueIsFilled(Object.Terms) Then
			
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NextDeliveryDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInGoodsByAgreementServerWithMeasurement();
	
EndProcedure

&AtClient
Procedure DecorationOfThePartnerSDossierCalculationsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "PartnerProfile" Then
		FormParameters = New Structure("Partner", Object.Partner);
		
		OpenForm("Report.PartnerProfile.Form.ReportForm", FormParameters, ThisObject);
	EndIf;
	
	If FormattedStringURL = "FormOfSegmentsOfShipmentProhibition" Then
		FormParameters = New Structure("Partner", Object.Partner);
		
		OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", FormParameters, ThisObject);
	EndIf;
	
	If FormattedStringURL = "ShipmentProhibitionReasons" Then
		DataOnSaleAmount = New Structure("AmountARAP",
												PriceManagementSystemClientServer.GetDocumentAmount(Object.Goods, Object.PriceIncludesVAT));
		
		FormParameters = New Structure;
		FormParameters.Insert("PurposeUseKey", Object.Ref);
		FormParameters.Insert("GenerateOnOpen",     True);
		FormParameters.Insert("Filter",                       New Structure("Contract", Object.Contract));
		FormParameters.Insert("Contract",                     Object.Contract);
		FormParameters.Insert("DataOnSaleAmount",        DataOnSaleAmount);
		
		OpenForm("Report.ShipmentProhibitionReasons.Form", FormParameters, ThisObject, "Contract=" + Object.Contract);
	EndIf;
	
	If FormattedStringURL = "OrderList" Then
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Filter", New Structure("Partner", Object.Partner));
		
		OpenForm("Document.SalesOrder.Form.DocumentsListForm", FilterStructure1, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationSparkriskieIndexesURLProcessing(Item, FormattedStringURL, StandardProcessing)


EndProcedure

#Region Supply

&AtClient
Procedure SecurityStatusHyperlinkClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIsBeingShippedClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIssueClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnChange(Item)
	
	WhenChangingBucketOnServer();
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.SalesWizard.Form.Form.Items.Goods.Selection");
	
	If Not ViewOnlyIsSet
		And Item.CurrentItem = Items.GoodsAvailable Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
		
	ElsIf Item.CurrentItem = Items.GoodsPercentRateOfAutomaticDiscountMarkup
		Or Item.CurrentItem = Items.GoodsDiscountMarkupAmount Then
		
		StandardProcessing = False;
		
		If Not Object.DiscountsAreCalculated Then
			
			ParametersStructure1 = New Structure;
			ParametersStructure1.Insert("ApplyToObject",                True);
			ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
			ParametersStructure1.Insert("RestoreManagedDiscounts", True);
			ParametersStructure1.Insert("ManagedDiscounts",                ManagedDiscounts);
			
			TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
			
			If TheStructureOfTheMessages.Messages.Count() > 0
				And TheStructureOfTheMessages.AutomaticallyOpen Then
				
				OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisObject, UUID);
				
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
			CalculateDiscountsWithoutApplyingToObject();
		EndIf;
		
		CurrentData = Items.Goods.CurrentData;
		DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisObject);
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",    CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet",  CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",         UUID);
			
			Notify("EditSet", NotificationParameter1, ThisObject);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
		
	ElsIf Field = Items.GoodsPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If ValueIsFilled(CurrentData.PriceKind) Then
			ClearMessages();
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"));
			
		EndIf;
		
	ElsIf Field = Items.GoodsNumberOfPackagesyForecast Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		
		If CurrentRow.SelectionIconIndex = 1 Then
			CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesyForecast;
			CurrentRow.Count = CurrentRow.QuantityForecast;
			CurrentRow.NumberOfPackagesyForecast = CurrentRow.NumberOfPackagesPreviousOrderVolume;
			CurrentRow.QuantityForecast = CurrentRow.QuantityPreviousOrderVolume;
			CurrentRow.SelectionIconIndex = CurrentRow.SelectionIconIndex + 1;
		ElsIf CurrentRow.SelectionIconIndex = 2 Then
			CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesyForecast;
			CurrentRow.Count = CurrentRow.QuantityForecast;
			CurrentRow.SelectionIconIndex = CurrentRow.SelectionIconIndex + 1;
		ElsIf CurrentRow.SelectionIconIndex = 3 Then
			CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + CurrentRow.NumberOfPackagesyForecast;
			CurrentRow.Count = CurrentRow.NumberOfPackages + CurrentRow.QuantityForecast;
		EndIf;
		
		If CurrentRow.SelectionIconIndex <> 0 Then
			StructureOfActions = New Structure;
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
			
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
			DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	ThisIsTransferOfGoods = ThisIsTransferOfGoods(Object.DocumentCreationOption);
	
	StatisticsText = ?(ThisIsTransferOfGoods, NStr("vi = 'chuyển';
													|ru = 'передаче';
													|en = 'transfer'; fa = 'transfer';
													|it = 'da consegnare';
													|pl = 'transferu';
													|tr = 'transfer'"), NStr("vi = 'bán';
																			|ru = 'продаже';
																			|en = 'sale'; fa = 'sale';
																			|it = 'da vendere';
																			|pl = 'sprzedaży';
																			|tr = 'satış'"));
	SalesText    = ?(ThisIsTransferOfGoods, NStr("vi = 'chuyển giao';
												|ru = 'передача';
												|en = 'transfer'; fa = 'transfer';
												|it = 'consegna';
												|pl = 'transfer';
												|tr = 'transfer'"), NStr("vi = 'bán';
																			|ru = 'продажа';
																			|en = 'sale'; fa = 'sale';
																			|it = 'vendita';
																			|pl = 'sprzedaż';
																			|tr = 'Satış'"));
	
	CurrentData = Items.Goods.CurrentData;
	
	ItWas = NStr("vi = 'Trong đơn hàng trước đó ngày %1 là %2%3.';
				|ru = 'В предыдущем заказе от %1 было %2 %3.';
				|en = '%2 %3 was in the previous order from %1.'; fa = '%2 %3 was in the previous order from %1.';
				|it = 'Nell''ordine precedente del %1 era presente %2 %3.';
				|pl = 'W poprzednim zamówieniu od %1 było %2 %3.';
				|tr = '%1 önceki siparişinde %2%3 meydana geldi.'") + " ";
	StatisticsLine = NStr("vi = 'Với mức trung bình hàng ngày %1 %2 %3 mỗi ngày, đủ cho%4 ngày.';
							|ru = 'При среднедневной %1 %2 %3 в день, хватит на %4 дн.';
							|en = 'When the average daily %1 %2 %3 per day, it is enough for %4 days.'; fa = 'When the average daily %1 %2 %3 per day, it is enough for %4 days.';
							|it = 'Con %1%2%3 medio giornaliero, basterà per %4 giorni.';
							|pl = 'Gdy średnia dzienna wynosi %1 %2 %3 dziennie, wystarcza na %4 dni.';
							|tr = 'Ortalama %1%2%3 günlük fiyatla, %4 gün için yeterli.'") + " ";
	StringBalance =  NStr("vi = 'Khách hàng có %1 %2 trái.';
							|ru = 'Осталось у клиента %1 %2.';
							|en = '%1 %2 left at the customer.'; fa = '%1 %2 left at the customer.';
							|it = 'Rimasto dal cliente %1 %2.';
							|pl = 'Pozostało u klienta %1 %2.';
							|tr = 'Müşteriden kalan %1%2.'") + " ";
	LineAverageDailySale = NStr("vi = 'Trung bình hàng ngày %1 %2 %3 mỗi ngày.';
								|ru = 'Среднедневная %1 %2 %3 в день.';
								|en = 'Average daily %1 %2 %3 per day.'; fa = 'Average daily %1 %2 %3 per day.';
								|it = 'Medio giornaliero %1%2%3 al giorno.';
								|pl = 'Średnia dzienna %1 %2 %3 w dzień.';
								|tr = 'Günlük ortalama %1 %2 %3.'") + " ";
	LineNoData = NStr("vi = 'Không có dữ liệu để tính toán dự báo.';
						|ru = 'Нет данных для расчета прогноза.';
						|en = 'No data for forecast calculation.'; fa = 'No data for forecast calculation.';
						|it = 'Nessun dato per calcolare la previsione.';
						|pl = 'Brak danych do obliczenia prognozy.';
						|tr = 'Tahmini hesaplama için veri bulunmamaktadır.'") + " ";
	LineForecast = "";
	
	If CurrentData <> Undefined Then
		
		ThisIsGoodsTara = CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
						Or CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage");
		
		If ValueIsFilled(CurrentData.QuantityPreviousOrderVolume) Then
			ItWas = StrTemplate(ItWas,
									Format(CurrentData.PreviousOrderDate,"DLF=D"),
									CurrentData.QuantityPreviousOrderVolume,
									CurrentData.UnitOfMeasureForecast);
			
			LineForecast = New FormattedString(LineForecast, ItWas);
		EndIf;
		
		If ThisIsGoodsTara
			And ValueIsFilled(CurrentData.QuantityForecastBalance) Then
			
			StringBalance = StrTemplate(StringBalance,
										CurrentData.QuantityForecastBalance,
										CurrentData.UnitOfMeasureForecast);
			
			LineForecast = New FormattedString(LineForecast, StringBalance);
			
		EndIf;
		
		If ThisIsGoodsTara
			And ValueIsFilled(CurrentData.NumberOfDaysBeforeInventoryExpiration) Then
			
			StatisticsLine = StrTemplate(StatisticsLine,
										StatisticsText,
										CurrentData.AverageDailySale,
										CurrentData.UnitOfMeasureForecast,
										CurrentData.NumberOfDaysBeforeInventoryExpiration);
			
			LineForecast = New FormattedString(LineForecast, StatisticsLine);
			
		ElsIf ValueIsFilled(CurrentData.AverageDailySale) Then
			
			LineAverageDailySale = StrTemplate(LineAverageDailySale,
													SalesText,
													CurrentData.AverageDailySale,
													CurrentData.UnitOfMeasureForecast);
			
			LineForecast = New FormattedString(LineForecast, LineAverageDailySale);
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(LineForecast) Then
		LineForecast = New FormattedString(LineForecast, LineNoData);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel);
	
	If Not Cancel Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues,
			DefineSeriesParametersOnClient(Items.Goods.CurrentData.GetID()));
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	WhenChangingWarehouseInTablePartServer();
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,
		SeriesSpecificationParameters.SaleOfGoodsAndServices);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,
		SeriesSpecificationParameters.OrderDocument);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	
	CurrentData = Items.Goods.CurrentData;
	
	SeriesStatusesNeedToBeUpdated = False;
	
	If CurrentData <> Undefined Then
		
		IDCurrentRow     = CurrentData.GetID();
		
		SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues,
			DefineSeriesParametersOnClient(IDCurrentRow));
		
		If SeriesStatusesNeedToBeUpdated Then
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		EndIf;
		
	EndIf;
	
	If SeriesStatusesNeedToBeUpdated Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues,
			DefineSeriesParametersOnClient(IDCurrentRow));
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow And Not Copy Then
		CurrentData.Department = Object.Department;
	EndIf;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisObject, "Goods", CurrentData, NewRow, Copy);
	
	If Copy Then
		
		StructureOfActions = New Structure;
		AddCollateralActionsOnClient(StructureOfActions,
			"SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
		
		UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
		
	EndIf;
	
	If NewRow Then
		If Not Copy Then
			FillInLayoutOptionInRowOfTablePart(CurrentData, Object.DocumentCreationOption, Object.Date, Object.NotShipInInstallments);
		EndIf;
		
		UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		DefineSeriesParametersOnClient(CurrentData.GetID()),
		Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotals_(ThisObject);
	
	CurrentData = Items.Goods.CurrentData;
	
	If Not CancelEdit Then
		
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		
		If CurrentData <> Undefined Then
			If Object.NotShipInInstallments Then
				CurrentData.DateOfShipment = Object.DateOfShipment;
			EndIf;
			If CachedValues <> Undefined
				And CachedValues.Property("RegistrationOption")
				And CurrentData.RegistrationOption <> CachedValues.RegistrationOption Then
				CachedValues.RegistrationOption = CurrentData.RegistrationOption;
			EndIf;
		EndIf;
		
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		
	EndIf;
	
	If CurrentData <> Undefined Then
		If ProductsClient.SeriesStatusesNeedToBeUpdated(Item,CachedValues, DefineSeriesParametersOnClient(CurrentData.GetID())) Then
			IDCurrentRow = CurrentData.GetID();
			
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
			WarehousesClient.UpdateCachedValues(Item, CachedValues,
				DefineSeriesParametersOnClient(IDCurrentRow));
		EndIf;
	EndIf;
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure GoodsContentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(Item.EditText,
																ThisObject,
																"Items.Goods.CurrentData.Content",
																NStr("vi = 'Nội dung dịch vụ';
																	|ru = 'Содержание услуги';
																	|en = 'Service content'; fa = 'Service content';
																	|it = 'Contenuto del servizio';
																	|pl = 'Opis usługi';
																	|tr = 'Hizmet içeriği'"));
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurDataId = CurrentRow.GetID();
	
	CurrentRow.QuantityForReturn         = 0;
	CurrentRow.NumberOfPackagesDueToReturn = 0;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ParametersFillInVATRate = ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse",
								BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillIn_TermsOfSales",
									BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice",
									BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	StructureOfFillingInVATRate.VATTaxation = ParametersFillInVATRate.VATTaxation;
	StructureOfActions.Insert("FillInVATRateByPriceType", StructureOfFillingInVATRate);
	
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSalesOptionAttribute",
								New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInContent",
								BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("FillInFlagForWhetherThereIsProductSoldJointly",
								PredefinedValue("Enum.AnalysisOptionsForItemsSoldTogether.Wholesale"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
								New Structure("Warehouse, SeriesSpecificationParameters",
												CurrentRow.Warehouse,
												DefineSeriesParametersOnClient(CurDataId)));
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));

	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	ClearDetails_(CurrentRow);
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillIn_TermsOfSales",
									BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice",
									BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInContent",
								BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("FillInFlagForWhetherThereIsProductSoldJointly",
								PredefinedValue("Enum.AnalysisOptionsForItemsSoldTogether.Wholesale"));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	ClearDetails_(CurrentRow);
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurrentRowID = CurrentRow.GetID();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks", "Prediction");
	
	RecalculateNumberOfPackagesVolumeOfPreviousOrder(CurrentRow, CachedValues);
	
	If Object.CreateRequestForReturnOfGoodsFromCustomers Then
		RecalculateNumberOfPackagesToReturn(CurrentRowID, CachedValues);
	EndIf;
	
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillIn_TermsOfSales",
									BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice",
									BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesDueToReturnOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "ForReturn");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",
								New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow       = Items.Goods.CurrentData;
	ThisIsTransferOperation = ThisIsTransferOperation(Object.BusinessOperation);
	
	StructureOfPriceConversion  = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInWHSales(Object,
																													ThisIsTransferOperation);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", StructureOfPriceConversion);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurDataId = CurrentRow.GetID();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
								New Structure("Warehouse, SeriesSpecificationParameters",
												CurrentRow.Warehouse,
												DefineSeriesParametersOnClient(CurDataId)));
	AddCollateralActionsOnClient(StructureOfActions,
		"AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject,
												DefineSeriesParametersOnClient(ValueSelected.CurrentRowID),
												ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsRegistrationOptionOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurDataId = CurrentRow.GetID();
	
	SeriesParameters_ = DefineSeriesParametersOnClient(CurDataId);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
								New Structure("Warehouse, SeriesSpecificationParameters",
												CurrentRow.Warehouse, SeriesParameters_));
	
	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesParameters_);
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel, True);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.Goods.CurrentData,
		ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsSupplyOptionOnChange(Item)
	
	Var FormParameters;
	If ProvisionInDocumentsClient.OpenWarehouseAndSeriesSelectionForm(ThisObject) Then
		OptionForGettingParameters = ProvisionInDocumentsClientServer.ActionSelectionMode();
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(OptionForGettingParameters); // A call to the server
	EndIf;
	
	ProvisionInDocumentsClient.SupplyOptionOnChange(
		ThisObject,
		FormParameters,
		"ProcessWarehouseAndBatchSelection",
		True,
		"GoodsCollateralOptionWhenChangedAfterIssue");
	
EndProcedure

&AtClient
Procedure GoodsSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsWithAssignmentOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	ProvisionInDocumentsClient.WithAssignmentOnChange(TableRow);
	StructureOfActions = New Structure();
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, Undefined);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.WarehouseSelectionMode());
	
	If TypeOf(FormParameters) = Type("Structure") Then
		
		StandardProcessing = False;
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisObject,
			,
			,
			,
			New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCompletedDocuments_4

&AtClient
Procedure CompletedDocuments_4Selection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentItem = Items.CompletedDocumentsDocument Then
		
		StandardProcessing = False;
		If Items.CompletedDocuments_4.CurrentData <> Undefined Then
			ShowValue(Undefined, Items.CompletedDocuments_4.CurrentData.Document);
		EndIf;
		
	ElsIf Item.CurrentItem = Items.CompletedDocumentsPrint Then
		
		StandardProcessing = False;
		
		If Items.CompletedDocuments_4.CurrentData <> Undefined And Items.CompletedDocuments_4.CurrentData.Print Then
			
			ObjectsArray = New Array();
			ObjectsArray.Add(Items.CompletedDocuments_4.CurrentData.Document);
			
			FormParameters = New Structure();
			FormParameters.Insert("ObjectType", FullDocumentName(Items.CompletedDocuments_4.CurrentData.Document));
			FormParameters.Insert("Objects",    ObjectsArray);
			
			OpenForm("InformationRegister.ObjectPrintSettings.Form.SetPrintSettings", FormParameters, ThisObject);
				
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ShowMessages(Command)
	
	DiscountsMarkupsFillingClient.OpenMessageForm(TheStructureOfTheMessages(), ThisObject);
	
EndProcedure

&AtClient
Procedure PrintDetails(Item)
	
	OpenPrintDetails();
	
EndProcedure

&AtClient
Procedure BankDetailsStampOfTheAct(Item)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Counterparty",                    Object.Counterparty);
	ParametersStructure.Insert("AdditionalInformation",      Object.AdditionalInformation);
	ParametersStructure.Insert("AdditionalInformationOfHeader", Object.AdditionalInformationOfHeader);
	ParametersStructure.Insert("CounterpartyBankAccount",     Object.CounterpartyBankAccount);
	ParametersStructure.Insert("ReadOnly",                DocumentsAreCreated And Not Modified);
	
	OpenForm("DataProcessor.SalesWizard.Form.AttributesForCertificatePrinting", ParametersStructure, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInShipmentDate(Command)

	ArrayOfSelectedRows = Items.Goods.SelectedRows;
	If ArrayOfSelectedRows.Count() > 0 Then
		DateOfShipment = Object.DateOfShipment;
		
		Notification = New CallbackDescription("FillInShipmentDateCompletion", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
		
		TMCommonUseClient.EnterDateWithControlOfEmptyValue(DateOfShipment, NStr("vi = 'Hãy nhập ngày giao hàng';
																				|ru = 'Введите дату отгрузки';
																				|en = 'Enter shipment date'; fa = 'Enter shipment date';
																				|it = 'Inserire la data di spedizione';
																				|pl = 'Wprowadź datę wysyłki';
																				|tr = 'Sevkiyat tarihini girin'"), DateFractions.Date, Notification);
		
	Else
		WarningText = NStr("vi = 'Trong chứng từ chưa chọn dòng để điền. Sẽ không điền ngày giao hàng.';
							|ru = 'В документе не выбраны строки для заполнения. Дата отгрузки не будет заполнена.';
							|en = 'No lines to fill in are selected in the document. The shipment date will not be filled in.'; fa = 'No lines to fill in are selected in the document. The shipment date will not be filled in.';
							|it = 'Nel documento non sono selezionate le righe per la compilazione. La data di spedizione non verrà compilata.';
							|pl = 'W dokumencie nie wybrano wierszy do wypełnienia. Nie będzie wypełniono daty wysyłki.';
							|tr = 'Belgede doldurulacak herhangi bir satır seçilmemiştir. Sevkiyat tarihi doldurulmayacaktır.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;

EndProcedure

&AtClient
Procedure NewSale(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.SalesWizard.Form.Command.NewSale");
	
	If Modified Then
		
		CallbackDescription = New CallbackDescription("NewSaleCompletion", ThisObject);
		QueryText = NStr("vi = 'Tất cả dữ liệu chưa lưu lại sẽ bị mất. Bắt đầu lập lại chứng từ bán hàng?';
						|ru = 'Все несохраненные данные будут потеряны. Начать оформление продажи заново?';
						|en = 'All unsaved data will be lost. Start a sale again?'; fa = 'All unsaved data will be lost. Start a sale again?';
						|it = 'All unsaved data will be lost. Start a sale again?';
						|pl = 'All unsaved data will be lost. Start a sale again?';
						|tr = 'Kaydedilmemiş tüm veriler kaybolacaktır. Satış süreci tekrar başlatılsın mı?'");
		
		ButtonsList = New ValueList();
		ButtonsList.Add("ToBegin", NStr("vi = 'Bắt đầu bán hàng mới';
										|ru = 'Начать новую продажу';
										|en = 'Start new sale'; fa = 'شروع فروش جدید';
										|it = 'Iniziare una nuova vendita';
										|pl = 'Rozpocznij nową sprzedaż';
										|tr = 'Yeni bir satış başlat'"));
		ButtonsList.Add("DonTStart", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Cancel';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(CallbackDescription,
			QueryText,
			ButtonsList,,
			"DonTStart",
			NStr("vi = 'Lập chứng từ bán hàng mới';
				|ru = 'Оформление новой продажи';
				|en = 'Register a new sale'; fa = 'Register a new sale';
				|it = 'Register a new sale';
				|pl = 'Register a new sale';
				|tr = 'Yeni satış düzenleme'"), );
		
		Return;
		
	EndIf;
	
	NewSaleFragment();
	
EndProcedure

&AtClient
Procedure GoShoppingCart(Command)
	
	ResetTagsAndCaps(Items);
	
	Items.GoShoppingCart.Check   = True;
	Items.Pages.CurrentPage = Items.PageShoppingCart;
	
	FillInStatusesForSpecifyingSeries();
	
EndProcedure

&AtClient
Procedure GoPartner(Command)
		
	ResetTagsAndCaps(Items);
	
	ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisObject);
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	
	Items.GoPartner.Check   = True;
	Items.Pages.CurrentPage = Items.PagePartner;
	
EndProcedure

&AtClient
Procedure GoToShipmentPayment(Command)
	
	ResetTagsAndCaps(Items);
	
	Items.GoToShipmentPayment.Check = True;
	Items.Pages.CurrentPage      = Items.PagePaymentShipment;
		
EndProcedure

&AtClient
Procedure GoToDocuments_5(Command)
	
	GoToDocuments(Undefined);
	
EndProcedure

&AtClient
Procedure Setting(Command)
	
	OpenSettingsForm();
	
EndProcedure

&AtClient
Procedure CreatePartner(Command)
	
	If ValueIsFilled(Object.Partner) Then
		
		CallbackDescription = New CallbackDescription("CreatePartnerCompletion", ThisObject);
		
		QueryText = NStr("vi = 'Khách hàng hiện tại %Partner% sẽ được thay thế bằng khách hàng mới. Tạo mới khách hàng?';
						|ru = 'Текущий клиент %Partner% будет заменен на нового. Создать нового клиента?';
						|en = 'Current customer %Partner% will be replaced with a new one. Create a new customer?'; fa = 'Current customer %Partner% will be replaced with a new one. Create a new customer?';
						|it = 'Il cliente corrente %Partner% verrà sostituito con uno nuovo. Creare un nuovo cliente?';
						|pl = 'Bieżący klient %Partner% będzie wymieniony na nowy. Utworzyć nowego klienta?';
						|tr = 'Mevcut müşteri %Partner% yeni bir müşteri ile değiştirilecektir. Yeni bir müşteri mi oluşturulsun mu?'");
		QueryText = StrReplace(QueryText, "%Partner%", Object.Partner);
		
		ButtonsList = New ValueList();
		ButtonsList.Add("CreateNewClient",    NStr("vi = 'Tạo mới';
													|ru = 'Создать нового';
													|en = 'Create new'; fa = 'ایجاد جدید';
													|it = 'Creare una nuova controparte';
													|pl = 'Utwórz nowy';
													|tr = 'Yenisini oluştur'"));
		ButtonsList.Add("LeaveCurClient", NStr("vi = 'Để như hiện tại';
												|ru = 'Оставить текущего';
												|en = 'Leave the current'; fa = 'Leave the current';
												|it = 'Lasciare quello corrente';
												|pl = 'Zostawić bieżącego';
												|tr = 'Geçerli olan kalsın'"));
		
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		
		Return;
		
	EndIf;
	
	CreatePartnerFragment();
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	ProcessedDetails = "Count, Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount, "
		+ DependentPropsByString();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
								ProcessedDetails, "NumberOfPackages");
	
	If FormTable.CurrentData <> Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	CallbackDescription      = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, CallbackDescription);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure ToReadLoyaltyCard(Command)
	
	OpeningParameters = New Structure("Partner, Organization", Object.Partner, Object.Organization);
	
	OpenForm("Catalog.LoyaltyCards.Form.ReadLoyaltyCard", OpeningParameters, ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure AssignAutomaticDiscounts(Command)
	
	AddressInStorage = PerformPreliminaryCalculationOfDiscountsOnServer();
	Notification      = New CallbackDescription("AssignAutomaticDiscountsCompletion", ThisObject);
	
	DiscountsMarkupsFillingClient.OpenManagedDiscountMarkUpAssignmentForm(AddressInStorage, Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscount(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Wiersze pozycji';
																										|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(False);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Wiersze pozycji';
																										|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(True);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountForSelectedLinesCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Goods", NStr("vi = 'Hàng hóa';
																											|ru = 'Товары';
																											|en = 'Goods'; fa = 'کالاها';
																											|it = 'Merci';
																											|pl = 'Wiersze pozycji';
																											|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure CancelPaymentWithBonusPoints(Command)
	
	ApplyPaymentWithBonusPoints(Undefined);
	
EndProcedure

&AtClient
Procedure AddPaymentWithBonusPoints(Command) Export
	
	FillInCommunicationKeysInTablePart();

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Partner",                   Object.Partner);
	FormOpenParameters.Insert("LoyaltyCard",           Object.LoyaltyCard);
	FormOpenParameters.Insert("AddressOfTheTablePartProducts", AddressOfTheTablePartProducts());
	FormOpenParameters.Insert("Currency",                    Object.Currency);
	
	OpenForm(
		"Catalog.LoyaltyPrograms.Form.PaymentWithBonusPoints",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("AddPaymentWithBonusPointsCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	If Not Object.DiscountsAreCalculated Then
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("ApplyToObject",                True);
		ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
		ParametersStructure1.Insert("RestoreManagedDiscounts", True);
		ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisObject, UUID);
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
		CalculateDiscountsWithoutApplyingToObject();
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisObject);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPricesUnderAgreement(Command)
	
	TypeOfContractPrice = AccountingTypeOfContractPrice();
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
		
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales,Object.Terms,Object.Partner);
		
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'"), SelectedRows) Then
		FilterArray = New Array();
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		
		FilterStructure1 = New Structure("SelectGroup, IsFolder", FilterArray, False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses,TableRepresentation", 
			FilterStructure1, Object.Warehouse, TableRepresentation.List);

		OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisObject,,,, New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDocuments(Command)
	
	ClearMessages();
	
	If DocumentsAreCreated Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Create", NStr("vi = 'Tạo mới';
										|ru = 'Создать';
										|en = 'Create'; fa = 'ایجاد';
										|it = 'Creare';
										|pl = 'Create';
										|tr = 'Oluştur'"));
		ButtonsList.Add("NotCreate", NStr("vi = 'Không tạo mới';
											|ru = 'Не создавать';
											|en = 'Do not create'; fa = 'ایجاد نشود';
											|it = 'Non creare';
											|pl = 'Nie tworzyć';
											|tr = 'Oluşturma'"));
		
		ShowQueryBox(New CallbackDescription("CreateDocumentsCompletion", ThisObject), NStr("vi = 'Đã tạo chứng từ. Tạo mới chứng từ một lần nữa?';
																							|ru = 'Документы уже были созданы. Создать документы заново?';
																							|en = 'Documents have already been created. Create the documents again?'; fa = 'Documents have already been created. Create the documents again?';
																							|it = 'I documenti sono già stati creati. Creare i documenti nuovamente?';
																							|pl = 'Dokumenty zostały już utworzone. Utworzyć dokumenty na nowo?';
																							|tr = 'Belgeler zaten oluşturuldu. Belgeler tekrar oluşturulsun mu?'"), ButtonsList);
		
		Return;
		
	EndIf;
	
	CreateDocumentsClient(Undefined);
	
EndProcedure

&AtClient
Procedure MarkToDelete(Command)
	
	GetHighlightedDocuments(New CallbackDescription("MarkForDeletionAfterGetSelection", ThisObject));
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	GetHighlightedDocuments(New CallbackDescription("PostCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure UndoPosting(Command)
	
	GetHighlightedDocuments(New CallbackDescription("UndoPostingCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure PrintDocuments_(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.SalesWizard.Form.Command.PrintDocuments_");
	
	ClearMessages();
	
	DocumentsArray = New Array;
	
	For Each CurRow In Object.Documents Do
		
		If CurRow.State = 0 Then
			
			DocumentType = TypeOf(CurRow.Document);
			
			If Object.PrintSalesOrder
				And DocumentType = Type("DocumentRef.SalesOrder") Then
				
				DocumentsArray.Add(CurRow.Document);
				
			ElsIf Object.PrintRequestForReturnOfGoodsFromCustomer
				And DocumentType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				
				DocumentsArray.Add(CurRow.Document);
				
			ElsIf Object.PrintCommercialInvoice
				And DocumentType = Type("DocumentRef.CustomerCommercialInvoice") Then
				
				DocumentsArray.Add(CurRow.Document);
				
			ElsIf Object.PrintCustomerInvoice
				And DocumentType = Type("DocumentRef.CustomerInvoice") Then
				
				DocumentsArray.Add(CurRow.Document);
				
			ElsIf Object.PrintCustomerInvoiceWorksAndServices
				And DocumentType = Type("DocumentRef.CustomerInvoiceServices") Then
				
				DocumentsArray.Add(CurRow.Document);
				
			ElsIf Object.PrintCashAccountReceiptNote
				And DocumentType = Type("DocumentRef.CashAccountReceiptNote") Then
				
				DocumentsArray.Add(CurRow.Document);
				
			ElsIf Object.PrintTheTransferOfGoodsToBailee
				And DocumentType = Type("DocumentRef.TransferOfGoodsToBailee") Then
				
				DocumentsArray.Add(CurRow.Document);
				
			ElsIf Object.PrintCommercialProposal
				And DocumentType = Type("DocumentRef.CommercialProposalForCustomer") Then
		
				DocumentsArray.Add(CurRow.Document);
					
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If DocumentsArray.Count() > 0 Then
		
		PrintManagerName = "InformationRegister.ObjectPrintSettings";
		TemplatesNames       = "SetOfDocuments";
		
		If Object.DocumentCreationOption = 
			PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
			PrintManagerName = "Document.CommercialProposalForCustomer";
			TemplatesNames       = "CommercialProposalForCustomer";
		EndIf;
		
		PrintParameters    = New Structure("DisplayDiscounts_", DisplayDiscountsInPrintForms);
		
		PrintManagementClient.ExecutePrintToPrinterCommand(PrintManagerName, TemplatesNames, DocumentsArray,
			PrintParameters);
		
		If DocumentsArray.Count() > 0 Then
			NotificationText1 = NStr("vi = 'Đã in chứng từ (%DocumentsCount%)';
									|ru = 'Документы напечатаны (%DocumentsCount%)';
									|en = 'Documents are printed (%DocumentsCount%)'; fa = 'Documents are printed (%DocumentsCount%)';
									|it = 'I documenti sono stampati (%DocumentsCount%)';
									|pl = 'Dokumenty zostały wydrukowane (%DocumentsCount%)';
									|tr = 'Belgeler yazdırıldı (%DocumentsCount%)'");
			NotificationText1 = StrReplace(NotificationText1, "%DocumentsCount%", DocumentsArray.Count());
			
			ShowUserNotification(NotificationText1, , , PictureLib.Information32);
		EndIf;
		
	ElsIf Object.Documents.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không thể in. Chưa tạo chứng từ nào.';
								|ru = 'Печать недоступна. Не создано ни одного документа.';
								|en = 'Cannot print. No document is created.'; fa = 'Cannot print. No document is created.';
								|it = 'La stampa non è disponibile. Nessun documento creato.';
								|pl = 'Drukowanie nie jest dostępne. Nie utworzono ani jednego dokumentu.';
								|tr = 'Yazdırma işlemi yapılamıyor. Hiçbir belge oluşturulmadı.'"));
	Else
		ShowMessageBox(, NStr("vi = 'Chưa tùy chỉnh in chứng từ trong menu Tùy chỉnh...';
								|ru = 'Не настроена печать документов в меню Настройка...';
								|en = 'Document printing is not configured in the Setting menu...'; fa = 'Document printing is not configured in the Setting menu...';
								|it = 'Non è configurata la stampa dei documenti nel menu Impostazioni...';
								|pl = 'Nie jest skonfigurowany wydruk dokumentów w menu Ustawienia...';
								|tr = 'Belge yazdırma işlemi Kurulum menüsünde ayarlanmamış...'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure Change(Command)
	
	CallbackDescription = New CallbackDescription("ChangeCompletion", ThisObject);
	
	QueryText = NStr("vi = 'Sẽ thay thế chứng từ đã lập. Thay đổi các mục tin của chứng từ bán hàng hiện tại?';
					|ru = 'Сформированные документы будут заменены. Изменить реквизиты текущей продажи?';
					|en = 'Generated documents will be replaced. Change attributes of the current sale?'; fa = 'Generated documents will be replaced. Change attributes of the current sale?';
					|it = 'I documenti generati verranno sostituiti. Modificare i requisiti della vendita corrente?';
					|pl = 'Utworzone dokumenty zostaną zastąpione. Zmienić rekwizyty bieżącej sprzedaży?';
					|tr = 'Oluşturulan belgeler değiştirilecektir. Mevcut satışın öznitelikleri değiştirilsin mi?'");
	
	ButtonsList = New ValueList;
	ButtonsList.Add("Change",   NStr("vi = 'Thay đổi';
									|ru = 'Изменить';
									|en = 'Change'; fa = 'تغییر';
									|it = 'Modificare';
									|pl = 'Change';
									|tr = 'Değiştir'"));
	ButtonsList.Add("DontChange", NStr("vi = 'Không thay đổi';
										|ru = 'Не изменять';
										|en = 'Do not change'; fa = 'تغییر نکند';
										|it = 'Non modificare';
										|pl = 'Nie zmieniaj';
										|tr = 'Değiştirme'"));
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	Cancel = False;
	If (ToUseTermsOfSales And Not ValueIsFilled(Object.Terms))
		Or Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa trong Trợ giúp bán hàng';
							|ru = 'Подбор товаров в помощник продаж';
							|en = 'Pick goods using sales wizard'; fa = 'Pick goods using sales wizard';
							|it = 'Selezione dei prodotti per l''assistente alle vendite';
							|pl = 'Dobór towarów do asystenta sprzedaży';
							|tr = 'Satış sihirbazında ürünlerin seçimi'");
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner",    Object.Partner);
	If Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
		FormParameters.Insert("Terms", Undefined);
	Else
		FormParameters.Insert("Terms", Object.Terms);
	EndIf;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	If ValueIsFilled(Object.Warehouse) Then
		FormParameters.Insert("Warehouse", Object.Warehouse);
	Else
		FormParameters.Insert("AllWarehouseBalance", True);
	EndIf;
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	
	If ThisIsTransferOperation(Object.BusinessOperation) Then
		
		If Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal")
			Or Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer")
			Or Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee") Then
				
			FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(True, False);
			FormParameters.Insert("FilterByProductType", New FixedArray(FilterByProductType));
			
		EndIf;
		FormParameters.Insert("HideManualDiscounts",True);
		
	ElsIf ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
		FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer(True, False);
		FormParameters.Insert("FilterByProductType", New FixedArray(FilterByProductType));
		FormParameters.Insert("HideManualDiscounts", True);
	EndIf;

	PromptFillingIn = (Object.DateOfShipment = BegOfDay(CommonClient.SessionDate())	// If the prompt filling
		Or Not ValueIsFilled(Object.DateOfShipment));

	// Options for processing documents for which the "Ship" security option is forcibly set
	LimitedSupply = Object.DocumentCreationOption <> PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder")
		And Object.DocumentCreationOption <> PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer")
		And Object.DocumentCreationOption <> PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice");
	
	// Similar to interactive work:
	SetToShip = Object.NotShipInInstallments
		And (Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer")
			Or Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice"));
	
	If (LimitedSupply Or Object.NotShipInInstallments And PromptFillingIn And ToUseTermsOfSales)
		Or SetToShip Then
		
		OptionAndFlagForMatching = GetCollateralOptionAndFlagSeparately(
			PredefinedValue("Enum.SupplyOptions.Ship"),
			Object.Terms,
			Object.SalesOrderStatus);
		LimitSupplyOptions = True;
	ElsIf Object.SimplifiedFulfillment Then
		OptionAndFlagForMatching = GetCollateralOptionAndFlagSeparately(
			Object.SupplyOption,
			Object.Terms,
			Object.SalesOrderStatus);
		LimitSupplyOptions = True;
	Else
		LimitSupplyOptions = False;
		OptionAndFlagForMatching = SecurityOptionAndFlagSeparately;
	EndIf;

	ParametersForSpecifyingImplementationSeries = ThisIsImplementation(Object.DocumentCreationOption)
		Or ThisIsTransferOfGoods(Object.DocumentCreationOption);

	ParametersForSpecifyingSeriesParameter = ?(ParametersForSpecifyingImplementationSeries,
									   SeriesSpecificationParameters.SaleOfGoodsAndServices,
									   SeriesSpecificationParameters.OrderDocument);

	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("UseShipmentDates", Not Object.NotShipInInstallments);
	FormParameters.Insert("SeriesSpecificationParameters", ParametersForSpecifyingSeriesParameter);
	FormParameters.Insert("Purpose", Object.Purpose);
	FormParameters.Insert("Department", Object.Department);
	FormParameters.Insert("SelectSupplyOptions", Not LimitSupplyOptions);
	FormParameters.Insert("SecurityOptionAndFlagSeparately", OptionAndFlagForMatching);
	FormParameters.Insert("AvailableRemainingDocumentParameters",
		ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisObject));
	FormParameters.Insert("LimitSupplyOptions", LimitSupplyOptions);

	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);

EndProcedure

&AtClient
Procedure AddReusablePackage(Command)
	
	FieldsNames = NamingOfMultiTurnContainerSelectionFields(Object.DocumentCreationOption);
	ReusablePackageClient.SelectReusablePackage(
		ThisObject,
		"Goods",
		FieldsNames);
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	RowSelected = Items.Goods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể mở thành phần bộ sản phẩm đối với bộ sản phẩm.';
							|ru = 'Открытие состава набора возможно только для набора.';
							|en = 'You can open a set only for the set.'; fa = 'You can open a set only for the set.';
							|it = 'L''apertura della composizione del kit è possibile solo per il kit.';
							|pl = 'Otwarcie składu zestawu jest możliwe tylko dla zestawu.';
							|tr = 'Set kompozisyonunun açılması sadece bir set için mümkündür.'"));
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns", DialColumns(ThisObject));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Partner", Object.Partner);
	If Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
		OpeningParameters.Insert("Terms", Undefined);
	Else
		OpeningParameters.Insert("Terms", Object.Terms);
	EndIf;
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure ConsignmentNote(Command)
	
	ClearMessages();
	
	Items.CompletedDocuments_4ConsignmentNote.Check = Not Items.CompletedDocuments_4ConsignmentNote.Check;
	CreateConsignmentNote = Items.CompletedDocuments_4ConsignmentNote.Check;
	ManagementOfWaybills();
	ManagingTaggingOfConsignmentNoteCommand();
	
EndProcedure

&AtClient
Procedure IssuedLetterOfAuthority(Command)
	
	ClearMessages();
	
	Items.CompletedDocuments_4IssuedLetterOfAuthority.Check = Not Items.CompletedDocuments_4IssuedLetterOfAuthority.Check;
	CreateLetterOfAuthorityForReceivingCash = Items.CompletedDocuments_4IssuedLetterOfAuthority.Check;
	PowerOfAttorneyManagement();
	ManagingTeamTaggingPowerOfAttorney();
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

&AtClient
Procedure FillInAccordingToTheForecast(Command)
	
	SendForecastToServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure AdditionalAttributesSalesOrder(Command)
	
	AddressInTempStorage = PlaceAdditionalDetailsInTemporaryStorage("AdditionalOrderAttributes");
	
	FormParameters = New Structure();
	FormParameters.Insert("ReadOnly",            DocumentsAreCreated And Not Modified);
	FormParameters.Insert("DocumentType",              "DocumentObject.SalesOrder");
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	
	OpenForm(
		"DataProcessor.SalesWizard.Form.AdditionalAttributes",
		FormParameters,
		ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AdditionalRequestAttributes(Command)
	
	AddressInTempStorage = PlaceAdditionalDetailsInTemporaryStorage("AdditionalRequestAttributes");
	
	FormParameters = New Structure();
	FormParameters.Insert("ReadOnly",            DocumentsAreCreated And Not Modified);
	FormParameters.Insert("DocumentType",              "DocumentObject.RequestForReturnOfGoodsFromCustomer");
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	
	OpenForm(
		"DataProcessor.SalesWizard.Form.AdditionalAttributes",
		FormParameters,
		ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AdditionalDetailsCommercialOffer(Command)
	
	ImportParameters = New Structure;
	ImportParameters.Insert("NameOfAdditionalDetailsTable_", "");
	ImportParameters.Insert("ObjectName", "");
	
	If Command.Name = "AdditionalDetailsCommercialOffer" Then
		ImportParameters.NameOfAdditionalDetailsTable_ = "AdditionalAttributesOfCommercialProposal";
		ImportParameters.ObjectName                         = "DocumentObject.CommercialProposalForCustomer";
	EndIf;
	
	AddressInTempStorage = PlaceAdditionalDetailsInTemporaryStorage(ImportParameters.NameOfAdditionalDetailsTable_);
	
	FormParameters = New Structure();
	FormParameters.Insert("ReadOnly",            DocumentsAreCreated And Not Modified);
	FormParameters.Insert("DocumentType",              ImportParameters.ObjectName);
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	
	OpenForm(
		"DataProcessor.SalesWizard.Form.AdditionalAttributes",
		FormParameters,
		ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AdditionalDetailsSalesOfGoodsServices(Command)
	
	AddressInTempStorage = PlaceAdditionalDetailsInTemporaryStorage("AdditionalSaleAttributes");
	
	FormParameters = New Structure();
	FormParameters.Insert("ReadOnly",            DocumentsAreCreated And Not Modified);
	FormParameters.Insert("DocumentType",              "DocumentObject.CustomerInvoice");
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	
	OpenForm(
		"DataProcessor.SalesWizard.Form.AdditionalAttributes",
		FormParameters,
		ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AdditionalDetailsTransferOfGoodsToTheCustodian(Command)
	
	OpeningOption           = Not Modified
								And DocumentsAreCreated;
	AddressInTempStorage = PlaceAdditionalDetailsInTemporaryStorage("AdditionalAttributesTransferOfGoods");
	
	FormParameters = New Structure;
	FormParameters.Insert("ReadOnly",            OpeningOption);
	FormParameters.Insert("DocumentType",              "DocumentObject.TransferOfGoodsToBailee");
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	
	OpenForm("DataProcessor.SalesWizard.Form.AdditionalAttributes", FormParameters, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	Return;
	
EndProcedure

&AtClient
Procedure AdditionalAttributesShipmentOfGoodsToCustomer(Command)
	
	OpeningOption           = Not Modified
								And DocumentsAreCreated;
	AddressInTempStorage = PlaceAdditionalDetailsInTemporaryStorage("AdditionalAttributesOfGoodsShipment");
	
	FormParameters = New Structure;
	FormParameters.Insert("ReadOnly",            OpeningOption);
	FormParameters.Insert("DocumentType",              "DocumentObject.GoodsShipmentToCustomer");
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	
	OpenForm("DataProcessor.SalesWizard.Form.AdditionalAttributes", FormParameters, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	Return;
	
EndProcedure

&AtClient
Procedure AdditionalDetailsCertificateOfWorkPerformed(Command)
	
	AddressInTempStorage = PlaceAdditionalDetailsInTemporaryStorage("AdditionalInvoiceAttributes");
	
	FormParameters = New Structure();
	FormParameters.Insert("ReadOnly",            DocumentsAreCreated And Not Modified);
	FormParameters.Insert("DocumentType",              "DocumentObject.CustomerInvoiceServices");
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	
	OpenForm(
		"DataProcessor.SalesWizard.Form.AdditionalAttributes",
		FormParameters,
		ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#Region Supply

&AtClient
Procedure EnableStandAloneSoftware(Command)
	
	ProvidingSetAction("FLAG_UNITED");
	
EndProcedure

&AtClient
Procedure DisableStandAloneSoftware(Command)
	
	ProvidingSetAction("FLAG_NOTABLE");
	
EndProcedure

&AtClient
Procedure ToSupply(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ReserveAsReceived(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure NotProvide(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure Ship(Command)
	
	ProvidingSetActionWithQuestion("ACTION_LOAD");
	
EndProcedure

&AtClient
Procedure ToReserve_(Command)
	
	ProvidingSetActionWithQuestion("ACTION_RESERVE");
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Conditional registration of collateral.
	
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.GoodsWithAssignment,
		"Object.Goods.SupplyOption",
		"Object.Goods.ItemsType");
		
	// Prohibition of editing the security option for the options for ordering + implementation (transfer)
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSupplyOption.Name);
	
	ListOfDesignOptions = New ValueList();
	ListOfDesignOptions.Add(Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
	ListOfDesignOptions.Add(Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Goods.RegistrationOption");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = ListOfDesignOptions;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	
	TMCommonUse.SetUncheckBlank(ConditionalAppearance,
															"DateOfShipment",
															"Object.DateOfShipment",
															"DateOfShipmentRequired_");
	
	TMCommonUse.SetUncheckBlank(ConditionalAppearance,
															"GoodsDateOfShipment",
															"Object.Goods.DateOfShipment",
															"Object.Goods.DateOfShipmentRequired_");
	
	TMCommonUse.SetUncheckBlank(ConditionalAppearance,
															"Warehouse",
															"Object.Warehouse",
															"WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(ConditionalAppearance,
															"GoodsWarehouse",
															"Object.Goods.Warehouse",
															"Object.Goods.WarehouseIsRequired");
	
	SettingMarkOfEmptyWarehouseAndDateOfShipmentForDesignOption();
	
	// Hiding the security option for the design options Implementation and Commercial Offer.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSupplyOption.Name);
	ItemField.Field = New DataCompositionField(Items.GoodsWithAssignment.Name);
	ItemField.Field = New DataCompositionField(Items.GoodsAvailable.Name);
	
	OptionsForRegistrationOfDocuments = New ValueList;
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal);
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice);
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = OptionsForRegistrationOfDocuments;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	GoodsTransferOperations = New ValueList;
	GoodsTransferOperations.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	GoodsTransferOperations.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseDiscountAdjustmentsInSales");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = GoodsTransferOperations;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject);
	
	//
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	
	//
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfContent(ThisObject);
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cần điền mặt hàng>';
													|ru = '<необходимо заполнить номенклатуру>';
													|en = '<fill in items>'; fa = '<fill in items>';
													|it = '<необходимо заполнить номенклатуру>';
													|pl = '<fill in items>';
													|tr = '<öğe doldurulmalıdır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PictureMultipleWarehouses.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsBatchesIndicationStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFillInTheWarehouseInSelectedLines.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompletedDocumentsPrint.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Documents.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Documents.Document");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotContains;
	ItemFilter.RightValue = NStr("vi = 'Phiếu xuất kho';
								|ru = 'Расходный ордер';
								|en = 'Goods issue note'; fa = 'حواله صدور کالا';
								|it = 'Mandato di pagamento';
								|pl = 'Asygnata rozchodowa';
								|tr = 'Ambar çıkış fişi'");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mẫu in';
													|ru = 'Печатные формы';
													|en = 'Print forms'; fa = 'فرم‌های چاپی';
													|it = 'Modelli di stampa';
													|pl = 'Formularze wydruku';
													|tr = 'Yazdırma formları'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompletedDocumentsPrint.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Documents.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", "");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IssuedDocumentsFiscalized.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IssueAFiscalReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FiscalizationIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRegistrationOption.Name);
	
	OptionsForRegistrationOfDocuments = New ValueList;
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = OptionsForRegistrationOfDocuments;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);
	
	//
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	InstallationParameters.Form          = ThisObject;
	InstallationParameters.ThisIsAdmission = False;
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);
	
	ListOfSeriesStatuses = New ValueList;
	ListOfSeriesStatuses.Add(11);
	ListOfSeriesStatuses.Add(15);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfSeriesStatuses;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	
	//
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");
	
	//
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPackagesDueToReturn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesDueToReturn.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ListOfServiceTypes = New ValueList;
	ListOfServiceTypes.Add(Enums.ItemsTypes.OperationService);
	ListOfServiceTypes.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ListOfServiceTypes;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
#Region MarkingEmptyDivision
	
	OptionsForRegistrationOfDocuments = New ValueList;
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice);
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee);
	
	// Setting the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = OptionsForRegistrationOfDocuments;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Removing the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = OptionsForRegistrationOfDocuments;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject);
	
#EndRegion
	
EndProcedure

&AtServer
Procedure SettingMarkOfEmptyWarehouseAndDateOfShipmentForDesignOption()
	
	SalesRegistrationOptions = New ValueList;
	SalesRegistrationOptions.Add(Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice);
	SalesRegistrationOptions.Add(Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Warehouse");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = SalesRegistrationOptions;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Warehouse");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("WarehouseIsRequired");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Warehouse");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Warehouse");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DateOfShipment");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = SalesRegistrationOptions;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DateOfShipment");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsDateOfShipment");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = SalesRegistrationOptions;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Goods.DateOfShipment");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsWarehouse");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = SalesRegistrationOptions;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	Filter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	Filter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GoodsWarehouse");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DocumentCreationOption");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetMarkIncompleteWarehouse()
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee Or
		Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
		WarehouseIsRequired = 1;
		Items.Warehouse.AutoMarkIncomplete = True;
	Else
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;
	
EndProcedure

#Region Pickup

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterSelection(
		ThisObject,
		ValueSelected,
		"ProcessingSelectionIsDoneOnClientAfterQuestion");
	
	WhenChangingWarehouseInTablePartServer();
	CalculateTotals_(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessingSelectionIsDoneOnClientAfterQuestion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.Yes Then
		Object.NotShipInInstallments = False;
		
		SetVisibilityOfShippingDateFormElements();
	EndIf;
	
	ProcessingSelectionOfSelectionOnServer(AdditionalParameters);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, ListOfProperties = Undefined)
	
	FillWarehouses_      = False;
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	ParametersFillInVATRate = ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	StructureOfFillingInVATRate.VATTaxation = ParametersFillInVATRate.VATTaxation;
	StructureOfActions.Insert("FillInVATRateByPriceType", StructureOfFillingInVATRate);
	
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSalesOptionAttribute",
		New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks", "Prediction");
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	If Not ValueIsFilled(ListOfProperties) Then
		ListOfProperties = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, PriceKind, Price, 
						|NumberOfPackages, DeliveryPeriodDays, PercentRateOfManualDiscount, SupplyOption, Series, DateOfShipment, WithAssignment";
		
		If ValueIsFilled(Object.Warehouse) Then
			ListOfProperties = ListOfProperties + ", Warehouse";
		EndIf;
	EndIf;
	
	// Fill in the warehouses according to the header, if the warehouses did not arrive in the table.
	FillWarehouses_ = StrFind(ListOfProperties, "Warehouse") = 0;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	RowsToProcess = New Array();
	
	SearchFields = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, PriceKind, 
		|DeliveryPeriodDays, SupplyOption, Series, WithAssignment";
	If Not FillWarehouses_ Then
		SearchFields = SearchFields + ", Warehouse";
	EndIf;
	If Not Object.NotShipInInstallments Then
		SearchFields = SearchFields + ", DateOfShipment";
	EndIf;
	FilterParameters = New Structure(SearchFields);
	
	For Each RowOfProduct In TableOfGoods Do
		
		If CommonClientServer.HasAttributeOrObjectProperty(RowOfProduct, "ProductsInSet")
			And ValueIsFilled(RowOfProduct.ProductsInSet) Then
			// For sets, you should increase the number in the set lines that have already been added to the TS.
			
			FillPropertyValues(FilterParameters, RowOfProduct);
			FoundRows = Object.Goods.FindRows(FilterParameters);
			
			If FoundRows.Count() > 0 Then
				CurrentRow = FoundRows[0];
				CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + RowOfProduct.NumberOfPackages;
			Else
				CurrentRow = Object.Goods.Add();
				FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
			EndIf;
		Else
			// For non-sets, you should always add a new line, regardless of the availability of such an item in the TS.
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		EndIf;
		
		If CurrentRow.SelectionIconIndex = 0 Then
			If CurrentRow.QuantityForecast > 0 Then
				CurrentRow.SelectionIconIndex = 1;
			ElsIf CurrentRow.QuantityPreviousOrderVolume > 0 Then
				CurrentRow.SelectionIconIndex = 2;
				CurrentRow.QuantityForecast = CurrentRow.QuantityPreviousOrderVolume;
			Else
				CurrentRow.SelectionIconIndex = 0;
			EndIf;
		EndIf;
		
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		
		RecalculateNumberOfPackagesVolumeOfPreviousOrder(CurrentRow, CachedValues);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	For Each CurrentRow In RowsToProcess Do
		
		CurrentRow.DateOfShipment = ProvisionInDocumentsServer.ShipmentDateProcessingSelectionSelection(
			CurrentRow.DateOfShipment,
			CurrentRow.SupplyOption,
			BegOfDay);
		FillInLayoutOptionInRowOfTablePart(CurrentRow, Object.DocumentCreationOption, Object.Date, Object.NotShipInInstallments);
		
	EndDo;
	
	ProvisionInDocumentsServer.UpdateShipmentDateWithSingleDate(
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.Goods,
		"DateOfShipment");
	
	If FillWarehouses_ Then
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
		
		WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, False);
		
		Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	EndIf;
	
	FillInStatusesForSpecifyingSeries();
	WhenChangingBucketOnServer();
	UpdateColumnAvailableServer();
	
EndProcedure


&AtServer
Procedure SetAgreementSelectionParameters()
	
	FormItem = Items.Terms;
	NewSelectionOptions = New Array;
	
	If Not ValueIsFilled(Object.Partner) Then
		NewParameter1 = New ChoiceParameter("OnlyStandard", True);
		NewSelectionOptions.Add(NewParameter1);
		
		NewParameter1 = New ChoiceParameter("Filter.PartnersSegment", Catalogs.PartnersSegments.EmptyRef());
		NewSelectionOptions.Add(NewParameter1);
	EndIf;
	
	If ThisIsImplementation(Object.DocumentCreationOption) Then
		OperationsOfSale = Items.BusinessOperation.ChoiceList.UnloadValues();
		
		ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", OperationsOfSale);
		NewSelectionOptions.Add(ChoiceParameter);
		
		If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice Then
			ChoiceParameter = New ChoiceParameter("Filter.ConsignmentSales25", False);
			NewSelectionOptions.Add(ChoiceParameter);
		EndIf
		
	EndIf;
	
	If ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		
		ChoiceParameter = New ChoiceParameter("OnlyTransferOperations", True);
		NewSelectionOptions.Add(ChoiceParameter);
		
		If UseShipmentWithDeferredTransferOfTitle2_5 Then
			ChoiceParameter = New ChoiceParameter("ShipmentWithDeferredTransferOfTitle25", True);
			NewSelectionOptions.Add(ChoiceParameter);
		EndIf;
		
	EndIf;
	
	FormItem.ChoiceParameters = New FixedArray(NewSelectionOptions);
	
EndProcedure

&AtServer
Procedure EstablishRelationshipsBetweenContractSelectionParameters()
	
	FormItem = Items.Contract;
	NewSelectionParameterRelationships = New Array;
	
	PathToDataIsBT = "";
	For Each RelationshipOfSelectionParameters In FormItem.ChoiceParameterLinks Do
		If Not RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation" Then
			NewSelectionParameterRelationships.Add(RelationshipOfSelectionParameters);
		Else
			PathToDataIsBT = RelationshipOfSelectionParameters.DataPath;
		EndIf;
	EndDo;
	
	DataPath = "Object.BusinessOperation";
	If ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
		DataPath = "OperationImplementationToClient";
	EndIf;
	
	If PathToDataIsBT = DataPath Then
		Return;
	EndIf;
	
	ChoiceParameterLink = New ChoiceParameterLink("Filter.BusinessOperation",
														DataPath,
														LinkedValueChangeMode.Clear);
	NewSelectionParameterRelationships.Add(ChoiceParameterLink);
	FormItem.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillThePricesByTermsOfSalesServer()
	
	RowsArray = New Array;
	
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And Common.ObjectAttributeValue(Object.Contract, "ConsignmentSales25") Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract,"PriceTypeAccountingPriceType"));
	Else
		FillParameters.Insert("Terms", Object.Terms);
	EndIf;
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind, DeliveryPeriodDays");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	For Each String In Items.Goods.SelectedRows Do
		CurrentRow = Object.Goods.FindByID(String);
		CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	EndDo;
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Organization",        Object.Organization);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("PriceKind",            PricesKind);
	FillParameters.Insert("PriceIncludesVAT",    Object.PriceIncludesVAT);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields",     "Price, PriceKind");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	For Each String In Items.Goods.SelectedRows Do
		CurrentRow = Object.Goods.FindByID(String);
		CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	EndDo;
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure CalculateDiscountsWithoutApplyingToObject()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = False;
	ParametersStructure1.RestoreManagedDiscounts	 = True;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
	AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	
EndProcedure

&AtServer
Function CalculateDiscountsMarginsOnServer(ParametersStructure1, TakeFromTemporaryStorage = False)
	
	If TakeFromTemporaryStorage Then
		AppliedDiscounts = GetFromTempStorage(AddressOfAppliedDiscountsInTheTemporaryStorage);
		DiscountsMarkupsFillingServer.ApplyCalculationResult(Object, AppliedDiscounts);
	Else
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	EndIf;
	
	Object.DiscountsAreCalculated = True;
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	UpdateTextOfInformationLabelGeneratedDocuments();
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	Return TheStructureOfTheMessages;
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	If AmountOfDiscountMarkUp <> 0 Then
		
		DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
		DiscountParameters.AutomaticDiscountsAreUsed = True;
		DiscountParameters.OnlyForActiveRows			 = False;
		DiscountParameters.CalculateAmountWithVAT			 = True;
		DiscountParameters.SelectedRows				 = SelectedRows;
		DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
		DiscountParameters.SalesInExcessOfOrder			 = False;
		
		DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", AmountOfDiscountMarkUp, DiscountParameters);
		
	Else
		DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", True, True);
	EndIf;
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtServer
Function PerformPreliminaryCalculationOfDiscountsOnServer()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject = False;
	ParametersStructure1.OnlyPreliminaryCalculation = True;
	ParametersStructure1.RestoreManagedDiscounts = True;
	ParametersStructure1.ManagedDiscounts = ManagedDiscounts;
	
	Return PutToTempStorage(
		DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1), UUID);
	
EndFunction

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName				 = "Goods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisObject, UUID, ParametersStructure);
	
EndFunction

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", True, True);
	
EndProcedure

&AtClient
Procedure LoyaltyCardIsRead(Val Notification, LoyaltyCard)
	
	LoyaltyCardDetails = LoyaltyCardServerCall.GetLoyaltyCardDetails(LoyaltyCard);
	
	If ValueIsFilled(LoyaltyCardDetails.Ref) Then
		
		If Not LoyaltyCardDetails.PartnerAvailable Then
			ShowMessageBox(New CallbackDescription("LoyaltyCardIsReadCompletion", ThisObject, New Structure("Notification", Notification)), NStr("vi = 'Không có quyền truy cập đến bạn hàng sở hữu thẻ khách hàng thân thiết.';
																																				|ru = 'Нет доступа к партнеру-владельцу карты лояльности.';
																																				|en = 'No access to the partner who holds the loyalty card.'; fa = 'No access to the partner who holds the loyalty card.';
																																				|it = 'Nessun accesso al partner-titolare della carta fedeltà.';
																																				|pl = 'Brak dostępu do partnera-posiadacza karty lojalnościowej.';
																																				|tr = 'Sadakat kart sahibi iş ortağına erişim yok.'"));
			Return;
		EndIf;
		
		If Not ValueIsFilled(LoyaltyCardDetails.Partner) Then // Depersonalized card
			
			DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
			Modified = True;
			Object.LoyaltyCard   = LoyaltyCard;
			
			RunCallback(Notification);
			Return;
			
		ElsIf Object.Partner <> LoyaltyCardDetails.Partner Then // The partner in the card is different from the partner in the shoulder strap.
			
			If ValueIsFilled(Object.Partner) Then
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("Notification", Notification);
				AdditionalParameters.Insert("LoyaltyCard", LoyaltyCard);
				AdditionalParameters.Insert("LoyaltyCardDetails", LoyaltyCardDetails);
				ShowQueryBox(
					New CallbackDescription("LoyaltyCardReadQuestionCompletion", ThisObject, AdditionalParameters),
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thẻ khách hàng thân thiết đang thuộc bạn hàng ""%1"". Thay đổi bạn hàng trong bộ trợ giúp?';
																					|ru = 'Карта лояльности принадлежит партнеру ""%1"". Изменить партнера в помощнике?';
																					|en = 'The loyalty card belongs to partner ""%1"". Change the partner in wizard?'; fa = 'The loyalty card belongs to partner ""%1"". Change the partner in wizard?';
																					|it = 'La carta fedeltà appartiene al partner ""%1"". Sostituire il partner in assistente?';
																					|pl = 'Karty lojalnościowa należy do partnera ""%1"". Zmienić partnera w asystencie?';
																					|tr = 'Sadakat kartı ""%1"" adlı iş ortağına aittir. Sihirbazdaki iş ortağı değiştirilsin mi?'"), LoyaltyCardDetails.Partner),
					QuestionDialogMode.YesNo);
				Return;
			EndIf;
			
		Else // The partner in the document is equal to the partner in the map.
			
			QuestionOfChangingCounterparty = False;
			If ValueIsFilled(LoyaltyCardDetails.Counterparty)
				And ValueIsFilled(Object.Counterparty) And LoyaltyCardDetails.Counterparty <> Object.Counterparty Then
				QuestionOfChangingCounterparty = True;
			EndIf;
			
			QuestionOfChangingAgreement = False;
			If ToUseTermsOfSales And ValueIsFilled(LoyaltyCardDetails.Terms)
				And ValueIsFilled(Object.Terms) And LoyaltyCardDetails.Terms <> Object.Terms Then
				QuestionOfChangingAgreement = True;
			EndIf;
			
			If QuestionOfChangingCounterparty Or QuestionOfChangingAgreement Then
				
				CounterpartyChangeNotAvailable = QuestionOfChangingCounterparty And Not LoyaltyCardDetails.CounterpartyAvailable;
				AgreementChangeNotAvailable  = QuestionOfChangingAgreement  And Not LoyaltyCardDetails.AgreementAvailable;
				
				If CounterpartyChangeNotAvailable And AgreementChangeNotAvailable Then
					WarningText = NStr("vi = 'Đối với thẻ khách hàng thân thiết, một đối tác và một thỏa thuận được thiết lập không có sẵn cho người dùng hiện tại. Một thẻ khách hàng thân thiết có thể được áp dụng bởi một người dùng khác có quyền truy cập vào đối tác và thỏa thuận của nó.';
										|ru = 'Для карты лояльности заданы контрагент и соглашение, недоступные текущему пользователю. Применить карту лояльности может другой пользователь, имеющий доступ к ее контрагенту и соглашению.';
										|en = 'Counterparty and agreement unavailable for the current user are specified for the loyalty card. Another user that has access to its counterparty and agreement can apply it.'; fa = 'Counterparty and agreement unavailable for the current user are specified for the loyalty card. Another user that has access to its counterparty and agreement can apply it.';
										|it = 'Per la carta fedeltà sono impostati un contraente e un contratto non disponibili per l''utente corrente. Applicare la carta fedeltà potrà un altro utente, che possiede l''accesso al contraente e al contratto di essa.';
										|pl = 'Dla karty lojalnościowej są ustawione kontrahent i umowa, które nie są dostępne dla bieżącego użytkownika. Zastosować kartę lojalnościową może inny użytkownik, który ma dostęp do jej kontrahentów i umowy.';
										|tr = 'Sadakat kartı, mevcut kullanıcı tarafından kullanılamayan bir cari hesaba ve anlaşmaya sahiptir. Sadakat kartı, cari hesaba ve anlaşmaya erişimi olan başka bir kullanıcı tarafından uygulanabilir.'");
				ElsIf CounterpartyChangeNotAvailable Then
					WarningText = NStr("vi = 'Một đối tác không thể truy cập đối với người dùng hiện tại được đặt cho thẻ khách hàng thân thiết. Áp dụng thẻ khách hàng thân thiết có thể người dùng khác có quyền truy cập vào đối tác của mình.';
										|ru = 'Для карты лояльности задан контрагент, недоступный текущему пользователю. Применить карту лояльности может другой пользователь, имеющий доступ к ее контрагенту.';
										|en = 'Counterparty unavailable for the current user is specified for the loyalty card. Another user that has access to its counterparty can apply it.'; fa = 'Counterparty unavailable for the current user is specified for the loyalty card. Another user that has access to its counterparty can apply it.';
										|it = 'Per la carta fedeltà è impostato un contraente non disponibile per l''utente corrente. Applicare la carta fedeltà potrà un altro utente, che possiede l''accesso al contraente di essa.';
										|pl = 'Dla karty lojalnościowej jest ustawiony kontrahent, który nie jest dostępny dla bieżącego użytkownika. Zastosować kartę lojalnościową może inny użytkownik, który ma dostęp do jej kontrahenta.';
										|tr = 'Sadakat kartına mevcut kullanıcı için mevcut olmayan bir cari hesap atanmıştır. Sadakat kartı, muadiline erişimi olan başka bir kullanıcı tarafından uygulanabilir.'");
				ElsIf AgreementChangeNotAvailable Then
					WarningText = NStr("vi = 'Đã đặt thỏa thuận cho thẻ khách hàng thân thiết không hợp lệ đối với người sử dụng hiện tại. Người sử dụng khác có quyền truy cập đến thỏa thuận của thẻ mới có thể áp dụng thẻ khách hàng thân thiết.';
										|ru = 'Для карты лояльности задано соглашение, недоступное текущему пользователю. Применить карту лояльности может другой пользователь, имеющий доступ к ее соглашению.';
										|en = 'Agreement unavailable for the current user is specified for the loyalty card. Another user that has access to its agreement can apply it.'; fa = 'Agreement unavailable for the current user is specified for the loyalty card. Another user that has access to its agreement can apply it.';
										|it = 'Per la carta fedeltà è impostato un contratto non disponibile per l''utente corrente. Applicare la carta fedeltà potrà un altro utente, che possiede l''accesso al contratto di essa.';
										|pl = 'Dla karty lojalnościowej jest ustawiona umowa która nie jest dostępna dla bieżącego użytkownika. Zastosować kartę lojalnościową może inny użytkownik, który ma dostęp do jej kontrahenta.';
										|tr = 'Sadakat kartı, mevcut kullanıcı tarafından kullanılamayan tanımlanmış bir anlaşmaya sahiptir. Sadakat kartı, anlaşmaya erişimi olan başka bir kullanıcı tarafından uygulanabilir.'");
				EndIf;
				
				If CounterpartyChangeNotAvailable Or AgreementChangeNotAvailable Then
					ShowMessageBox(, WarningText, 30);
					RunCallback(Notification);
				Else
					If QuestionOfChangingCounterparty And QuestionOfChangingAgreement Then
						QueryText = NStr("vi = 'Đối với thẻ khách hàng thân thiết có đặt đối tác ""%1"" và thỏa thuận ""%2"". Áp dụng thẻ khách hàng thân thiết và đặt vào bộ trợ giúp của đối tác ""%1"" cả thỏa thuận ""%2""?';
										|ru = 'Для карты лояльности заданы контрагент ""%1"" и соглашение ""%2"". Применить карту лояльности и подставить в помощник контрагента ""%1"" и соглашение ""%2""?';
										|en = 'Counterparty ""%1"" and agreement ""%2"" are specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" and agreement ""%2"" to the wizard?'; fa = 'Counterparty ""%1"" and agreement ""%2"" are specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" and agreement ""%2"" to the wizard?';
										|it = 'Per la carta fedeltà sono impostati il contraente ""%1"" e il contratto ""%2"". Applicare la carta fedeltà ed impostare per l''assistente il contraente ""%1"" e il contratto ""%2""?';
										|pl = 'Dla karty lojalnościowej jest ustawiony kontrahent ""%1"" i umowa ""%2"". Zastosować kartę lojalnościową i podstawić do asystenta kontrahenta ""%1"" i umowę ""%2""?';
										|tr = 'Sadakat kartına ""%1"" cari hesabı ve ""%2"" anlaşması atanmıştır. Sadakat kartı uygulansın ve asistanda ""%1"" cari hesabı ve ""%2"" anlaşması değiştirilsin mi?'");
					ElsIf QuestionOfChangingCounterparty Then
						QueryText = NStr("vi = 'Đã đặt đối tác ""%1"" đối với thẻ khách hàng thân thiết. Áp dụng thẻ khách hàng thân thiết và chèn vào trợ giúp đối tác ""%1""?';
										|ru = 'Для карты лояльности задан контрагент ""%1"". Применить карту лояльности и подставить в помощник контрагента ""%1""?';
										|en = 'Counterparty ""%1"" is specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" to the wizard?'; fa = 'Counterparty ""%1"" is specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" to the wizard?';
										|it = 'Per la carta fedeltà è impostato il contraente ""%1"". Applicare la carta fedeltà ed impostare per l''assistente il contraente ""%1""?';
										|pl = 'Dla karty lojalnościowej jest ustawiony kontrahent ""%1"". Zastosować kartę lojalnościową i podstawić do asystenta kontrahenta ""%1""?';
										|tr = 'Sadakat kartına ""%1"" cari hesabı ayarlanmıştır. Sadakat kartı uygulansın ve sihirbazda ""%1"" cari hesabı değiştirilsin mi?'");
					ElsIf QuestionOfChangingAgreement Then
						QueryText = NStr("vi = 'Đối với thẻ khách hàng thân thiết có đặt thỏa thuận ""%2"". Áp dụng thẻ khách hàng thân thiết và đặt vào bộ trợ giúp thỏa thuận ""%2""?';
										|ru = 'Для карты лояльности задано соглашение ""%2"". Применить карту лояльности и подставить в помощник соглашение ""%2""?';
										|en = 'Agreement ""%2"" is specified for the loyalty card. Apply the loyalty card and substitute agreement ""%2"" to the wizard?'; fa = 'Agreement ""%2"" is specified for the loyalty card. Apply the loyalty card and substitute agreement ""%2"" to the wizard?';
										|it = 'Per la carta fedeltà è impostato il contratto ""%2"". Applicare la carta fedeltà ed impostare per l''assistente il contratto ""%2""?';
										|pl = 'Dla karty lojalnościowej jest ustawiona umowa ""%2"". Zastosować kartę lojalnościową i podstawić do asystenta umowę ""%2""?';
										|tr = 'Sadakat kartı ""%2"" anlaşmasına ayarlanmıştır. Sadakat kartını uygulansın ve sihirbazda ""%2"" anlaşması değiştirilsin mi?'");
					EndIf;
					
					AdditionalParameters = New Structure;
					AdditionalParameters.Insert("Notification", Notification);
					AdditionalParameters.Insert("LoyaltyCard", LoyaltyCard);
					AdditionalParameters.Insert("LoyaltyCardDetails", LoyaltyCardDetails);
					ShowQueryBox(
						New CallbackDescription("LoyaltyCardReadQuestionCompletion", ThisObject, AdditionalParameters),
						StringFunctionsClientServer.SubstituteParametersToString(QueryText, LoyaltyCardDetails.Counterparty, LoyaltyCardDetails.Terms),
						QuestionDialogMode.YesNo);
				EndIf;
					
				Return;
				
			EndIf;
			
		EndIf;
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		Modified = True;
		Object.LoyaltyCard   = LoyaltyCard;
		LoyaltyCardReadOnServer(LoyaltyCardDetails);
		
	Else
		
		UseLoyaltyPrograms = UseLoyaltyPrograms(Undefined);
		ApplyPaymentWithBonusPoints(Undefined);
		SetVisibilityOfElementsOfLoyaltyBonusProgram();
		
	EndIf;
	
	RunCallback(Notification);
	
EndProcedure

&AtClient
Procedure LoyaltyCardReadQuestionCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		
		UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
		SetVisibilityOfElementsOfLoyaltyBonusProgram();
		RunCallback(AdditionalParameters.Notification);
		
	ElsIf Response = DialogReturnCode.Yes Then
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		Modified = True;
		Object.LoyaltyCard = AdditionalParameters.LoyaltyCard;
		LoyaltyCardReadOnServer(AdditionalParameters.LoyaltyCardDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoyaltyCardIsReadCompletion(AdditionalParameters) Export
	
	Notification = AdditionalParameters.Notification;
	
	RunCallback(Notification);
	
EndProcedure

&AtServer
Procedure LoyaltyCardReadOnServer(LoyaltyCardDetails)
	
	If ValueIsFilled(LoyaltyCardDetails.Partner) And LoyaltyCardDetails.Partner <> Object.Partner Then
		Object.Partner = LoyaltyCardDetails.Partner;
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Object.Terms = Catalogs.TermsOfSale.EmptyRef();
		PartnerOnChangeServer();
	EndIf;
	
	If ValueIsFilled(LoyaltyCardDetails.Terms)
		And LoyaltyCardDetails.Terms <> Object.Terms
		And LoyaltyCardDetails.AgreementAvailable Then
		Object.Terms = LoyaltyCardDetails.Terms;
		TermsOnChangeServer();
	EndIf;
	
	If ValueIsFilled(LoyaltyCardDetails.Counterparty)
		And LoyaltyCardDetails.Counterparty <> Object.Counterparty
		And LoyaltyCardDetails.CounterpartyAvailable Then
		Object.Counterparty = LoyaltyCardDetails.Counterparty;
		CounterpartyOnChangeServer();
	EndIf;

	UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
	SetVisibilityOfElementsOfLoyaltyBonusProgram();
	
EndProcedure

&AtServerNoContext
Function UseLoyaltyPrograms(LoyaltyCard)
	
	If Not ValueIsFilled(LoyaltyCard) Then
		Return False;
	EndIf;
	
	Return DiscountsMarkupsServer.UseLoyaltyPrograms(LoyaltyCard);
	
EndFunction

&AtServer
Procedure MessagesReceived(Messages)
	
	DiscountsMarkupsFillingServer.SaveSpentMessages(Object, Messages);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
EndProcedure

&AtServer
Function DiscountsHaveChanged()
	
	DiscountsHaveChanged = DiscountsMarkupsFillingServer.DiscountsMustBeRecalculated(
		Object, 
		ManagedDiscounts, 
		UUID, 
		AddressOfAppliedDiscountsInTheTemporaryStorage);
	
	If Object.Goods.Total("DiscountMarkupAmount") <> Object.DiscountsMarkups.Total("Sum") Then
		DiscountsHaveChanged = True;
	EndIf;

	Return DiscountsHaveChanged;
	
EndFunction

&AtClient
Procedure ApplyDiscountMarkUpChangesOnCustomer(Val Notification)
	
	TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(Undefined, True);
	
	If TheStructureOfTheMessages.Messages.Count() > 0
		And TheStructureOfTheMessages.AutomaticallyOpen Then
		
		AdditionalParameters = New Structure("Notification", Notification);
		CallbackDescription      = New CallbackDescription("ApplyDiscountMarkUpChangesOnCustomerCompletion",
															ThisObject,
															AdditionalParameters);
		
		OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisObject, , , , CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	ApplyDiscountMarkUpChangesOnFragmentClient(Notification);
	
EndProcedure

&AtClient
Procedure ApplyDiscountMarkUpChangesOnCustomerCompletion(Result, AdditionalParameters) Export
	
	Notification = AdditionalParameters.Notification;
	
	ApplyDiscountMarkUpChangesOnFragmentClient(Notification);
	
EndProcedure

&AtClient
Procedure ApplyDiscountMarkUpChangesOnFragmentClient(Val Notification)
	
	MessageText = NStr("vi = 'Chiết khấu (phụ thu)';
						|ru = 'Скидки (наценки)';
						|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
						|it = 'Sconti (sovrapprezzo)';
						|pl = 'Rabaty (marże)';
						|tr = 'İndirim (marj)'");
	ExplanationText = NStr("vi = 'Đã tính chiết khấu (phụ thu)';
							|ru = 'Скидки (наценки) рассчитаны';
							|en = 'Discounts (markups) are calculated'; fa = 'Discounts (markups) are calculated';
							|it = 'Sconti (sovrapprezzi) sono calcolati';
							|pl = 'Rabaty (marże) są obliczone';
							|tr = 'İndirim (marj) uygulandı'");
	
	ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	UpdateTextOfInformationLabelGeneratedDocuments();
	RunCallback(Notification);
	
EndProcedure

&AtServer
Function TheStructureOfTheMessages()
	
	Return DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	
EndFunction

&AtServer
Procedure ApplyPaymentWithBonusPoints(AddressInTempStorage)
	
	DeletingPayment = False;
	If AddressInTempStorage <> Undefined Then
		TableOfGoods = GetFromTempStorage(AddressInTempStorage);
	Else
		TableOfGoods = Object.Goods;
		DeletingPayment = True;
	EndIf;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	RowsToProcess = New Array;
	
	For Each TableRow In TableOfGoods Do
		
		If DeletingPayment Then
			TSRow = TableRow;
			TSRow.AmountOfBonusPointsToDeduction        = 0;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
		Else
			TSRow = Object.Goods.FindRows(New Structure("ConnectionKey", TableRow.ConnectionKey))[0];
			TSRow.AmountOfBonusPointsToDeduction        = TableRow.AmountOfBonusPointsToDeduction;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = TableRow.AmountOfBonusPointsToDeductionInCurrency;
		EndIf;
		
		RowsToProcess.Add(TSRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	CalculateTotals_(ThisObject);
	UpdateTextOfInformationLabelGeneratedDocuments();

EndProcedure

&AtServer
Procedure FillInCommunicationKeysInTablePart()
	DiscountsMarkupsServer.FillInCommunicationKeysInTablePart(Object, "Goods");
EndProcedure

&AtServer
Function AccountingTypeOfContractPrice()
	
	ParametersStructure = EnterprisePricesFillingServer.NewParametersForCheckingTypeOfContractPrices();
	ParametersStructure.FieldPriceType = "PriceTypeAccountingPriceType";
	
	If ValueIsFilled(Object.Contract) Then
		PriceKind = Common.ObjectAttributeValue(Object.Contract, ParametersStructure.FieldPriceType);
		If ValueIsFilled(PriceKind) Then
			ParametersStructure.PriceKind = PriceKind;
			ParametersStructure.PriceIncludesVAT = Common.ObjectAttributeValue(PriceKind, "PriceIncludesVAT");
		EndIf;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#Region SetOfSeries

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId, ThisIsImplementation)
	
	ParametersForSpecifyingSeriesInForm = ?(ThisIsImplementation, SeriesSpecificationParameters.SaleOfGoodsAndServices, SeriesSpecificationParameters.OrderDocument);
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object,
															ParametersForSpecifyingSeriesInForm,
															CurDataId,
															ThisObject,
															FormAttributeToValue("Object").Metadata());
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, ThisIsImplementation)
	
	ParametersForSpecifyingSeriesParameter = ?(ThisIsImplementation, SeriesSpecificationParameters.SaleOfGoodsAndServices, SeriesSpecificationParameters.OrderDocument);
	
	ProductsServer.ProcessSeriesIndication_(Object, ParametersForSpecifyingSeriesParameter, ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
				DefineSeriesParametersOnServer(IDCurrentRow), IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.SaleOfGoodsAndServices.UseItemsBatch;
	
	Items.GoodsSpecifySeries.Visible = SeriesSpecificationParameters.SaleOfGoodsAndServices.UseItemsBatch;
		
	Items.GoodsContextMenuSpecifySeries.Visible = SeriesSpecificationParameters.SaleOfGoodsAndServices.UseItemsBatch;
	
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.SaleOfGoodsAndServices.UseItemsBatch
		Or SeriesSpecificationParameters.OrderDocument.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeries()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
		DataProcessors.SalesWizard));
	
	If ThisIsImplementation(Object.DocumentCreationOption)
		Or ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		
		If ThisIsOrderWithImplementationOfTransfer(Object.DocumentCreationOption) Then
			FillInStatusesOfSpecifyingSerialOrderWithImplementationOfTransfer(SeriesSpecificationParameters);
		Else
			ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SaleOfGoodsAndServices);
		EndIf;
		
	Else
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.OrderDocument);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSerialOrderWithImplementationOfTransfer(SeriesSpecificationParameters)
	
	// Reset the Status of the series indication to zero.
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.OrderDocument);
	
	// Re-filling Statuses for order lines with implementation/transfer (shipment).
	GoodsLinesSalesTransfer = New Array;
	For Each CurRow In Object.Goods Do
		If CurRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
			Continue;
		EndIf;
		GoodsLinesSalesTransfer.Add(CurRow);
	EndDo;
	
	If GoodsLinesSalesTransfer.Count() = 0 Then
		Return;
	EndIf;
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SaleOfGoodsAndServices,
		GoodsLinesSalesTransfer);
	
EndProcedure

&AtClient
Function DefineSeriesParametersOnClient(CurDataId)
	
	Return DefineSeriesParameters(Object, SeriesSpecificationParameters, CurDataId);
	
EndFunction

&AtServer
Function DefineSeriesParametersOnServer(CurDataId)
	
	Return DefineSeriesParameters(Object, SeriesSpecificationParameters, CurDataId);
	
EndFunction 

&AtClientAtServerNoContext
Function DefineSeriesParameters(Object, SeriesSpecificationParameters, CurDataId)
	
	If CurDataId <> Undefined Then
		CurrentData = Object.Goods.FindByID(CurDataId);
		
		If ThisIsImplementation(CurrentData.RegistrationOption)
			Or ThisIsTransferOfGoods(CurrentData.RegistrationOption) Then
			
			Return SeriesSpecificationParameters.SaleOfGoodsAndServices;
			
		Else
			Return SeriesSpecificationParameters.OrderDocument;
		EndIf;
	Else
		Return SeriesSpecificationParameters.SaleOfGoodsAndServices
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function ThisIsImplementation(RegistrationOption)
	
	If RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice")
		Or	RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice") Then
		
		Return True;
		
	Else
		Return False
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function ThisIsTransferOfGoods(RegistrationOption)
	
	If RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee")
		Or RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer") Then
		
		Return True;
		
	Else
		Return False
	EndIf;
	
EndFunction

&AtServerNoContext
Function ThisIsOrderWithImplementationOfTransfer(RegistrationOption)
	
	Return RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
		Or RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer;
	
EndFunction

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	
	OpenSelectionOfSeries(, CurrentData);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = ParametersForFillingInVATRate(Object);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersFillInVATRate);
		
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	StructureOfFillingInVATRate.VATTaxation = ParametersFillInVATRate.VATTaxation;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", StructureOfFillingInVATRate);
	
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInSalesOptionAttribute",
		New Structure("Products", "SaleRegistrationOption"));
	StructureOfActionsWithAddedStrings.Insert("FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		
	Else
		
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
	EndIf;

	If ThisIsImplementation(Object.DocumentCreationOption) Or ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		
		StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.SaleOfGoodsAndServices));
		
	ElsIf Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder") Then
		
		StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.OrderDocument));
		
	EndIf;

	StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.CalculateSets                     = True;
	
	StructureOfActions.SeriesSpecificationParameters = ?(Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder"),
		SeriesSpecificationParameters.OrderDocument,
		SeriesSpecificationParameters.SaleOfGoodsAndServices);
	
	If ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
		
		StructureOfActions.GoodsOnly = True;
		StructureOfActions.AddContainers = False;
		StructureOfActions.UseContainersAsGoods = False;
		
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	WhenChangingBucketOnServer();
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
		
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	AddCollateralActionsOnServer(
		StructureOfActionParameters.StructureOfActionsWithAddedStrings,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	FillInDesignOptionInTablePart(False);
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

#EndRegion

#Region CreatingDocuments

// Returns:
// 	DocumentObject.SalesOrder - 
//
&AtServer
Function RecordOrder(ArrayOfFoundDocuments, Cancel, WithoutConducting)
	
	NewDocumentIsCreated = False;
	TableRow       = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
	                                              Documents.SalesOrder,
	                                              Type("DocumentRef.SalesOrder"),
	                                              ArrayOfFoundDocuments,
	                                              NewDocumentIsCreated,
	                                              TableRow); // DocumentObject.SalesOrder
	
	FillPropertyValues(DocumentObject, Object, , "Date");
	If ThisIsOperationOfShippingGoods(DocumentObject.BusinessOperation) Then
		DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
	EndIf;
	
	ResponsiblePersonsServer.ClearResponsiblePersonInDocument(DocumentObject);
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		DocumentObject.Status = Object.SalesOrderStatus;
	Else
		SelectionParametersSale  = New Structure("RegistrationOption",
												Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
		TransferSelectionParameters = New Structure("RegistrationOption",
												Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
		SelectionParametersOrder    = New Structure("RegistrationOption",
												Enums.OptionsOfRegisteringSalesDocuments.SalesOrder);
		
		SalesLines  = Object.Goods.FindRows(SelectionParametersSale);
		TransferLines = Object.Goods.FindRows(TransferSelectionParameters);
		OrderLines    = Object.Goods.FindRows(SelectionParametersOrder);
		
		ImplementationWithoutConducting = Object.CreateCashAccountReceiptNote
									And AmountOfPrepaymentBeforeShipment + AmountPrepaymentBeforeGoodsIssue > 0
									And Not ThisIsTransferOperation(Object.BusinessOperation);
		
		MonitorPayment   = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment");
		MonitorShipment = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment");
		
		If OrderLines.Count() = 0
			And Not MonitorPayment
			And Not ImplementationWithoutConducting Then
			
			If UseAdvancedFeaturesOfSalesOrder
				And Not UseShipmentByRowsInSalesOrder Then
				
				DocumentObject.Status = Enums.SalesOrderStatuses.ToShip;
				
			ElsIf UseAdvancedFeaturesOfSalesOrder Then
				DocumentObject.Status = Enums.SalesOrderStatuses.ToSupply;
			Else
				DocumentObject.Status = Enums.SalesOrderStatuses.NotApproved;
			EndIf;
			
		ElsIf SalesLines.Count() > 0
			Or TransferLines.Count() > 0 Then
			
			If UseAdvancedFeaturesOfSalesOrder
				And Not UseShipmentByRowsInSalesOrder Then
				
				DocumentObject.Status = ?(MonitorPayment
												And WithoutConducting
												And Not MonitorShipment,
											Enums.SalesOrderStatuses.Closed,
											Enums.SalesOrderStatuses.ToShip);
				
			ElsIf UseAdvancedFeaturesOfSalesOrder Then
				DocumentObject.Status = ?(MonitorPayment
												And WithoutConducting
												And Not MonitorShipment,
											Enums.SalesOrderStatuses.Closed,
											Enums.SalesOrderStatuses.ToSupply);
			Else
				DocumentObject.Status = Enums.SalesOrderStatuses.NotApproved;
			EndIf;
			
		Else
			DocumentObject.Status = Object.SalesOrderStatus;
		EndIf;
		
		ChangeOrderStatus = MonitorShipment
								And Object.SalesOrderStatus = Enums.SalesOrderStatuses.Closed;
	EndIf;
	
	DocumentObject.Priority = SettingsValueCached.GetDefaultPriority(DocumentObject.Priority);
	DocumentObject.Goods.Clear();
	
	FillInRowSecurityOption = False;
	If UseAdvancedFeaturesOfSalesOrder And Not UseShipmentByRowsInSalesOrder Then
		If DocumentObject.Status = Enums.SalesOrderStatuses.ToShip Then
			RowSecurityOption = Enums.SupplyOptions.Ship;
			FillInRowSecurityOption = True;
		ElsIf DocumentObject.Status = Enums.SalesOrderStatuses.ToSupply Then
			RowSecurityOption = Enums.SupplyOptions.FromWarehouse;
			FillInRowSecurityOption = True;
		EndIf; 
	EndIf; 
	
	RowCode = 0;
	
	For Each CurRow In Object.Goods Do
		If CurRow.NumberOfPackages > 0 Then
			RowCode = RowCode + 1;
			CurRow.RowCode = RowCode;
			
			If FillInRowSecurityOption Then
				CurRow.SupplyOption = RowSecurityOption;
			EndIf;
			
			NewLineProducts = DocumentObject.Goods.Add();
			FillPropertyValues(NewLineProducts, CurRow);
			
		EndIf;
	EndDo;
	
	DocumentObject.MaximumRowCode = RowCode;
	DocumentObject.DiscountsMarkups.Load(Object.DiscountsMarkups.Unload());
	DocumentObject.BonusPointAccrual.Load(Object.BonusPointAccrual.Unload());
	DocumentObject.PaymentScheduleSteps.Load(Object.PaymentScheduleSteps.Unload());
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalOrderAttributes.Unload());
	
	ParametersForSpecifyingOrderSeries = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.SalesOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, ParametersForSpecifyingOrderSeries);
	
	Try
		
		If WithoutConducting Then
			DocumentObject.Write(DocumentWriteMode.Write);
		Else
			DocumentObject.Write(DocumentWriteMode.Posting);
		EndIf;
		
		If NewDocumentIsCreated Then
			
			Sales.AddRowToGeneratedDocumentsTable(ThisObject,
															DocumentObject.Ref,
															2,
															?(DocumentObject.Posted,0,2),
															KitPrintingIsAvailable(DocumentObject.Ref));
			
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
			
		ElsIf TableRow <> Undefined Then
			
			Sales.UpdateRowInGeneratedDocumentsTable(TableRow,
															DocumentObject.Ref,
															2,
															?(DocumentObject.Posted,0,2));
			
		EndIf;
		
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
		
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.RequestForReturnOfGoodsFromCustomer - 
//
&AtServer
Function RecordRefundRequest(ArrayOfFoundDocuments, Goods, Warehouse, Cancel, WithoutConducting = False)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	ThisIsGoodsTransferOperation = Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
	                                             Documents.RequestForReturnOfGoodsFromCustomer,
	                                             Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"),
	                                             ArrayOfFoundDocuments,
	                                             NewDocumentIsCreated,
	                                             TableRow); // DocumentObject.RequestForReturnOfGoodsFromCustomer
	
	FillPropertyValues(DocumentObject, Object, , "Date");
	
	ResponsiblePersonsServer.ClearResponsiblePersonInDocument(DocumentObject);
	
	DocumentObject.Warehouse                 = Warehouse;
	DocumentObject.Status                = Object.StatusOfRequestForReturnOfGoodsFromCustomers;
	DocumentObject.Priority             = SettingsValueCached.GetDefaultPriority(DocumentObject.Priority);
	DocumentObject.BusinessOperation = SalesServer.GetRefundTransactionForSale(
												Object.BusinessOperation);
	DocumentObject.DateOfReceipt       = Object.DateOfShipment;
	DocumentObject.OneDateReceipt = Object.NotShipInInstallments;
	DocumentObject.GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		DocumentObject.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods;
		DocumentObject.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
	ElsIf DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		DocumentObject.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.EmptyRef();
		DocumentObject.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
	ElsIf ThisIsGoodsTransferOperation Then
		DocumentObject.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods;
	Else
		DocumentObject.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash;
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian 
		Or Object.ConsignmentSales25) 
		And ValueIsFilled(Warehouse)
		And Common.ObjectAttributeValue(Warehouse, "IsFolder") Then
		DocumentObject.Warehouse = Catalogs.Warehouses.EmptyRef();
	EndIf;	
	
	DocumentObject.ReturnedGoods.Clear();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	CacheQualityControl = QualityControl.DataCacheOfMechanism(DocumentObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	RowCode = 0;
	
	For Each CurRow In Goods Do
		If CurRow.NumberOfPackagesDueToReturn > 0 Then
			
			RowCode = RowCode + 1;
			CurRow.RowCode = RowCode;
			
			NewLineProducts = DocumentObject.ReturnedGoods.Add();
			FillPropertyValues(NewLineProducts, CurRow);
			
			NewLineProducts.DateOfReceipt    = ?(DocumentObject.OneDateReceipt,
													Object.DateOfShipment,
													CurRow.DateOfShipment);
			NewLineProducts.Count         = CurRow.QuantityForReturn;
			NewLineProducts.NumberOfPackages = CurRow.NumberOfPackagesDueToReturn;
			
		EndIf;
	EndDo;
	
	SalesServer.FillInSalesAndPrices(DocumentObject, "ReturnedGoods");
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Package");
	
	For Each CurRow In DocumentObject.ReturnedGoods Do
		
		If CurRow.Price = 0 Then
			
			FillPropertyValues(TheStructureOfTheSearch, CurRow);
			FoundRows = Goods.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.Count() > 0 Then
				
				CurRow.Price = FoundRows[0].Price;
				
				ErrorText = NStr("vi = 'Không thể tìm thấy chứng từ giao hàng đối với ""%1"" (dòng %2). Đơn hàng sẽ được nhận từ Trợ giúp bán hàng.';
								|ru = 'Не удалось найти документ реализации для ""%1"" (строка %2). Цена товара будет получена из Помощника продаж.';
								|en = 'Cannot find a sale document for the ""%1"" (line %2). The product price will be received from the sales wizard.'; fa = 'Cannot find a sale document for the ""%1"" (line %2). The product price will be received from the sales wizard.';
								|it = 'Impossibile trovare il documento di vendita per ""%1"" (riga %2). Il prezzo della merce verrà ottenuto dall''Assistente vendite.';
								|pl = 'Nie udało się odnaleźć dokumentu realizacji dla ""%1"" (wiersz %2). Cena towaru zostanie otrzymana z Asystenta sprzedaży.';
								|tr = '""%1"" (%2satır) için satış belgesi bulunamadı. Malların fiyatı Satış Sihirbazından alınacaktır.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								ErrorText, DocumentObject, CurRow.LineNumber);
				Common.MessageToUser(ErrorText);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(DocumentObject.ReturnedGoods, StructureOfActions, Undefined);
	
	DocumentObject.ReturnedGoodsMaximumRowCode = RowCode;
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalRequestAttributes.Unload());
	
	ParametersForSpecifyingSerialNumbers = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.RequestForReturnOfGoodsFromCustomer);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, ParametersForSpecifyingSerialNumbers.Returned_);
	
	Try
		
		If ValueIsFilled(DocumentObject.Warehouse) 
			And Not WithoutConducting Then
			DocumentObject.Write(DocumentWriteMode.Posting);
		Else
			DocumentObject.Write(DocumentWriteMode.Write);
		EndIf;	
		
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(ThisObject,
																	DocumentObject.Ref,
																	2,
																	,
																	KitPrintingIsAvailable(DocumentObject.Ref));
			
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(TableRow,
																	DocumentObject.Ref,
																	2);
		EndIf;
		
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
			
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.CustomerInvoice - 
//
&AtServer
Function WriteImplementation(ArrayOfFoundDocuments, Goods, Cancel, WithoutConducting = False)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		                                          Documents.CustomerInvoice,
		                                          Type("DocumentRef.CustomerInvoice"),
		                                          ArrayOfFoundDocuments,
		                                          NewDocumentIsCreated,
		                                          TableRow); // DocumentObject.CustomerInvoice
	
	DocumentObject.OrderSales = False;
	DocumentObject.SalesOrder = Undefined;
	FillPropertyValues(DocumentObject, Object, , "Date");
	
	ResponsiblePersonsServer.ClearResponsiblePersonInDocument(DocumentObject);
	
	DocumentObject.ARAPCurrency = DocumentObject.Currency;
	DocumentObject.CompanyBankAccount = Object.BankAccount;
	
	If DocumentObject.ToReturnReusablePackage Then
		
		DetailsOfAgreement = Common.ObjectAttributesValues(Object.Terms, "CalculatePackageReturnDateAccordingToCalendar, ScheduleOfPackageReturn");
		If Not ToUseTermsOfSales Then
			DetailsOfAgreement.Insert("CalculatePackageReturnDateAccordingToCalendar", False);
		EndIf;
		DocumentObject.ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
			DocumentObject,
			Object.ReusablePackageReturnCycleLength,
			DetailsOfAgreement.CalculatePackageReturnDateAccordingToCalendar,
			DetailsOfAgreement.ScheduleOfPackageReturn);
			
	EndIf;
	
	If UseStatusesOfGoodsServicesSales Then
		If Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			And Object.StatusOfCustomerInvoice = Enums.StatusesOfCustomerInvoices.Shipped Then
			DocumentObject.Status = Enums.StatusesOfCustomerInvoices.InTransit;
		Else
			DocumentObject.Status = Object.StatusOfCustomerInvoice;
		EndIf;
	Else
		DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped;
	EndIf;
	
	ParametersForSelectingTransferCertificate = New Structure(
		"SaleRegistrationOption,RegistrationOption",
		Enums.SalesRegistrationOptions.DeedOfTransfer,
		Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice);
	ProductsWithCertificate = Object.Goods.Unload(ParametersForSelectingTransferCertificate);
	
	DocumentObject.SaleRegistrationOption = ?(ProductsWithCertificate.Count() = Object.Goods.Count(), 
		Enums.SalesRegistrationOptions.DeedOfTransfer,
		Enums.SalesRegistrationOptions.CustomerInvoice);
	
	DocumentObject.Goods.Load(Goods);
	
	DocumentObject.BonusPointAccrual.Load(Object.BonusPointAccrual.Unload());
	DocumentObject.PaymentScheduleSteps.Load(Object.PaymentScheduleSteps.Unload());
	
	DocumentObject.SetOfSeries.Clear();
	DocumentObject.DiscountsMarkups.Clear();
	
	For Each ObjectDiscountRow In Object.DiscountsMarkups Do
		If DocumentObject.Goods.Find(ObjectDiscountRow.ConnectionKey, "ConnectionKey") <> Undefined Then
			DiscountsRow = DocumentObject.DiscountsMarkups.Add();
			FillPropertyValues(DiscountsRow, ObjectDiscountRow);
		EndIf;
	EndDo;
	
	For Each ObjectSeriesString In Object.SetOfSeries Do
		If DocumentObject.Goods.Find(ObjectSeriesString.Products, "Products") <> Undefined Then
			RowSeries = DocumentObject.SetOfSeries.Add();
			FillPropertyValues(RowSeries, ObjectSeriesString);
		EndIf;
	EndDo;
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalSaleAttributes.Unload());
	
	ParametersForSpecifyingSerialNumbers_ = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.CustomerInvoice);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, ParametersForSpecifyingSerialNumbers_);
	
	Try
		If WithoutConducting Then
			DocumentObject.Write(DocumentWriteMode.Write);
		Else
			DocumentObject.Write(DocumentWriteMode.Posting);
		EndIf;
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				3,
				?(DocumentObject.Posted,0,2),
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				3,
				?(DocumentObject.Posted,0,2));
		EndIf;
	Except

		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
	
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Creates or updates the document of the transfer of goods to the custodian.
//
// Parameters:
// 	ArrayOfFoundDocuments - Array of DocumentRef
// 	Goods - ValueTable
// 	Cancel - Boolean
//
// Returns:
// 	DocumentObject.TransferOfGoodsToBailee
//
&AtServer
Function RecordTransferOfGoodsToCustodian(ArrayOfFoundDocuments, Goods, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		Documents.TransferOfGoodsToBailee,
		Type("DocumentRef.TransferOfGoodsToBailee"),
		ArrayOfFoundDocuments,
		NewDocumentIsCreated,
		TableRow); // DocumentObject.TransferOfGoodsToBailee
	
	DocumentObject.TransferByOrders = False;
	DocumentObject.SalesOrder = Undefined;
	DocumentObject.CompanyBankAccount = Object.BankAccount;
	
	FillPropertyValues(DocumentObject, Object, , "Date");
	
	If DocumentObject.ToReturnReusablePackage Then
		
		DetailsOfAgreement = Common.ObjectAttributesValues(Object.Terms,
			"CalculatePackageReturnDateAccordingToCalendar, ScheduleOfPackageReturn");
		
		If Not ToUseTermsOfSales Then
			DetailsOfAgreement.Insert("CalculatePackageReturnDateAccordingToCalendar", False);
		EndIf;
		
		DocumentObject.ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(DocumentObject,
			Object.ReusablePackageReturnCycleLength,
			DetailsOfAgreement.CalculatePackageReturnDateAccordingToCalendar,
			DetailsOfAgreement.ScheduleOfPackageReturn);
		
	EndIf;
	
	DocumentObject.Goods.Load(Goods);
	DocumentObject.SetOfSeries.Load(Object.SetOfSeries.Unload());
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalSaleAttributes.Unload());
	
	ParametersForSpecifyingTransferSeries = ProductsServer.SeriesSpecificationParameters(DocumentObject,
		Documents.TransferOfGoodsToBailee);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, ParametersForSpecifyingTransferSeries);
	
	Try
		
		DocumentObject.Write(DocumentWriteMode.Posting);
		
		If NewDocumentIsCreated Then
			
			Sales.AddRowToGeneratedDocumentsTable(ThisObject,
				DocumentObject.Ref,
				3,,
				KitPrintingIsAvailable(DocumentObject.Ref));
			
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
			
		ElsIf TableRow <> Undefined Then
			
			Sales.UpdateRowInGeneratedDocumentsTable(TableRow,
				DocumentObject.Ref,
				3);
			
		EndIf;
		
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
			
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.CustomerInvoice - 
//
&AtServer
Function RecordImplementationByOrder(ArrayOfFoundDocuments, BaseObject, Goods, Warehouse, Cancel, WithoutConducting = False, WithoutChangingOrderStatus = False)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
	                                              Documents.CustomerInvoice,
	                                              Type("DocumentRef.CustomerInvoice"),
	                                              ArrayOfFoundDocuments,
	                                              NewDocumentIsCreated,
	                                              TableRow); // DocumentObject.CustomerInvoice
	
	FillPropertyValues(DocumentObject, Object, ,
		"Date,DeliveryMethod,DeliveryZone,CarrierPartner,DeliveryAddressOfCarrier,,DeliveryAddressOfCarrierFieldValues,DeliveryTimeFrom,DeliveryTimeTo,AdditionalDeliveryInformation");
	
	DocumentObject.Warehouse = Warehouse;
	DocumentObject.ARAPCurrency = DocumentObject.Currency;
	DocumentObject.SalesOrder = BaseObject.Ref;
	DocumentObject.CompanyBankAccount = Object.BankAccount;
	DocumentObject.DeliveryMethod = Enums.TransportMethods.SelfPickup;
	
	FillInAttributesOfDeliveryOnBasisOf(DocumentObject, BaseObject.Ref);
	
	ResponsiblePersonsServer.ClearResponsiblePersonInDocument(DocumentObject);
	
	ParametersForSelectingTransferCertificate = New Structure(
		"SaleRegistrationOption",
		Enums.SalesRegistrationOptions.DeedOfTransfer);
	ProductsWithCertificate = Goods.FindRows(ParametersForSelectingTransferCertificate);
	
	DocumentObject.SaleRegistrationOption = ?(ProductsWithCertificate.Count() = Goods.Count(), 
		Enums.SalesRegistrationOptions.DeedOfTransfer,
		Enums.SalesRegistrationOptions.CustomerInvoice);
		
	If DocumentObject.ToReturnReusablePackage Then
		
		DetailsOfAgreement = Common.ObjectAttributesValues(Object.Terms, "CalculatePackageReturnDateAccordingToCalendar, ScheduleOfPackageReturn");
		If Not ToUseTermsOfSales Then
			DetailsOfAgreement.Insert("CalculatePackageReturnDateAccordingToCalendar", False);
		EndIf;
		DocumentObject.ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
			DocumentObject,
			Object.ReusablePackageReturnCycleLength,
			DetailsOfAgreement.CalculatePackageReturnDateAccordingToCalendar,
			DetailsOfAgreement.ScheduleOfPackageReturn);
			
	EndIf;
	
	If UseStatusesOfGoodsServicesSales Then
		If Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			And Object.StatusOfCustomerInvoice = Enums.StatusesOfCustomerInvoices.Shipped Then
			DocumentObject.Status = Enums.StatusesOfCustomerInvoices.InTransit;
		ElsIf GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
			DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		Else
			DocumentObject.Status = Object.StatusOfCustomerInvoice;
		EndIf;
	Else
		DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped;
	EndIf;
	DocumentObject.OrderSales = True;
	
	DocumentObject.Goods.Load(Goods);
	For Each CurRow In DocumentObject.Goods Do
		CurRow.SalesOrder = DocumentObject.SalesOrder;
		CurRow.AmountARAP = CurRow.AmountIncludingVAT;
	EndDo;
	
	DocumentObject.DiscountsMarkups.Load(Object.DiscountsMarkups.Unload());
	For Each OrderDiscountsRow In BaseObject.DiscountsMarkups Do
		If DocumentObject.Goods.Find(OrderDiscountsRow.ConnectionKey, "ConnectionKey") <> Undefined Then
			DiscountsRow = DocumentObject.DiscountsMarkups.Add();
			FillPropertyValues(DiscountsRow, OrderDiscountsRow);
		EndIf;
	EndDo;
	
	DocumentObject.BonusPointAccrual.Load(Object.BonusPointAccrual.Unload());
	DocumentObject.PaymentScheduleSteps.Load(Object.PaymentScheduleSteps.Unload());
	
	TotalPrepaymentAmount = AmountOfPrepaymentBeforeShipment + AmountPrepaymentBeforeGoodsIssue;
	
	If Not WithoutConducting And Object.CreateCashAccountReceiptNote And TotalPrepaymentAmount 
		And (Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
			Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice) Then
		NwRw = DocumentObject.ARAPDetails.Add();
		NwRw.Sum = TotalPrepaymentAmount;
		NwRw.AmountARAP = TotalPrepaymentAmount;
		NwRw.ARAPCurrency = Object.ARAPCurrency;
		If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			NwRw.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(Object.Contract,Object.Organization,Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
		Else
			NwRw.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(BaseObject.Ref,Object.Organization,Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
		EndIf;
	EndIf;
	
	SelectionParametersSale = New Structure("RegistrationOption", Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
	DocumentObject.SetOfSeries.Load(Object.SetOfSeries.Unload(Object.SetOfSeries.FindRows(SelectionParametersSale)));
	
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalSaleAttributes.Unload());
	
	ParametersForSpecifyingSerialNumbers_ = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.CustomerInvoice);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, ParametersForSpecifyingSerialNumbers_);
	
	AdvancedParameters = ARAPAccountingServer.AugmentedMechanismParameters(DocumentObject);
	ARAPAccountingServer.FillInPossibleAdvancesInInvoice(DocumentObject, AdvancedParameters.ParametersArray[0]);
	
	Try
		If WithoutConducting Then
			DocumentObject.Write(DocumentWriteMode.Write);
		Else
			DocumentObject.Write(DocumentWriteMode.Posting);
		EndIf;
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				3,
				?(DocumentObject.Posted,0,2),
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				3,
				?(DocumentObject.Posted,0,2));
		EndIf;
		If ChangeOrderStatus And Not WithoutChangingOrderStatus Then
			OrderDocument = DocumentObject.SalesOrder.GetObject(); // DocumentObject.SalesOrder
			OrderDocument.Status = Enums.SalesOrderStatuses.Closed;
			OrderDocument.Write(DocumentWriteMode.Posting);
		EndIf;
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış danışmanı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
		
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.TransferOfGoodsToBailee - 
//
&AtServer
Function RecordTransferOfGoodsByOrder(ArrayOfFoundDocuments, BaseObject, Goods, Warehouse, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
	                                              Documents.TransferOfGoodsToBailee,
	                                              Type("DocumentRef.TransferOfGoodsToBailee"),
	                                              ArrayOfFoundDocuments,
	                                              NewDocumentIsCreated,
	                                              TableRow); // DocumentObject.TransferOfGoodsToBailee
	
	PropertiesToExclude = "Date, DeliveryMethod, DeliveryZone, CarrierPartner, DeliveryAddressOfCarrier, 
							|DeliveryAddressOfCarrierFieldValues, DeliveryTimeFrom, DeliveryTimeTo, AdditionalDeliveryInformation";
	FillPropertyValues(DocumentObject, Object, , PropertiesToExclude);
	
	DocumentObject.TransferByOrders         = True;
	DocumentObject.SalesOrder              = BaseObject.Ref;
	DocumentObject.Warehouse                     = Warehouse;
	DocumentObject.CompanyBankAccount = Object.BankAccount;
	DocumentObject.DeliveryMethod            = Enums.TransportMethods.SelfPickup;
	
	FillInAttributesOfDeliveryOnBasisOf(DocumentObject, BaseObject.Ref);
	
	If DocumentObject.ToReturnReusablePackage Then
		DetailsOfAgreement = Common.ObjectAttributesValues(Object.Terms,
																		"CalculatePackageReturnDateAccordingToCalendar, ScheduleOfPackageReturn");
		
		If Not ToUseTermsOfSales Then
			DetailsOfAgreement.Insert("CalculatePackageReturnDateAccordingToCalendar", False);
		EndIf;
		
		DocumentObject.ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(DocumentObject,
																														Object.ReusablePackageReturnCycleLength,
																														DetailsOfAgreement.CalculatePackageReturnDateAccordingToCalendar,
																														DetailsOfAgreement.ScheduleOfPackageReturn);
	EndIf;
	
	DocumentObject.Goods.Load(Goods);
	
	For Each CurRow In DocumentObject.Goods Do
		CurRow.SalesOrder = DocumentObject.SalesOrder;
	EndDo;
	
	TransferFilterParameters = New Structure("RegistrationOption",
												Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
	DocumentObject.SetOfSeries.Load(Object.SetOfSeries.Unload(Object.SetOfSeries.FindRows(TransferFilterParameters)));
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalSaleAttributes.Unload());
	
	ParametersForSpecifyingTransferSeries = ProductsServer.SeriesSpecificationParameters(DocumentObject,
																				Documents.TransferOfGoodsToBailee);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, ParametersForSpecifyingTransferSeries);
	
	Try
		
		DocumentObject.Write(DocumentWriteMode.Posting);
		
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable( ThisObject,
																	DocumentObject.Ref,
																	3,
																	,
																	KitPrintingIsAvailable(DocumentObject.Ref));
			
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(TableRow,
																	DocumentObject.Ref,
																	3);
		EndIf;
		
		If ChangeOrderStatus Then
			OrderDocument = DocumentObject.SalesOrder.GetObject(); // DocumentObject.SalesOrder
			OrderDocument.Status = Enums.SalesOrderStatuses.Closed;
			
			OrderDocument.Write(DocumentWriteMode.Posting);
		EndIf;
		
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
		
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.CustomerInvoiceServices - 
//
&AtServer
Function RecordReport(ArrayOfFoundDocuments, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		                                          Documents.CustomerInvoiceServices,
		                                          Type("DocumentRef.CustomerInvoiceServices"),
		                                          ArrayOfFoundDocuments,
		                                          NewDocumentIsCreated,
		                                          TableRow); // DocumentObject.CustomerInvoiceServices
	
	DocumentObject.InvoiceByOrders = False;
	DocumentObject.SalesOrder = Undefined;
	FillPropertyValues(DocumentObject, Object, , "Date");
	DocumentObject.ARAPCurrency = DocumentObject.Currency;
	DocumentObject.CompanyBankAccount = Object.BankAccount;
	
	DocumentObject.Services.Load(Object.Goods.Unload());
	DocumentObject.DiscountsMarkups.Load(Object.DiscountsMarkups.Unload());
	DocumentObject.BonusPointAccrual.Load(Object.BonusPointAccrual.Unload());
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalInvoiceAttributes.Unload());
	DocumentObject.PaymentScheduleSteps.Load(Object.PaymentScheduleSteps.Unload());
					
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				4,
				,
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				4);
		EndIf;
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
		
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.CustomerInvoiceServices - 
//
&AtServer
Function RecordOrderReport(ArrayOfFoundDocuments, BaseObject, Works, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		                                          Documents.CustomerInvoiceServices,
		                                          Type("DocumentRef.CustomerInvoiceServices"),
		                                          ArrayOfFoundDocuments,
		                                          NewDocumentIsCreated,
		                                          TableRow); // DocumentObject.CustomerInvoiceServices
	
	FillPropertyValues(DocumentObject, Object, , "Date");
	DocumentObject.ARAPCurrency = DocumentObject.Currency;
	DocumentObject.SalesOrder = BaseObject.Ref;
	DocumentObject.InvoiceByOrders = True;
	DocumentObject.CompanyBankAccount = Object.BankAccount;
	DocumentObject.Services.Load(Works);
	
	For Each CurRow In DocumentObject.Services Do
		CurRow.SalesOrder = DocumentObject.SalesOrder;
		CurRow.AmountARAP = CurRow.AmountIncludingVAT;
	EndDo;
	
	DocumentObject.DiscountsMarkups.Load(Object.DiscountsMarkups.Unload());
	DocumentObject.BonusPointAccrual.Load(Object.BonusPointAccrual.Unload());
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalInvoiceAttributes.Unload());
	DocumentObject.PaymentScheduleSteps.Load(Object.PaymentScheduleSteps.Unload());
	
	For Each OrderDiscountsRow In Object.DiscountsMarkups Do
		If DocumentObject.Services.Find(CurRow.ConnectionKey, "ConnectionKey") <> Undefined Then
			DiscountsRow = DocumentObject.DiscountsMarkups.Add();
			FillPropertyValues(DiscountsRow, OrderDiscountsRow);
		EndIf;
	EndDo;
		
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				4,
				,
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				4);
		EndIf;
		If ChangeOrderStatus Then
			OrderDocument = DocumentObject.SalesOrder.GetObject(); // DocumentObject.SalesOrder
			OrderDocument.Status = Enums.SalesOrderStatuses.Closed;
			OrderDocument.Write(DocumentWriteMode.Posting);
		EndIf;
	Except
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
			
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.CustomerCommercialInvoice - 
//
&AtServer
Function RecordInvoiceForPayment(ArrayOfFoundDocuments, BaseObject, PaymentScheduleSteps, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		                                          Documents.CustomerCommercialInvoice,
		                                          Type("DocumentRef.CustomerCommercialInvoice"),
		                                          ArrayOfFoundDocuments,
		                                          NewDocumentIsCreated,
		                                          TableRow); // DocumentObject.CustomerCommercialInvoice
	
	FillPropertyValues(DocumentObject, Object, , "Date");
	DocumentObject.DocumentBasis = BaseObject.Ref;
	
	DocumentObject.PaymentScheduleSteps.Clear();
	For Each ScheduleStage In PaymentScheduleSteps Do
		
		If ScheduleStage.PaymentAmount > 0 Then
			NewStage = DocumentObject.PaymentScheduleSteps.Add();
			NewStage.PaymentDate = ScheduleStage.PaymentDate;
			NewStage.PaymentPercentage = ScheduleStage.PaymentPercentage;
			NewStage.PaymentAmount = ScheduleStage.PaymentAmount;
			NewStage.ThisIsDepositForPackage = False;
		EndIf;
		If TypeOf(BaseObject) = Type("DocumentObject.CustomerInvoice") And ScheduleStage.PackageDepositValue > 0 Then
			NewStage = DocumentObject.PaymentScheduleSteps.Add();
			NewStage.PaymentDate = ScheduleStage.PaymentDate;
			NewStage.PaymentPercentage = 0;
			NewStage.PaymentAmount = ScheduleStage.PackageDepositValue;
			NewStage.ThisIsDepositForPackage = True;
		EndIf;
		
	EndDo;
	
	DocumentObject.DocumentAmount = Documents.CustomerCommercialInvoice.GetAmountOfFoundationDocument(BaseObject.Ref);
	DocumentObject.PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
		BaseObject.Number,
		BaseObject.Ref);
		
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				6,
				,
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				6);
		EndIf;
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış danışmanı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
			
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.IssuedLetterOfAuthority - 
//
&AtServer
Function WritePowerOfAttorneyToReceiveCash(ArrayOfFoundDocuments, BaseObject, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		                                          Documents.IssuedLetterOfAuthority,
		                                          Type("DocumentRef.IssuedLetterOfAuthority"),
		                                          ArrayOfFoundDocuments,
		                                          NewDocumentIsCreated,
		                                          TableRow); // DocumentObject.IssuedLetterOfAuthority
	DocumentObject.Fill(BaseObject.Ref);
	
	If Not ValueIsFilled(DocumentObject.BankAccount) And ValueIsFilled(Object.BankAccount) Then
		DocumentObject.BankAccount = Object.BankAccount;
	EndIf;
	
	If DocumentObject.Person.IsEmpty() Then
		ErrorText = NStr("vi = 'Không thể tạo giấy ủy quyền: không có dữ liệu cá nhân.';
						|ru = 'Не удалось создать доверенность: нет данных физического лица.';
						|en = 'Cannot create authorization letter: no person''s data.'; fa = 'Cannot create authorization letter: no person''s data.';
						|it = 'Non è stato possibile creare una delega: mancano i dati della persona fisica.';
						|pl = 'Nie udało się utworzyć pełnomocnictwa: brak danych osoby fizycznej.';
						|tr = 'Yetki belgesi oluşturulamadı: hiçbir fiziksel kişi verisi yok.'");
		Message = Undefined;
		CommonClientServer.AddUserError(Message,"Object",ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		Return DocumentObject;
	EndIf; 
	
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				9,
				,
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				9);
		EndIf;
	Except
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
			
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
	EndTry;
	
	Return DocumentObject;
EndFunction

// Parameters:
//  ArrayOfFoundDocuments - Array of DocumentRef
// 	BaseObject - Array of DocumentObject.SalesOrder
// 					- Array of DocumentObject.CustomerInvoice
// 					- DocumentObject.SalesOrder
// 					- DocumentObject.CustomerInvoice
// 	Cancel - Boolean				
// Returns:
// 	DocumentObject.CashAccountReceiptNote
&AtServer
Function RecordIncomingCashOrder(ArrayOfFoundDocuments, BaseObject, Cancel)
	
	// An incoming cash order is created only if
	//  there are stages in the stages of the payment schedule at the date of registration of the sale.
	AmountOfICO = 0;
	FoundRows = Object.PaymentScheduleSteps.FindRows(New Structure("PaymentDate", BegOfDay(Object.Date)));
	If FoundRows.Count() = 0 Then
		Return Undefined;
	Else
		For Each CurRow In FoundRows Do
			AmountOfICO = AmountOfICO + CurRow.PaymentAmount + CurRow.PackageDepositValue;
		EndDo;
	EndIf;
	
	If AmountOfICO = 0 Then
		Return Undefined;
	EndIf;
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		                                          Documents.CashAccountReceiptNote,
		                                          Type("DocumentRef.CashAccountReceiptNote"),
		                                          ArrayOfFoundDocuments,
		                                          NewDocumentIsCreated,
		                                          TableRow); // DocumentObject.CashAccountReceiptNote
	
	FillPropertyValues(DocumentObject, Object, , "Date");
	If TypeOf(BaseObject) <> Type("Array") Then
		DocumentObject.DocumentBasis = BaseObject.Ref;
	EndIf;
	CounterpartyDetails_ = Common.ObjectAttributesValues(
		Object.Counterparty,
		"Description,DescriptionFull");
	
	If Not IsBlankString(CounterpartyDetails_.DescriptionFull) Then
		DocumentObject.ReceivedFrom = CounterpartyDetails_.DescriptionFull;
	Else
		DocumentObject.ReceivedFrom = CounterpartyDetails_.Description;
	EndIf;
	
	DocumentObject.Currency = Catalogs.CashAccounts.GetCheckoutDetails(DocumentObject.CashAccount).Currency;
	DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer;
	DocumentObject.CashFlowItem = Catalogs.CashFlowReportItems.CashReceiptFromCustomer;
	
	DocumentObject.ARAPDetails.Clear();
	
	Addriteria = ARAPObjectsServer.AdditionalSearchCriteria_1();
	Addriteria.ReturnFirstOne = False;
	
	If TypeOf(BaseObject) <> Type("Array") Then
		
		NewRow = DocumentObject.ARAPDetails.Add();
		NewRow.Partner = BaseObject.Partner;
		
		If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			NewRow.PaymentPurpose = BaseObject.Contract;
			NewRow.ARAPObject   = ARAPObjectsServer.GetCalculationObjectFromLink(BaseObject.Contract,,Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, Addriteria);
		Else
			NewRow.PaymentPurpose = BaseObject.Ref;
			NewRow.ARAPObject   = ARAPObjectsServer.GetCalculationObjectFromLink(BaseObject.Ref,,, Addriteria);
		EndIf;
		NewRow.ARAPCurrency = BaseObject.Currency;
		NewRow.AmountARAP  = AmountOfICO;
		NewRow.CashFlowItem = Catalogs.CashFlowReportItems.CashReceiptFromCustomer;
		
	Else
		
		For Each SellingObject In BaseObject Do	// Document object.Implementationsparovuslug,document object.Customer Order
			
			NewRow = DocumentObject.ARAPDetails.Add();
			NewRow.Partner              = SellingObject.Partner;
			NewRow.PaymentPurpose     = SellingObject.Ref;
			NewRow.ARAPObject       = ARAPObjectsServer.GetCalculationObjectFromLink(SellingObject.Ref,,, Addriteria);
			NewRow.ARAPCurrency = SellingObject.Currency;
			StagesOfPrepayment = SellingObject.PaymentScheduleSteps.Unload(New Structure("PaymentOption",Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment));
			NewRow.AmountARAP  = StagesOfPrepayment.Total("PaymentAmount");
			NewRow.CashFlowItem = Catalogs.CashFlowReportItems.CashReceiptFromCustomer;
			
		EndDo;
			
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(DocumentObject.Currency, Object.Currency, CurrentSessionDate(), Object.Organization);
	NewRow.Sum = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, NewRow.AmountARAP / Coefficients.ConversionRateToSettlementCurrency, 0);
	
	DocumentObject.DocumentAmount = DocumentObject.ARAPDetails.Total("Sum");
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				7,
				,
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				7);
		EndIf;
	Except
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış danışmanı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
			
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
	EndTry;
	
	Return DocumentObject;
	
EndFunction

&AtServer
Procedure CreateAnInvoice_3(ArrayOfFoundDocuments, BaseObject, Cancel)
	
	If Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		Return;
	EndIf;
	
	LegalEntityIndividual = Common.ObjectAttributeValue(BaseObject.Counterparty, "LegalEntityIndividual");
	If LegalEntityIndividual = Enums.LegalEntityIndividual.Person Then
		Return;
	EndIf;
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentName = VATAccountingERP.FullNameOfInvoiceIssued();
	If ValueIsFilled(DocumentName) Then
			
		ManagerOfDocument = Common.ObjectManagerByFullName(DocumentName);
		DocumentType = Type(StrReplace(DocumentName, "Document", "DocumentRef"));
	
		DocumentObject = Sales.FindCreateDocument(ThisObject,
			                                          ManagerOfDocument,
			                                          DocumentType,
			                                          ArrayOfFoundDocuments,
			                                          NewDocumentIsCreated,
			                                          TableRow);
	
		RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
		RegistrationParameters.Ref = BaseObject.Ref;
		RegistrationParameters.Date = BaseObject.Date;
		RegistrationParameters.Organization = BaseObject.Organization;
		RegistrationParameters.Counterparty = BaseObject.Counterparty;
		RegistrationParameters.VATTaxation = BaseObject.VATTaxation;
		RegistrationParameters.GoodsSales = True;
		RegistrationParameters.ImplementationOfWorksServices = True;
		RegistrationParameters.TransferOfTitleToGoods = False;
		RegistrationParameters.VATAccrualUponShipment = False;
		If CommonClientServer.HasAttributeOrObjectProperty(BaseObject, "BusinessOperation") = True Then
			RegistrationParameters.TransferOfTitleToGoods = (BaseObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
			RegistrationParameters.VATAccrualUponShipment = (BaseObject.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer);
		EndIf;

		InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
		If Not InvoicesIssuedOnBasisOf.ThereIsRightToInteractivelyAddDocumentOnBasisOf 
			Or Not InvoicesIssuedOnBasisOf.DocumentOnBasisIsRequired Then
			Return;
		EndIf;

		Result = VATAccountingERP.FillInInvoiceIssued(DocumentObject, RegistrationParameters);
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				ThisObject,
				DocumentObject.Ref,
				5,
				?(DocumentObject.Posted,0,2),
				KitPrintingIsAvailable(DocumentObject.Ref));
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				5,
				?(DocumentObject.Posted,0,2));
		EndIf;
		If Not Result.Posted Then
			Message = Undefined;
			CommonClientServer.AddUserError(Message,"Object", Result.ErrorMessage, "");
			CommonClientServer.ReportErrorsToUser(Message, Cancel);
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
// 	ArrayOfFoundDocuments - Array of DocumentRef
// 	Basis1 - Array of DocumentObject
// 	Cancel - Boolean
//
&AtServer
Procedure RecordBillOfLading(ArrayOfFoundDocuments, Basis1, Cancel)
	
	
	Return;
	
EndProcedure

// Creates or updates the document shipment of goods to the client.
//
// Parameters:
// 	ArrayOfFoundDocuments - Array of DocumentRef
// 	Goods - ValueTable
// 	Cancel - Boolean
//
// Returns:
// 	DocumentObject.GoodsShipmentToCustomer
//
&AtServer
Function RecordShipmentOfItemsToCustomer(ArrayOfFoundDocuments, Goods, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		Documents.GoodsShipmentToCustomer,
		Type("DocumentRef.GoodsShipmentToCustomer"),
		ArrayOfFoundDocuments,
		NewDocumentIsCreated,
		TableRow); // DocumentObject.GoodsShipmentToCustomer
	
	FillPropertyValues(DocumentObject, Object, , "Date");	
	
	DocumentObject.Goods.Clear();
	For Each LineProducts_ In Goods Do
		
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, LineProducts_);
		
		NewRow.Sum = LineProducts_.AmountIncludingVAT;
		
		If ValueIsFilled(NewRow.NumberOfPackages) Then
			NewRow.Price = NewRow.Sum / NewRow.NumberOfPackages;
		EndIf;
		
	EndDo;
	
	DocumentObject.SetOfSeries.Load(Object.SetOfSeries.Unload());
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalAttributesOfGoodsShipment.Unload());
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject,
		Documents.GoodsShipmentToCustomer);
		
	ProductsServer.FillInSeriesByFEFO(DocumentObject, SeriesSpecificationParameters, False);
	
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		
		If NewDocumentIsCreated Then
			
			Sales.AddRowToGeneratedDocumentsTable(ThisObject,
				DocumentObject.Ref,
				3,,
				KitPrintingIsAvailable(DocumentObject.Ref));
			
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
			
		ElsIf TableRow <> Undefined Then
			
			Sales.UpdateRowInGeneratedDocumentsTable(TableRow,
				DocumentObject.Ref,
				3);
			
		EndIf;
		
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış danışmanı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
			
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

// Returns:
// 	DocumentObject.GoodsShipmentToCustomer - 
//
&AtServer
Function RecordShipmentOfItemsToCustomerByOrder(ArrayOfFoundDocuments, BaseObject, Goods, Warehouse, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(ThisObject,
		Documents.GoodsShipmentToCustomer,
		Type("DocumentRef.GoodsShipmentToCustomer"),
		ArrayOfFoundDocuments,
		NewDocumentIsCreated,
		TableRow); // DocumentObject.GoodsShipmentToCustomer

	PropertiesToExclude = "Date, DeliveryMethod, DeliveryZone, CarrierPartner, DeliveryAddressOfCarrier, 
		|DeliveryAddressOfCarrierFieldValues, DeliveryTimeFrom, DeliveryTimeTo, AdditionalDeliveryInformation";
	FillPropertyValues(DocumentObject, Object, , PropertiesToExclude);
	
	DocumentObject.ShipmentByOrders         = True;
	DocumentObject.SalesOrder              = BaseObject.Ref;
	DocumentObject.Warehouse                     = Warehouse;
	DocumentObject.DeliveryMethod            = Enums.TransportMethods.SelfPickup;
	DocumentObject.CompanyBankAccount = Object.BankAccount;
	
	DocumentObject.Goods.Clear();
	For Each LineProducts_ In Goods Do
		
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, LineProducts_);
		
		NewRow.SalesOrder = DocumentObject.SalesOrder;
		NewRow.Sum = LineProducts_.AmountIncludingVAT;
		
		If ValueIsFilled(NewRow.NumberOfPackages) Then
			NewRow.Price = NewRow.Sum / NewRow.NumberOfPackages;
		EndIf;
		
	EndDo;
	
	DocumentObject.AdditionalAttributes.Load(Object.AdditionalAttributesOfGoodsShipment.Unload());
	
	TransferFilterParameters = New Structure("RegistrationOption", 
		Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
	
	DocumentObject.SetOfSeries.Load(Object.SetOfSeries.Unload(Object.SetOfSeries.FindRows(TransferFilterParameters)));
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject,
		Documents.GoodsShipmentToCustomer);
	
	ProductsServer.FillInSeriesByFEFO(DocumentObject, SeriesSpecificationParameters, False);
	
	Try
		
		DocumentObject.Write(DocumentWriteMode.Posting);
		
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable( ThisObject,
																	DocumentObject.Ref,
																	3,
																	,
																	KitPrintingIsAvailable(DocumentObject.Ref));
			
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(TableRow,
																	DocumentObject.Ref,
																	3);
		EndIf;
		
		If ChangeOrderStatus Then
			OrderDocument = DocumentObject.SalesOrder.GetObject(); // DocumentObject.SalesOrder
			OrderDocument.Status = Enums.SalesOrderStatuses.Closed;
			
			OrderDocument.Write(DocumentWriteMode.Posting);
		EndIf;
		
	Except
		
		Cancel = True;
		
		ErrorInfo = ErrorInfo();
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış danışmanı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			DetailErrorDescription);
		
		Message = Undefined;
		CommonClientServer.AddUserError(Message, "Object", ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		
	EndTry;
	
	Return DocumentObject;
	
EndFunction

#EndRegion

// Splits the rows of the table of goods by type of taxation.
//
// Returns:
// 	Map of KeyAndValue
//
&AtServer
Function BreakDownGoodsByTypeOfTaxation()
	
	Result = New Map;
	
	
	If Result.Count() = 0 Then
		Result.Insert(Object.VATTaxation, "");
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function CreateDocumentsServer()
	
// Cancellationreferencesedited documents
	
	If DocumentsAreCreated Then
		DocumentsArray = New Array;
		
		For Each CurRow In Object.Documents Do
			DocumentsArray.Add(CurRow.GetID());
		EndDo;
		
		HoldCancelDocumentsServer(DocumentsArray, False);
	EndIf;
	
// Initialize
	
	GoodsByTaxationTypes = BreakDownGoodsByTypeOfTaxation();
	SeveralTypesOfTaxation = GoodsByTaxationTypes.Count() > 1;
	If SeveralTypesOfTaxation Then
		InitialDataGoods = Object.Goods.Unload();
		InitialDataVATTaxation = Object.VATTaxation;
	EndIf;
	
	GroundsOfConsignmentNote.Clear();
	
	BeginTransaction();
	
	Try
	
		Cancel = False;
		ArrayOfFoundDocuments = New Array;
		ThisIsTransferOperation = ThisIsTransferOperation(Object.BusinessOperation);

		TotalPrepaymentAmount = AmountPrepaymentBeforeGoodsIssue + AmountOfPrepaymentBeforeShipment;
		WithoutConducting = Object.CreateCashAccountReceiptNote
			And Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_
			And TotalPrepaymentAmount > 0
			And Not ThisIsTransferOperation;
	
		For Each GoodsByTaxationType In GoodsByTaxationTypes Do
			
			If SeveralTypesOfTaxation Then
				Object.VATTaxation = GoodsByTaxationType.Key;
				Object.Goods.Load(GoodsByTaxationType.Value);
			EndIf;
			
			If Object.Goods.Total("NumberOfPackages") > 0 Then
				
	// Creating a Customer
	
				If Not Cancel
					And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
					Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
					Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice)
					 Then
					
					WithoutConducting = Object.CreateCashAccountReceiptNote
					And Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_
					And Object.PaymentScheduleSteps.Count() > 0
					And Not ThisIsTransferOperation
					And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments;
					
					BaseObject = RecordOrder(ArrayOfFoundDocuments, Cancel, WithoutConducting);
					
					// Creating an invoice for payment by customer's order
					If Object.CreateCommercialInvoice
						And Not Cancel
						And Not ThisIsTransferOperation
						And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments
						And Object.PaymentScheduleSteps.Total("PaymentAmount") + Object.PaymentScheduleSteps.Total("PackageDepositValue") > 0 Then
						
						RecordInvoiceForPayment(ArrayOfFoundDocuments, BaseObject, Object.PaymentScheduleSteps.Unload(), Cancel);
						
					EndIf;
					
					// Creation of a cash receipt order on the client's order
					If Object.CreateCashAccountReceiptNote
						And Not Cancel
						And Not ThisIsTransferOperation
						And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments
						And Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
						
						OCR = RecordIncomingCashOrder(ArrayOfFoundDocuments, BaseObject, Cancel);
						
						If WithoutConducting And OCR <> Undefined Then
							
							BaseObject.Write(DocumentWriteMode.Posting);
							WithoutConducting = False; //The PCO is always linked to the object of calculations
							
						EndIf;
						
					EndIf;
					
	// Creationrealization of goods and servicesfulfilled works
	
				ElsIf Not Cancel
					And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice Then
					
					Query = New Query;
					Query.Text =
					"SELECT
					|	*
					|INTO TTProducts_1
					|FROM
					|	&Goods AS Goods;
					|
					|//////////////////////////////////////////////////////////////////////////////// 0
					|SELECT
					|	*
					|FROM
					|	TTProducts_1 AS Goods
					|WHERE
					|	Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice)
					|	AND Goods.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
					|;
					|
					|//////////////////////////////////////////////////////////////////////////////// 1
					|SELECT
					|	*
					|FROM
					|	TTProducts_1 AS Goods
					|WHERE
					|	Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice)
					|	AND Goods.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)";
					
					Query.SetParameter("Goods", Object.Goods.Unload());
					
					// @skip-check query-in-loop
					ResultsPackage = Query.ExecuteBatch();
					
					Works    = ResultsPackage[1].Unload();
					Goods    = ResultsPackage[2].Unload();
					
					CreateICOInvoice = False;
					
					ArrayOfSalesDocuments = New Array;
					
					// If only the work - we put everything in the act of completed work
					If Works.Count() > 0
						And Goods.Count() = 0 Then
						
						BaseObject  = RecordReport(ArrayOfFoundDocuments, Cancel);
						CreateICOInvoice = True;
						
					// If there are no works or there are goods + works, we put everything into the sale of goods and services.
					Else
						
						CommonClientServer.SupplementTable(Works, Goods);
						Goods.Sort("LineNumber");
						
						CreateAnImplementation(Goods,
							ArrayOfSalesDocuments,
							ArrayOfFoundDocuments,
							WithoutConducting,
							Cancel);
						
					EndIf;
					
					// Creating a sales invoice
					If Not Cancel
						And Works.Count() > 0
						And Goods.Count() = 0
						And CreateICOInvoice
						And Object.CreateCommercialInvoice
						And Object.Goods.Total("SumWithoutReusablePackages") > 0 Then
						
						RecordInvoiceForPayment(ArrayOfFoundDocuments, BaseObject, BaseObject.PaymentScheduleSteps.Unload(),
						Cancel);
						
					EndIf;
					
					// Creation of an incoming cash order for the implementation / act
					If Not Cancel
						And Works.Count() > 0
						And Goods.Count() = 0
						And CreateICOInvoice
						And Object.CreateCashAccountReceiptNote
						And Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
						
						OCR = RecordIncomingCashOrder(ArrayOfFoundDocuments, BaseObject, Cancel);
						
						If WithoutConducting
							And OCR <> Undefined Then
							
							BaseObject.Write(DocumentWriteMode.Posting);
							
							// Creating a bill of lading for implementation
							If CreateConsignmentNote And Not Cancel Then
								GroundsOfConsignmentNote.Add(BaseObject.Ref);
							EndIf;
							
						EndIf;
						
					EndIf;
					
					// Creating an invoice for the implementation / act
					If Not Cancel
						And Works.Count() > 0
						And Goods.Count() = 0
						And Object.Goods.Total("SumWithoutReusablePackages") > 0
						And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
						
						CreateAnInvoice_3(ArrayOfFoundDocuments, BaseObject, Cancel);
						
					EndIf;
					
	// Creationtransmission of goods to the Keeper
	
				ElsIf Not Cancel
					And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee Then
					
					Query = New Query;
					Query.SetParameter("BusinessOperation", Object.BusinessOperation);
					Query.SetParameter("Goods", Object.Goods.Unload());
					Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
					Query.Text =
					"SELECT
					|	*,
					|	Goods.RegistrationOption AS RegistrationOption,
					|	Goods.ItemsType AS ItemsType
					|INTO TTProducts_1
					|FROM
					|	&Goods AS Goods
					|;
					|
					|////////////////////////////////////////////////////////////////////////////////
					|SELECT
					|	*
					|FROM
					|	TTProducts_1 AS Goods
					|WHERE
					|	Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee)
					|	AND CASE
					|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer)
					|			THEN Goods.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
					|		ELSE Goods.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
					|			VALUE(Enum.ItemsTypes.ReusablePackage))
					|	END";
					
					//@skip-check query-in-loop
					QueryResult = Query.Execute();
					If Not QueryResult.IsEmpty() Then
						
						Goods = QueryResult.Unload();
						
						If ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
							
							BaseObject = RecordShipmentOfItemsToCustomer(ArrayOfFoundDocuments, Goods, Cancel);
							
							If Not Cancel
								And Object.PrintTaxInvoice Then
								CreateAnInvoice_3(ArrayOfFoundDocuments, BaseObject, Cancel);
							EndIf;
							
						Else
							BaseObject = RecordTransferOfGoodsToCustodian(ArrayOfFoundDocuments, Goods, Cancel);
						EndIf;
						
						If Not Cancel
							And CreateConsignmentNote Then
							GroundsOfConsignmentNote.Add(BaseObject.Ref);
						EndIf;
						
					EndIf;
					
				EndIf;
				
	// The creation of the actualization of goods and services and the completion of the work order
	
				If Not Cancel
					And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
					
					Query = New Query;
					Query.Text =
					"SELECT
					|	*,
					|	Goods.SupplyOption       AS SupplyOption,
					|	Goods.SaleRegistrationOption AS SaleRegistrationOption,
					|	Goods.Warehouse                    AS Warehouse,
					|	Goods.RegistrationOption        AS RegistrationOption
					|INTO TTProducts_1
					|FROM
					|	&Goods AS Goods;
					|
					|//////////////////////////////////////////////////////////////////////////////// 0
					|SELECT
					|	*
					|FROM
					|	TTProducts_1 AS Goods
					|WHERE
					|	(Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
					|		OR NOT &UseAdvancedFeaturesOfSalesOrder)
					|	AND Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice)
					|	AND Goods.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
					|;
					|
					|//////////////////////////////////////////////////////////////////////////////// 1
					|SELECT
					|	*
					|FROM
					|	TTProducts_1 AS Goods
					|WHERE
					|	(Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
					|		OR NOT &UseAdvancedFeaturesOfSalesOrder)
					|	AND Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice)
					|	AND Goods.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)
					|;
					|
					|//////////////////////////////////////////////////////////////////////////////// 2
					|SELECT
					|	*
					|FROM
					|	TTProducts_1 AS Goods
					|WHERE
					|	(Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
					|		OR NOT &UseAdvancedFeaturesOfSalesOrder)
					|	AND Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice)
					|	AND Goods.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)";
					
					Query.SetParameter("Goods", Object.Goods.Unload());
					Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
					
					//@skip-check query-in-loop
					ResultsPackage = Query.ExecuteBatch();
					
					Works    = ResultsPackage[1].Unload();
					ProductsAct = ResultsPackage[2].Unload();
					Goods    = ResultsPackage[3].Unload();
					
					ArrayOfSalesDocuments = New Array;
					
					// Creation of sales of goods and services by order
					If Goods.Count() > 0 Then
					
						//@skip-check query-in-loop
						CreateImplementationByOrder(Goods,
						ArrayOfSalesDocuments,
						ArrayOfFoundDocuments,
						BaseObject,
						Works.Count() > 0
						Or ProductsAct.Count() > 0,
						WithoutConducting,
						Cancel);
						
					EndIf;
					
					// Creation of an act for the transfer of rights by order
					If Not Cancel
						And ProductsAct.Count() > 0 Then
						
						//@skip-check query-in-loop
						CreateImplementationByOrder(ProductsAct,
						ArrayOfSalesDocuments,
						ArrayOfFoundDocuments,
						BaseObject,
						Works.Count() >0 Or Goods.Count() > 0,
						WithoutConducting,
						Cancel);
						
					EndIf;
					
					// Creation of an act of completed works by order
					If Not Cancel
						And Works.Count() > 0 Then
						
						SellingObject = RecordOrderReport(ArrayOfFoundDocuments, BaseObject, Works, Cancel);
						
						// Creating an invoice for the implementation / act
						If Not Cancel
							And Not ThisIsTransferOperation Then
							
							CreateAnInvoice_3(ArrayOfFoundDocuments, SellingObject, Cancel);
							
						EndIf;
						
						// Creating an invoice for payment for the implementation / act
						If Not Cancel
							And Object.CreateCommercialInvoice
							And Not ThisIsTransferOperation
							And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
							And Object.Goods.Total("SumWithoutReusablePackages") > 0 Then
							
							RecordInvoiceForPayment(ArrayOfFoundDocuments, SellingObject, SellingObject.PaymentScheduleSteps.Unload(), Cancel);
							
						EndIf;
						
					EndIf;
					
	// Creationtransmission of goods to the store by order
	
				ElsIf Not Cancel
					And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
					
					Query = New Query;
					Query.SetParameter("BusinessOperation", Object.BusinessOperation);
					Query.SetParameter("Goods", Object.Goods.Unload());
					Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
					Query.Text =
					"SELECT
					|	*,
					|	Goods.SupplyOption AS SupplyOption,
					|	Goods.RegistrationOption AS RegistrationOption,
					|	Goods.ItemsType AS ItemsType
					|INTO TTProducts_1
					|FROM
					|	&Goods AS Goods
					|;
					|
					|////////////////////////////////////////////////////////////////////////////////
					|SELECT
					|	*
					|FROM
					|	TTProducts_1 AS Goods
					|WHERE
					|	(Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
					|	OR NOT &UseAdvancedFeaturesOfSalesOrder)
					|	AND
					|		Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer)
					|	AND CASE
					|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer)
					|			THEN Goods.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
					|		ELSE Goods.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
					|			VALUE(Enum.ItemsTypes.ReusablePackage))
					|	END";
					
					ArrayOfSalesDocuments = New Array;
					
					//@skip-check query-in-loop
					QueryResult = Query.Execute();
					
					If Not QueryResult.IsEmpty() Then
						
						Goods = QueryResult.Unload();
						
						If ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
							
							CreateShipmentOfItemsToCustomerByOrder(Goods,
								ArrayOfSalesDocuments,
								ArrayOfFoundDocuments,
								BaseObject,
								Cancel);
							
						Else
							
							//@skip-check query-in-loop
							CreateTransferOfGoodsByOrder(Goods,
								ArrayOfSalesDocuments,
								ArrayOfFoundDocuments,
								BaseObject,
								Cancel);
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
	// Creationexternal links
	
				If Not Cancel
					And GoodsIssueNoteCreationIsRequired Then
					
					Query = New Query;
					Query.Text =
					"SELECT
					|	*,
					|	Goods.SupplyOption       AS SupplyOption,
					|	Goods.SaleRegistrationOption AS SaleRegistrationOption,
					|	Goods.Warehouse                    AS Warehouse,
					|	Goods.RegistrationOption        AS RegistrationOption
					|INTO TTProducts_1
					|FROM
					|	&Goods AS Goods;
					|
					|////////////////////////////////////////////////////////////////////////////////
					|SELECT *
					|FROM 
					|	TTProducts_1 AS Goods
					|WHERE
					|	(Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
					|		OR NOT &UseAdvancedFeaturesOfSalesOrder)
					|	AND Goods.RegistrationOption IN(VALUE(Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice),
					|								VALUE(Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee),
					|								VALUE(Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer),
					|								VALUE(Enum.OptionsOfRegisteringSalesDocuments.SalesOrder),
					|								VALUE(Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice))
					|	AND (Goods.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
					|		OR &DocumentCreationOption IN(VALUE(Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee),
					|											VALUE(Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer))
					|	)";
					
					Query.SetParameter("Goods", Object.Goods.Unload());
					Query.SetParameter("DocumentCreationOption", Object.DocumentCreationOption);
					Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
					
					//@skip-check query-in-loop
					QueryResult = Query.Execute();
					
					Goods = QueryResult.Unload();
					
					If Goods.Count() > 0 Then
						CreateSpendingOrders(Goods, ArrayOfFoundDocuments, ArrayOfSalesDocuments, BaseObject, WithoutConducting, Cancel);
					EndIf;
					
				Else 
					
					Sales.WhenCreatingDocumentsSalesAssistant(ThisObject, ArrayOfFoundDocuments, Cancel);
					
				EndIf;
				
			EndIf; // Number of packages > 0
			
	// The creation of a callback of the client's goods
			
			If Not Cancel
				And Object.CreateRequestForReturnOfGoodsFromCustomers
				And Object.Goods.Total("NumberOfPackagesDueToReturn") > 0
				And Not ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
				
				 TableOfProductsInCart = Object.Goods.Unload();
				 Goods = TableOfProductsInCart.CopyColumns();
				 For Each CurrentRowOfProductTable In TableOfProductsInCart Do
					 If CurrentRowOfProductTable.NumberOfPackagesDueToReturn = 0 Then
						 Continue;
					 EndIf; 	 
					 
					 NewRow = Goods.Add();
					 FillPropertyValues(NewRow, CurrentRowOfProductTable);
					 
				 EndDo;
				
				CreateReturnRequest(Goods,
						ArrayOfSalesDocuments,
						ArrayOfFoundDocuments,
						WithoutConducting,
						Cancel);
				
			EndIf;
			
		EndDo;
		
		If GroundsOfConsignmentNote.Count() Then
			
			RecordBillOfLading(
				ArrayOfFoundDocuments,
				GroundsOfConsignmentNote.UnloadValues(),
				Cancel);
			
		EndIf;
		
// Notesreferencesexternal documents
	
		If Not Cancel Then	
			For Each CurRow In Object.Documents Do
				If ArrayOfFoundDocuments.Find(CurRow.Document) = Undefined Then
					MarkDocumentForDeletion(CurRow, Cancel);
					If Cancel Then
						Break;
					EndIf; 
				EndIf;
			EndDo;
		EndIf;
	
// Finalizationsreferences

		If Cancel Then
			Raise NStr("vi = 'Lỗi hoàn thành tạo chứng từ';
						|ru = 'Ошибка завершения создания документов';
						|en = 'An error occurred when completing the documents creation'; fa = 'An error occurred when completing the documents creation';
						|it = 'Impossibile completare la creazione di documenti';
						|pl = 'Błąd zakończenia tworzenia dokumentów';
						|tr = 'Belge oluşturma işlemi tamamlandı hatası'", Common.DefaultLanguageCode());
		EndIf; 
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	GroundsOfConsignmentNote.Clear();
	
	If SeveralTypesOfTaxation Then
		Object.Goods.Load(InitialDataGoods);
		Object.VATTaxation = InitialDataVATTaxation;
	EndIf;
	
	If Cancel Then
		
		For Each CurRow In Object.Documents Do
			MarkDocumentForDeletion(CurRow, Cancel);
		EndDo;
		
		Object.Documents.Clear();
		ArrayOfFoundDocuments.Clear();
		
	EndIf;
	
	If ArrayOfFoundDocuments.Count() > 0 Then
		DocumentsAreCreated = True;
		Modified    = False;
		UpdateTextOfInformationLabelGeneratedDocuments();
		ManagingCreationOfWaybills(False);
		ManagingCreationOfPowerOfAttorney();
		SetOnlyViewFormElements(True);
		
		UpdateDocumentStateDisplay();
		Object.Documents.Sort("State, Order");
		
		If Object.Partner = Catalogs.Partners.RetailCustomer Then
			SaleToRetailCustomerWasRegistered = True;
		EndIf;
		
		UpdatePartnerDossierInformationContacts();
		UpdatePartnerDossierInformation();
	EndIf;
	
	Return ArrayOfFoundDocuments.Count();
	
EndFunction

&AtServer
Procedure UpdateDocumentStateDisplay()
	
	For Each CurrentDocument In Object.Documents Do
		DocumentAttributeValues = Common.ObjectAttributesValues(CurrentDocument.Document,"Posted,DeletionMark");
		If DocumentAttributeValues.Posted = True Then
			CurrentStatus = 0;
		ElsIf DocumentAttributeValues.DeletionMark = True Then
			CurrentStatus = 1;
		Else
			CurrentStatus = 2;
		EndIf; 
		If CurrentDocument.State <> CurrentStatus Then
			CurrentDocument.State = CurrentStatus;
		EndIf; 
	EndDo; 
	
EndProcedure

&AtClient
Procedure CreateDocumentsClient(Val Notification)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Notification", Notification);
	
	If Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.GoodsShipmentToCustomer") Then
		
		CreateDocumentsClientOfferToPickUpMultiTurnContainerCompletion(Undefined, AdditionalParameters);
		
	Else
		
		FieldsNames = NamingOfMultiTurnContainerSelectionFields(Object.DocumentCreationOption);
		CallbackDescription = New CallbackDescription("CreateDocumentsClientOfferToPickUpMultiTurnContainerCompletion",
			ThisObject,
			AdditionalParameters);
		
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(ThisObject, "Goods", FieldsNames,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDocumentsClientOfferToPickUpMultiTurnContainerCompletion(Value, AdditionalParameters) Export

	If UseDiscountsMarkupsInSales
		And Not ThisIsTransferOperation(Object.BusinessOperation) Then
		
		ThisIsShipmentOperationWithoutOrder =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsShipmentToCustomer")
				And Object.DocumentCreationOption =
					PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee");
		
		If DiscountsHaveChanged()
			And Not Object.DiscountsAreCalculated
			And Not ThisIsShipmentOperationWithoutOrder Then
			
			CallbackDescription = New CallbackDescription("SuggestUserToCalculateDiscountsCompletion",
				ThisObject,
				AdditionalParameters);
			
			DiscountsMarkupsFillingClient.SuggestUserToCalculateDiscounts(CallbackDescription);
			
			Return;
			
		Else
			Object.DiscountsAreCalculated = True;
		EndIf;
		
	EndIf;
	
	CreateDocumentsClientFragment(AdditionalParameters.Notification);
	
EndProcedure

&AtClient
Procedure SuggestUserToCalculateDiscountsCompletion(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Cancel Then
		RunCallback(AdditionalParameters.Notification);
		
		Return;
	ElsIf UserAnswer = DialogReturnCode.OK Then
		AdditionalParameters = New Structure("Notification", AdditionalParameters.Notification);
		CallbackDescription      = New CallbackDescription("CreateDocumentsClientCompletion",
															ThisObject,
															AdditionalParameters);
		
		ApplyDiscountMarkUpChangesOnCustomer(CallbackDescription);
		
		Return;
	EndIf;
	
	CreateDocumentsClientFragment(AdditionalParameters.Notification);
	
EndProcedure

&AtClient
Procedure CreateDocumentsClientCompletion(Result, AdditionalParameters) Export
	
	Notification = AdditionalParameters.Notification;
	
	CreateDocumentsClientFragment(Notification);
	
EndProcedure

&AtClient
Procedure CreateDocumentsClientFragment(Val Notification)
	
	Var NumberOfDocumentsCreated, MaxAdvanceDate;
	
	CalculateTotals_(ThisObject);
	
	If ValueIsFilled(Object.DateOfShipment) Then
		MaxAdvanceDate = SalesClient.MaximumAdvancePaymentDate(Object.PaymentScheduleSteps);
		
		If ValueIsFilled(MaxAdvanceDate)
			And MaxAdvanceDate > Object.DateOfShipment Then
			
			Object.DateOfShipment = MaxAdvanceDate;
			
		EndIf;
	EndIf;
	
	ClearMessages();
	
	BeforeWriteAtClientServer();
	
	If CheckFilling() Then
		NumberOfDocumentsCreated = CreateDocumentsServer();
		If FiscalizationIsAvailable And NumberOfDocumentsCreated > 0 Then
			FiscalizeDocuments();
		EndIf;
		If NumberOfDocumentsCreated > 0 Then
			MessageText = NStr("vi = 'Đã tạo (%NumberOfDocumentsCreated%) chứng từ';
								|ru = 'Созданы документы (%NumberOfDocumentsCreated%)';
								|en = 'Documents are created (%NumberOfDocumentsCreated%)'; fa = 'Documents are created (%NumberOfDocumentsCreated%)';
								|it = 'Documenti creati (%NumberOfDocumentsCreated%)';
								|pl = 'Utworzono dokumenty (%NumberOfDocumentsCreated%)';
								|tr = 'Oluşturulan belgeler (%NumberOfDocumentsCreated%)'");
			MessageText = StrReplace(MessageText, "%NumberOfDocumentsCreated%", NumberOfDocumentsCreated);
		Else
			MessageText = NStr("vi = 'Chưa tạo chứng từ';
								|ru = 'Документы не созданы';
								|en = 'Documents are not created'; fa = 'Documents are not created';
								|it = 'Документы не созданы';
								|pl = 'Documents are not created';
								|tr = 'Belgeler oluşturulmadı'");
		EndIf;
		
		ShowUserNotification(MessageText, , , PictureLib.Information32);
	EndIf;
	
	RunCallback(Notification);
	
EndProcedure

&AtServer
Procedure MarkDocumentForDeletion(TableRow, Cancel)
	
	If Sales.LockDocument_(TableRow.Document) Then
		DocumentObject = TableRow.Document.GetObject();
		
		If Not DocumentObject = Undefined
			And Not DocumentObject.DeletionMark Then
			
			Try
				
				DocumentObject.SetDeletionMark(True);
				
				TableRow.State = 1;
				
			Except

				Cancel = True;
				
				ErrorInfo = ErrorInfo();
				DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
				ShortErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
				
				WriteLogEvent(
					NStr("vi = 'Trợ giúp bán hàng';
						|ru = 'Помощник продаж';
						|en = 'Sales wizard'; fa = 'دستیار فروش';
						|it = 'Assistente vendite';
						|pl = 'Asystent sprzedaży';
						|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,, 
					DetailErrorDescription);
					
				ErrorText = NStr("vi = 'Không thể đặt dấu xóa đối với chứng từ %Document%. %ErrorDescription%';
								|ru = 'Не удалось установить пометку удаления для документа %Document%. %ErrorDescription%';
								|en = 'Cannot set deletion mark for document %Document%. %ErrorDescription%'; fa = 'Cannot set deletion mark for document %Document%. %ErrorDescription%';
								|it = 'Impossibile impostare il contrassegno per la cancellazione per il documento %Document%. %ErrorDescription%';
								|pl = 'Nie udało się ustawić znacznik usunięcia dla dokumentu %Document%. %ErrorDescription%';
								|tr = '%Document%belgesi için silme işareti ayarlanamadı. %ErrorDescription%'");
				ErrorText = StrReplace(ErrorText, "%Document%", DocumentObject);
				ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ShortErrorText);
				
				Common.MessageToUser(ErrorText, DocumentObject);
				
			EndTry;
			
		Else
			TableRow.State = 1;
		EndIf;
	Else
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure GetHighlightedDocuments(Val Notification)
	
	If Object.Documents.Count() = 0 Then
		ShowMessageBox(New CallbackDescription("GetHighlightedDocumentsCompletion", ThisObject, New Structure("Notification", Notification)), NStr("vi = 'Không có các chứng từ vừa lập';
																																					|ru = 'Отсутствуют оформленные документы';
																																					|en = 'Created documents are missing'; fa = 'Created documents are missing';
																																					|it = 'Non ci sono documenti formalizzati';
																																					|pl = 'Brak sporządzonych dokumentów';
																																					|tr = 'Düzenlenmiş belge yok'"));
		Return;
	ElsIf Items.CompletedDocuments_4.SelectedRows.Count() = 0 Then
		ShowMessageBox(New CallbackDescription("GetHighlightedDocumentsCompletion", ThisObject, New Structure("Notification", Notification)), NStr("vi = 'Không có các chứng từ được tách chọn';
																																					|ru = 'Отсутствуют выделенные документы';
																																					|en = 'Selected documents are missing'; fa = 'Selected documents are missing';
																																					|it = 'Non ci sono documenti selezionati';
																																					|pl = 'Brak zaznaczonych dokumentów';
																																					|tr = 'Seçili belge yok'"));
		Return;
	Else
		DocumentsArray = New Array();
		For Each CurItem In Items.CompletedDocuments_4.SelectedRows Do
			DocumentsArray.Add(CurItem);
		EndDo;
		RunCallback(Notification, DocumentsArray);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure GetHighlightedDocumentsCompletion(AdditionalParameters) Export
	
	Notification = AdditionalParameters.Notification;
	
	RunCallback(Notification, Undefined);
	
EndProcedure

&AtServer
Function SetDeletionMarkServer(SelectedDocuments_)
	
	Counter = SelectedDocuments_.Count();
	NumberOfChangedDocuments = 0;
	Cancel = False;
	DocumentsForProcessing_ = New Array;
	
	BeginTransaction();
	
	Try
		
		While Counter > 0 Do
			
			Counter = Counter - 1;
			DocumentNotMarkedForDeletion_ = False;
			
			TableRow = Object.Documents.FindByID(SelectedDocuments_[Counter]);
			If TableRow = Undefined Then
				Continue;
			EndIf;
			
			MarkDocumentForDeletion(TableRow, DocumentNotMarkedForDeletion_);
			If DocumentNotMarkedForDeletion_ Then
				Cancel = True;
			Else
				NumberOfChangedDocuments = NumberOfChangedDocuments + 1;
			EndIf;
			
			DocumentsForProcessing_.Add(TableRow);
			
		EndDo;
		
		If Cancel Then
			RollbackTransaction();
			
			WriteLogEvent(
				NStr("vi = 'Trợ giúp bán hàng';
					|ru = 'Помощник продаж';
					|en = 'Sales wizard'; fa = 'دستیار فروش';
					|it = 'Assistente vendite';
					|pl = 'Asystent sprzedaży';
					|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return 0;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Trợ giúp bán hàng';
				|ru = 'Помощник продаж';
				|en = 'Sales wizard'; fa = 'دستیار فروش';
				|it = 'Assistente vendite';
				|pl = 'Asystent sprzedaży';
				|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return 0;
	EndTry;
	
	ManagementOfWaybills(DocumentsForProcessing_);
	ManagingTaggingOfConsignmentNoteCommand();
	PowerOfAttorneyManagement();
	ManagingTeamTaggingPowerOfAttorney();
	
	Return NumberOfChangedDocuments;
	
EndFunction

&AtServer
Function HoldCancelDocumentsServer(SelectedDocuments_, Posting = True)
	
	Cancel = False;
	Counter = SelectedDocuments_.Count();
	NumberOfChangedDocuments = 0;
	ArrayOfRowsToDelete_ = New Array;
	DocumentsForProcessing_ = New Array;
	
	BeginTransaction();
	
	Try
		
		While Counter > 0 Do
			
			Counter = Counter - 1;
			
			TableRow = Object.Documents.FindByID(SelectedDocuments_[Counter]);
			
			If TableRow = Undefined Then
				Continue;
			EndIf;
			
			If Sales.LockDocument_(TableRow.Document) Then
				
				DocumentObject = TableRow.Document.GetObject();
				
				// If the document was deleted, we will remember it and then delete it from the Documents table
				If DocumentObject = Undefined Then
					ArrayOfRowsToDelete_.Add(TableRow);
					
					Continue;
				EndIf;
				
				If DocumentObject.DeletionMark And Posting Then
					Try
						DocumentObject.SetDeletionMark(False);
						
						TableRow.State = 1;
					Except
						ErrorInfo = ErrorInfo();
						DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
						ShortErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
						
						WriteLogEvent(
							NStr("vi = 'Trợ giúp bán hàng';
								|ru = 'Помощник продаж';
								|en = 'Sales wizard'; fa = 'دستیار فروش';
								|it = 'Assistente vendite';
								|pl = 'Asystent sprzedaży';
								|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
							EventLogLevel.Error,,, 
							DetailErrorDescription);
							
						ErrorText = NStr("vi = 'Không thể hủy dấu xóa đối với chứng từ %Document%.""""%ErrorDescription%';
										|ru = 'Не удалось снять пометку удаления для документа %Document%. %ErrorDescription%';
										|en = 'Cannot clear a deletion mark for document %Document%. %ErrorDescription%'; fa = 'Cannot clear a deletion mark for document %Document%. %ErrorDescription%';
										|it = 'Impossibile rimuovere il contrassegno per la cancellazione per il documento %Document%. %ErrorDescription%';
										|pl = 'Nie udało się usunąć znacznik usunięcia dla dokumentu %Document%. %ErrorDescription%';
										|tr = '%Document%belgesi için silme işareti kaldırılamadı. %ErrorDescription%'");
						ErrorText = StrReplace(ErrorText, "%Document%", DocumentObject);
						ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ShortErrorText);
						
						Common.MessageToUser(ErrorText, DocumentObject);
					EndTry;
					
				EndIf;
				
				If DocumentObject.Posted <> Posting Then
					
					If Posting And Not DocumentObject.CheckFilling() Then 
						Continue;
					EndIf;
					
					Try
						DocumentObject.Write(?(Posting, DocumentWriteMode.Posting, DocumentWriteMode.UndoPosting));
					Except
						Cancel = True;
						
						ErrorInfo = ErrorInfo();
						DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
						ShortErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
						
						WriteLogEvent(
							NStr("vi = 'Trợ giúp bán hàng';
								|ru = 'Помощник продаж';
								|en = 'Sales wizard'; fa = 'دستیار فروش';
								|it = 'Assistente vendite';
								|pl = 'Asystent sprzedaży';
								|tr = 'Satış sihirbazı'", Common.DefaultLanguageCode()),
							EventLogLevel.Error,,, 
							DetailErrorDescription);
							
						If Posting Then
							ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ %Document%. %ErrorDescription%';
											|ru = 'Не удалось провести документ %Document%. %ErrorDescription%';
											|en = 'Cannot post document %Document%. %ErrorDescription%'; fa = 'Cannot post document %Document%. %ErrorDescription%';
											|it = 'Impossibile pubblicare il documento %Document% %ErrorDescription%';
											|pl = 'Nie udało się zatwierdzić dokumentu %Document%. %ErrorDescription%';
											|tr = '%Document% belgesi kaydedilemedi:%ErrorDescription%'");
						Else
							ErrorText = NStr("vi = 'Không thể hủy kết chuyển chứng từ %Document%. %ErrorDescription%';
											|ru = 'Не удалось отменить проведение документа %Document%. %ErrorDescription%';
											|en = 'Cannot cancel posting of document %Document%. %ErrorDescription%'; fa = 'Cannot cancel posting of document %Document%. %ErrorDescription%';
											|it = 'Impossibile annullare la registrazione del  documento %Document%. %ErrorDescription%';
											|pl = 'Nie udało się anulować zatwierdzenie dokumentu %Document%. %ErrorDescription%';
											|tr = '%Document% belgesinin kaydedilmesi iptal edilemedi.%ErrorDescription%'");
						EndIf;
						
						ErrorText = StrReplace(ErrorText, "%Document%", DocumentObject);
						ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ShortErrorText);
						
						Common.MessageToUser(ErrorText, DocumentObject);
						
						Continue;
					EndTry;
					
					TableRow.State = ?(Posting, 0, 2);
					
					NumberOfChangedDocuments = NumberOfChangedDocuments + 1;
					
				EndIf;
				
				DocumentsForProcessing_.Add(TableRow);
				
			EndIf;
			
		EndDo;
		
		For Each RowToDelete In ArrayOfRowsToDelete_ Do
			Object.Documents.Delete(RowToDelete);
		EndDo;
	
		If Cancel Then
			RollbackTransaction();
			
			EventName = NStr("vi = 'Kết chuyển văn bản';
							|ru = 'Проведение документов';
							|en = 'Document posting'; fa = 'ثبت سند';
							|it = 'Registrazione dei documenti';
							|pl = 'Zaksięgowanie dokumentów';
							|tr = 'Belge kaydetme'", Common.DefaultLanguageCode());
			
			WriteLogEvent(EventName, EventLogLevel.Error, , ,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Else
			ManagementOfWaybills(DocumentsForProcessing_);
			PowerOfAttorneyManagement();
			
			CommitTransaction();
		EndIf;
	
	Except
		RollbackTransaction();
		
		EventName = NStr("vi = 'Kết chuyển văn bản';
						|ru = 'Проведение документов';
						|en = 'Document posting'; fa = 'ثبت سند';
						|it = 'Registrazione dei documenti';
						|pl = 'Zaksięgowanie dokumentów';
						|tr = 'Belge kaydetme'", Common.DefaultLanguageCode());
		
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return NumberOfChangedDocuments;
	
EndFunction

&AtServerNoContext
Function FullDocumentName(DocumentRef)
	
	Return DocumentRef.Metadata().FullName();
	
EndFunction

&AtServer
Procedure UpdateTextOfInformationLabelGeneratedDocuments()
	
	ArrayOfLabels = New Array;
	
	DocumentAmounts_ = New Structure;
	DocumentAmounts_.Insert("OrderAmount", 0);
	DocumentAmounts_.Insert("ApplicationAmount", 0);
	DocumentAmounts_.Insert("ActAmount", 0);
	DocumentAmounts_.Insert("TransferAmount", 0);
	DocumentAmounts_.Insert("ImplementationAmount", 0);
	DocumentAmounts_.Insert("AmountOfICO", 0);
	DocumentAmounts_.Insert("AmountOfTransferCertificate", 0);
	DocumentAmounts_.Insert("AmountTotal", 0);
	
	DocumentAmounts_.AmountTotal = ?(Object.PackageDepositIsRequired,
									Object.Goods.Total("AmountIncludingVAT"),
									Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		
		DocumentAmounts_.OrderAmount = ?(Object.PackageDepositIsRequired,
										Object.Goods.Total("AmountIncludingVAT"),
										Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
		
		LabelText = NStr("vi = 'Báo giá (%AmountTotal% %Currency%)';
						|ru = 'Коммерческое предложение (%AmountTotal% %Currency%)';
						|en = 'Sales quotation (%AmountTotal% %Currency%)'; fa = 'Sales quotation (%AmountTotal% %Currency%)';
						|it = 'Offerta commerciale (%AmountTotal% %Currency%)';
						|pl = 'Oferta cenowa (%AmountTotal% %Currency%)';
						|tr = 'Satış teklifi (%AmountTotal% %Currency%)'");
		
		ArrayOfLabels.Add(LabelText);
		
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		
		DocumentAmounts_.OrderAmount = ?(Object.PackageDepositIsRequired,
										Object.Goods.Total("AmountIncludingVAT"),
										Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
		
		CreateCommercialInvoice = Object.CreateCommercialInvoice
								And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments;
		
		If DocumentAmounts_.OrderAmount > 0 Then
			AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Đơn hàng';
														|ru = 'Заказ';
														|en = 'Order'; fa = 'سفارش';
														|it = 'Ordine';
														|pl = 'Order';
														|tr = 'Sipariş'"), "%AmountTotal%", DocumentAmounts_.OrderAmount, CreateCommercialInvoice);
		EndIf;
		
	ElsIf ThisIsImplementation(Object.DocumentCreationOption) Then
		
		OrderIsRequired_             = False;
		RegistrationOfActIsRequired               = False;
		RegistrationOfImplementationIsRequired         = False;
		RegistrationOfActOnTransferOfRightsIsRequired = False;
		
		FilterParameters = New Structure("SaleRegistrationOption",
											Enums.SalesRegistrationOptions.CustomerInvoice);
		ThereAreProducts_      = Object.Goods.FindRows(FilterParameters).Count() > 0;
		
		FilterParameters            = New Structure("SaleRegistrationOption",
													Enums.SalesRegistrationOptions.DeedOfTransfer);
		ThereAreGoodsWithActOfTransfer = Object.Goods.FindRows(FilterParameters).Count() > 0;
		
		FilterParameters = New Structure("SaleRegistrationOption",
											Enums.SalesRegistrationOptions.CustomerInvoiceServices);
		ThereAreServicesAct  = Object.Goods.FindRows(FilterParameters).Count() > 0;
		
		If Object.Goods.Count() = 0 Then
			If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
				CreateCommercialInvoice = Object.CreateCommercialInvoice
										And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments;
				
				AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Đơn hàng';
															|ru = 'Заказ';
															|en = 'Order'; fa = 'سفارش';
															|it = 'Ordine';
															|pl = 'Order';
															|tr = 'Sipariş'"), "%OrderAmount%", DocumentAmounts_.OrderAmount,
					CreateCommercialInvoice);
			Else
				CreateCommercialInvoice = Object.CreateCommercialInvoice
										And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
				
				AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Bán hàng';
															|ru = 'Реализация';
															|en = 'Sales'; fa = 'فروش';
															|it = 'Vendita';
															|pl = 'Sales';
															|tr = 'Satış'"), "%OrderAmount%", DocumentAmounts_.OrderAmount,
					CreateCommercialInvoice);
			EndIf;
		EndIf;
		
		For Each CurRow In Object.Goods Do
			
			If CurRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
				DocumentAmounts_.OrderAmount = DocumentAmounts_.OrderAmount + 
												?(Object.PackageDepositIsRequired,
													CurRow.AmountIncludingVAT,
													CurRow.AmountIncludingVATWithoutReusablePackages);
				
				OrderIsRequired_ = True;
			Else
				
				If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
					DocumentAmounts_.OrderAmount = DocumentAmounts_.OrderAmount + 
													?(Object.PackageDepositIsRequired,
														CurRow.AmountIncludingVAT,
														CurRow.AmountIncludingVATWithoutReusablePackages);
					
					OrderIsRequired_ = True;
				EndIf;
				
				If CurRow.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice
					Or ((ThereAreProducts_
							Or ThereAreGoodsWithActOfTransfer)
						And CurRow.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoiceServices
						And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice)
					Or ((ThereAreProducts_
							Or ThereAreServicesAct)
						And CurRow.SaleRegistrationOption = Enums.SalesRegistrationOptions.DeedOfTransfer
						And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice) Then
					
					DocumentAmounts_.ImplementationAmount = DocumentAmounts_.ImplementationAmount 
														+ ?(Object.PackageDepositIsRequired,
															CurRow.AmountIncludingVAT,
															CurRow.AmountIncludingVATWithoutReusablePackages);
					
					RegistrationOfImplementationIsRequired = True;
					
				ElsIf CurRow.SaleRegistrationOption = Enums.SalesRegistrationOptions.DeedOfTransfer Then
					DocumentAmounts_.AmountOfTransferCertificate = DocumentAmounts_.AmountOfTransferCertificate 
																+ ?(Object.PackageDepositIsRequired,
																	CurRow.AmountIncludingVAT,
																	CurRow.AmountIncludingVATWithoutReusablePackages);
					
					RegistrationOfActOnTransferOfRightsIsRequired = True;
				ElsIf CurRow.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoiceServices Then
					DocumentAmounts_.ActAmount = DocumentAmounts_.ActAmount 
												+ ?(Object.PackageDepositIsRequired,
													CurRow.AmountIncludingVAT,
													CurRow.AmountIncludingVATWithoutReusablePackages);
					
					RegistrationOfActIsRequired = True;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If OrderIsRequired_ Then
			CreateCommercialInvoice = Object.CreateCommercialInvoice
										And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments;
			
			AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Đơn hàng';
														|ru = 'Заказ';
														|en = 'Order'; fa = 'سفارش';
														|it = 'Ordine';
														|pl = 'Order';
														|tr = 'Sipariş'"), "%OrderAmount%", DocumentAmounts_.OrderAmount, CreateCommercialInvoice);
		EndIf;
		
		If RegistrationOfImplementationIsRequired Then
			CreateCommercialInvoice = Object.CreateCommercialInvoice
									And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
										Or (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
											And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments));
			
			AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Bán hàng';
														|ru = 'Реализация';
														|en = 'Sales'; fa = 'فروش';
														|it = 'Vendita';
														|pl = 'Sales';
														|tr = 'Satış'"), "%ImplementationAmount%", DocumentAmounts_.ImplementationAmount,
				CreateCommercialInvoice);
		EndIf;
		
		If RegistrationOfActOnTransferOfRightsIsRequired Then
			CreateCommercialInvoice = Object.CreateCommercialInvoice
									And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
										Or (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
											And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments));
			
			AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Biên bản chuyển giao quyền sở hữu';
														|ru = 'Акт на передачу прав';
														|en = 'Deed of transfer'; fa = 'صورتجلسه تحویل';
														|it = 'Atto di trasferimento dei diritti';
														|pl = 'Protokół przekazania praw';
														|tr = 'Yetki devir senedi'"), "%AmountOfTransferCertificate%",
				DocumentAmounts_.AmountOfTransferCertificate, CreateCommercialInvoice);
		EndIf;
		
		If RegistrationOfActIsRequired Then
			CreateCommercialInvoice = Object.CreateCommercialInvoice
									And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
										Or (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
											And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments));
									
			AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Biên bản';
														|ru = 'Акт';
														|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
														|it = 'Atto';
														|pl = 'Customer invoice — Services';
														|tr = 'Tutanak'"), "%ActAmount%", DocumentAmounts_.ActAmount, CreateCommercialInvoice);
		EndIf;
		
	ElsIf ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		
		OrderIsRequired_   = False;
		RegistrationOfTransferIsRequired = False;
		
		If Object.Goods.Count() = 0 Then
			If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
				AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Đơn hàng';
															|ru = 'Заказ';
															|en = 'Order'; fa = 'سفارش';
															|it = 'Ordine';
															|pl = 'Order';
															|tr = 'Sipariş'"), "%OrderAmount%", DocumentAmounts_.OrderAmount, False);
			Else
				NameOfDocumentParameter = NStr("vi = 'Chuyển giao';
												|ru = 'Передача';
												|en = 'Transfer'; fa = 'انتقال';
												|it = 'Consegna';
												|pl = 'Transfer';
												|tr = 'Transfer'");
				If ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
					NameOfDocumentParameter = NStr("vi = 'Giao hàng';
													|ru = 'Отгрузка';
													|en = 'Shipment'; fa = 'ارسال';
													|it = 'Shipment';
													|pl = 'Shipment';
													|tr = 'Sevkiyat'");
				EndIf;
				AddCaptionTextToArray(ArrayOfLabels, NameOfDocumentParameter, "%TransferAmount%", DocumentAmounts_.OrderAmount, False);
			EndIf;
		EndIf;
		
		For Each CurRow In Object.Goods Do
			
			If CurRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
				DocumentAmounts_.OrderAmount = DocumentAmounts_.OrderAmount + CurRow.AmountIncludingVATWithoutReusablePackages;
				
				OrderIsRequired_ = True;
			Else
				If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
					DocumentAmounts_.OrderAmount = DocumentAmounts_.OrderAmount + CurRow.AmountIncludingVATWithoutReusablePackages;
					
					OrderIsRequired_ = True;
				EndIf;
				
				DocumentAmounts_.TransferAmount = DocumentAmounts_.TransferAmount
					+ CurRow.AmountIncludingVATWithoutReusablePackages;
				
				RegistrationOfTransferIsRequired = True;
			EndIf;
			
		EndDo;
		
		If OrderIsRequired_ Then
			AddCaptionTextToArray(ArrayOfLabels, NStr("vi = 'Đơn hàng';
														|ru = 'Заказ';
														|en = 'Order'; fa = 'سفارش';
														|it = 'Ordine';
														|pl = 'Order';
														|tr = 'Sipariş'"), "%OrderAmount%", DocumentAmounts_.OrderAmount, False);
		EndIf;
		
		If RegistrationOfTransferIsRequired Then
			NameOfDocumentParameter = NStr("vi = 'Chuyển giao';
											|ru = 'Передача';
											|en = 'Transfer'; fa = 'انتقال';
											|it = 'Consegna';
											|pl = 'Transfer';
											|tr = 'Transfer'");
			If ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
				NameOfDocumentParameter = NStr("vi = 'Giao hàng';
												|ru = 'Отгрузка';
												|en = 'Shipment'; fa = 'ارسال';
												|it = 'Shipment';
												|pl = 'Shipment';
												|tr = 'Sevkiyat'");
			EndIf;
			AddCaptionTextToArray(ArrayOfLabels, NameOfDocumentParameter, "%TransferAmount%", DocumentAmounts_.TransferAmount, False);
		EndIf;
		
	EndIf;
	
	GoodsIssueNoteCreationIsRequired = False;
	
	If UseWarehouseManagementSystem
		And GoodsIssueNoteCreationIsAvailable
		And Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		
		For Each CurRow In Object.Goods Do
			WarehouseUsesOrderScheme = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(CurRow.Warehouse);
			
			If WarehouseUsesOrderScheme
				And CurRow.SupplyOption = Enums.SupplyOptions.Ship Then
				
				GoodsIssueNoteCreationIsRequired = True;
				
				Break;
				
			EndIf;
		EndDo;
		
	EndIf;
	
	If GoodsIssueNoteCreationIsRequired Then
		LabelText = NStr("vi = 'Phiếu xuất kho';
						|ru = 'Расходный ордер на товары';
						|en = 'Goods issue'; fa = 'حواله انبار';
						|it = 'Mandato di pagamento per le merci';
						|pl = 'Asygnata rozchodowa na wiersze pozycji';
						|tr = 'Ambar çıkış fişi'");
		
		ArrayOfLabels.Add(LabelText);
	EndIf;
	
	PaymentStepsServer.CheckAndFillInPaymentScheduleStages(ThisObject);
	
	If Object.CreateCashAccountReceiptNote
		And Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal
		And Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
		
		FilterParameters = New Structure("PaymentDate", Object.Date);
		PaymentLines_    = Object.PaymentScheduleSteps.FindRows(FilterParameters);
		
		If PaymentLines_.Count() > 0 Then
			TableOfPaymentStages = Object.PaymentScheduleSteps.Unload(PaymentLines_, "PaymentAmount, PackageDepositValue");
			TableOfPaymentStages.GroupBy(,"PaymentAmount, PackageDepositValue");
			
			DocumentAmounts_.AmountOfICO = TableOfPaymentStages[0].PaymentAmount + TableOfPaymentStages[0].PackageDepositValue;
			
			LabelText = NStr("vi = 'Phiếu thu (%AmountOfICO% %Currency%)';
							|ru = 'ПКО (%AmountOfICO% %Currency%)';
							|en = 'Incoming payment — Cash account (%AmountOfICO% %Currency%)'; fa = 'Incoming payment — Cash account (%AmountOfICO% %Currency%)';
							|it = 'Mandato Di Versamento In Cassa (%AmountOfICO% %Currency%)';
							|pl = 'POG (%AmountOfICO% %Currency%)';
							|tr = 'Gelen ödeme - kasa hesabı (%AmountOfICO% %Currency%)'");
			
			ArrayOfLabels.Add(LabelText);
		EndIf;
			
	EndIf;
	
	If Object.Goods.Total("AmountIncludingVATReturn") > 0
		And Object.CreateRequestForReturnOfGoodsFromCustomers Then
		
		For Each LineDocument In Object.Documents Do
			If TypeOf(LineDocument.Document) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				DocumentAmounts_.ApplicationAmount = DocumentAmounts_.ApplicationAmount + LineDocument.DocumentAmount;
			EndIf;
		EndDo;
		
		DocumentAmounts_.ApplicationAmount = ?(DocumentAmounts_.ApplicationAmount = 0, Object.Goods.Total("AmountIncludingVATReturn"), DocumentAmounts_.ApplicationAmount);
		
		LabelText = NStr("vi = 'Giấy đề nghị trả hàng (%ApplicationAmount%%Currency%)';
						|ru = 'Заявка на возврат (%ApplicationAmount% %Currency%)';
						|en = 'Return request (%ApplicationAmount% %Currency%)'; fa = 'Return request (%ApplicationAmount% %Currency%)';
						|it = 'Domanda di rimborso (%ApplicationAmount% %Currency%)';
						|pl = 'Wniosek o zwrot (%ApplicationAmount% %Currency%)';
						|tr = 'İade talebi (%ApplicationAmount% %Currency%)'");
		
		ArrayOfLabels.Add(LabelText);
		
	EndIf;
	
	LabelGeneratedDocuments = "";
	
	ArrayOfLabelsToOutput = New Array;
	
	For Each CurItem In ArrayOfLabels Do
		
		PositionAmount = StrFind(CurItem, "%Sum");
		AmountName = Mid(CurItem, PositionAmount+1, StrFind(CurItem, "%", , PositionAmount+1) - PositionAmount - 1);
		
		If PositionAmount = 0 And ValueIsFilled(CurItem)
			Or DocumentAmounts_.Property(AmountName) And DocumentAmounts_[AmountName] <> 0 Then
			ArrayOfLabelsToOutput.Add(CurItem);
		EndIf;
		
	EndDo;
	
	LabelGeneratedDocuments = StrConcat(ArrayOfLabelsToOutput, ", ");
	
	For Each SumElement In DocumentAmounts_ Do
		LabelGeneratedDocuments = StrReplace(LabelGeneratedDocuments,
												"%"+SumElement.Key+"%",
												Format(SumElement.Value, "NFD=2"))
	EndDo;

	LabelGeneratedDocuments = StrReplace(LabelGeneratedDocuments,
												"%Currency%",
												Object.Currency);
	
	UpdateHyperlinkOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtServer
Procedure UpdateHyperlinkOfInformationLabelGeneratedDocuments()
	
	If DocumentsAreCreated Then
		Items.LabelGeneratedDocuments.Hyperlink = True;
	Else
		Items.LabelGeneratedDocuments.Hyperlink = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddCaptionTextToArray(ArrayOfLabels, NameOfDocumentParameter, NameOfAmountParameter, DocumentAmount, CreateCommercialInvoice)
	
	If CreateCommercialInvoice
		And Not ThisIsTransferOperation(Object.BusinessOperation) Then
		
		LabelText = NStr("vi = '%NameOfDocumentParameter% + Hóa đơn (%NameOfAmountParameter% %Currency%)';
						|ru = '%NameOfDocumentParameter% + Счет (%NameOfAmountParameter% %Currency%)';
						|en = '%NameOfDocumentParameter% + Invoice (%NameOfAmountParameter% %Currency%)'; fa = '%NameOfDocumentParameter% + Invoice (%NameOfAmountParameter% %Currency%)';
						|it = '%NameOfDocumentParameter% + Fattura (%NameOfAmountParameter% %Currency%)';
						|pl = '%NameOfDocumentParameter% + Rachunek (%NameOfAmountParameter% %Currency%)';
						|tr = '%NameOfDocumentParameter% + Hesap (%NameOfAmountParameter% %Currency%)'");
		
	Else
		LabelText = NStr("vi = '%NameOfDocumentParameter% (%NameOfAmountParameter% %Currency%)';
						|ru = '%NameOfDocumentParameter% (%NameOfAmountParameter% %Currency%)';
						|en = '%NameOfDocumentParameter% (%NameOfAmountParameter% %Currency%)'; fa = '%NameOfDocumentParameter% (%NameOfAmountParameter% %Currency%)';
						|it = '%NameOfDocumentParameter% (%NameOfAmountParameter% %Currency%)';
						|pl = '%NameOfDocumentParameter% (%NameOfAmountParameter% %Currency%)';
						|tr = '%NameOfDocumentParameter% (%NameOfAmountParameter%%Currency%)'");
	EndIf;
	
	LabelText = StrReplace(LabelText, "%NameOfDocumentParameter%", NameOfDocumentParameter);
	LabelText = StrReplace(LabelText, "%NameOfAmountParameter%",    NameOfAmountParameter);
	
	ArrayOfLabels.Add(LabelText);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisObject);
EndProcedure

&AtClientAtServerNoContext
Function ThisIsTransferOperation(BusinessOperation)
	
	TransferOperations_ = New Array;
	TransferOperations_.Add(PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"));
	TransferOperations_.Add(PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	
	ThisIsTransferOperation = TransferOperations_.Find(BusinessOperation) <> Undefined;
	
	Return ThisIsTransferOperation;
	
EndFunction

&AtClientAtServerNoContext
Function ThisIsCustomerOrderOperation(VariantOfRegistrationOfDocumentsOfSale)
	
	CustomerOrderOperations = New Array;
	CustomerOrderOperations.Add(PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder"));
	CustomerOrderOperations.Add(PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer"));
	CustomerOrderOperations.Add(PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice"));
	
	ThisIsCustomerOrderOperation = CustomerOrderOperations.Find(VariantOfRegistrationOfDocumentsOfSale) <> Undefined;
	
	Return ThisIsCustomerOrderOperation;
	
EndFunction

&AtClientAtServerNoContext
Function ThisIsOperationOfShippingGoods(BusinessOperation)
	
	Return BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsShipmentToCustomer");
	
EndFunction

#Region Fiscalization

&AtClient
Function FiscalizeDocuments()
	
	ArrayOfFiscalizedDocuments = New Array;
	
	If DocumentsAreCreated Then
		
		If Not FiscalizationByWarehouseIsAllowed(Object.Warehouse, Object.IssueAFiscalReceipt) Then
			Return ArrayOfFiscalizedDocuments.Count();
		EndIf; 
		
		FillInConnectedHardwareServer();
		TMPeripheralsClient.SetHardwareConnectionStatus(
			True,
			ThisObject,
			UsedEquipment(),
			EquipmentTable);
			
		Equipment = Undefined;
		For Each String In EquipmentTable Do
			If String.Attached Then
				Equipment = String.Equipment;
				Break;
			EndIf; 
		EndDo; 
		
		If Not ValueIsFilled(Equipment) Then
			Return ArrayOfFiscalizedDocuments.Count();
		EndIf;
		
		FiscalizationIsRequired = False;
		
		For Each Document In Object.Documents Do
			DocumentTypeLink = TypeOf(Document.Document);
			If DocumentTypeLink = Type("DocumentRef.CustomerInvoice")
				Or DocumentTypeLink = Type("DocumentRef.CustomerInvoiceServices")
				Or DocumentTypeLink = Type("DocumentRef.CashAccountReceiptNote") Then
				FiscalizationIsRequired = True;
				Break;
			EndIf;
		EndDo;
		
		If Not FiscalizationIsRequired Then
			Return ArrayOfFiscalizedDocuments.Count();
		EndIf;
		
		RetailSalesClient.HandleShiftStateAutomatically(Equipment);
		
		For Each Document In Object.Documents Do
			
			DocumentRef = Document.Document;
			
			DocumentTypeLink = TypeOf(DocumentRef);
			
			If DocumentTypeLink = Type("DocumentRef.CustomerInvoice")
				Or DocumentTypeLink = Type("DocumentRef.CustomerInvoiceServices")
				Or DocumentTypeLink = Type("DocumentRef.CashAccountReceiptNote") Then
				
				If Not Document.Posted Then
					Continue;
				EndIf;
				
				ParametersOfReceiptFiscalizationOperation = GeneratingFiscalChecksServerCall.ParametersOfReceiptFiscalizationOperationBatchMode(
							DocumentRef, Equipment);
				
				If ParametersOfReceiptFiscalizationOperation = Undefined Then
					Continue;
				EndIf;
				
				NotificationOnCompletion = New CallbackDescription("PrintingReceipt_Completion", ThisObject, Document);
				
				PeripheralsReceiptPrintersClient.StartCheckFiscalizationOnFiscalDevice(
					NotificationOnCompletion,
					UUID,
					Equipment,
					ParametersOfReceiptFiscalizationOperation);
				
			EndIf;
				
		EndDo;
		
	EndIf;
	
EndFunction

&AtServer
Function FiscalizationByWarehouseIsAllowed(Warehouse, IssueAFiscalReceipt)
	
	Return WarehousesServer.FiscalizationByWarehouseIsAllowed(Warehouse, IssueAFiscalReceipt);
	
EndFunction

&AtServer
Procedure FillInConnectedHardwareServer()
	
	EquipmentTable.Clear();
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Organization", Object.Organization);
	TheStructureOfTheSearch.Insert("RetailFacility", Object.CashAccount);
	
	ArrayOfEquipment = GeneratingFiscalChecksServer.ConnectedReceiptPrintingEquipment(TheStructureOfTheSearch);
	
	For Each Item In ArrayOfEquipment Do
		String = EquipmentTable.Add();
		FillPropertyValues(String, Item);
	EndDo; 
	
EndProcedure

&AtClient
Function UsedEquipment()
	
	UsedEquipment = New Array;
	
	For Each HardwareTableRow In EquipmentTable Do
		UsedEquipment.Add(HardwareTableRow.Equipment);
	EndDo;
	
	Return UsedEquipment;
	
EndFunction

&AtClient
Procedure PrintingReceipt_Completion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		FiscalizationParameters = Undefined;
		
		// If the data was not recorded in the Fiscal Operation register, an error occurred during recording.
		If ExecutionResult.Property("OutputParametersSet") And ExecutionResult.OutputParametersSet.Count() > 8 Then
			FiscalizationParameters = ExecutionResult.OutputParametersSet[8];
		EndIf;
		
		CompletionParameters = New Structure;
		CompletionParameters.Insert("CloseForm",                False);
		CompletionParameters.Insert("Form",                       ThisObject);
		CompletionParameters.Insert("FiscalOperationDetails", FiscalizationParameters);
		CompletionParameters.Insert("NotificationOnCompletion",     New CallbackDescription("IssueCashReceiptCompletion", ThisObject, AdditionalParameters));
		
		// in any case, even with a successful recording, we proceed to perform actions after recording 
		TMPeripheralsClient.PerformActionAfterRecordingFiscalTransactionInLog(
			ThisObject,
			New CallbackDescription("FiscalTransactionIsRecordedInLog", TMPeripheralsClient, CompletionParameters),
			NStr("vi = 'Không thể ghi dữ liệu vào nhật ký máy tính tiền.';
				|ru = 'Не удалось записать данные в журнал фискальных операций.';
				|en = 'Cannot save data to the fiscal transactions journal.'; fa = 'Cannot save data to the fiscal transactions journal.';
				|it = 'Non è stato possibile salvare i dati nel registro delle operazioni fiscali.';
				|pl = 'Nie udało się zapisać dane do dziennika operacji fiskalnych.';
				|tr = 'Mali işlem günlüğüne veri yazılamadı.'"));
		
	Else
		
		MessageText = NStr("vi = 'Đã xảy ra lỗi khi in phiếu.
									|Phiếu không được in trên thiết bị ghi nhận tiền mặt.
									|Mô tả bổ sung:
									|%AdditionalDetails%';
									|ru = 'При печати чека произошла ошибка.
									|Чек не напечатан на фискальном устройстве.
									|Дополнительное описание:
									|%AdditionalDetails%';
									|en = 'An error occurred when printing the receipt.
									|The receipt is not printed on a fiscal device.
									|Additional description:
									|%AdditionalDetails%'; fa = 'An error occurred when printing the receipt.
									|The receipt is not printed on a fiscal device.
									|Additional description:
									|%AdditionalDetails%';
									|it = 'Durante la stampa di scontrino si è verificato un errore. 
									|Scontrino non è stato stampato dal dispositivo fiscale. 
									|Descrizione aggiuntiva:
									| %AdditionalDetails%';
									|pl = 'Podczas drukowania paragonu wystąpił błąd.
									|Paragon nie został wydrukowany na urządzeniu fiskalnym.
									|Dodatkowy opis:
									|%AdditionalDetails%';
									|tr = 'Fiş yazdırılırken hata oluştu.
									|Fiş mali cihazda yazdırılamadı.
									|Ek açıklama: 
									|%AdditionalDetails%.'");
		
		MessageText = StrReplace(
			MessageText,
			"%AdditionalDetails%",
			ExecutionResult.ErrorDescription);
			
		CommonClient.MessageToUser(MessageText);
		
		AdditionalParameters.Fiscalized = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueCashReceiptCompletion(Result, AdditionalParameters) Export
	
	AdditionalParameters.Fiscalized = True;
	
EndProcedure

#EndRegion

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "Close" Then
		ClosingInProgress = True;
		
		Close();
	EndIf;
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * EventName - String - 
// * Source - String - 
// * Parameter - Structure - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("EventName", "");
	Result.Insert("Source", "");
	Result.Insert("Parameter", New Structure());
	
	Return Result;
	
EndFunction

// Parameters:
// 	Result - Arbitrary
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export
	
	EventName = AdditionalParameters.EventName;
	Source   = AdditionalParameters.Source;
	Parameter   = AdditionalParameters.Parameter;
	
	HandlingFragmentAlerts(EventName, Source, Parameter);
	
EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName, Val Source, Val Parameter)
	
	Var SetAddressInTemporaryStorage, KitParameters, OpeningParameters, ThisIsWriteEvent;
	
	If EventName = "MessagesReceived"
		And Parameter.OwnerForm = UUID
		And Not ThisIsTransferOperation(Object.BusinessOperation) Then
		
		MessagesReceived(Parameter.Messages);
		
	EndIf;
	
	If EventName = "ChoosingPartnerFound"
		And Not Parameter.Carrier Then
		
		Object.Partner = Parameter.Partner;
		
		PartnerOnChangeServer();
		
	EndIf;
	
	If EventName = "AddingPartnerToSegment"
		Or EventName = "RemovingPartnerFromSegment" Then
		
		SetVisibilityOfShipmentBanToPartner();
		
	EndIf;
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
		
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns",        DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",        Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet",      Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT",           Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation",        Object.VATTaxation);
		OpeningParameters.Insert("Currency",                    Object.Currency);
		OpeningParameters.Insert("Partner", Object.Partner);
		If Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
			OpeningParameters.Insert("Terms", Undefined);
		Else
			OpeningParameters.Insert("Terms", Object.Terms);
		EndIf;
		OpeningParameters.Insert("Date",                      Object.Date);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	// When a record event occurs, you need to update the status of the document.
	ThisIsWriteEvent = (Left(EventName,7) = "Record_");
	
	If ThisIsWriteEvent Then
		UpdateDocumentState(Source);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessAddressChange(Item, NameOfAddressDetails)
	
	AttributesNames = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(NameOfAddressDetails);
	
	If IsBlankString(Object[AttributesNames.NameOfDetailsOfDeliveryAddress]) Then
		
		GoodsDeliveryClient.ClearAddressPresentation(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
	Else
		
		GoodsDeliveryClient.WhenChangingAddressPresentation(
			Item,
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
		DeliveryAddressOnChangeATServer(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues]);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeliveryAddressOnChangeATServer(Address, AddressValue, FieldValueAddress)
	
	CustomFormatAddress = ContactsManager.AddressEnteredInFreeFormat(AddressValue);
	If Not CustomFormatAddress Then
		
		CountryData1 = ContactsManager.ContactInformationAddressCountry(AddressValue);
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = Address;
		NewAddressStructure.Country = CountryData1.Description;
		NewAddressStructure.CountryCode = CountryData1.Code;
		
		AddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		SetAddressTypeInFreeForm(AddressValue);
		
	EndIf;
	
	FieldValueAddress = ContactsManager.ContactInformationToXML(
		AddressValue,
		Address,
		Enums.ContactInformationTypes.Address);
	
EndProcedure

&AtServerNoContext
Procedure SetAddressTypeInFreeForm(DeliveryAddressValue)
	
	StringTypeToReplace = """addressType"": ""Administrative-territorial""";
	StringIsFreeType = """addressType"": ""FreeForm""";
	DeliveryAddressValue = StrReplace(DeliveryAddressValue, StringTypeToReplace, StringIsFreeType);
	
EndProcedure

#Region FillingInTermsOfSales

&AtServer
Function DefaultContract()
	
	ObjectOfOperation = Object.BusinessOperation;
	If ThisIsOperationOfShippingGoods(ObjectOfOperation) Then
		ObjectOfOperation = OperationImplementationToClient;
	EndIf;

	LineOfBusiness = Undefined;
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	Contract = SalesServer.GetDefaultContract(Object,
		ObjectOfOperation,
		Object.Currency,
		LineOfBusiness,
		Object.ConsignmentSales25);
		
	Return Contract;
		
EndFunction

&AtServer
Procedure FillInDefaultContract()
	
	Contract = DefaultContract();
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ContractOnChangeServer();
	EndIf;
	
	UpdateDebtLimit();
	UpdatePartnerDossierInformation();
	
EndProcedure

&AtServer
Procedure FillInDefaultSalesConditions()
	
	FillInPartnerData = True;
	
	SelectionParameterBusinessOperations = Undefined;
	EmptyDocumentLink = Documents.CustomerInvoice.EmptyRef();
	
	FilterParameters = New Structure;
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		EmptyDocumentLink = Documents.SalesOrder.EmptyRef();
	
	ElsIf ThisIsImplementation(Object.DocumentCreationOption) Then 

		SelectionParameterBusinessOperations = New Array();
		SelectionParameterBusinessOperations.Add(
			Enums.BusinessTransactions.SaleToCustomer);
		SelectionParameterBusinessOperations.Add(
			Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
		SelectionParameterBusinessOperations.Add(
			Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
	
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee
		Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
		
		EmptyDocumentLink = Documents.TransferOfGoodsToBailee.EmptyRef();
		SelectionParameterBusinessOperations = New Array();
		SelectionParameterBusinessOperations.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
		SelectionParameterBusinessOperations.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		
		If UseShipmentWithDeferredTransferOfTitle2_5 Then
			SelectionParameterBusinessOperations.Add(OperationImplementationToClient);
			FilterParameters.Insert("ShipmentWithDeferredTransferOfTitle25", True);
		EndIf;
		
		FilterParameters.Insert("ConsignmentSales25", UseSalesCommission);
		
	Else
		
		Sales.WhenDeterminingDocumentTypeOfDocumentBeingCreatedSalesAssistant(ThisObject, EmptyDocumentLink);
	
	EndIf;
	
	FilterParameters.Insert("ConsiderWarehouseGroups", True);
	FilterParameters.Insert("SelectedAgreement",    Object.Terms);
	FilterParameters.Insert("EmptyDocumentLink",  EmptyDocumentLink);
	FilterParameters.Insert("BusinessTransactions",  SelectionParameterBusinessOperations);
	
	DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Object.Partner, FilterParameters);
	
	If DefaultSalesTerms <> Undefined Then
		
		If Not ToUseTermsOfSales
			Or (Object.Terms <> DefaultSalesTerms.Terms
				And ValueIsFilled(DefaultSalesTerms.Terms)) Then
			
			FillInPartnerData = False;
			Object.Terms         = DefaultSalesTerms.Terms;
			
			FillIn_TermsOfSales(DefaultSalesTerms);
			FillInSalesVATTaxation();
			
			If ToUseTermsOfSales Then
				
				TermsOnChangeServer();
				
				StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
				
				FillParameters = New Structure;
				FillParameters.Insert("Date",                         Object.Date);
				FillParameters.Insert("Currency",                       Object.Currency);
				FillParameters.Insert("Organization",                  Object.Organization);
				FillParameters.Insert("Terms",                   Object.Terms);
				FillParameters.Insert("VATTaxation",           Object.VATTaxation);
				FillParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
				FillParameters.Insert("CalculateSets",           True);
				FillParameters.Insert("PopulationFields", "             Price, VATRate, PriceKind, DeliveryPeriodDays");
				
				StructureOfActions = New Structure;
				StructureOfActions.Insert("RecalculateAmount",                    "NumberOfPackages");
				StructureOfActions.Insert("RecalculateAmountWithVAT",                StructureOfRecalculationOfAmount);
				StructureOfActions.Insert("RecalculateVATAmount",                 StructureOfRecalculationOfAmount);
				StructureOfActions.Insert("RecalculateAmountOfManualDiscount",        "NumberOfPackages");
				StructureOfActions.Insert("ClearAutomaticDiscount",        Undefined);
				StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
				
				EnterprisePricesFillingServer.FillInPrices(Object.Goods,
											, // Array of rows or selection structure
											FillParameters,
											StructureOfActions);
			EndIf;
			
		Else
			Object.Terms = DefaultSalesTerms.Terms;
		EndIf;
		
		If	UseShipmentWithDeferredTransferOfTitle2_5
				And ValueIsFilled(DefaultSalesTerms.Terms)
				And DefaultSalesTerms.SaleWithDeferredTransferOfTitleIsAllowed
				And Not ThisIsImplementation(Object.DocumentCreationOption) Then
			Object.BusinessOperation =  Enums.BusinessTransactions.GoodsShipmentToCustomer;
		EndIf;
		
		BusinessOperationOnChangeServer(False);
		
	EndIf;
	
	If FillInPartnerData
		And ValueIsFilled(Object.Partner) Then
		
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTermsOfSalesUnderAgreement()
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Object.Terms, True);
	
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	If UseShipmentWithDeferredTransferOfTitle2_5
		And SalesTermsAndConditions.SaleWithDeferredTransferOfTitleIsAllowed
		And Not ThisIsImplementation(Object.DocumentCreationOption)
		And Not Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		
		Object.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer;
		
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",                         Object.Date);
	FillParameters.Insert("Currency",                       Object.Currency);
	FillParameters.Insert("Organization",                  Object.Organization);
	FillParameters.Insert("Terms",                   Object.Terms);
	FillParameters.Insert("VATTaxation",           Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillParameters.Insert("CalculateSets",           True);
	FillParameters.Insert("PopulationFields",               "Price, VATRate, PriceKind, DeliveryPeriodDays");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",                    "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT",                StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount",                 StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount",        "NumberOfPackages");
	StructureOfActions.Insert("ClearAutomaticDiscount",        Undefined);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	
	EnterprisePricesFillingServer.FillInPrices(Object.Goods, , FillParameters, StructureOfActions);
	
	For Each CurrentRow In Object.Goods Do
		CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	EndDo;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.BankAccount);
	
	Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
	
EndProcedure

&AtServer
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions)
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Then
		Object.PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
	EndIf;
	
	Object.ToReturnReusablePackage = SalesTermsAndConditions.ReturnReusablePackage;
	
	FillableProperties = "Currency, BusinessOperation, PriceIncludesVAT, ReusablePackageReturnCycleLength, 
							|PackageDepositIsRequired, FinancialAccountingGroup,ARAPCurrency";
	
	FillPropertyValues(Object, SalesTermsAndConditions, FillableProperties);
	
	If ValueIsFilled(SalesTermsAndConditions.OrderFrequency) Then
		Object.DateOfNextOrder = CurrentSessionDate() + SalesTermsAndConditions.OrderFrequency*86400;
	EndIf;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization)
							And SalesTermsAndConditions.Organization <> Object.Organization;
	PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod)
							And SalesTermsAndConditions.PaymentMethod <> Object.PaymentMethod;
	
	Object.PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	If OrganizationChanged Then
		Object.Organization = SalesTermsAndConditions.Organization;
	EndIf;
	
	If OrganizationChanged
		Or PaymentFormChanged Then
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		
		Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization = Object.Organization;
		ParametersStructure.PaymentMethod = Object.PaymentMethod;
		
		Object.CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) Then
			Object.Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.ContactPerson) 
			And Not ValueIsFilled(Object.ContactPerson) Then
			Object.ContactPerson = SalesTermsAndConditions.ContactPerson;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
	
	Object.Contract = DefaultContract();
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount, Object.CounterpartyBankAccount);
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Object.Warehouse = SalesTermsAndConditions.Warehouse;
		
		StructureOfResponsible = SalesServer.GetWarehouseManager(Object.Warehouse);
		
		If StructureOfResponsible <> Undefined Then
			Object.IssuiedBy          = StructureOfResponsible.EmployeeResponsible;
			Object.IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	Object.DeliveryPeriodDays = SalesTermsAndConditions.DeliveryPeriodDays;
	
	If ValueIsFilled(SalesTermsAndConditions.DeliveryPeriodDays)
		And UseAdvancedFeaturesOfSalesOrder
		And UseShipmentByRowsInSalesOrder Then
		
		ShipmentDateInLine = Date(1,1,1);
		StartDate    = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		EndDate = TMCommonUseClientServer.CalculatePeriodEndDate(StartDate,
																						Enums.Periodicity.Day,
																						SalesTermsAndConditions.DeliveryPeriodDays);
		
		ShipmentDateInLine = EndDate + 1;
		If Object.NotShipInInstallments Then
			Object.DateOfShipment = ShipmentDateInLine;
		EndIf;
		
		For Each String In Object.Goods Do
			String.DateOfShipment = ShipmentDateInLine;
		EndDo;
		
	EndIf;
	
	If Not ValueIsFilled(SalesTermsAndConditions.ContractsAreUsed)
		Or Not SalesTermsAndConditions.ContractsAreUsed Then
		
		Object.ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
		
	Else
		Object.ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract, "ForeignCurrencyTransaction");
	EndIf;
	
EndProcedure

#EndRegion

#Region PaymentTerm

&AtServer
Procedure SetVisibilityOfPaymentDetails_()
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal
		Or ThisIsTransferOperation(Object.BusinessOperation)
		Or ThisIsOperationOfShippingGoods(Object.BusinessOperation) Then
		
		ItemVisibility = False;
		
	Else
		
		ItemVisibility = True;
		
	EndIf;
	
	Items.PaymentGroup_2.Visible = ItemVisibility;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfBusinessDirection()
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		ItemVisibility = False;
	Else
		ItemVisibility = True;
	EndIf;
	
	Items.LineOfBusiness.Visible = ItemVisibility;
	
EndProcedure

&AtServer
Procedure SetBankAccountVisibility()
	
	DesignOptionIsNotCommercialOffer
		= Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Items.BankAccount.Visible = DesignOptionIsNotCommercialOffer;
	
EndProcedure

&AtServer
Procedure SetVisibilityGroupFinAccounting()
	
	DesignOptionIsNotCommercialOffer
		= Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Items.FinancialAccountingGroup.Visible = DesignOptionIsNotCommercialOffer;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfMultiTurnPackaging()
	
	DesignOptionIsNotCommercialOffer
		= Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
		
	Items.AddReusablePackage.Visible = DesignOptionIsNotCommercialOffer;
	Items.TareGroup.Visible                   = DesignOptionIsNotCommercialOffer;
	Items.GroupRequiresADepositForPackaging.Visible   = DesignOptionIsNotCommercialOffer;
	
EndProcedure

&AtServer
Procedure SetUnitVisibility()
	
	DesignOptionIsNotCommercialOffer
		= Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Items.Department.Visible = DesignOptionIsNotCommercialOffer;
	
EndProcedure

&AtServer
Procedure SetWarehouseVisibility()
	
	DesignOptionIsNotCommercialOffer
		= Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Items.Warehouse.Visible = DesignOptionIsNotCommercialOffer;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfAgreementWithClient()
	
	DesignOptionIsNotCommercialOffer
		= Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Items.Terms.Visible                      = DesignOptionIsNotCommercialOffer;
	Items.GoodsFillThePricesByTermsOfSales.Visible = DesignOptionIsNotCommercialOffer;
	
EndProcedure

&AtServer
Procedure SetVisibilityExpirationDate()
	
	DesignOptionCommercialOffer
		= Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
		
	Items.ValidityPeriod.Visible              = DesignOptionCommercialOffer;
	Items.NotPartialSaleAllowed.Visible = DesignOptionCommercialOffer;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandToFillInContractPriceView()
	
	Items.GoodsFillInPricesUnderAgreement.Visible = Object.ConsignmentSales25;
	Items.GoodsFillThePricesByTermsOfSales.Visible = Not Object.ConsignmentSales25;
	
EndProcedure

#EndRegion

#Region OptionsForRegistrationOfDocuments

&AtServer
Procedure DocumentCreationOptionOnChangeServer()
	
	SetSoftwareAvailability();
	FillOperationSelectionList(True);
	SetAgreementSelectionParameters();
	
	If Object.Goods.Count() > 0 Then
		FillInDesignOptionInTablePart();
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("PictureMultipleWarehouses");
	ItemArray.Add("SeveralWarehousesText");
	ItemArray.Add("DecorationDetailsOfPrintImplementation");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal);
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		Items.GroupAdditionalAttributes.CurrentPage = Items.GroupAdditionalDetailsCommercialOffer;
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		Items.GroupAdditionalAttributes.CurrentPage = Items.GroupAdditionalDetailsCustomerOrder;
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice Then
		Items.GroupAdditionalAttributes.CurrentPage = Items.GroupAdditionalDetailsSalesOfGoodsServices;
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
		Items.GroupAdditionalAttributes.CurrentPage = Items.GroupAdditionalDetailsCustomerOrderSaleOfGoodsServices;
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee Then
		Items.GroupAdditionalAttributes.CurrentPage = Items.TheGroupFurtherDetailsOfTheTransferOfGoodsToTheKeeper;
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
		Items.GroupAdditionalAttributes.CurrentPage = Items.GroupAdditionalDetailsCustomerOrderTransferOfGoodsToTheCustodian;
	EndIf;
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		Items.DeliveryAddressSelfPickup.Visible = False;
		
		Items.GroupDeliveryMethodCarrier.Visible = False;
		Items.DeliveryPages.CurrentPage         = Items.PageDeliveryQuotation;
		
	Else
		Items.DeliveryAddressSelfPickup.Visible = True;
		// We call filling in the delivery details when the Partner changes,
		//	in order to completely re-fill them, because the document type has changed.
		GoodsDelivery.FillInDeliveryDetails(Items, "Partner", Object);
	EndIf;
	
	Object.ConsignmentSales25 =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			And (Not ToUseTermsOfSales Or SalesServer.ThisIsAgreementOnNewCommission(Object.Terms));
	
	UseContracts =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
		Or (Object.ConsignmentSales25 And Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	
	SalesServer.SetBlankContractMark(Items, "Contract", UseContracts);
	
	EstablishVisibilityOfAgreementWithClient();
	EstablishVisibilityOfMultiTurnPackaging();
	SetVisibilityExpirationDate();
	SetWarehouseVisibility();
	SetUnitVisibility();
	SetBankAccountVisibility();
	SetVisibilityGroupFinAccounting();
	SetVisibilityGroupPaymentShipmentPrintOptions();
	SetVisibilityOfPaymentDetails_();
	EstablishVisibilityOfBusinessDirection();
	SetPropertiesOfElementsInOrderOfCalculations();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									DataProcessors.SalesWizard));
	
	SetVisibilityOfSeriesElements();
	FillInStatusesForSpecifyingSeries();
	
	SetVisibilityOfShippingDateFormElements();
	
	FillInListOfOptionsForRegistrationOfSalesDocuments();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInDesignOptionInTablePart(FillWithReplacement = True)
	
	For Each CurRow In Object.Goods Do
		If FillWithReplacement
			Or Not ValueIsFilled(CurRow.RegistrationOption) Then
			
			FillInLayoutOptionInRowOfTablePart(CurRow, Object.DocumentCreationOption, Object.Date, Object.NotShipInInstallments);
			
			If CurRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
					Or CurRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
						CurRow.SupplyOption = Enums.SupplyOptions.Ship;
			EndIf;
			
		EndIf;
	EndDo;
	
	For Each CurRow In Object.SetOfSeries Do
		
		If FillWithReplacement
			Or Not ValueIsFilled(CurRow.RegistrationOption) Then
			CurRow.RegistrationOption = Object.DocumentCreationOption;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInLayoutOptionInRowOfTablePart(CurRow, DocumentCreationOption, Date, NotShipInInstallments)
	
	If DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice")
		Or DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer")
		Then
		
		If CurRow.DateOfShipment = BegOfDay(Date) Or NotShipInInstallments
			Or CurRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
			Or CurRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			
			CurRow.RegistrationOption = DocumentCreationOption;
			
		Else
			CurRow.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder");
		EndIf;
		
	Else
		CurRow.RegistrationOption = DocumentCreationOption;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDefaultOptionForIssuingSalesDocuments()
	
	If Object.CreateSalesOrder
		And UseSalesOrders
		And Object.CreateSalesDocument Then
		
		Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice;
		
	ElsIf Object.CreateSalesDocument Then
		
		Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice;
		
	ElsIf Object.CreateSalesOrder
		And UseSalesOrders
		And Object.CreateTransferOfGoodsToBailee Then
		
		Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer;
		
	ElsIf Object.CreateTransferOfGoodsToBailee Then
		
		Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee;
		
	ElsIf UseSalesOrders
		And Object.CreateSalesOrder Then
		
		Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder;
		
	Else
		
		Sales.WhenSettingDefaultSalesPaperworkOption(ThisObject)
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ShippingDates

&AtClient
Procedure FillInShipmentDateCompletion(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		DateOfShipment = SelectedDate;
		ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
		
		FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows);
		SalesClient.NotifyEndOfFillingInShipmentDates(DateOfShipment, True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows)
	
	ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", DateOfShipment, ArrayOfSelectedRows);
	
EndProcedure

#EndRegion

#Region Delivery

&AtServer
Procedure FillInDeliveryDetails(FormItemName)
	
	FillParameters = GoodsDelivery.ParametersForFillingInBankingDetails();
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
		Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
		FillParameters.SourceOfStatistics = Documents.CustomerInvoice;
	ElsIf Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee
		Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
		
		FillParameters.SourceOfStatistics = Documents.TransferOfGoodsToBailee;
		
	Else
		FillParameters.SourceOfStatistics = Documents.SalesOrder;
	EndIf;
	
	If FormItemName = "GoodsRecipient" Then
		FillParameters.ClearDeliveryDetails = False;
		FillParameters.SetDeliveryMethod = False;
		FillParameters.SetDeliveryAddress = False;
	EndIf;
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object, FillParameters);
	
EndProcedure

&AtServer
Procedure FillInAttributesOfDeliveryOnBasisOf(DocumentObject, DocumentBasis)
	
	DeliveryDetails_ = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails();
	
	If GetFunctionalOption("UseSaleByMultipleOrders") Then
		
		ReferencesArrray = New Array;
		ReferencesArrray.Add(DocumentBasis);
		HeaderAttributes = New Structure;
		
		SalesServerCall.GenerateImplementationFillInData(ReferencesArrray, DocumentObject.Metadata().Name, HeaderAttributes);
		CommonClientServer.SupplementStructure(HeaderAttributes, DeliveryDetails_, False);
		
	Else
		
		Query = New Query;
		
		Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers",
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
		Query.SetParameter("ToUseTermsOfSales",
			GetFunctionalOption("ToUseTermsOfSales"));
			
		If TypeOf(DocumentObject) = Type("DocumentObject.TransferOfGoodsToBailee") Then
			Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsByOrderType(TypeOf(DocumentBasis));
			Query.SetParameter("DocumentBasis", DocumentBasis);
		ElsIf TypeOf(DocumentObject) = Type("DocumentObject.CustomerInvoice") Then
			Handler = Documents.CustomerInvoice;
			Query.SetParameter("SalesOrder", DocumentBasis);
			Query.SetParameter("UsedDelivery", GoodsDeliveryClientServer.UsedDelivery());
			Query.SetParameter("UsedDelivery25", GoodsDeliveryClientServer.UsedDelivery25());
			Query.SetParameter("EnterOnBasisOfUnverified", False);
		Else
			Return;
		EndIf;
		
		Query.Text = Handler.QueryTextForFillingInBasedOnOrder();
		
		QueryResult = Query.ExecuteBatch();
		
		HeaderAttributes = QueryResult[0].Select();
		HeaderAttributes.Next();
		
	EndIf;
	
	GoodsDelivery.AddDeliveryDetailsToFillInDetails(DeliveryDetails_, HeaderAttributes);
	
	FillPropertyValues(DocumentObject, DeliveryDetails_);
	
EndProcedure

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure InitializeSalesAssistant()
	
	Modified = False;
	DocumentsAreCreated = False;
	ViewOnlyIsSet = False;
	Object.DoNotAskSupply = False;
	
	Object.Date = CurrentSessionDate();
	
	Object.Goods.Clear();
	Object.PaymentScheduleSteps.Clear();
	Object.DiscountsMarkups.Clear();
	Object.SetOfSeries.Clear();
	Object.Documents.Clear();
	Object.AdditionalAttributesOfCommercialProposal.Clear();
	Object.AdditionalOrderAttributes.Clear();
	Object.AdditionalSaleAttributes.Clear();
	Object.AdditionalInvoiceAttributes.Clear();
	Object.AdditionalAttributesTransferOfGoods.Clear();
	Object.AdditionalAttributesOfGoodsShipment.Clear();	
	TypesOfPrices.Clear();
	
	If SaleToRetailCustomerWasRegistered Then
		Object.Partner = Catalogs.Partners.RetailCustomer;
	Else
		Object.Partner = Undefined;
	EndIf;
	
	Object.Terms                     = Undefined;
	Object.Organization                    = Undefined;
	Object.BankAccount                 = Undefined;
	Object.Warehouse                          = Undefined;
	Object.PriceIncludesVAT                = Undefined;
	Object.Counterparty                     = Undefined;
	Object.Contract                        = Undefined;
	Object.SalesOpportunity                         = Undefined;
	Object.PaymentSchedule                   = Undefined;
	Object.AdditionalInformation       = Undefined;
	Object.PaymentMethod                    = Undefined;
	Object.BankAccount                 = Undefined;
	Object.CounterpartyBankAccount      = Undefined;
	Object.CashAccount                          = Undefined;
	Object.DeliveryAddress                  = Undefined;
	Object.VATTaxation             = Undefined;
	Object.Comment                    = Undefined;
	Object.NumberAccordingToCustomerData           = Undefined;
	Object.DateAccordingToInformationFromCustomer            = Undefined;
	Object.Shipper               = Undefined;
	Object.GoodsRecipient                = Undefined;
	Object.ShipperBankAccount = Undefined;
	Object.GoodsRecipientBankAccount  = Undefined;
	Object.FinancialAccountingGroup         = Undefined;
	Object.LoyaltyCard                = Undefined;
	Object.Vehicle                     = Undefined;
	Object.LetterOfAuthorityIssuedBy             = Undefined;
	Object.PowerOfAttorneyDate               = Undefined;
	Object.PowerOfAttorneyPerson               = Undefined;
	Object.PowerOfAttorneyNumber              = Undefined;
	Object.IssuiedBy                       = Undefined;
	Object.IssuiedByJobTitle              = Undefined;
	Object.Department                  = Undefined;
	Object.Basis                      = Undefined;
	Object.DeliveryTime                   = Undefined;
	Object.Driver                       = Undefined;
	Object.DocumentCreationOption    = Undefined;
	Object.DocumentAmount                 = Undefined;
	Object.DiscountsAreCalculated               = Undefined;
	Object.ToReturnReusablePackage      = Undefined;
	Object.ReusablePackageReturnCycleLength = Undefined;
	Object.PackageDepositIsRequired           = Undefined;
	Object.ARAPObjectSettings                = Undefined;
	Object.NotShipInInstallments             = True;
	Object.DateOfShipment                   = CurrentSessionDate();
	Object.LineOfBusiness        = Undefined;
	
	Object.Manager       = Users.CurrentUser();
	Object.Organization    = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	Object.Currency         = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.BankAccount);
	
	UseMultipleCashAccounts = GetFunctionalOption("UseMultipleCashAccounts");
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Object.Organization;
	ParametersStructure.PaymentMethod = Object.PaymentMethod;
	ParametersStructure.CashAccount       = Object.CashAccount;
	
	Object.CashAccount	= ?(UseMultipleCashAccounts,
						SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure),
						SettingsValueCached.GetOrganizationSDefaultSalesRegister());
	
	Object.Warehouse          = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse, GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments"));
	Object.Department  = SettingsValueCached.UserDivision(Object.Manager, Object.Department);
	
	Partner = Object.Partner;
	
	TMCommonUse.Filling(Object, New Structure, True);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	SetDefaultOptionForIssuingSalesDocuments();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	FillInDefaultSalesConditions();
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
	EndIf;
		
	If ValueIsFilled(Object.Warehouse) Then
		WarehouseOnChangeServer(True);
	EndIf;
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
	UpdateDebtLimit();
	
	BaseStructure = StructureOfBaseForPrinting();
	FillPropertyValues(Object, BaseStructure);
	
	PrintParameters = New Structure("BusinessOperation, Contract", Object.BusinessOperation, Object.Contract);
	
	PrintBasisTable.Load(DataProcessors.SalesWizard.PrintBasisTable(PrintParameters));
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	If Not ToUseTermsOfSales
		And TypesOfPrices.Count() > 0 Then
		
		DefaultPriceType = TypesOfPrices[0].Value;
		
	EndIf;
	
	DocumentCreationOptionOnChangeServer();
	
	UpdateHyperlinkOfInformationLabelGeneratedDocuments();
	
	SetOnlyViewFormElements(False);
	
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	SetVisibilityOfShippingDateFormElements();
	
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	
	FillInServiceDetailsOfDocumentForm();
	
	If Not ValueIsFilled(Object.ForeignCurrencyTransaction) Then
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	EndIf;
	
	UpdatePartnerDossierInformation();
	UpdatePartnerDossierInformationContacts();
	
EndProcedure

&AtClientAtServerNoContext
Procedure ResetTagsAndCaps(Items)
	
	Items.GoPartner.Check        = False;
	Items.GoShoppingCart.Check        = False;
	Items.GoToShipmentPayment.Check = False;
	Items.GoToDocuments_5.Check      = False;
	Items.GoShipping.Check       = False;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(Initialize = False)
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, False);
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	SetParametersForSelectingProductsWarehouse();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									DataProcessors.SalesWizard));
	
	SetVisibilityOfSeriesElements();
	FillInStatusesForSpecifyingSeries();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
		TotalWarehouses_);
	If Not Initialize Then
		ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref",
		WarehouseSelectionData(Object.Warehouse));
	
EndProcedure

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)";
	
	Query.SetParameter("GroupOfWarehouses", Warehouse);
	
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return WarehouseArray;
	
EndFunction

&AtServer
Procedure PartnerOnChangeServer()
	
	AttributesArray = New Array;
	
	If ToUseTermsOfSales Then
		
		AttributesArray.Add("Currency");
		AttributesArray.Add("ARAPCurrency");
		AttributesArray.Add("Contract");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Counterparty");
		AttributesArray.Add("Organization");
		AttributesArray.Add("Terms");
		
		FillOperationSelectionList();
		FillInDefaultSalesConditions();
		UpdateDebtLimit();
		
		If ValueIsFilled(Object.Terms) Then
			DocumentCurrency = Object.Currency;
			UpdateTextOfInformationLabelGeneratedDocuments();
			UpdateAvailabilityOfReturnContainerItems(ThisObject);
		EndIf;
		
		SetAgreementSelectionParameters();
		
	Else
		If ValueIsFilled(Object.Partner) Then
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
			PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
		EndIf;
	EndIf;
	
	Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
		
	AttributesArray.Add("Partner");
	ChangedBankingDetails = ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then
		SetPropertiesOfElementsInOrderOfCalculations();
	EndIf;
	
	WarehouseOnChangeServer();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
								New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInSalesOptionAttribute",
								New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	SetsServer.FillInServiceDetails(ThisObject);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	FillInServiceDetailsOfDocumentForm();
	CalculateTotals_(ThisObject);
	SetContractAvailability();
	
	FillBaseForPrinting();
	
	Partner = Object.Partner;
	
	If Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		FillInDeliveryDetails("Partner");
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	EndIf;
	
	If ToUseTermsOfSales Then

		OptionAndFlag = Undefined;
		If Object.SimplifiedFulfillment Then
			OptionAndFlag = New Structure("SupplyOption,WithAssignment", Object.SupplyOption, Undefined);
		EndIf;
		
		SecurityOptionAndFlagSeparately  = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
			Object.Terms,
			Object.SalesOrderStatus,
			OptionAndFlag);
			
	EndIf; 
	
	UpdatePartnerDossierInformationContacts();
	UpdatePartnerDossierInformation();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	Form.AmountTotal        = ?(Form.Object.PackageDepositIsRequired,
								Form.Object.Goods.Total("AmountIncludingVAT"),
								Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"));
	Form.VATAmount          = ?(Form.Object.PackageDepositIsRequired,
								Form.Object.Goods.Total("VATAmount"),
								Form.Object.Goods.Total("VATAmountWithoutReusablePackages"));
	Form.AutoDiscountAmount   = ?(Form.Object.PackageDepositIsRequired,
								Form.Object.Goods.Total("DiscountMarkupAmount"),
								Form.Object.Goods.Total("DiscountMarkupAmountWithoutReusablePackages"));
	Form.ManualDiscount = ?(Form.Object.PackageDepositIsRequired,
								Form.Object.Goods.Total("ManualDiscount"),
								Form.Object.Goods.Total("ManualDiscountWithoutReusablePackages"));
	AmountOfBonusPointsToDeductionInCurrency = ?(Form.Object.PackageDepositIsRequired,
								Form.Object.Goods.Total("AmountOfBonusPointsToDeductionInCurrency"),
								Form.Object.Goods.Total("AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages"));
	Form.DiscountAmount       = 	Form.AutoDiscountAmount 
								+ Form.ManualDiscount 
								+ AmountOfBonusPointsToDeductionInCurrency;
	AmountTotal              = ?(Form.Object.PackageDepositIsRequired,
								Form.Object.Goods.Total("Sum"),
								Form.Object.Goods.Total("SumWithoutReusablePackages"));
	
	If AmountTotal > 0 Then
		
		Form.AutoDiscountPercentage   = Form.AutoDiscountAmount * 100 / (AmountTotal + Form.DiscountAmount);
		Form.PercentRateOfManualDiscount = Form.ManualDiscount * 100 / (AmountTotal + Form.DiscountAmount);
		Form.DiscountPercentage       = Form.AutoDiscountPercentage + Form.PercentRateOfManualDiscount;
		
	ElsIf Form.DiscountAmount > 0 Then
		
		Form.AutoDiscountPercentage   = Form.AutoDiscountAmount * 100 / Form.DiscountAmount;
		Form.PercentRateOfManualDiscount = Form.ManualDiscount * 100 / Form.DiscountAmount;
		Form.DiscountPercentage       = 100;
		
	Else
		
		Form.AutoDiscountPercentage   = 0;
		Form.PercentRateOfManualDiscount = 0;
		Form.DiscountPercentage       = 0;
		
	EndIf;
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
	Form.AmountPrepaymentBeforeGoodsIssue    = 0;
	Form.AmountOfPrepaymentBeforeShipment   = 0;
	Form.CreditAmountAfterShipment   = 0;
	Form.PercentageOfAdvancePaymentBeforeCollateral  = 0;
	Form.PrepaymentPercentageBeforeShipment = 0;
	Form.CreditPercentageAfterShipment = 0;
	
	MatchingPaymentOptions = New Map;
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision"),
										New Structure("Sum, Interests", "AmountPrepaymentBeforeGoodsIssue", "PercentageOfAdvancePaymentBeforeCollateral"));
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"),
										New Structure("Sum, Interests", "AmountOfPrepaymentBeforeShipment", "PrepaymentPercentageBeforeShipment"));
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment"),
										New Structure("Sum, Interests", "CreditAmountAfterShipment", "CreditPercentageAfterShipment"));
	
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		ItemsNames = MatchingPaymentOptions[CurRow.PaymentOption];
		
		If ItemsNames <> Undefined Then
			Form[ItemsNames.Sum] = Form[ItemsNames.Sum] + CurRow.PaymentAmount
											+ ?(Form.Object.PackageDepositIsRequired, CurRow.PackageDepositValue, 0);
		EndIf;
	EndDo;
	
	TotalByStage = Form.AmountPrepaymentBeforeGoodsIssue + Form.AmountOfPrepaymentBeforeShipment
						+ Form.CreditAmountAfterShipment;
	
	Form.PackageDepositValue        = ?(Form.Object.PackageDepositIsRequired,
								Form.Object.Goods.Total("AmountIncludingVAT")- Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"),
								0);

	If TotalByStage <> 0 Then
		Form.PercentageOfAdvancePaymentBeforeCollateral  = (Form.AmountPrepaymentBeforeGoodsIssue/TotalByStage) * 100;
		Form.PrepaymentPercentageBeforeShipment = (Form.AmountOfPrepaymentBeforeShipment/TotalByStage) * 100;
		Form.CreditPercentageAfterShipment = (Form.CreditAmountAfterShipment/TotalByStage) * 100;
	EndIf;
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer(ChallengeByCommand = True)
	
	SetAgreementSelectionParameters();
	
	EstablishRelationshipsBetweenContractSelectionParameters();
	If ChallengeByCommand Then
		FillInDefaultContract();
	EndIf;
	
	If ThisIsTransferOperation(Object.BusinessOperation) Then
		
		If UseDiscountAdjustmentsInSales
			Or UseDiscountsMarkupsInSales Then
			
			DiscountsMarkupsFillingServer.CancelDiscounts(Object, "Goods", True);
		EndIf;
		
		If Object.PackageDepositIsRequired Then
			Object.PackageDepositIsRequired = False;
		EndIf;
		
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	Object.ConsignmentSales25 =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			And (Not ToUseTermsOfSales Or SalesServer.ThisIsAgreementOnNewCommission(Object.Terms));
	
	UseContracts =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
		Or (Object.ConsignmentSales25 And Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	SalesServer.SetBlankContractMark(Items, "Contract", UseContracts);
	
	SetTitleOfPrintDetails();
	UpdateTextOfInformationLabelGeneratedDocuments();
	
	FillInServiceDetailsOfDocumentForm();
	
	CalculateTotals_(ThisObject);
	SetVisibilityOfElementsByOperationServer();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
		
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.SalesOrder.FillInNamesOfBusinessTransactionDetails(Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ThisIsOperationOfShippingGoods = ThisIsOperationOfShippingGoods(Object.BusinessOperation);
	
	ThisIsOperationOfShipmentByOrder = ThisIsOperationOfShippingGoods
		And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer;
	
	ThisIsShipmentOperationWithoutOrder = ThisIsOperationOfShippingGoods
		And Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee;
	
	If ThisIsOperationOfShipmentByOrder Then
		CommonClientServer.SupplementArray(ArrayOfOperationDetails, ArrayOfAllProps);
	EndIf;
	
	CashServer.SetVisibilityOfElementsByArray(Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ThisIsTransferOperation = ThisIsTransferOperation(Object.BusinessOperation);
	
	ItemArray = New Array;
	
	ItemArray.Add("GoodsCalculateDiscountsMarkups");
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscount");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	ItemArray.Add("GoodsAssignAutomaticDiscounts");
	ItemArray.Add("GroupProductsBonusPoints");
	ItemArray.Add("GoodsOpenInformationAboutDiscounts");
	ItemArray.Add("TheProductsContextMenuOpensInformationAboutDiscounts");
	
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	ItemArray.Add("PercentRateOfManualDiscount");
	ItemArray.Add("ManualDiscount");
	ItemArray.Add("AutoDiscountPercentage");
	ItemArray.Add("AutoDiscountAmount");
	ItemArray.Add("DiscountPercentage");
	ItemArray.Add("DiscountAmount");
	ItemArray.Add("AmountOfPrepaymentBeforeShipment");
	ItemArray.Add("PrepaymentPercentageBeforeShipment");
	ItemArray.Add("CreditAmountAfterShipment");
	ItemArray.Add("CreditPercentageAfterShipment");
	ItemArray.Add("OurDebtIsAmountOfDebt");
	ItemArray.Add("CustomerDebtAmountOfDebt");
	ItemArray.Add("AmountOfDebt");
	ItemArray.Add("DebtPercentage");
	ItemArray.Add("PayAmount");
	ItemArray.Add("PayPercentage");
	ItemArray.Add("AmountByShipment");
	ItemArray.Add("OrderShipmentPercentage");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("DecorationIndentDepositRequiredForPackaging");
	ItemArray.Add("BankDetailsStampOfTheAct");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		Not (ThisIsTransferOperation
			Or ThisIsShipmentOperationWithoutOrder));
	
	ItemArray = New Array;
	ItemArray.Add("AddReusablePackage");
	ItemArray.Add("GroupPaymentContainer");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		Not ThisIsOperationOfShippingGoods);
	
	If ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		
		ItemArray = New Array;
		ItemArray.Add("AdditionalAttributesShipmentOfGoodsToCustomer");
		ItemArray.Add("AdditionalAttributesShipmentOfGoodsToCustomer1");
		TMCommonUseClientServer.SetPropertyOfFormElements(Items,
			ItemArray,
			"Visible",
			ThisIsOperationOfShippingGoods);
		
		ItemArray = New Array;
		ItemArray.Add("AdditionalDetailsTransferOfGoodsToTheCustodian");
		ItemArray.Add("AdditionalDetailsTransferOfGoodsToTheCustodian1");
		TMCommonUseClientServer.SetPropertyOfFormElements(Items,
			ItemArray,
			"Visible",
			ThisIsOperationOfShippingGoods);
		
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("AmountPrepaymentBeforeGoodsIssue");
	ItemArray.Add("PercentageOfAdvancePaymentBeforeCollateral");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		Not (ThisIsTransferOperation
			Or UseSimplifiedPaymentScheme));
	
	SetVisibilityOfPaymentDetails_();
	EstablishVisibilityOfBusinessDirection();
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	
	SetVisibilityOfPartnerField();
	SetContractAvailability();
	SetVisibilityOfCommandToFillInContractPriceView();
	SetVisibilityOfItemsNumberOfPackagesToBeReturned();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfItemsNumberOfPackagesToBeReturned()
	
	If Object.CreateRequestForReturnOfGoodsFromCustomers Then
		
		ThisIsOperationOfShippingGoods = ThisIsOperationOfShippingGoods(Object.BusinessOperation);
		Items.GoodsNumberOfPackagesDueToReturn.Visible = Not ThisIsOperationOfShippingGoods;
		
		If ThisIsOperationOfShippingGoods And Object.Goods.Total("NumberOfPackagesDueToReturn") > 0 Then
			For Each CurRow In Object.Goods Do
				CurRow.NumberOfPackagesDueToReturn = 0;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateNumberOfPackagesVolumeOfPreviousOrder(CurrentRow, CachedValues)
	
	If CurrentRow["QuantityPreviousOrderVolume"] = 0 Then
		CurrentRow["NumberOfPackagesPreviousOrderVolume"] = 0;
	Else
		ZoomRatio = BatchProcessingOfTablePartClientServer.GetPackingRatio(CurrentRow.Package,
																						CachedValues,
																						CurrentRow.Products).ZoomRatio;
		If ZoomRatio <> 0 Then
			CurrentRow["NumberOfPackagesPreviousOrderVolume"] = CurrentRow["QuantityPreviousOrderVolume"]
																		/ ZoomRatio;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfPackagesToReturn(CurrentRowID, CachedValues)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	If CurrentRow["QuantityForReturn"] = 0 Then
		CurrentRow["NumberOfPackagesDueToReturn"] = 0;
	Else
		ZoomRatio = BatchProcessingOfTablePartClientServer.GetPackingRatio(CurrentRow.Package, CachedValues, CurrentRow.Products).ZoomRatio;
		If ZoomRatio <> 0 Then
			CurrentRow["NumberOfPackagesDueToReturn"] = CurrentRow["QuantityForReturn"] / ZoomRatio;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateVATRefundAmount(CurrentRow, PriceIncludesVAT)
	
	VATAmount     = 0;
	RefundAmount = 0;
	
	RefundAmount = CurrentRow.Price * CurrentRow.NumberOfPackagesDueToReturn;
	If Not PriceIncludesVAT Then
		VATAmount = PriceManagementSystemClientServer.CalculateVATAmount(RefundAmount, CurrentRow.VATRate, PriceIncludesVAT);
	EndIf;
	
	CurrentRow.AmountIncludingVATReturn = RefundAmount + VATAmount;
	
EndProcedure

&AtClient
Procedure ClearDetails_(CurrentRow)
	
	CleaningStructure = New Structure;
	CleaningStructure.Insert("QuantityForecast", 0);
	CleaningStructure.Insert("NumberOfPackagesyForecast", 0);
	CleaningStructure.Insert("PreviousOrderDate", Undefined);
	CleaningStructure.Insert("QuantityForecastBalance", 0);
	CleaningStructure.Insert("NumberOfDaysBeforeInventoryExpiration", 0);
	CleaningStructure.Insert("QuantityPreviousOrderVolume", 0);
	CleaningStructure.Insert("NumberOfPackagesPreviousOrderVolume", 0);
	CleaningStructure.Insert("AverageDailySale", 0);
	CleaningStructure.Insert("UnitOfMeasureForecast", Undefined);
	CleaningStructure.Insert("SelectionIconIndex", 0);
	
	FillPropertyValues(CurrentRow, CleaningStructure);
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		FillInStatusesForSpecifyingSeries();
		
		WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		UpdateColumnAvailableServer();
		
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Procedure TermsOnChangeServer()
	
	Object.ConsignmentSales25 = Common.ObjectAttributeValue(Object.Terms, "ConsignmentSales25");
	
	FillInTermsOfSalesUnderAgreement();
	UpdateDebtLimit();
	
	FillOperationSelectionList();
	
	DocumentCurrency = Object.Currency;
	
	BusinessOperationOnChangeServer(False);
	WarehouseOnChangeServer();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,
																		Object.Terms,
																		Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ChangedBankingDetails = ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then
		SetPropertiesOfElementsInOrderOfCalculations();
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
								New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInSalesOptionAttribute",
								New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	SetsServer.FillInServiceDetails(ThisObject);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	FillInServiceDetailsOfDocumentForm();
	
	SetContractAvailability();
	
	FillBaseForPrinting();
	
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	SetPropertiesOfElementsInOrderOfCalculations();
	
	OptionAndFlag = Undefined;
	If Object.SimplifiedFulfillment Then
		OptionAndFlag = New Structure("SupplyOption,WithAssignment", Object.SupplyOption, Undefined);
	EndIf;
	
	SecurityOptionAndFlagSeparately  = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.SalesOrderStatus,
		OptionAndFlag);
		
	FillInSeparately = Common.ObjectAttributeValue(Object.Terms, "EnableAssigmentSupplyForOrders");
	
	FillInGoodsByAgreementServerWithMeasurement();
	
	CalculateTotals_(ThisObject);
	UpdateTextOfInformationLabelGeneratedDocuments();
	UpdateDebtLimit();
	UpdatePartnerDossierInformation();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	If Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		FillInDeliveryDetails("Partner");
	EndIf;
	
	SetContractAvailability();
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		
		Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount,
		Object.CounterpartyBankAccount);
		
	ChangedBankingDetails = ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then
		SetPropertiesOfElementsInOrderOfCalculations();
	EndIf;
	
	SetVisibilityOfPaymentDetails_();
	EstablishVisibilityOfBusinessDirection();
	SetVisibilityOfCommandToFillInContractPriceView();
	
	FillBaseForPrinting();
	UpdateDebtLimit();
	UpdatePartnerDossierInformation();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	SetContractAvailability();
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount,
		Object.PaymentMethod);
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
				Object.Contract);
			LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
			ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
		EndIf;
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
																					Object.BankAccount,
																					Object.PaymentMethod,
																					Object.LineOfBusiness,
																					Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization,
																		Object.CashAccount,
																		Object.PaymentMethod,
																		Object.LineOfBusiness);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtServer
Procedure WhenChangingCurrencyServer(NewCurrency, RecalculateAmounts = True)
	
	FillInDefaultContract();
	
	If RecalculateAmounts Then
		OldCurrency                = DocumentCurrency;
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisObject, OldCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
		StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
		StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			Object.Goods,
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates,
			True,
			True);
		
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		CalculateTotals_(ThisObject);
		
		PriceManagementSystem.DistributeAmountByPaymentStages(
			Object,
			Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"),
			?(Object.PackageDepositIsRequired,
				Object.Goods.Total("AmountIncludingVAT") - Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"), 0));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	If Not ToUseTermsOfSales Then
		If TypesOfPrices.Count() > 0 Then
			DefaultPriceType = TypesOfPrices[0].Value;
		EndIf;
	EndIf;
	
	For Each CurrentRow In Object.Goods Do
		CalculateVATRefundAmount(CurrentRow, Object.PriceIncludesVAT);
	EndDo;
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTotals_(ThisObject);
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues = Undefined)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	ParametersFillInVATRate = ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	StructureOfFillingInVATRate.VATTaxation = ParametersFillInVATRate.VATTaxation;
	StructureOfActions.Insert("FillInVATRateByPriceType", StructureOfFillingInVATRate);
	
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Function StructureOfBaseForPrinting()
	
	BaseStructure = DataProcessors.SalesWizard.BaseStructure(Object, Object.ARAPObjectSettings);
	
	If ThisIsTransferOperation(Object.BusinessOperation) Then
        If ValueIsFilled(BaseStructure.Basis) Then
			TextOfTransfer = BaseStructure.Basis + ", " + ?(Object.BusinessOperation
				= Enums.BusinessTransactions.TransferToCommissionAgent, NStr("vi = 'chuyển đi ký gửi';
																			|ru = 'передача на комиссию';
																			|en = 'consignment sales'; fa = 'consignment sales';
																			|it = 'trasferimento in conto vendita';
																			|pl = 'przekazanie do komisu';
																			|tr = 'konsinye satış'"), NStr(
				"ru = 'передача на хранение';
				|vi = 'VMI fill-up';
				|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
				|it = 'VMI fill-up';
				|pl = 'VMI fill-up';
				|tr = 'depoya transfer'"));
		Else
			TextOfTransfer = ?(Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent,
				NStr("vi = 'chuyển đi ký gửi';
					|ru = 'передача на комиссию';
					|en = 'consignment sales'; fa = 'consignment sales';
					|it = 'trasferimento in conto vendita';
					|pl = 'przekazanie do komisu';
					|tr = 'konsinye satış'"), NStr("ru = 'передача на хранение';
														|vi = 'VMI fill-up';
														|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
														|it = 'VMI fill-up';
														|pl = 'VMI fill-up';
														|tr = 'depoya transfer'"));

		EndIf;

		BaseStructure.Basis = TextOfTransfer;
	EndIf;
	
	Return BaseStructure;
	
EndFunction

&AtServer
Procedure ProcessChangesToServerParameters(ParameterValues)
	
	FillPropertyValues(Object, ParameterValues);
	
	OptionAndFlag = Undefined;
	
	If Object.SimplifiedFulfillment Then
		OptionAndFlag = New Structure("SupplyOption,WithAssignment", Object.SupplyOption, Undefined);
	EndIf;
	
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.SalesOrderStatus,
		OptionAndFlag);
		
	SetContractAvailability();
	
	ManagingCreationOfWaybills();
	ManagingCreationOfPowerOfAttorney();
	
	If Not ValueIsFilled(Object.DocumentCreationOption) Then
		SetDefaultOptionForIssuingSalesDocuments();
	EndIf;
	
	DocumentCreationOptionOnChangeServer();
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnServer(StructureOfActions,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	FillInServiceDetailsOfDocumentForm();
	UpdateColumnAvailableServer();
	
	If ThisIsImplementation(Object.DocumentCreationOption) Then
		If UseStatusesOfGoodsServicesSales
			And Object.StatusOfCustomerInvoice = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
				
			Object.SetOfSeries.Clear();
			SetVisibilityOfSeriesElements();
			FillInStatusesForSpecifyingSeries();
			
		EndIf;
	EndIf;
	
	If Object.SimplifiedFulfillment
		Or Object.NotShipInInstallments Then
		
		Object.NotShipInInstallments = True;
		
		SetVisibilityOfShippingDateFormElements();
	EndIf;
	
	SetVisibilityOfItemsBySettings();
	
	Modified = True;
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure SetOnlyViewFormElements(Set = True)
	
	ItemArray = New Array;
	ItemArray.Add("Warehouse");
	ItemArray.Add("Terms");
	ItemArray.Add("Partner");
	
	ItemArray.Add("SettingsInHeader");
	ItemArray.Add("OpenSelection");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Contract");
	ItemArray.Add("SalesOpportunity");
	ItemArray.Add("DocumentCurrency_2");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("LoyaltyCard");
	ItemArray.Add("Manager");
	ItemArray.Add("ContactPerson");
	ItemArray.Add("Department");
	ItemArray.Add("BankAccount");
	ItemArray.Add("FinancialAccountingGroup");
	ItemArray.Add("NotShipInInstallments");
	ItemArray.Add("AdditionalInformation");
	ItemArray.Add("Comment");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Goods");
	ItemArray.Add("ToReturnReusablePackage");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("FillInAccordingToTheForecast");
	
	ItemArray.Add("DeliveryPage");
	ItemArray.Add("GroupShipmentDateDoNotShipInParts");
	
	ItemArray.Add("LineOfBusiness");
	ItemArray.Add("NumberAccordingToCustomerData");
	ItemArray.Add("DateAccordingToInformationFromCustomer");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly",
		Set);
	
	ItemArray = New Array;
	ItemArray.Add("CreatePartner");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("GoodsSplitRow");
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsImportDataFromPDT");
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInPricesOfSelectedRowsByPriceType");
	ItemArray.Add("GoodsAssignAutomaticDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscount");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GroupProductsBonusPoints");
	ItemArray.Add("GoodsSpecifySeries");
	ItemArray.Add("ProductsCancelSpecifyingSeries");
	ItemArray.Add("FillInShipmentDate");
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	ItemArray.Add("GoodsContextMenuSplitRow");
	ItemArray.Add("GoodsContextMenuSpecifySeries");
	ItemArray.Add("OpenUndoSeriesContextMenu");
	ItemArray.Add("Setting");
	ItemArray.Add("AddReusablePackage");
	ItemArray.Add("GoodsSetComposition");
	ItemArray.Add("GoodsShip");
	ItemArray.Add("GoodsToReserve_");
	ItemArray.Add("GoodsToSupply");
	ItemArray.Add("GoodsReserveAsReceived");
	ItemArray.Add("GoodsNotProvide");
	ItemArray.Add("GoodsEnableStandAloneSoftware");
	ItemArray.Add("GoodsDisableStandAloneSoftware");
	ItemArray.Add("GoodsContextMenuShip");
	ItemArray.Add("GoodsContextMenuToReserve_");
	ItemArray.Add("GoodsContextMenuToSupply");
	ItemArray.Add("GoodsContextMenuReserveAsReceived");
	ItemArray.Add("GoodsContextMenuNotProvide");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not Set);
	
	If Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = True Then
		Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Change", "Enabled", Set);
	
	ViewOnlyIsSet = Set;
	
EndProcedure

&AtClient
Procedure OpenPrintDetails()
	
	UsedDelivery = UseDeliveryManagement
							And (Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods.ToCustomer")
								Or Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToAddress"));
	
	DeliveryOrderData = GoodsDeliveryClientServer.OrderParameters();
	FillPropertyValues(DeliveryOrderData, Object);
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",     Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("DeliveryZone",                   Object.DeliveryZone);
	ParametersStructure.Insert("DeliveryTimeFrom",                 Object.DeliveryTimeFrom);
	ParametersStructure.Insert("DeliveryTimeTo",                Object.DeliveryTimeTo);
	ParametersStructure.Insert("AdditionalDeliveryInformation", Object.AdditionalDeliveryInformation);
	ParametersStructure.Insert("DeliveryOrderData",   DeliveryOrderData);
	ParametersStructure.Insert("Ref",                         LinkToDesignOption(Object.DocumentCreationOption));
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",               Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",               Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",              Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Contract",                        Object.Contract);
	ParametersStructure.Insert("Basis",                      Object.Basis);
	ParametersStructure.Insert("BaseDocumentNumber",                 Object.BaseDocumentNumber);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("IssuiedBy",                       Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",              Object.IssuiedByJobTitle);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                 DocumentsAreCreated And Not Modified);
	ParametersStructure.Insert("ObjectType",                     "SalesWizard");
	ParametersStructure.Insert("UsedDelivery",           UsedDelivery);
	ParametersStructure.Insert("CompanyBankAccount",      Object.BankAccount);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",      PrintBasisTable);
		
	If Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrier")
		Or Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToAddress") Then
		
		ParametersStructure.Insert("CarrierPartner", Object.CarrierPartner);
		
	EndIf;
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisObject, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function PlaceAdditionalDetailsInTemporaryStorage(AdditionalAttributes)
	
	AddlAttributesTable      = Object[AdditionalAttributes].Unload();
	AddressInTempStorage = PutToTempStorage(AddlAttributesTable, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, NumberOfSelectedPositions)
	
	Label = NStr("vi = 'Vị trí phù hợp (%NumberOfSelectedPositions%)';
				|ru = 'Подобрано позиций (%NumberOfSelectedPositions%)';
				|en = 'Items picked (%NumberOfSelectedPositions%)'; fa = 'Items picked (%NumberOfSelectedPositions%)';
				|it = 'Voci selezionate (%NumberOfSelectedPositions%)';
				|pl = 'Dobrano pozycji (%NumberOfSelectedPositions%)';
				|tr = 'Seçilen kalemler (%NumberOfSelectedPositions%)'");
	
	LabelTotalItemsSelected = StrReplace(Label, "%NumberOfSelectedPositions%", NumberOfSelectedPositions);
	
EndProcedure

&AtServer
Procedure NotShipInInstallmentsOnChangeServer()
	
	If Object.NotShipInInstallments Then
		Object.DateOfShipment = ProvisionInDocumentsServer.MaximumValueInCollection(Object.Goods, "DateOfShipment", '00010101');
		ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", Object.DateOfShipment);
	EndIf;
	
	SetVisibilityOfShippingDateFormElements();
	
EndProcedure

&AtServer
Procedure ManagingTaggingOfConsignmentNoteCommand()
	
	ThisIsTransferOfGoods = ThisIsTransferOfGoods(Object.DocumentCreationOption);
		
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentTable.Ref AS Document
	|FROM
	|	#Document AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN(&DocumentsArray)
	|	AND DocumentTable.Posted
	|";
	
	DocumentName = "Document.CustomerInvoice";
	If ThisIsTransferOfGoods Then
		DocumentName = "Document.TransferOfGoodsToBailee";
		
		ThisIsOperationOfShippingGoods = ThisIsOperationOfShippingGoods(Object.BusinessOperation);
		If ThisIsOperationOfShippingGoods Then
			DocumentName = "Document.GoodsShipmentToCustomer";
		EndIf;
	EndIf;
	Query.Text = StrReplace(Query.Text, "#Document", DocumentName);
	Query.SetParameter("DocumentsArray", Object.Documents.Unload().UnloadColumn("Document"));
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		CreateConsignmentNote = False;
		Items.CompletedDocuments_4ConsignmentNote.Check     = False;
		Items.CompletedDocuments_4ConsignmentNote.Enabled = False;
	Else
		Items.CompletedDocuments_4ConsignmentNote.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ManagingCreationOfWaybills(ThisIsInitialization = True)
	
	UseWaybill = GetFunctionalOption("UseWaybill");
	
	Items.CompletedDocuments_4ConsignmentNote.Visible = UseWaybill;
	
EndProcedure

&AtServer
Procedure ManagementOfWaybills(DocumentsForProcessing_ = Undefined)
	
	
EndProcedure

&AtServer
Procedure ManagingCreationOfPowerOfAttorney()
	
	UseLettersOfAuthority = GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt")
		And Not ThisIsTransferOperation(Object.BusinessOperation);
	Items.CompletedDocuments_4IssuedLetterOfAuthority.Visible = UseLettersOfAuthority;
	PowersOfAttorneyCreated = False;
	OrdersCreated = False;
	ImplementationsCreated = False;
	For Each Document In Object.Documents Do 
		If TypeOf(Document.Document) = Type("DocumentRef.IssuedLetterOfAuthority") Then
			PowersOfAttorneyCreated = True;
		EndIf;
		If TypeOf(Document.Document) = Type("DocumentRef.CustomerInvoice") Then
			ImplementationsCreated = True;
		EndIf;
		If TypeOf(Document.Document) = Type("DocumentRef.SalesOrder") Then
			OrdersCreated = True;
		EndIf;
	EndDo;
	CreateLetterOfAuthorityForReceivingCash = UseLettersOfAuthority And Object.CreateAuthorizationLetterForReceivingCash;
	If Not (Object.PaymentMethod = Enums.PaymentForms.BankAccountPayment
			Or Object.PaymentMethod = Enums.PaymentForms.PaymentCard
			Or Object.PaymentMethod = Enums.PaymentForms.SettlementOfARAP
			Or Object.PaymentMethod = Enums.PaymentForms.InstantPayments)
		And (ImplementationsCreated Or OrdersCreated) Then 
		Items.CompletedDocuments_4IssuedLetterOfAuthority.Check = CreateLetterOfAuthorityForReceivingCash And PowersOfAttorneyCreated;
		Items.CompletedDocuments_4IssuedLetterOfAuthority.Enabled = True;
		If CreateLetterOfAuthorityForReceivingCash And Not PowersOfAttorneyCreated Then
			PowerOfAttorneyManagement();
			Items.CompletedDocuments_4IssuedLetterOfAuthority.Check = True;
		EndIf;
	Else
		Items.CompletedDocuments_4IssuedLetterOfAuthority.Check = False;
		Items.CompletedDocuments_4IssuedLetterOfAuthority.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure PowerOfAttorneyManagement()
	
	If Not GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt") Then
		Return;
	EndIf;
	If ThisIsTransferOperation(Object.BusinessOperation) Then
		Return;
	EndIf;
	
	// Creating a power of attorney for a customer's Order
	
	OrderMarkedForDeletion = False;
	OrderPosted = False;
	PowerOfAttorneyLine = Undefined;
	OrderBase = Undefined;
	AcceptableStatuses = Documents.SalesOrder.ValidInputStatusesBasedOn(True);
	DeletePowerOfAttorney = False;
	For Each LineDocument In Object.Documents Do 
		If TypeOf(LineDocument.Document) = Type("DocumentRef.SalesOrder") Then
			OrderDetails = Common.ObjectAttributesValues(LineDocument.Document, "DeletionMark, Posted, Status");
			OrderBase = LineDocument.Document;
			OrderMarkedForDeletion = OrderDetails.DeletionMark;
			OrderPosted = OrderDetails.Posted;
			If AcceptableStatuses.Find(OrderDetails.Status) = Undefined Then
				OrderBase = Undefined;
			EndIf;
		ElsIf TypeOf(LineDocument.Document) = Type("DocumentRef.IssuedLetterOfAuthority") Then
			PowerOfAttorneyLine = LineDocument;
		EndIf;
	EndDo;
	If PowerOfAttorneyLine <> Undefined Then
		DeletePowerOfAttorney = Not CreateLetterOfAuthorityForReceivingCash Or Not OrderPosted Or OrderMarkedForDeletion;
		If Not DeletePowerOfAttorney Then
			Return;
		EndIf;
	EndIf;
	
	If CreateLetterOfAuthorityForReceivingCash And PowerOfAttorneyLine = Undefined
		And OrderBase <> Undefined And OrderPosted And Not OrderMarkedForDeletion
		And Not DeletePowerOfAttorney Then
		
		WritePowerOfAttorneyToReceiveCash(New Array, OrderBase, False);
	
	// Creation of powers of attorney for Sales of goods and services
	Else
		MassOfPowersOfAttorneyFound = New Array;
		For Each LineDocument In Object.Documents Do
			
			If Not Common.RefExists(LineDocument.Document) Then
				Continue;
			EndIf; 
			If TypeOf(LineDocument.Document) = Type("DocumentRef.IssuedLetterOfAuthority") Then
				AttributesDetails1 = New Structure("DocumentBasisDeletionMark, DocumentFoundationIsCarriedOut",
						"DocumentBasis.DeletionMark", 
						"DocumentBasis.Posted");
				ResultingStructure = Common.ObjectAttributesValues(LineDocument.Document, AttributesDetails1, True);
				ImplementationMarkedForDeletion = ResultingStructure.DocumentBasisDeletionMark;
				ImplementationCarriedOut          = ResultingStructure.DocumentFoundationIsCarriedOut;
				If Not CreateLetterOfAuthorityForReceivingCash Or Not ImplementationCarriedOut Or ImplementationMarkedForDeletion Then
					MassOfPowersOfAttorneyFound.Add(LineDocument);
				EndIf;
			EndIf;
		EndDo;
		TMCommonUse.DeleteTableRows(Object.Documents, MassOfPowersOfAttorneyFound);
		
		MassOfPowersOfAttorneyFound = New Array;
		For Each LineDocument In Object.Documents Do
			
			If Not Common.RefExists(LineDocument.Document) Then
				Continue;
			EndIf; 
			ImplementationMarkedForDeletion = False;
			ImplementationCarriedOut = False;
			ImplementationBasis = Undefined;
			If TypeOf(LineDocument.Document) = Type("DocumentRef.CustomerInvoice") Then
				ResultingStructure = Common.ObjectAttributesValues(LineDocument.Document, "DeletionMark, Posted");
				ImplementationBasis = LineDocument.Document;
				ImplementationMarkedForDeletion = ResultingStructure.DeletionMark;
				ImplementationCarriedOut          = ResultingStructure.Posted;
			EndIf;
			If ImplementationBasis <> Undefined
				And CreateLetterOfAuthorityForReceivingCash 
				And ImplementationCarriedOut 
				And Not ImplementationMarkedForDeletion Then
				WritePowerOfAttorneyToReceiveCash(MassOfPowersOfAttorneyFound, ImplementationBasis, False);
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure ManagingTeamTaggingPowerOfAttorney()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SUM(ValidDocuments.NumberOfValidRTUDocuments) AS NumberOfValidRTUDocuments,
	|	SUM(ValidDocuments.NumberOfValidDocumentsOrder) AS NumberOfValidDocumentsOrder
	|FROM
	|	(SELECT
	|		ISNULL(SUM(CASE
	|					WHEN NOT CustomerInvoice.DeletionMark
	|							AND CustomerInvoice.Posted
	|						THEN 1
	|					ELSE 0
	|				END), 0) AS NumberOfValidRTUDocuments,
	|		0 AS NumberOfValidDocumentsOrder
	|	FROM
	|		Document.CustomerInvoice AS CustomerInvoice
	|	WHERE
	|		CustomerInvoice.Ref IN(&DocumentsArray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		ISNULL(SUM(CASE
	|					WHEN NOT SalesOrder.DeletionMark
	|							AND SalesOrder.Posted
	|						THEN 1
	|					ELSE 0
	|				END), 0)
	|	FROM
	|		Document.SalesOrder AS SalesOrder
	|	WHERE
	|		SalesOrder.Ref IN(&DocumentsArray)) AS ValidDocuments";
	
	Query.SetParameter("DocumentsArray", Object.Documents.Unload().UnloadColumn("Document"));
	Result = Query.Execute().Select();
	While Result.Next() Do
		If Result.NumberOfValidRTUDocuments = 0 And Result.NumberOfValidDocumentsOrder = 0 Then
			Items.CompletedDocuments_4IssuedLetterOfAuthority.Check = False;
			CreateLetterOfAuthorityForReceivingCash = False;
			Items.CompletedDocuments_4IssuedLetterOfAuthority.Enabled = False;
		Else
			Items.CompletedDocuments_4IssuedLetterOfAuthority.Enabled = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetTitleOfPrintDetails()
	
	If GetFunctionalOption("UseDeedsOfTransfer") Then
		ItemTitle = ?(Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
								NStr("vi = 'Mục tin in';
									|ru = 'Реквизиты печати';
									|en = 'Print details'; fa = 'جزئیات چاپ';
									|it = 'Requisiti di stampa';
									|pl = 'Atrybuty drukowania';
									|tr = 'Yazdırma öznitelikleri'"),
								NStr("vi = 'Chi tiết in / chứng nhận chuyển nhượng quyền';
									|ru = 'Реквизиты печати / Акта на передачу прав';
									|en = 'Print details / Deed of transfer'; fa = 'Print details / Deed of transfer';
									|it = 'Requisiti di stampa / Atto sul trasferimento di diritti';
									|pl = 'Atrybuty wydruku / Protokołu przeniesienia praw';
									|tr = 'Yazdırma öznitelikleri / Transfer hakkı raporu'"));
		
		Items.PrintDetails.Title = ItemTitle;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateReturnRequest(Goods,
						ArrayOfSalesDocuments,
						ArrayOfFoundDocuments,
						WithoutConducting,
						Cancel)
						
	WarehouseArray = New Array();
	ReturnFromGroupOfWarehouses = False;
	
	If WarehouseGroup_ Then
		SelectGroup = Common.ObjectAttributeValue(Object.Warehouse, "SelectGroup");
		If SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			WarehouseArray.Add(Object.Warehouse);
			ReturnFromGroupOfWarehouses = True;
		Else
			TimeTableOfWarehouses = Goods.Copy(, "Warehouse");
			TimeTableOfWarehouses.GroupBy("Warehouse");
			WarehouseArray = TimeTableOfWarehouses.UnloadColumn("Warehouse");
		EndIf;
	Else
		WarehouseArray.Add(Object.Warehouse);
	EndIf;
	
	For Each CurWarehouse In WarehouseArray Do
		
		If ValueIsFilled(CurWarehouse) Or WarehouseArray.Count() = 1 Then
			
			If ReturnFromGroupOfWarehouses Then
				
				GoodsInStock_ = Goods;
				
			Else
				
				GoodsInStock_ = Goods.Copy(New Structure("Warehouse", CurWarehouse)); // ValueTable
				
			EndIf;
			
				//@skip-check query-in-loop
				SellingObject = RecordRefundRequest(ArrayOfFoundDocuments,
					GoodsInStock_,
					CurWarehouse,
					Cancel,
					WithoutConducting); // DocumentObject.RequestForReturnOfGoodsFromCustomer
				
				If Cancel Then
					Break;
				EndIf;  
				
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure CreateImplementationByOrder(Goods,
	ArrayOfImplementations,
	ArrayOfFoundDocuments,
	BaseObject,
	WithoutChangingOrderStatus,
	WithoutConducting,
	Cancel)

	WarehouseArray = New Array();
	ArrayOfImplementations = New Array();
	ImplementationFromWarehouseGroup = False;
	
	If WarehouseGroup_ Then
		SelectGroup = Common.ObjectAttributeValue(Object.Warehouse, "SelectGroup");
		If SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			WarehouseArray.Add(Object.Warehouse);
			ImplementationFromWarehouseGroup = True;
		Else
			TimeTableOfWarehouses = Goods.Copy(, "Warehouse");
			TimeTableOfWarehouses.GroupBy("Warehouse");
			WarehouseArray = TimeTableOfWarehouses.UnloadColumn("Warehouse");
		EndIf;
	Else
		WarehouseArray.Add(Object.Warehouse);
	EndIf;
	
	IncludeServices = True;
	
	For Each CurWarehouse In WarehouseArray Do
		
		If ValueIsFilled(CurWarehouse) Or WarehouseArray.Count() = 1 Then
			
			If ImplementationFromWarehouseGroup Then
				
				GoodsInStock_ = Goods;
				
			Else
				
				GoodsInStock_ = Goods.Copy(New Structure("Warehouse", CurWarehouse)); // ValueTable
				
				If IncludeServices And ValueIsFilled(CurWarehouse) Then
					Services = Goods.Copy(New Structure("Warehouse", Catalogs.Warehouses.EmptyRef()));
					For Each CurRow In Services Do
						NewRow = GoodsInStock_.Add();
						FillPropertyValues(NewRow, CurRow);
					EndDo;
					IncludeServices = False;
				EndIf;
				
			EndIf;
			
			//@skip-check query-in-loop
			SellingObject = RecordImplementationByOrder(ArrayOfFoundDocuments,
				BaseObject,
				GoodsInStock_,
				CurWarehouse,
				Cancel,
				WithoutConducting,
				WithoutChangingOrderStatus); // DocumentObject.CustomerInvoice
			
			If Cancel Then
				Continue;
			EndIf;
			ArrayOfImplementations.Add(SellingObject);
			
			// Creating a bill of lading for implementation
			If Not WithoutConducting And CreateConsignmentNote And Not Cancel Then
				GroundsOfConsignmentNote.Add(SellingObject.Ref);
			EndIf;
			
			// Creating an invoice for the implementation / act
			If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
				And Object.Goods.Total("SumWithoutReusablePackages") > 0 And Not Cancel Then
				CreateAnInvoice_3(ArrayOfFoundDocuments, SellingObject, Cancel);
			EndIf;
			
			// Creating an invoice for payment for the implementation / act
			If Object.CreateCommercialInvoice And Not Cancel
				And Object.BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent
				And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
				And Object.Goods.Total("SumWithoutReusablePackages") > 0 Then
				
				RecordInvoiceForPayment(ArrayOfFoundDocuments, SellingObject, SellingObject.PaymentScheduleSteps.Unload(), Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;

	// Creating a bill of lading for implementation
	If Not WithoutConducting And CreateConsignmentNote And Not Cancel Then
		
		For Each ArrayElement In ArrayOfImplementations Do // DocumentObject.CustomerInvoice
			GroundsOfConsignmentNote.Add(ArrayElement.Ref);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateAnImplementation(Goods, ArrayOfImplementations, ArrayOfFoundDocuments, WithoutConducting, Cancel)
	
	SellingObject  = WriteImplementation(ArrayOfFoundDocuments, Goods, Cancel, WithoutConducting);
	If Cancel Then
		Return;
	EndIf; 
	ArrayOfImplementations.Add(SellingObject);
	
	CreateICOInvoice = Object.BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent;
	
	// Creating a bill of lading for implementation
	If Not Cancel
		And Not WithoutConducting
		And CreateConsignmentNote Then
			
		GroundsOfConsignmentNote.Add(SellingObject.Ref);
		
	EndIf;
	
	// Creating a sales invoice
	If Not Cancel
		And CreateICOInvoice
		And Object.CreateCommercialInvoice
		And Goods.Total("SumWithoutReusablePackages") > 0 Then
		
		RecordInvoiceForPayment(
			ArrayOfFoundDocuments, SellingObject, SellingObject.PaymentScheduleSteps.Unload(), Cancel);
		
	EndIf;
	
	// Creation of an incoming cash order for the implementation / act
	If Not Cancel
		And CreateICOInvoice
		And Object.CreateCashAccountReceiptNote
		And Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
		
		OCR = RecordIncomingCashOrder(ArrayOfFoundDocuments, SellingObject, Cancel);
		
		If WithoutConducting
			And OCR <> Undefined Then
			
			SellingObject.Write(DocumentWriteMode.Posting);
			
			// Creating a bill of lading for implementation
			If CreateConsignmentNote And Not Cancel Then
				GroundsOfConsignmentNote.Add(SellingObject.Ref);
			EndIf;
		
		EndIf;
		
	EndIf;
	
	// Creating an invoice for the implementation / act
	If Not Cancel
		And Goods.Total("SumWithoutReusablePackages") > 0
		And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		
		CreateAnInvoice_3(ArrayOfFoundDocuments, SellingObject, Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateTransferOfGoodsByOrder(Goods, ArrayOfGears, ArrayOfFoundDocuments, BaseObject, Cancel)

	WarehouseArray = New Array;
	ArrayOfGears = New Array;
	TransferFromWarehouseGroup = False;
	
	If WarehouseGroup_ Then
		SelectGroup = Common.ObjectAttributeValue(Object.Warehouse, "SelectGroup");
		
		If SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			TransferFromWarehouseGroup = True;
			
			WarehouseArray.Add(Object.Warehouse);
		Else
			Warehouses = Goods.Copy(, "Warehouse");
			Warehouses.GroupBy("Warehouse");
			
			WarehouseArray = Warehouses.UnloadColumn("Warehouse");
		EndIf;
	Else
		WarehouseArray.Add(Object.Warehouse);
	EndIf;
	
	For Each CurWarehouse In WarehouseArray Do
		
		If ValueIsFilled(CurWarehouse)
			Or WarehouseArray.Count() = 1 Then
			
			If TransferFromWarehouseGroup Then
				GoodsInStock_ = Goods;
			Else
				FilterByWarehouse  = New Structure("Warehouse", CurWarehouse);
				GoodsInStock_ = Goods.Copy(FilterByWarehouse);
			EndIf;
			
			//@skip-check query-in-loop
			TransferObject = RecordTransferOfGoodsByOrder(ArrayOfFoundDocuments,
				BaseObject,
				GoodsInStock_,
				CurWarehouse,
				Cancel);
			
			If Cancel Then
				Break;
			EndIf;
			
			ArrayOfGears.Add(TransferObject);
			
			// Creation of a bill of lading for the transfer of goods to the custodian.
			If Not Cancel
				And CreateConsignmentNote Then
				
				For Each ArrayElement In ArrayOfGears Do // DocumentObject.TransferOfGoodsToBailee
					GroundsOfConsignmentNote.Add(ArrayElement.Ref);
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateShipmentOfItemsToCustomerByOrder(Goods, ArrayOfShipments, ArrayOfFoundDocuments, BaseObject, Cancel)

	WarehouseArray = New Array;
	ArrayOfShipments = New Array;
	ShipmentFromGroupOfWarehouses = False;
	
	If WarehouseGroup_ Then
		SelectGroup = Common.ObjectAttributeValue(Object.Warehouse, "SelectGroup");
		
		If SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			ShipmentFromGroupOfWarehouses = True;
			
			WarehouseArray.Add(Object.Warehouse);
		Else
			Warehouses = Goods.Copy(, "Warehouse");
			Warehouses.GroupBy("Warehouse");
			
			WarehouseArray = Warehouses.UnloadColumn("Warehouse");
		EndIf;
	Else
		WarehouseArray.Add(Object.Warehouse);
	EndIf;
	
	For Each CurWarehouse In WarehouseArray Do
		
		If ValueIsFilled(CurWarehouse)
			Or WarehouseArray.Count() = 1 Then
			
			If ShipmentFromGroupOfWarehouses Then
				GoodsInStock_ = Goods;
			Else
				FilterByWarehouse  = New Structure("Warehouse", CurWarehouse);
				GoodsInStock_ = Goods.Copy(FilterByWarehouse);
			EndIf;
			
			ShipmentOfItemsObject = RecordShipmentOfItemsToCustomerByOrder(ArrayOfFoundDocuments,
				BaseObject,
				GoodsInStock_,
				CurWarehouse,
				Cancel);
			
			If Cancel Then
				Break;
			EndIf;
			
			ArrayOfShipments.Add(ShipmentOfItemsObject);
			
			// Creating an invoice for the Shipment of goods
			If Not Cancel And Object.PrintTaxInvoice Then
				CreateAnInvoice_3(ArrayOfFoundDocuments, ShipmentOfItemsObject, Cancel);
			EndIf;
			
			// Creation of a bill of lading for the shipment of goods
			If CreateConsignmentNote And Not Cancel Then
				GroundsOfConsignmentNote.Add(ShipmentOfItemsObject.Ref);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateSpendingOrders(Goods, ArrayOfFoundDocuments, ArrayOfImplementations, BaseObject, WithoutConducting, Cancel)
	
	ListOfWarehouses = Goods.Copy(,"Warehouse");
	ListOfWarehouses.GroupBy("Warehouse");
	WarehouseArray = ListOfWarehouses.UnloadColumn("Warehouse");
	
	ShipmentReferences=New Array;
	
	If TypeOf(BaseObject)=Type("Array") Then
		
		For Each Basis In BaseObject Do //DocumentObject
			ShipmentReferences=Basis.Ref;
		EndDo;
		
	Else
		ShipmentReferences.Add(BaseObject.Ref);
	EndIf;
		
	// We fill in the table of created documents for re-registration
	CreatedSpendingOrders = New ValueTable;
	CreatedSpendingOrders.Columns.Add("DocumentObject",New TypeDescription("DocumentObject.GoodsIssueNote"));
	CreatedSpendingOrders.Columns.Add("WasUsed",New TypeDescription("Boolean"));
	
	TableRow = Sales.FindCreatedDocumentByType(ThisObject, Type("DocumentRef.GoodsIssueNote"), ArrayOfFoundDocuments);
	
	While TableRow <> Undefined And Sales.LockDocument_(TableRow.Document) Do
		
		DocumentObject = TableRow.Document.GetObject();
		If Not DocumentObject = Undefined And DocumentObject.DeletionMark Then
			DocumentObject.SetDeletionMark(False);
		EndIf;
		
		ArrayOfFoundDocuments.Add(TableRow.Document);
		
		NwRw = CreatedSpendingOrders.Add();
		NwRw.DocumentObject = DocumentObject;
		NwRw.WasUsed = False;
		
		TableRow = Sales.FindCreatedDocumentByType(ThisObject, Type("DocumentRef.GoodsIssueNote"), ArrayOfFoundDocuments);
	EndDo;
	
	For Each CurWarehouse In WarehouseArray Do
		
		If CurWarehouse = Catalogs.Warehouses.EmptyRef() Then
			Continue;
		EndIf;
	
		DocumentObject = Undefined;
		
		ParametersForReissuingSpendingOrders = WarehousesServer.ParametersForReissuingSpendingOrders();
		ParametersForReissuingSpendingOrders.Warehouse = CurWarehouse;
		ParametersForReissuingSpendingOrders.Recipient = Object.Partner;
		
		Result = WarehousesServer.ReissueSpendingOrders(ParametersForReissuingSpendingOrders);
		
		If Result.HasError Then
			
			Cancel = True;
			Return;
			
		EndIf;
		
		TableOfCreatedDocuments = Result.ExecutedOrders;
		
		For Each CurRow In TableOfCreatedDocuments Do 
			
			DocumentPosted = Common.ObjectAttributeValue(CurRow.ExpenseOrder, "Posted");
			
			DocumentStrings= Object.Documents.FindRows(New Structure("Document",CurRow.ExpenseOrder));
			
			If DocumentPosted Then
				State = 0;
			Else
				State = 2;
			EndIf;
		
			If DocumentStrings.Count() = 0 Then
				
				Sales.AddRowToGeneratedDocumentsTable(
					ThisObject,
					CurRow.ExpenseOrder,
					7, 
					State,
					KitPrintingIsAvailable(CurRow.ExpenseOrder));
					
				ArrayOfFoundDocuments.Add(CurRow.ExpenseOrder);
				
			Else 
				
				Sales.UpdateRowInGeneratedDocumentsTable(
					DocumentStrings[0],
					DocumentObject.Ref,
					7, 
					State);
				
			EndIf;
				
		EndDo;
		
	EndDo;	
	
	// we remove unused documents
	For Each Page1 In CreatedSpendingOrders Do
		If Not Page1.WasUsed And Not ArrayOfFoundDocuments.Find(Page1.DocumentObject.Ref)=Undefined Then
			ArrayOfFoundDocuments.Delete(ArrayOfFoundDocuments.Find(Page1.DocumentObject.Ref));
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVisibilityGroupPaymentShipmentPrintOptions()
	
	ThisIsCommercialOffer = Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	Items.GroupPaymentShipmentPrintOptions.Visible = Not ThisIsCommercialOffer;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShippingDateFormElements()
	
	ThisIsCommercialOffer = Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	ThisIsCustomerOrderOperation = ThisIsCustomerOrderOperation(Object.DocumentCreationOption);
	
	Items.GroupShipment.Visible		 = ThisIsCustomerOrderOperation;
	
	Items.GoodsDateOfShipment.Visible    = Not Object.NotShipInInstallments
												And  ThisIsCustomerOrderOperation;
	Items.DateOfShipment.Visible          = Object.NotShipInInstallments
												And Not ThisIsCommercialOffer;
	Items.FillInShipmentDate.Enabled = Not Object.NotShipInInstallments
												 And ThisIsCustomerOrderOperation;
	Items.FillInShipmentDate.Visible = Not Object.NotShipInInstallments
												 And ThisIsCustomerOrderOperation;
	Items.NotShipInInstallments.Visible    = Not ThisIsCommercialOffer
												And Not Object.SimplifiedFulfillment
												And Not Object.DisplayRecommendationsToPurchase;
	Items.DecorationShipmentDate.Visible = ((Not UseShipmentByRowsInSalesOrder
														And Object.NotShipInInstallments)
													Or Object.SimplifiedFulfillment
													Or Object.DisplayRecommendationsToPurchase)
												And Not ThisIsCommercialOffer;
	
EndProcedure

&AtServer
Procedure CheckAvailabilityOfAdditionalBankingDetails()
	
	PropertiesSet = PropertyManagerInternal.GetObjectPropertySets(Documents.CustomerInvoiceServices.EmptyRef());
	
	If PropertiesSet.Count() > 0 Then
		AdditionalAttributes = Common.ObjectAttributeValue(PropertiesSet[0].Set, "AdditionalAttributes"); // QueryResult
		If AdditionalAttributes <> Undefined
				And Not AdditionalAttributes.IsEmpty() > 0 Then
			ThereAreAdditionalCertificateAttributes = True;
		EndIf;
	EndIf;
	
	PropertiesSet = PropertyManagerInternal.GetObjectPropertySets(Documents.SalesOrder.EmptyRef());
	
	If PropertiesSet.Count() > 0 Then
		AdditionalAttributes = Common.ObjectAttributeValue(PropertiesSet[0].Set, "AdditionalAttributes"); // QueryResult
		If AdditionalAttributes <> Undefined
				And Not AdditionalAttributes.IsEmpty() > 0 Then
			ThereAreAdditionalOrderAttributes = True;
		EndIf;
	EndIf;
	
	PropertiesSet = PropertyManagerInternal.GetObjectPropertySets(Documents.CustomerInvoice.EmptyRef());
	
	If PropertiesSet.Count() > 0 Then
		AdditionalAttributes = Common.ObjectAttributeValue(PropertiesSet[0].Set, "AdditionalAttributes"); // QueryResult
		If AdditionalAttributes <> Undefined
				And Not AdditionalAttributes.IsEmpty() > 0 Then
			ThereAreAdditionalSaleAttributes = True;
		EndIf;
	EndIf;
	
	PropertiesSet = PropertyManagerInternal.GetObjectPropertySets(Documents.TransferOfGoodsToBailee.EmptyRef());
	
	If PropertiesSet.Count() > 0 Then
		AdditionalAttributes = Common.ObjectAttributeValue(PropertiesSet[0].Set, "AdditionalAttributes"); // QueryResult
		If AdditionalAttributes <> Undefined
				And Not AdditionalAttributes.IsEmpty() > 0 Then
			ThereAreAdditionalDetailsOfTheTransferOfGoods = True;
		EndIf;
	EndIf;
	
	Sales.CheckAvailabilityOfAdditionalBankingDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure HideUnavailableAdditionalBankingDetails()
	
	CheckAvailabilityOfAdditionalBankingDetails();
	
EndProcedure

&AtServer
Procedure CheckAvailabilityOfICOPrinting()
	
	ThereIsARightToPrintCashReceiptStatement = AccessRight("Insert",Metadata.Documents.CashAccountReceiptNote);
	
	If Not ThereIsARightToPrintCashReceiptStatement Then
		If Object.CreateCashAccountReceiptNote Then
			Object.CreateCashAccountReceiptNote = False;
		EndIf;
		If Object.PrintCashAccountReceiptNote Then
			Object.PrintCashAccountReceiptNote = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAvailabilityOfPowerOfAttorneySeal()
	
	YouHaveTheRightToPrintAPowerOfAttorney = AccessRight("Insert",Metadata.Documents.IssuedLetterOfAuthority);
	
	If Not YouHaveTheRightToPrintAPowerOfAttorney Then
		If CreateLetterOfAuthorityForReceivingCash Then
			CreateLetterOfAuthorityForReceivingCash = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDebtLimit()
	
	SalesServer.UpdateDebtLimit(Object.Contract, Object.Date, TextAllowedCreditBalance, False,
		Undefined, False);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfElementsInOrderOfCalculations()
		
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtClient
Procedure UpdateDocumentState(DocumentSource)
	
	FoundDocuments = Object.Documents.FindRows(New Structure("Document", DocumentSource));
	
	If FoundDocuments.Count() = 1 Then
		DocumentPosted = GeneralPurposeTMServerCall.ObjectAttributeValue(DocumentSource, "Posted");
		
		If DocumentPosted Then
			FoundDocuments[0].State = 0;
		Else
			FoundDocuments[0].State = 2;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ToReturnReusablePackageOnChangeServer()
	
	If Not Object.ToReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	
	CalculateTotals_(ThisObject);
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"WithoutReusablePackages",
		"Sum,VATAmount,AmountIncludingVAT,DiscountMarkupAmount,ManualDiscount,AmountOfBonusPointsToDeductionInCurrency");
	
EndFunction

&AtClientAtServerNoContext
Function DependentPropsByString()
	
	Return "SumWithoutReusablePackages,VATAmountWithoutReusablePackages,AmountIncludingVATWithoutReusablePackages,
			|DiscountMarkupAmountWithoutReusablePackages,ManualDiscountWithoutReusablePackages,
			|AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages";
	
EndFunction

&AtServer
Procedure SetVisibilityOfShipmentBanToPartner()
	
	UpdatePartnerDossierInformation();
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = StructureOfBaseForPrinting();
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	
	PrintParameters = New Structure("BusinessOperation, Contract", Object.BusinessOperation, Object.Contract);
	
	PrintBasisTable.Load(DataProcessors.SalesWizard.PrintBasisTable(PrintParameters));
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		FillInDefaultContract();
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "LineOfBusiness");
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure NewSaleServer()
	
	InitializeSalesAssistant();
	WhenChangingBucketOnServer();
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure MarkForDeletionAfterGetSelection(Result, AdditionalParameters) Export
	
	SelectedDocuments_ = Result;
	
	If SelectedDocuments_ = Undefined Then
		Return;
	EndIf;
	
	ShowQueryBox(New CallbackDescription("MarkToDeleteCompletion", ThisObject, New Structure("SelectedDocuments_", SelectedDocuments_)), NStr("vi = 'Đánh dấu xóa các chứng từ đã chọn?';
																																				|ru = 'Пометить на удаление выделенные документы?';
																																				|en = 'Mark the selected documents for deletion?'; fa = 'Mark the selected documents for deletion?';
																																				|it = 'Segnare per la cancellazione i documenti selezionati?';
																																				|pl = 'Oznaczyć na usuwanie zaznaczone dokumenty?';
																																				|tr = 'Seçili belgeler silinmek üzere işaretlensin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfPartnerField()
	
	CLVisibility = Items.ToReadLoyaltyCardClient.Visible;
	
	If CLVisibility Then
		CLVisibility = GetFunctionalOption("UseLoyaltyCards");
	EndIf;
	
	Items.PartnerWithoutCL.Visible = Not CLVisibility;
	Items.Partner.Visible      = CLVisibility;
	
EndProcedure

&AtServer
Function FillInGoodsByAgreementServer()
	
	Object.Goods.Clear();
	
	AcceptableNumberOfProductsInSegment = 300;
	ProductsTable             = Undefined;
	ListOfProperties                   = "";
	ProcessedItemsCount          = 0;
	
	If ValueIsFilled(Object.Terms) Then
		CurShipmentDate = ?(ValueIsFilled(Object.DateOfShipment),
								Object.DateOfShipment,
								CurrentSessionDate());
		CurShipmentDate = BegOfDay(CurShipmentDate);
		
		If Object.DisplayRecommendationsToPurchase
			And Object.ForecastingMethod = Enums.SalesForecastingMethods.BySalesPlans Then
			
			Query = New Query;
			Query.Text = 
			"SELECT ALLOWED
			|	SalesPlansTurnovers.Products,
			|	SalesPlansTurnovers.Products.UnitOfMeasure AS UnitOfMeasureForecast,
			|	SalesPlansTurnovers.Characteristic,
			|	SalesPlansTurnovers.CountTurnover AS QuantityForecast,
			|	2 AS SelectionIconIndex
			|FROM
			|	AccumulationRegister.SalesPlans.Turnovers(&BegPeriod, &NdPeriod, Auto,
			|		Scenario = &Scenario
			|		AND Status = VALUE(Enum.PlanStatuses.Upholded)
			|		AND NOT Products.ItemsType = VALUE(Enum.ItemsTypes.Set)
			|		AND &AdditionalSelections
			|		) AS SalesPlansTurnovers";
			
			Query.SetParameter("BegPeriod", CurShipmentDate - Object.StatisticsCollectionPeriod * 86400);
			Query.SetParameter("NdPeriod", EndOfDay(Object.DateOfNextOrder));
			Query.SetParameter("Partner",    Object.Partner);
			
			DetailsOfAgreement = Common.ObjectAttributesValues(Object.Terms,"PlanningScenario,PlanProfile");
			
			Query.SetParameter("Scenario",DetailsOfAgreement.PlanningScenario);
			
			AdditionalSelections = New Array;
			If ValueIsFilled(Object.Department) Then
				AdditionalSelections.Add("Department IN (&Departments)");
				CollectionParameter = New Array;
				CollectionParameter.Add(Object.Department);
				CollectionParameter.Add(Catalogs.BusinessStructure.EmptyRef());
				Query.SetParameter("Departments",CollectionParameter);
			EndIf; 
			
			If ValueIsFilled(Object.Warehouse) Then
				If Common.ObjectAttributeValue(Object.Warehouse, "IsFolder") Then
					AdditionalSelections.Add("(Warehouse IN HIERARCHY(&Warehouse) OR Warehouse = VALUE(CCatalog.Warehouses.EmptyRef))");
				Else
					AdditionalSelections.Add("(Warehouse = &Warehouse OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef))");
				EndIf; 
				Query.SetParameter("Warehouse",Object.Warehouse);
			EndIf; 
			
			If ValueIsFilled(Object.Terms) Then
				AdditionalSelections.Add("Terms IN (&Terms1)");
				CollectionParameter = New Array;
				CollectionParameter.Add(Object.Terms);
				CollectionParameter.Add(Catalogs.TermsOfSale.EmptyRef());
				Query.SetParameter("Terms1",CollectionParameter);
			EndIf; 
			
			If ValueIsFilled(Object.Manager) Then
				AdditionalSelections.Add("Manager IN (&Managers)");
				CollectionParameter = New Array;
				CollectionParameter.Add(Object.Manager);
				CollectionParameter.Add(Catalogs.Users.EmptyRef());
				Query.SetParameter("Managers",CollectionParameter);
			EndIf; 
			
			Query.Text = StrReplace(Query.Text,"&AdditionalSelections",StrConcat(AdditionalSelections," And "));
			
			ProductsTable = Query.Execute().Unload();
			
			If ProductsTable.Count() > AcceptableNumberOfProductsInSegment Then
				Return ProcessedItemsCount
			EndIf;
			
			ListOfProperties = "Products, Characteristic, QuantityForecast, SelectionIconIndex, UnitOfMeasureForecast";
			
		Else
			ProductSegment = Common.ObjectAttributeValue(Object.Terms, "ProductSegment");
			
			If Not ValueIsFilled(ProductSegment) Then
				Return ProcessedItemsCount
			EndIf;
			
			Query = New Query;
			Query.Text =
			"SELECT ALLOWED
			|	ISNULL(COUNT(SegmentProducts.Products),0) AS Products
			|FROM
			|	InformationRegister.SegmentProducts AS SegmentProducts
			|WHERE
			|	SegmentProducts.Segment = &Segment";
			
			Query.SetParameter("Segment", ProductSegment);
			
			Selection = Query.Execute().Select();
			Selection.Next();
			
			If Selection.Count()>AcceptableNumberOfProductsInSegment Then
				Return ProcessedItemsCount;
			EndIf;
			
			If Object.DisplayRecommendationsToPurchase
				And Object.ForecastingMethod = Enums.SalesForecastingMethods.BySalesStatistics Then
				
				Query = New Query;
				Query.Text =
				"SELECT ALLOWED
				|	SegmentProducts.Products AS Products,
				|	SegmentProducts.Characteristic AS Characteristic
				|INTO TT_Products
				|FROM
				|	InformationRegister.SegmentProducts AS SegmentProducts
				|WHERE
				|	SegmentProducts.Segment = &Segment
				|	AND NOT SegmentProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Set)
				|
				|INDEX BY
				|	Products,
				|	Characteristic
				|;
				|
				|//////////////////////////////////////////////////////////////////////////////// 1
				|SELECT ALLOWED
				|	ShipmentReferences.Products AS Products,
				|	ShipmentReferences.Characteristic AS Characteristic,
				|	MAX(ShipmentReferences.Period) AS LastOrderDate_,
				|	COUNT(DISTINCT ShipmentReferences.Recorder) AS OrdersCount,
				|	SUM(ShipmentReferences.Count) AS SalesVolume,
				|	CASE WHEN DATEDIFF(MIN(ShipmentReferences.Period), &CurrentDate, DAY) = 0 THEN
				|		SUM(ShipmentReferences.Count)
				|	ELSE
				|		SUM(ShipmentReferences.Count) / DATEDIFF(MIN(ShipmentReferences.Period), &CurrentDate, DAY)
				|	END AS AverageDailySale
				|INTO TTOrderVolume
				|FROM
				|	AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
				|WHERE
				|	ShipmentReferences.Period >= &Period
				|	AND ShipmentReferences.ReferenceOrder.Partner = &Partner
				|	AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
				|	AND ShipmentReferences.Active
				|	AND ShipmentReferences.Count > 0
				|	AND (ShipmentReferences.Products, ShipmentReferences.Characteristic) IN
				|			(SELECT
				|				TT_Products.Products,
				|				TT_Products.Characteristic
				|			FROM
				|				TT_Products)
				|
				|GROUP BY
				|	ShipmentReferences.Products,
				|	ShipmentReferences.Characteristic
				|
				|INDEX BY
				|	Products,
				|	Characteristic,
				|	LastOrderDate_
				|;
				|
				|//////////////////////////////////////////////////////////////////////////////// 2
				|SELECT ALLOWED
				|	ShipmentReferences.Products AS Products,
				|	ShipmentReferences.Characteristic AS Characteristic,
				|	DATEDIFF(MAX(ShipmentReferences.Period), &CurrentDate, DAY) AS NumberOfDaysFromOrder,
				|	SUM(ShipmentReferences.Count) AS PreviousOrderVolume
				|INTO TTVolumeOfOrders
				|FROM
				|	AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
				|		INNER JOIN TTOrderVolume AS TTOrderVolume
				|		ON ShipmentReferences.Products = TTOrderVolume.Products
				|			AND ShipmentReferences.Characteristic = TTOrderVolume.Characteristic
				|			AND TTOrderVolume.LastOrderDate_ = ShipmentReferences.Period
				|			AND TTOrderVolume.OrdersCount > 1
				|WHERE
				|	ShipmentReferences.ReferenceOrder.Partner = &Partner
				|	AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
				|	AND ShipmentReferences.Active
				|	AND ShipmentReferences.Count > 0
				|
				|GROUP BY
				|	ShipmentReferences.Products,
				|	ShipmentReferences.Characteristic
				|
				|INDEX BY
				|	Products,
				|	Characteristic
				|;
				|
				|//////////////////////////////////////////////////////////////////////////////// 3
				|SELECT
				|	TT_Products.Products AS Products,
				|	TT_Products.Products.UnitOfMeasure AS UnitOfMeasureForecast,
				|	TT_Products.Characteristic AS Characteristic,
				|	TTOrderVolume.LastOrderDate_ AS PreviousOrderDate,
				|	TTOrderVolume.OrdersCount AS OrdersCount,
				|	TTOrderVolume.SalesVolume AS SalesVolume,
				|	TTOrderVolume.AverageDailySale AS AverageDailySale,
				|	TTVolumeOfOrders.NumberOfDaysFromOrder AS NumberOfDaysFromOrder,
				|	TTVolumeOfOrders.PreviousOrderVolume AS QuantityPreviousOrderVolume,
				|	CASE
				|		WHEN TTVolumeOfOrders.PreviousOrderVolume - TTOrderVolume.AverageDailySale * TTVolumeOfOrders.NumberOfDaysFromOrder > 0
				|			THEN TTVolumeOfOrders.PreviousOrderVolume - TTOrderVolume.AverageDailySale * TTVolumeOfOrders.NumberOfDaysFromOrder
				|		ELSE 0
				|	END AS QuantityForecastBalance,
				|	CASE
				|		WHEN TTVolumeOfOrders.PreviousOrderVolume - TTOrderVolume.AverageDailySale * TTVolumeOfOrders.NumberOfDaysFromOrder > 0
				|			THEN TTOrderVolume.AverageDailySale * &NumberOfDaysUntilNextShipment - (TTVolumeOfOrders.PreviousOrderVolume - TTOrderVolume.AverageDailySale * TTVolumeOfOrders.NumberOfDaysFromOrder)
				|		ELSE TTOrderVolume.AverageDailySale * &NumberOfDaysUntilNextShipment
				|	END AS QuantityForecast,
				|	CASE
				|		WHEN TTVolumeOfOrders.PreviousOrderVolume - TTOrderVolume.AverageDailySale * TTVolumeOfOrders.NumberOfDaysFromOrder > 0
				|			THEN (TTVolumeOfOrders.PreviousOrderVolume - TTOrderVolume.AverageDailySale * TTVolumeOfOrders.NumberOfDaysFromOrder) / TTOrderVolume.AverageDailySale
				|		ELSE 0
				|	END AS NumberOfDaysBeforeInventoryExpiration
				|FROM
				|	TT_Products AS TT_Products
				|		LEFT JOIN TTOrderVolume AS TTOrderVolume
				|		ON TT_Products.Products = TTOrderVolume.Products
				|			AND TT_Products.Characteristic = TTOrderVolume.Characteristic
				|			AND (TTOrderVolume.OrdersCount > 1)
				|		LEFT JOIN TTVolumeOfOrders AS TTVolumeOfOrders
				|		ON TT_Products.Products = TTVolumeOfOrders.Products
				|			AND TT_Products.Characteristic = TTVolumeOfOrders.Characteristic";
				
				If ValueIsFilled(Object.DateOfNextOrder) Then
					NumberOfDaysUntilNextShipment = (BegOfDay(Object.DateOfNextOrder) - CurShipmentDate) / 86400;
				Else
					NumberOfDaysUntilNextShipment = 0;
				EndIf;
				
				Query.SetParameter("Segment",                           ProductSegment);
				Query.SetParameter("Partner",                           Object.Partner);
				Query.SetParameter("DaysCount",                    Object.StatisticsCollectionPeriod);
				Query.SetParameter("NumberOfDaysUntilNextShipment", NumberOfDaysUntilNextShipment);
				Query.SetParameter("CurrentDate",                       CurShipmentDate);
				Query.SetParameter("Period",                            CurShipmentDate - Object.StatisticsCollectionPeriod * 86400);
				
				ProductsTable = Query.Execute().Unload();
				
				ListOfProperties = "Products, Characteristic, QuantityForecast, PreviousOrderDate, 
								|QuantityForecastBalance, NumberOfDaysBeforeInventoryExpiration, QuantityPreviousOrderVolume, 
								|AverageDailySale, UnitOfMeasureForecast";
				
			ElsIf Object.FillInGoodsByTermsOfSales Then
				Query = New Query;
				Query.Text =
				"SELECT ALLOWED
				|	SegmentProducts.Products AS Products,
				|	SegmentProducts.Characteristic AS Characteristic
				|FROM
				|	InformationRegister.SegmentProducts AS SegmentProducts
				|WHERE
				|	SegmentProducts.Segment = &Segment
				|	AND NOT SegmentProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Set)";
				
				Query.SetParameter("Segment", ProductSegment);
				
				ProductsTable = Query.Execute().Unload();
				
				ListOfProperties = "Products, Characteristic";
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(ProductsTable) Then
			Return ProcessedItemsCount
		EndIf;
		
		TableAddress        = PutToTempStorage(ProductsTable);
		ParametersStructure = New Structure("GoodsAddressInStorage, MaximumShipmentDate",
												TableAddress, Object.DateOfShipment);
		
		ProcessingSelectionOfSelectionOnServer(ParametersStructure, ListOfProperties);
		
		ProcessedItemsCount = ProductsTable.Count();
	EndIf;
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	
	Return ProcessedItemsCount;
	
EndFunction

&AtServer
Procedure FillInGoodsByAgreementServerWithMeasurement()
	
	If Object.FillInGoodsByTermsOfSales Then
		Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
					"DataProcessor.SalesWizard.Form.Form.FillInGoodsByAgreementServer");
		
		ProcessedItemsCount = FillInGoodsByAgreementServer();
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProcessedItemsCount / 10);
		UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePartnerDossierInformation()
	
	If Not ValueIsFilled(Object.Partner) Then
		Items.DecorationOfThePartnerSDossierCalculations.Title = "";
		
		Return;
	EndIf;
	
	ArrayOfMessages = New Array;
	
	QueryTextCalculations =
	"SELECT DISTINCT
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey
	|INTO SelectingPartnerAnalytics
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	&FilterCriterion
	|INDEX BY
	|	DimensionKey
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CASE
	|		WHEN CustomersARAPAccountingBalance.SumBalance > 0
	|			THEN CustomersARAPAccountingBalance.SumBalance
	|		ELSE 0
	|	END AS Debt_,
	|	0 AS ARAPOverdue,
	|	CustomersARAPAccountingBalance.Currency.Presentation AS Currency
	|INTO
	|	TTCalculations
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|			,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					SelectingPartnerAnalytics.DimensionKey
	|				FROM
	|					SelectingPartnerAnalytics AS SelectingPartnerAnalytics)) AS CustomersARAPAccountingBalance
	|
	|UNION ALL
	|
	|SELECT
	|	0 AS Debt_,
	|	CASE
	|		WHEN CustomersARAPAccountingBalance.AmountDueBalance > 0
	|			THEN CustomersARAPAccountingBalance.AmountDueBalance
	|		ELSE 0
	|	END AS ARAPOverdue,
	|	CustomersARAPAccountingBalance.Currency.Presentation AS Currency
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|			&CurrentDate,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					SelectingPartnerAnalytics.DimensionKey
	|				FROM
	|					SelectingPartnerAnalytics AS SelectingPartnerAnalytics)) AS CustomersARAPAccountingBalance
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SUM(Calculations.Debt_) AS Debt_,
	|	SUM(Calculations.ARAPOverdue) AS ARAPOverdue,
	|	Calculations.Currency AS Currency
	|FROM
	|	TTCalculations AS Calculations
	|
	|GROUP BY
	|	Calculations.Currency
	|;";
	
	TemplateCondition = " AND AccountingDimensionByPartners.%Parameter = &%Parameter";
	FilterCriterion = "TRUE";
	
	If ValueIsFilled(Object.Partner) Then
		FilterCriterion = FilterCriterion + StrReplace(TemplateCondition, "%Parameter", "Partner");
	EndIf;
	If ValueIsFilled(Object.Organization) Then
		FilterCriterion = FilterCriterion + StrReplace(TemplateCondition, "%Parameter", "Organization");
	EndIf;
	If ValueIsFilled(Object.Counterparty) Then
		FilterCriterion = FilterCriterion + StrReplace(TemplateCondition, "%Parameter", "Counterparty");
	EndIf;
	If ValueIsFilled(Object.Contract) Then
		FilterCriterion = FilterCriterion + StrReplace(TemplateCondition, "%Parameter", "Contract");
	EndIf;
	If ValueIsFilled(Object.LineOfBusiness) Then
		FilterCriterion = FilterCriterion + StrReplace(TemplateCondition, "%Parameter", "LineOfBusiness");
	EndIf;
	
	QueryTextCalculations = StrReplace(QueryTextCalculations, "&FilterCriterion", FilterCriterion);
	
	QueryTextTerms = 
	"SELECT ALLOWED
	|	TermsOfSale.MinimumOrderAmount,
	|	TermsOfSale.Currency
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.Ref = &AgreementLink
	|	AND TermsOfSale.MinimumOrderAmount>0;
	|";
	
	Query = New Query;
	Query.Text = QueryTextCalculations + QueryTextTerms;
	
	Query.SetParameter("AgreementLink",        Object.Terms);
	Query.SetParameter("Partner",                 Object.Partner);
	Query.SetParameter("Organization",             Object.Organization);
	Query.SetParameter("Counterparty",              Object.Counterparty);
	Query.SetParameter("Contract",                 Object.Contract);
	Query.SetParameter("LineOfBusiness", Object.LineOfBusiness);
	Query.SetParameter("CurrentDate",             EndOfDay(CurrentSessionDate()));
	
	ResultsPackage      = Query.ExecuteBatch();
	TableOfArrears = ResultsPackage[2].Unload();
	
	For Each RowDebt In TableOfArrears Do
		Debt_ = Format(RowDebt.Debt_,"NFD=2");
		
		Info = "";
		
		If RowDebt.Debt_ > 0 Then
			Template = NStr("vi = 'Công nợ khách hàng: %1 %2';
							|ru = 'Долг клиента: %1 %2';
							|en = 'Total receivables: %1 %2'; fa = 'Total receivables: %1 %2';
							|it = 'Debito cliente: %1 %2';
							|pl = 'Zobowiązanie klienta: %1 %2';
							|tr = 'Müşterinin borcu: %1 %2'")+ Chars.LF;
			Info = StrTemplate(Template, Debt_, RowDebt.Currency);
		ElsIf RowDebt.Debt_ < 0 Then
			Template = NStr("vi = 'Nợ phải trả: %1%2';
							|ru = 'Наш долг: %1 %2';
							|en = 'Payables: %1 %2'; fa = 'Payables: %1 %2';
							|it = 'Nostro debito: %1 %2';
							|pl = 'Nasze zobowiązanie: %1 %2';
							|tr = 'Borcumuz: %1 %2'")+ Chars.LF;
			Info = StrTemplate(Template, -Debt_, RowDebt.Currency);
		EndIf;
		
		If ValueIsFilled(Info) Then
			ArrayOfMessages.Add(New FormattedString(Info));
		EndIf;
		
		ARAPOverdue = Format(RowDebt.ARAPOverdue, "NFD=2");
		
		If RowDebt.ARAPOverdue > 0 Then
			Template = NStr("vi = 'Nợ quá hạn:';
							|ru = 'Просроченная задолженность:';
							|en = 'AR/AP overdue:'; fa = 'AR/AP overdue:';
							|it = 'Debiti arretrati:';
							|pl = 'Przeterminowany dług:';
							|tr = 'Vadesi geçmiş toplam borç:'") + " ";
			
			ArrayOfMessages.Add(New FormattedString(Template));
			
			Template = NStr("vi = '%1 %2';
							|ru = '%1 %2';
							|en = '%1 %2'; fa = '%1 %2';
							|it = '%1 %2';
							|pl = '%1 %2';
							|tr = '%1 %2'")+ Chars.LF;
			Info   = StrTemplate(Template, ARAPOverdue, RowDebt.Currency);
			
			ArrayOfMessages.Add(New FormattedString(Info,,WebColors.FireBrick));
		EndIf;
	EndDo;
	
	SampleAgreement = ResultsPackage[3].Select();
	
	If SampleAgreement.Next() Then
		Template = NStr("vi = 'Số tiền đặt hàng tối thiểu: %1%2';
						|ru = 'Мин. сумма заказа: %1 %2';
						|en = 'Min. order amount: %1 %2'; fa = 'Min. order amount: %1 %2';
						|it = 'Importo minimo dell''ordine: %1 %2';
						|pl = 'Min. wartość zamówienia: %1 %2';
						|tr = 'Minimum sipariş tutarı: %1 %2'")+ Chars.LF;
		Info   = StrTemplate(Template, SampleAgreement.MinimumOrderAmount, SampleAgreement.Currency);
		
		ArrayOfMessages.Add(New FormattedString(Info));
	EndIf;
	
	If ValueIsFilled(TextAllowedCreditBalance) Then
		Info = TextAllowedCreditBalance + Chars.LF;
		
		ArrayOfMessages.Add(New FormattedString(Info, ,WebColors.FireBrick, ,"ShipmentProhibitionReasons"));
	EndIf;
	
	If SegmentsServer.PartnerIsIncludedInShipmentBanSegments(Object.Partner) Then
		Info = NStr("vi = 'Xuất kho bị cấm';
					|ru = 'Отгрузка запрещена';
					|en = 'Shipment is prohibited'; fa = 'ارسال ممنوع است';
					|it = 'Spedizione vietata';
					|pl = 'Wysyłka zabroniona';
					|tr = 'Sevkiyat yasaklandı'")+ Chars.LF;
		
		ArrayOfMessages.Add(New FormattedString(Info, , WebColors.FireBrick, ,"FormOfSegmentsOfShipmentProhibition"));
	EndIf;
	
	Items.DecorationOfThePartnerSDossierCalculations.Title = New FormattedString(ArrayOfMessages, New Font(, 12));
	
EndProcedure

&AtServer
Procedure UpdatePartnerDossierInformationContacts()
	
	If Not ValueIsFilled(Object.Partner) Then
		Items.DecorationPartnerSDossierContacts.Title = "";
		
		Return;
	EndIf;
	
	QueryTextOrderList =
	"SELECT ALLOWED
	|	COUNT(DISTINCT OrderStates.OrderDocument) AS OrdersCount
	|FROM
	|	InformationRegister.SalesOrderStates AS OrderStates
	|WHERE
	|	OrderStates.State <> VALUE(Enum.SalesOrderStates.Closed)
	|	AND OrderStates.OrderDocument REFS Document.SalesOrder
	|	AND CAST(OrderStates.OrderDocument AS Document.SalesOrder).Partner = &Partner;";
	
	ArrayOfMessages = New Array;
	
	If ValueIsFilled(Object.Partner) Then
		Info = NStr("vi = 'Hồ sơ khách hàng';
					|ru = 'Досье клиента';
					|en = 'Customer profile'; fa = 'Customer profile';
					|it = 'Cartella del cliente';
					|pl = 'Akta klienta';
					|tr = 'Müşteri klasörü'") + Chars.LF;
		
		ArrayOfMessages.Add(New FormattedString(Info, ,StyleColors.HyperlinkColor, ,"PartnerProfile"));
		
		Query = New Query(QueryTextOrderList);
		
		Query.SetParameter("Partner", Object.Partner);
		
		SampleOrderList = Query.Execute().Select();
		
		If UseSalesOrders And SampleOrderList.Next() Then
			Template = NStr("vi = 'Danh sách đơn hàng (%1)';
							|ru = 'Список заказов (%1)';
							|en = 'Order list (%1)'; fa = 'Order list (%1)';
							|it = 'Elenco ordini (%1)';
							|pl = 'Lista zamówień (%1)';
							|tr = 'Sipariş listesi (%1)'") + Chars.LF;
			Info   = StrTemplate(Template, SampleOrderList.OrdersCount);
			
			If SampleOrderList.OrdersCount > 0 Then
				ArrayOfMessages.Add(New FormattedString(Info, ,StyleColors.HyperlinkColor, , "OrderList"));
			Else
				ArrayOfMessages.Add(New FormattedString(Info, ,StyleColors.GrayTextColor1, ,"OrderList"));
			EndIf;
		EndIf;
		
		ArrayOfKIOwners = New Array;
		ArrayOfKIOwners.Add(Object.Partner);
		
		ArrayKiTypes = New Array;
		ArrayKiTypes.Add(Enums.ContactInformationTypes.Phone);
		ArrayKiTypes.Add(Enums.ContactInformationTypes.Fax);
		ArrayKiTypes.Add(Enums.ContactInformationTypes.Email);
		
		CITable = ContactsManager.ObjectsContactInformation(ArrayOfKIOwners,
																				ArrayKiTypes,
																				,
																				CurrentSessionDate());
		
		For Each CIRow In CITable Do
			Template = NStr("vi = '%1: %2';
							|ru = '%1: %2';
							|en = '%1: %2'; fa = '%1: %2';
							|it = '%1: %2';
							|pl = '%1: %2';
							|tr = '%1: %2'")+ Chars.LF;
			Info   = StrTemplate(Template, CIRow.Type, CIRow.Presentation);
			
			ArrayOfMessages.Add(New FormattedString(Info));
		EndDo;
		
	Else
		Info = NStr("vi = 'Không có đối tác được chọn.';
					|ru = 'Партнер не выбран.';
					|en = 'Partner is not selected.'; fa = 'Partner is not selected.';
					|it = 'Il partner non è selezionato.';
					|pl = 'Partner nie został wybrany.';
					|tr = 'İş ortağı seçilmedi.'")+ Chars.LF;
		
		ArrayOfMessages.Add(New FormattedString(Info, ,StyleColors.NoteText));
	EndIf;
	
	Items.DecorationPartnerSDossierContacts.Title = New FormattedString(ArrayOfMessages, New Font(, 12));
	
EndProcedure

&AtServer
Procedure SendForecastToServer()
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	SelectedRows = Items.Goods.SelectedRows;
	RowsToProcess = New Array;
	
	For Each RowSelected In SelectedRows Do
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If CurrentRow.SelectionIconIndex = 1 Then
			CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesyForecast;
			CurrentRow.Count = CurrentRow.QuantityForecast;
			CurrentRow.NumberOfPackagesyForecast = CurrentRow.NumberOfPackagesPreviousOrderVolume;
			CurrentRow.QuantityForecast = CurrentRow.QuantityPreviousOrderVolume;
			CurrentRow.SelectionIconIndex = CurrentRow.SelectionIconIndex + 1;
		ElsIf CurrentRow.SelectionIconIndex = 2 Then
			CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesyForecast;
			CurrentRow.Count = CurrentRow.QuantityForecast;
			CurrentRow.SelectionIconIndex = CurrentRow.SelectionIconIndex + 1;
		ElsIf CurrentRow.SelectionIconIndex = 3 Then
			CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + CurrentRow.NumberOfPackagesyForecast;
			CurrentRow.Count = CurrentRow.NumberOfPackages + CurrentRow.QuantityForecast;
		EndIf;
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);

EndProcedure

&AtServer
Procedure SetContractAvailability()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		Items.Contract.Visible = False;
	EndIf;
	Items.IndentDecoration.Visible = Not Items.Contract.Visible;
	
EndProcedure

&AtServer
Procedure SetDivisionDesign()
	
	DivisionsInTablePartAreUsed =	Object.CreateSalesOrder Or
												Object.CreateSalesDocument Or
												Object.CreateRequestForReturnOfGoodsFromCustomers;
												
	UseWarehousesInTabularSectionsOfSalesDocuments = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	Items.ProductsGroupSender.Visible = 
				UseBusinessUnits And DivisionsInTablePartAreUsed
					Or UseWarehousesInTabularSectionsOfSalesDocuments And WarehouseGroup_;
	
	If WarehouseGroup_ And DivisionsInTablePartAreUsed Then
		Items.ProductsGroupSender.Title = NStr("vi = 'Người gửi';
												|ru = 'Отправитель';
												|en = 'Sender'; fa = 'فرستنده';
												|it = 'Mittente';
												|pl = 'Nadawca';
												|tr = 'Gönderen'");
	ElsIf WarehouseGroup_ And Not DivisionsInTablePartAreUsed Then
		Items.ProductsGroupSender.Title = NStr("vi = 'Kho bãi';
												|ru = 'Склад';
												|en = 'Warehouse'; fa = 'Warehouse';
												|it = 'Magazzino';
												|pl = 'Magazyn';
												|tr = 'Ambar'");
	Else
		Items.ProductsGroupSender.Title = NStr("vi = 'Bộ phận gửi';
												|ru = 'Подразделение-отправитель';
												|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
												|it = 'Unità-mittente';
												|pl = 'Dział-nadawca';
												|tr = 'Gönderen departman'");
	EndIf;

EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = DataProcessors.SalesWizard.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsOfLoyaltyBonusProgram()
	
	Items.GroupProductsBonusPoints.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfBonusPointsToDeductionInCurrency.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfEarnedBonusPointsInCurrency.Visible = UseLoyaltyPrograms;
	
EndProcedure

&AtServer
Function AddressOfTheTablePartProducts()
	
	Return PutToTempStorage(Object.Goods.Unload(), UUID);
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForFillingInVATRate(Object)
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	Return ParametersFillInVATRate;
	
EndFunction

&AtClientAtServerNoContext
Function LinkToDesignOption(DocumentCreationOption)
	
	Result = PredefinedValue("Document.SalesOrder.EmptyRef");
	
	If DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice")
		Or DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice") Then
		
		Result = PredefinedValue("Document.CustomerInvoice.EmptyRef");
		
	ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee")
		Or DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer") Then
		
		Result = PredefinedValue("Document.TransferOfGoodsToBailee.EmptyRef");
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure DownloadAdditionalBankingDetailsFromStorageServer(ValueSelected);
	
	TableName = "";
	
	If ValueSelected.DocumentType = "DocumentObject.SalesOrder" Then
		TableName = "AdditionalOrderAttributes";
	ElsIf ValueSelected.DocumentType = "DocumentObject.CustomerInvoice" Then
		TableName = "AdditionalSaleAttributes";
	ElsIf ValueSelected.DocumentType = "DocumentObject.CustomerInvoiceServices" Then
		TableName = "AdditionalInvoiceAttributes";
	ElsIf ValueSelected.DocumentType = "DocumentObject.RequestForReturnOfGoodsFromCustomer" Then
		TableName = "AdditionalRequestAttributes";
	ElsIf ValueSelected.DocumentType = "DocumentObject.TransferOfGoodsToBailee" Then
		TableName = "AdditionalAttributesTransferOfGoods";
	ElsIf ValueSelected.DocumentType = "DocumentObject.GoodsShipmentToCustomer" Then
		TableName = "AdditionalAttributesOfGoodsShipment";
	Else
		Sales.WhenDeterminingNameOfLoadingTableOfAdditionalDetails(ValueSelected, TableName);
	EndIf;
	
	Object[TableName].Load(GetFromTempStorage(ValueSelected.AdditionalAttributes));
	
EndProcedure

&AtClient
Procedure AskQuestionSupplyCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "EnableMode" Then
		Object.SimplifiedFulfillment = False;
		
		SetVisibilityOfItemsBySettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure AskQuestionSupply()
	
	ThisIsOrder = Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder")
				Or Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee")
				Or Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer")
				Or Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice");
	
	If FillInSeparately
		And Object.SimplifiedFulfillment
		And Not Object.DoNotAskSupply
		And ThisIsOrder Then
		
		QueryText = NStr("vi = 'Trong thỏa thuận có chỉ ra dấu hiệu ""Đảm bảo hàng hóa đặt riêng"".
							|Trong các trường hợp đó, nên sử dụng chế độ đảm bảo hàng hóa nâng cao.
							|Bật chế độ đảm bảo nâng cao?';
							|ru = 'В соглашении указан признак ""Обеспечивать товары обособленно"".
							|В таких случаях рекомендуется использовать расширенный режим обеспечения товаров.
							|Включить расширенный режим обеспечения?';
							|en = 'The ""Provide goods as assigned"" attribute is specified in the agreement.
							|In these cases, it is recommended that you use the advanced goods supply mode.
							|Do you want to enable the advanced goods supply mode?'; fa = 'The ""Provide goods as assigned"" attribute is specified in the agreement.
							|In these cases, it is recommended that you use the advanced goods supply mode.
							|Do you want to enable the advanced goods supply mode?';
							|it = 'Nell''accordo è specifica il criterio ""Fornire i prodotti separatamente"".
							|In questi casi, si consiglia di utilizzare la modalità allargata di approvvigionamento prodotti.
							|Abilitare la modalità di approvvigionamento allargata?';
							|pl = 'W umowie określono wskazówkę ""Dostarczać wiersze pozycji osobno"". 
							|W takich przypadkach zaleca się skorzystać z trybu zaawansowanego dostarczania towarów.
							|Włączyć zaawansowany tryb dostarczania?';
							|tr = 'Anlaşmada ""Ürünleri ayrı olarak temin edin"" ibaresi yer almaktadır.
							| Bu gibi durumlarda genişletilmiş teminat modunun kullanılması önerilir.
							| Genişletilmiş teminat modu etkinleştirilsin mi?'");
		
		ButtonsList = New ValueList();
		ButtonsList.Add("EnableMode", NStr("vi = 'Bật sử dụng chế độ';
											|ru = 'Включить режим';
											|en = 'Enable mode'; fa = 'Enable mode';
											|it = 'Abilitare modalità';
											|pl = 'Włączyć tryb';
											|tr = 'Modu etkinleştir'"));
		ButtonsList.Add("Continue",    NStr("vi = 'Tiếp tục';
											|ru = 'Продолжить';
											|en = 'Continue'; fa = 'ادامه';
											|it = 'Continuare';
											|pl = 'Continue';
											|tr = 'Devam'"));
		
		ShowQueryBox(New CallbackDescription("AskQuestionSupplyCompletion", ThisObject), QueryText, ButtonsList);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisObject, TagName);
EndProcedure

&AtServer
Procedure LoadPaymentStagesFromTemporaryStorage()
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisObject);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		LoadPaymentStagesFromTemporaryStorage();
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		
		If ChangedBankingDetails.Count() > 0 Then
			
			LabelPaymentStagesClickCompletionServer(ChangedBankingDetails);
			If ChangedBankingDetails.Property("PaymentMethod") Then
				DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
			EndIf;
		
		EndIf;
		
	EndIf;
	
	CalculateTotals_(ThisObject);
	UpdateTextOfInformationLabelGeneratedDocuments();
	
EndProcedure

&AtServer
Procedure LabelPaymentStagesClickCompletionServer(ChangedBankingDetails)
	
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then	
		SetPropertiesOfElementsInOrderOfCalculations();
	EndIf;
	
	FillInShippingDateSelectionList();
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
EndProcedure

&AtServerNoContext
Function KitPrintingIsAvailable(Document)
	
	ObjectParameters = InformationRegisters.ObjectPrintSettings.ObjectParametersForCompletePrinting(
		Document.Metadata().FullName());
	
	Return ObjectParameters.KitPrintingIsAvailable;
	
EndFunction

&AtClient
Procedure NewSaleCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "DonTStart" Then
		Return;
	EndIf;
	
	NewSaleFragment();
	
EndProcedure

&AtClient
Procedure NewSaleFragment()
	
	ResetTagsAndCaps(Items);
	
	Items.GoPartner.Check   = True;
	Items.Pages.CurrentPage = Items.PagePartner;
	
	NewSaleServer();
	
	If ToUseTermsOfSales
		And ValueIsFilled(Object.Terms) Then
		
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoToDocuments(Val Notification)
	
	FillInStatusesForSpecifyingSeries();
	ResetTagsAndCaps(Items);
	
	Items.GoToDocuments_5.Check = True;
	Items.Pages.CurrentPage = Items.PageDocuments;
	
	If Modified
		Or Not DocumentsAreCreated Then
		
		NotificationParameters = New Structure("Notification", Notification);
		CallbackDescription  = New CallbackDescription("GoToDocumentsCompletion", ThisObject, NotificationParameters);
		
		CreateDocumentsClient(CallbackDescription);
		
		Return;
		
	EndIf;
	
	GoToDocumentsFragment(Notification);
	
EndProcedure

&AtClient
Procedure GoToDocumentsCompletion(Result, AdditionalParameters) Export
	
	Notification = AdditionalParameters.Notification;
	
	GoToDocumentsFragment(Notification);
	
EndProcedure

&AtClient
Procedure GoToDocumentsFragment(Val Notification)
	
	RunCallback(Notification);
	
EndProcedure

&AtClient
Procedure OpenSettingsForm()
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("PrintCustomerInvoiceWorksAndServices",                   Object.PrintCustomerInvoiceWorksAndServices);
	ParametersStructure.Insert("PrintSalesOrder",                          Object.PrintSalesOrder);
	ParametersStructure.Insert("PrintCommercialProposal",               Object.PrintCommercialProposal);
	ParametersStructure.Insert("PrintCashAccountReceiptNote",                Object.PrintCashAccountReceiptNote);
	ParametersStructure.Insert("PrintCustomerInvoice",                Object.PrintCustomerInvoice);
	ParametersStructure.Insert("PrintTheTransferOfGoodsToBailee",              Object.PrintTheTransferOfGoodsToBailee);
	ParametersStructure.Insert("PrintCommercialInvoice",                          Object.PrintCommercialInvoice);
	ParametersStructure.Insert("PrintTaxInvoice",                           Object.PrintTaxInvoice);
	ParametersStructure.Insert("CreateSalesDocument",                      Object.CreateSalesDocument);
	ParametersStructure.Insert("CreateTransferOfGoodsToBailee",             Object.CreateTransferOfGoodsToBailee);
	ParametersStructure.Insert("CreateSalesOrder",                         Object.CreateSalesOrder);
	ParametersStructure.Insert("CreateCommercialProposal",              Object.CreateCommercialProposal);
	ParametersStructure.Insert("CreateCashAccountReceiptNote",               Object.CreateCashAccountReceiptNote);
	ParametersStructure.Insert("CreateCommercialInvoice",                         Object.CreateCommercialInvoice);
	ParametersStructure.Insert("SalesOrderStatus",                           Object.SalesOrderStatus);
	ParametersStructure.Insert("CommercialProposalStatus",                Object.CommercialProposalStatus);
	ParametersStructure.Insert("StatusOfCustomerInvoice",                  Object.StatusOfCustomerInvoice);
	ParametersStructure.Insert("CreateDefaultConsignmentNote",     Object.CreateDefaultConsignmentNote);
	ParametersStructure.Insert("CreateAuthorizationLetterForReceivingCash", Object.CreateAuthorizationLetterForReceivingCash);
	ParametersStructure.Insert("DocumentCreationOption",                   Object.DocumentCreationOption);
	
	ParametersStructure.Insert("CreateRequestForReturnOfGoodsFromCustomers",     Object.CreateRequestForReturnOfGoodsFromCustomers);
	ParametersStructure.Insert("PrintRequestForReturnOfGoodsFromCustomer",      Object.PrintRequestForReturnOfGoodsFromCustomer);
	ParametersStructure.Insert("StatusOfRequestForReturnOfGoodsFromCustomers",        Object.StatusOfRequestForReturnOfGoodsFromCustomers);
	ParametersStructure.Insert("FillInGoodsByTermsOfSales",                   Object.FillInGoodsByTermsOfSales);
	ParametersStructure.Insert("DisplayRecommendationsToPurchase",                Object.DisplayRecommendationsToPurchase);
	ParametersStructure.Insert("ForecastingMethod",                   Object.ForecastingMethod);
	ParametersStructure.Insert("StatisticsCollectionPeriod",                         Object.StatisticsCollectionPeriod);
	ParametersStructure.Insert("SimplifiedFulfillment",                         Object.SimplifiedFulfillment);
	ParametersStructure.Insert("SupplyOption",                            Object.SupplyOption);
	ParametersStructure.Insert("DoNotAskSupply",                   Object.DoNotAskSupply);
	
	ParametersStructure.Insert("IssueAFiscalReceipt",                        Object.IssueAFiscalReceipt);
	
	CallbackDescription = New CallbackDescription("FormSettingsCompletion", ThisObject);
	
	OpenForm("DataProcessor.SalesWizard.Form.Setting", ParametersStructure, ThisObject, , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FormSettingsCompletion(SettingsResult, AdditionalParameters = Undefined) Export
	
	If SettingsResult = Undefined Then
		Return;
	EndIf;
	
	SetMarkIncompleteWarehouse();
	
EndProcedure

&AtClient
Procedure CreatePartnerCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "LeaveCurClient" Then
		Return;
	EndIf;
	
	CreatePartnerFragment();
	
EndProcedure

&AtClient
Procedure CreatePartnerFragment()
	
	OpeningParameters = New Structure("OwnerFormHeader", NStr("vi = 'Bạn hàng (Khách hàng)';
																|ru = 'Партнеры (Клиенты)';
																|en = 'Partners (Customers)'; fa = 'Partners (Customers)';
																|it = 'Partner (Clienti)';
																|pl = 'Partnerzy (Klienci)';
																|tr = 'İş ortakları (Müşteriler)'"));
	
	OpenForm("Catalog.Partners.Form.WizardOfNew", OpeningParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, CurrentRow);
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, NewRow);
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(AdditionalParameters.StructureOfRecalculationOfAmount);
		
		CalculateTotals_(ThisObject);
		StructureOfActions = New Structure();
		AddCollateralActionsOnClient(StructureOfActions, "UpdateProductCache_");
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		
	EndIf;
	
	UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If CurrentData = Undefined Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If CurrentData = Undefined Then
			MessageText = NStr("vi = 'Chọn dòng sản phẩm mà bạn muốn chỉ định loạt.';
								|ru = 'Выберите строку товаров, для которой необходимо указать серии.';
								|en = 'Select a goods line for which the batch shall be specified.'; fa = 'Select a goods line for which the batch shall be specified.';
								|it = 'Selezionare la riga dei prodotti per la quale è necessario specificare le serie.';
								|pl = 'Wybierz wiersz towarów, dla których chcesz określić serie.';
								|tr = 'Partisini belirtmek istediğin ürün satırını seç.'");
			
			ShowMessageBox(,MessageText);
			
			Return;
		EndIf;
		
		CurDataId = CurrentData.GetID();
		
	Else
		CurDataId = CurrentData.GetID();
	EndIf;
	
	If Not ThisIsImplementation(CurrentData.RegistrationOption)
			And Not ThisIsTransferOfGoods(CurrentData.RegistrationOption) Then
		
		If CurrentData.BatchesIndicationStatus = 0 Then
			MessageText = NStr("vi = 'Đối với hàng hóa này, không cần chỉ ra sê-ri. Dạng mặt hàng, kho, chính sách chỉ ra sê-ri, trạng thái chứng từ có thể ảnh hưởng đến tính năng chỉ ra sê-ri.';
								|ru = 'Для этого товара серии указывать не нужно. На возможность указания серий могут влиять: вид номенклатуры, склад, политика указания серий, статус документа.';
								|en = 'Batches are not required for these goods. The option depends on: item kind, warehouse, batch specification policy, document status.'; fa = 'Batches are not required for these goods. The option depends on: item kind, warehouse, batch specification policy, document status.';
								|it = 'Per questo prodotto non è necessario specificare le serie. La possibilità di specificare le serie può essere influenzata da: tipo di articolo, magazzino, politica dell''indicazione serie, stato del documento.';
								|pl = 'Dla tego towaru serii wskazywać nie trzeba. Na możliwość podania serii mogą wpływać: rodzaj pozycji, magazyn, polityka podania serii, status dokumentu.';
								|tr = 'Bu öğe için bir parti girmenize gerek yoktur. Bir parti belirtme gerekliliği şunlarda ortaya çıkabilir: ürün türü, depo, parti belirtme politikası, belge durumu.'");
			
			ShowMessageBox(,MessageText);
			
			Return;
		EndIf;
		
		If CurrentData.SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship") Then
			
			MessageText = NStr("vi = 'Để chọn sê-ri, cần chỉ ra thao tác ""Giao hàng"".';
								|ru = 'Для выбора серий необходимо указать действие ""Отгрузить"".';
								|en = 'Specify the ""Ship"" action to select a batch.'; fa = 'Specify the ""Ship"" action to select a batch.';
								|it = 'Per selezionare le serie è necessario indicare l''azione ""Spedire"".';
								|pl = 'Dla wyboru serii należy wskazać działanie ""Wysyłaj"".';
								|tr = 'Bir seri seçmek için ""Gönder"" eylemi belirtilmelidir.'");
			
			ShowMessageBox(,MessageText);
			
			Return;
		EndIf;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.SeriesSelectionMode());
		If FormParameters <> Undefined Then
			
			OpenForm(
				"DataProcessor.QuantityAndBatchRequest.Form",
				FormParameters,
				ThisObject,
				,
				,
				,
				New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
				
		EndIf;
		
		Return;
		
	EndIf;
	
	If Object.Goods.Count() > 0 Then
		ThisIsImplementation = ThisIsImplementation(Items.Goods.CurrentData.RegistrationOption)
						Or ThisIsTransferOfGoods(Items.Goods.CurrentData.RegistrationOption);
		
		If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, DefineSeriesParametersOnClient(CurDataId), Text, CurrentData) Then
			
			ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, ThisIsImplementation);
			
			AdditionalParameters = New Structure("ParametersOfSeriesIndicationForm, ThisIsImplementation",
														ParametersOfSeriesIndicationForm, ThisIsImplementation);
			CallbackDescription      = New CallbackDescription("OpenSelectionOfSeriesCompletion",
																ThisObject,
																AdditionalParameters);
			
			OpenForm(ParametersOfSeriesIndicationForm.FormName ,ParametersOfSeriesIndicationForm, ThisObject, , , , CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ReturnValue_1 = Result;
	
	ThisIsImplementation               = AdditionalParameters.ThisIsImplementation;
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, ThisIsImplementation);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
		UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAutomaticDiscountsCompletion(ReturnedValue, AdditionalParameters) Export 
	
	If ReturnedValue <> Undefined Then
		ManagedDiscounts = ReturnedValue;
		
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("ApplyToObject",                True);
		ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
		ParametersStructure1.Insert("RestoreManagedDiscounts", False);
		ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisObject, UUID);
		EndIf;
		
		ShowUserNotification(
			NStr("vi = 'Chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки)';
				|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
				|it = 'Sconti (sovrapprezzo)';
				|pl = 'Rabaty (marże)';
				|tr = 'İndirim (marj)'"),
			,
			NStr("vi = 'Đã tính chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки) рассчитаны';
				|en = 'Discounts (markups) are calculated'; fa = 'Discounts (markups) are calculated';
				|it = 'Sconti (sovrapprezzi) sono calcolati';
				|pl = 'Rabaty (marże) są obliczone';
				|tr = 'İndirim (marj) uygulandı'"),
			PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscountCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Undefined, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateTotals_(ThisObject);
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLinesCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Items.Goods.SelectedRows, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateTotals_(ThisObject);
		
	EndIf;

EndProcedure

&AtClient
Procedure AddPaymentWithBonusPointsCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		CalculateTotals_(ThisObject);
		UpdateTextOfInformationLabelGeneratedDocuments();
		Return;
	EndIf;
	
	ApplyPaymentWithBonusPoints(Result.AddressInTempStorage);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	SelectedWarehouse = Result;
	If ValueIsFilled(SelectedWarehouse) Then
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDocumentsCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "NotCreate" Then
		Return;
	EndIf;
	
	CreateDocumentsClient(Undefined);
	
EndProcedure

&AtClient
Procedure PostCompletion(Result, AdditionalParameters) Export
	
	ClearMessages();
	
	SelectedDocuments_ = Result;
	
	If SelectedDocuments_ = Undefined Then
		Return;
	EndIf;
	
	NumberOfChangedDocuments = HoldCancelDocumentsServer(SelectedDocuments_, True);
	ManagingTaggingOfConsignmentNoteCommand();
	ManagingTeamTaggingPowerOfAttorney();
	If NumberOfChangedDocuments > 0 Then
		
		ShowUserNotification(
		StrReplace(NStr("vi = 'Đã thực hiện kết chuyển chứng từ (%NumberOfChangedDocuments%)';
						|ru = 'Выполнено проведение документов (%NumberOfChangedDocuments%)';
						|en = 'Posted documents (%NumberOfChangedDocuments%)'; fa = 'Posted documents (%NumberOfChangedDocuments%)';
						|it = 'La registrazione dei documenti è eseguita (%NumberOfChangedDocuments%)';
						|pl = 'Wykonano zatwierdzenie dokumentów (%NumberOfChangedDocuments%)';
						|tr = 'Belgeler kaydedildi (%NumberOfChangedDocuments%)'"), "%NumberOfChangedDocuments%", NumberOfChangedDocuments),
		,,PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtClient
Procedure UndoPostingCompletion(Result, AdditionalParameters) Export
	
	ClearMessages();
	
	SelectedDocuments_ = Result;
	
	If SelectedDocuments_ = Undefined Then
		Return;
	EndIf;
	
	NumberOfChangedDocuments = HoldCancelDocumentsServer(SelectedDocuments_, False);
	ManagingTaggingOfConsignmentNoteCommand();
	ManagingTeamTaggingPowerOfAttorney();
	If NumberOfChangedDocuments > 0 Then
		
		ShowUserNotification(
		StrReplace(NStr("vi = 'Đã thực hiện hủy bỏ kết chuyển chứng từ""""(%NumberOfChangedDocuments%)';
						|ru = 'Выполнена отмена проведения документов (%NumberOfChangedDocuments%)';
						|en = 'Posting of documents (%NumberOfChangedDocuments%) is canceled'; fa = 'Posting of documents (%NumberOfChangedDocuments%) is canceled';
						|it = 'La cancellazione della registrazione dei documenti è eseguita (%NumberOfChangedDocuments%)';
						|pl = 'Wykonano anulowanie zatwierdzenia dokumentów (%NumberOfChangedDocuments%)';
						|tr = 'Belgelerin kaydedilmesi iptal edildi (%NumberOfChangedDocuments%)'"), "%NumberOfChangedDocuments%", NumberOfChangedDocuments),
		,,PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtClient
Procedure MarkToDeleteCompletion(QuestionResult, AdditionalParameters) Export
	
	ClearMessages();
	
	SelectedDocuments_ = AdditionalParameters.SelectedDocuments_;
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	NumberOfChangedDocuments = SetDeletionMarkServer(SelectedDocuments_);
	
	If NumberOfChangedDocuments > 0 Then
		ShowUserNotification(
		StrReplace(NStr("vi = 'Đã đặt dấu xóa (%NumberOfChangedDocuments%)';
						|ru = 'Пометка удаления установлена (%NumberOfChangedDocuments%)';
						|en = 'Deletion mark is set (%NumberOfChangedDocuments%)'; fa = 'Deletion mark is set (%NumberOfChangedDocuments%)';
						|it = 'Il contrassegno per la cancellazione è stato impostato (%NumberOfChangedDocuments%)';
						|pl = 'Znacznik usunięcia został ustawiony (%NumberOfChangedDocuments%)';
						|tr = 'Silme işareti yerleştirildi (%NumberOfChangedDocuments%)'"), "%NumberOfChangedDocuments%", NumberOfChangedDocuments),
		,
		,
		PictureLib.Information32);
	EndIf;

EndProcedure

&AtClient
Procedure ChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "DontChange" Then
		Return;
	EndIf;
	
	SetOnlyViewFormElements(False);
	
EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If ToUseTermsOfSales
		And Not ValueIsFilled(Object.Terms)
		And Object.DocumentCreationOption <> PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
							|ru = 'Поле ""Соглашение"" не заполнено';
							|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
							|it = 'Il campo ""Accordo"" non è compilato';
							|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
							|tr = '""Anlaşma"" alanı doldurulmamış'");
		
		CommonClient.MessageToUser(MessageText,,"Object.Terms",,Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Tiền tệ""';
							|ru = 'Поле ""Валюта"" не заполнено';
							|en = '""Currency"" is required'; fa = '""Currency"" is required';
							|it = 'Il campo ""Valuta"" non è compilato';
							|pl = 'Pole ""Waluta"" nie jest wypełnione';
							|tr = '""Para Birimi"" alanı doldurulmadı'");
		
		CommonClientServer.MessageToUser(MessageText,, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	If Not ThisIsTransferOperation(Form.Object.BusinessOperation) Then
		Columns.Add("PercentRateOfManualDiscount");
		Columns.Add("ManualDiscount");
		Columns.Add("PercentRateOfAutomaticDiscountMarkup");
		Columns.Add("DiscountMarkupAmount");
	EndIf;
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");
	
	Return Columns;
	
EndFunction

// Called via the description of the message from the general module setclient 
//
// Parameters:
// 	Action - String
// 	AdditionalParameter - Structure
// 
&AtClient
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisObject, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
	WhenChangingBucketOnServer();
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
	
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisObject, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	// The warehouse will be inserted later
	StructureOfActionsWithModifiedStrings.Insert("CheckSeriesCalculateStatus", Undefined);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
													New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInContent",
													BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActionsWithAddedStrings.Insert("CheckYourSoftwareOption");
	StructureOfActionsWithAddedStrings.Insert("CheckCharacteristicsByOwner", Undefined);
	StructureOfActionsWithAddedStrings.Insert("CheckFillPackageByOwner", Undefined);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse",
													BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInSalesOptionAttribute",
													New Structure("Products", "SaleRegistrationOption"));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", Undefined);
	StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	AddCollateralActionsOnServer(StructureOfActionsWithAddedStrings,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisObject));
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	WhenChangingBucketOnServer();
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure GoShipping(Command)
	
	ResetTagsAndCaps(Items);
	Items.GoShipping.Check = True;
	Items.Pages.CurrentPage = Items.DeliveryPage;
	
EndProcedure

&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	If Not Object.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
		FillInDeliveryDetails(Item.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	NameOfAddressDetails = GetNameOfDeliveryAddressDetails(Item);
	ProcessAddressChange(Item, NameOfAddressDetails);
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	NameOfAddressDetails = GetNameOfDeliveryAddressDetails(Item);
	AttributesNames = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(NameOfAddressDetails);
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
		Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues],
		Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(
																		GetNameOfDeliveryAddressDetails(Item));
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClientAtServerNoContext
Function GetNameOfDeliveryAddressDetails(Item)
	
	If StrFind(Item.Name, "DeliveryAddressOfCarrier") > 0 Then
		NameOfAddressDetails = "DeliveryAddressOfCarrier";
	Else
		NameOfAddressDetails = "DeliveryAddress";
	EndIf;
	
	Return NameOfAddressDetails;
	
EndFunction

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region EventHandlersOnServer

&AtServer
Procedure WhenChangingBucketOnServer()
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	FillInServiceDetailsOfDocumentForm();
	
	UpdateTextOfInformationLabelGeneratedDocuments();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	ItemArray = New Array;
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, ItemArray, "Enabled",
		Form.Object.ToReturnReusablePackage);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	CachedValues    = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = ParametersForFillingInVATRate(Object);
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_",
												New Structure("Products", "ItemsType"));
	ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionStructureModifiedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("FillInVATRate", ParametersFillInVATRate);
	ActionStructureModifiedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",
												New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsAddedLines = Common.CopyRecursive(ActionStructureModifiedStrings); // - Structure -
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse",
												BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsAddedLines.Insert("FillInSalesOptionAttribute",
												New Structure("Products", "SaleRegistrationOption"));
	StructureOfActionsAddedLines.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	AddCollateralActionsOnServer(StructureOfActionsAddedLines,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales",
													BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsAddedLines.Insert("FillInSalePrice",
													BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	FieldsNames = NamingOfMultiTurnContainerSelectionFields(Object.DocumentCreationOption, True);
	ReusablePackageServer.FillMultiTurnContainersFromStorage(Object,
																	AddressOfContainerInStorage,
																	"Goods",
																	FieldsNames,
																	ActionStructureModifiedStrings,
																	StructureOfActionsAddedLines,
																	CachedValues);
	
	StructureAndCharacteristics = New Structure;
	StructureAndCharacteristics.Insert("FillInFeatureAttribute",
												New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureAndCharacteristics);
	SetsServer.FillInServiceDetails(ThisObject);
	
	For Each CurRow In Object.Goods Do
		If Not ValueIsFilled(CurRow.RegistrationOption)
			And CurRow.ItemsType = Enums.ItemsTypes.ReusablePackage Then
			
			FillInLayoutOptionInRowOfTablePart(CurRow, Object.DocumentCreationOption, Object.Date, Object.NotShipInInstallments);
			
		EndIf;
	EndDo;
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	CalculateTotals_(ThisObject);
	UpdateCaptionTotalSelectedPositions(LabelTotalItemsSelected, Object.Goods.Count());
	UpdateColumnAvailableServer();
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClientAtServerNoContext
Function NamingOfMultiTurnContainerSelectionFields(DocumentCreationOption, ExcludeQuantity = False)
	
	If ExcludeQuantity Then
		
		If DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
			FieldsNames = "Products,Characteristic";
		ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice")
			Or DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee") Then
			
			FieldsNames = "Products,Characteristic,Warehouse";
			
		Else
			FieldsNames = "Products,Characteristic,Warehouse,DateOfShipment";
		EndIf;
		
	Else
		
		If DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
			FieldsNames = "Products,Characteristic,Count";
		ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice")
			Or DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee") Then
			
			FieldsNames = "Products,Characteristic,Count,Warehouse";
			
		Else
			FieldsNames = "Products,Characteristic,Count,Warehouse,DateOfShipment";
		EndIf;
		
	EndIf;
	
	Return FieldsNames;
	
EndFunction

&AtServer
Procedure FillOperationSelectionList(DesignOptionHasBeenChanged = False)
	
	If DesignOptionHasBeenChanged Then
		
		ThisIsImplementation = ThisIsImplementation(Object.DocumentCreationOption);
		
		OperationsOfSale = Items.BusinessOperation.ChoiceList;
		OperationsOfSale.Clear();
		
		If ThisIsImplementation
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
			Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
			
			OperationsOfSale.Add(Enums.BusinessTransactions.SaleToCustomer);
			OperationsOfSale.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
			OperationsOfSale.Add(Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
			OperationsOfSale.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
			If Not ThisIsImplementation 
				And Not Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
				OperationsOfSale.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
			EndIf;
			
		Else
			OperationsOfSale.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
			OperationsOfSale.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
			If UseShipmentWithDeferredTransferOfTitle2_5 Then
				OperationsOfSale.Add(Enums.BusinessTransactions.GoodsShipmentToCustomer);
			EndIf;
		EndIf;
		
		If OperationsOfSale.FindByValue(Object.BusinessOperation) = Undefined Then
			Object.Terms = Undefined;
			Object.BusinessOperation = OperationsOfSale[0].Value;
			BusinessOperationOnChangeServer();
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee)
			And Not Object.ConsignmentSales25 Then
			Object.Terms = Undefined;
			BusinessOperationOnChangeServer();
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			And (Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice)
			And Object.ConsignmentSales25 Then
			Object.Terms = Undefined;
			BusinessOperationOnChangeServer();
		EndIf;
		
	EndIf;
	
	If Not ToUseTermsOfSales Then
		SaleWithDeferredTransferOfTitleIsAllowed = UseShipmentWithDeferredTransferOfTitle;
	ElsIf Not ValueIsFilled(Object.Terms) Then
		SaleWithDeferredTransferOfTitleIsAllowed = False;
	Else
		SetPrivilegedMode(True);
		SaleWithDeferredTransferOfTitleIsAllowed = Common.ObjectAttributeValue(Object.Terms,
																									"SaleWithDeferredTransferOfTitleIsAllowed");
		SetPrivilegedMode(False);
	EndIf;
	
	If Items.Find("BusinessOperation") <> Undefined  Then
		
		If Not UseSalesCommission Then
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
								Enums.BusinessTransactions.TransferToCommissionAgent);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		If Not ToUseTheTransferOfGoodsToStorage Then
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
								Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		If Not GetFormFunctionalOption("UseManagementCompany") Then
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
								Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
							Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
		
		If Not SaleWithDeferredTransferOfTitleIsAllowed Then
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		ElsIf Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee
					And Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
			If ListItem = Undefined Then
				Items.BusinessOperation.ChoiceList.Add(
					Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
			EndIf;
		EndIf;
		
		OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
		If Not DesignOptionHasBeenChanged And OnlyOperation And Not ValueIsFilled(Object.BusinessOperation) Then
			Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
			BusinessOperationOnChangeServer();
		EndIf;
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"BusinessOperation",
			"ReadOnly",
			OnlyOperation And ValueIsFilled(Object.BusinessOperation));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListOfOptionsForRegistrationOfSalesDocuments()
	
	OptionsForRegistrationOfDocuments = Items.GoodsRegistrationOption.ChoiceList;
	OptionsForRegistrationOfDocuments.Clear();
	
	OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.SalesOrder);
	
	If ThisIsImplementation(Object.DocumentCreationOption) Then
		OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
	ElsIf ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		OptionsForRegistrationOfDocuments.Add(Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		
		PartnerOnChangeServer();
		
		PartnerChanged_ = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInShippingDateSelectionList()
	
	MaxAdvanceDate = SalesServer.MaximumAdvancePaymentDate(Object.PaymentScheduleSteps);
	ShipmentDateSelectionList = Items.DateOfShipment.ChoiceList;
	
	If ValueIsFilled(MaxAdvanceDate) Then
		PresentationMaxAdvanceDate = "%MaxAdvanceDate%";
		PresentationMaxAdvanceDate = StrReplace(PresentationMaxAdvanceDate,
													"%MaxAdvanceDate%",
													Format(MaxAdvanceDate,"DLF=DD"));
		
		ShipmentDateSelectionList.Clear();
		ShipmentDateSelectionList.Add(MaxAdvanceDate, PresentationMaxAdvanceDate);
	EndIf;
	
EndProcedure

#EndRegion

#Region Supply

&AtServer
Procedure SetVisibilityOfItemsBySettings()
	
	Items.GoodsNumberOfPackagesDueToReturn.Visible = Object.CreateRequestForReturnOfGoodsFromCustomers;
	Items.AdditionalRequestAttributes.Visible     = Object.CreateRequestForReturnOfGoodsFromCustomers;
	Items.AdditionalRequestAttributes1.Visible    = Object.CreateRequestForReturnOfGoodsFromCustomers;
	Items.AdditionalRequestAttributes2.Visible    = Object.CreateRequestForReturnOfGoodsFromCustomers;
	
	Items.CompletedDocumentsPrint.Visible = (Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal);
	
	Items.ProductsSelectField.Visible               = Object.DisplayRecommendationsToPurchase;
	Items.GoodsNumberOfPackagesyForecast.Visible = Object.DisplayRecommendationsToPurchase;
	Items.LineForecast.Visible                   = Object.DisplayRecommendationsToPurchase 
															And Object.ForecastingMethod = Enums.SalesForecastingMethods.BySalesStatistics;
	Items.DateOfNextOrder.Visible            = Object.DisplayRecommendationsToPurchase;
	
	ThisIsOrder = Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
				Or Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder;
	
	Items.NumberAccordingToCustomerData.Visible = ThisIsOrder;
	Items.DateAccordingToInformationFromCustomer.Visible  = ThisIsOrder;
	Items.FillInAccordingToTheForecast.Visible  = Object.DisplayRecommendationsToPurchase;
	
	SetVisibilityOfShippingDateFormElements();
	SetSoftwareAvailability();
	SetContractAvailability();
	SetDivisionDesign();
	SetSoftwareVisibility();
	
EndProcedure

&AtServer
Function AddressOfMovementTableInRepository()
	
	Return ProvisionInDocumentsServer.AddressOfMovementTableInRepository(ThisObject);
	
EndFunction

&AtServer
Function FillInCollateralFromCollateralStateForm(ActionCode, AddressAnalyst, FillParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.FillInCollateralFromCollateralStateForm(
		ActionCode,
		AddressAnalyst,
		ThisObject);
	
	Mode = ProvisionInDocumentsClientServer.SoftwareStateMode();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	AddressOfTheMovementTable = AddressOfMovementTableInRepository();
	Return AddressOfTheMovementTable;
	
EndFunction

&AtServer
Function ProvidingSetAction(ActionCode)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	If ActionCode = "FLAG_UNITED" Or ActionCode = "FLAG_NOTABLE" Then
		
		Changes = ProvisionInDocumentsServer.SetActionApart(
			ActionCode,
			ThisObject,
			Items.Goods.SelectedRows);
			
		UpdateColumnAvailableServer();
		
	Else
		
		SelectedRows = New Array();
		For Each Id In Items.Goods.SelectedRows Do
			
			TableRow = Object.Goods.FindByID(Id);
			If TableRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
					Or TableRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
					
					Continue;
					
			EndIf;
			
			SelectedRows.Add(Id);
			
		EndDo;
		
		Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode,
			ThisObject,
			SelectedRows);
			
		FillPropertyValues(Result, Changes);
		
		If Changes.ChangesTable <> Undefined Then
			AfterFillingOutCollateral(
				Changes.ChangesTable,
				ProvisionInDocumentsClientServer.ActionSelectionMode(),
				Result);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters, FillParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.WhenChoosingWarehouse(
		ValueSelected,
		ThisObject,
		Items.Goods.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode, FillParameters);
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForSoftwareActions(Form, SecurityOptionAndFlagSeparately, DateOfShipment)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.Goods);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", SecurityOptionAndFlagSeparately);
	
	Return DocumentParameters;
	
EndFunction

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	If Object.SimplifiedFulfillment Or Not AssuranceTeamsAreAvailable(ThisObject) Then
		FormParameters.AcceptableSecurityOptions = New Map();
	EndIf;
	FormParameters.ReadOnly = FormParameters.ReadOnly Or ViewOnlyIsSet;
	
	EmptyLinkForFormHeader = Undefined;
	If Object.DocumentCreationOption
			= PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
			
			EmptyLinkForFormHeader = PredefinedValue("Document.CommercialProposalForCustomer.EmptyRef");
			
	ElsIf Object.DocumentCreationOption
			= PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice") Then
			
			EmptyLinkForFormHeader = PredefinedValue("Document.CustomerInvoice.EmptyRef");
			
	ElsIf Object.DocumentCreationOption
			= PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee") Then
			
			EmptyLinkForFormHeader = PredefinedValue("Document.TransferOfGoodsToBailee.EmptyRef");
			
	Else
			
			EmptyLinkForFormHeader = PredefinedValue("Document.SalesOrder.EmptyRef");
			
	EndIf;
	
	FormParameters.OrderDocument = EmptyLinkForFormHeader;
	
	FormParameters.AcceptableSecurityOptions = ProvisionInDocumentsClient.AllValidSecurityOptions();
	FormParameters.AcceptableSecurityOptions.Delete(
		PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
	
	If FormParameters.ContextOfUse = "TABLE" Then
		
		FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
		
	EndIf;
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddCollateralActionsOnClient(StructureOfActions, StringFields_)
	
	DocumentParameters = ParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately, Undefined);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
	Fields = New Structure(StringFields_);
	If Fields.Property("SupplyOption") Then
		
		FillInShipForOrderPlusImplementationOption = Undefined;
		If UseAdvancedFeaturesOfSalesOrder And Not Object.SimplifiedFulfillment
			And Object.NotShipInInstallments And Object.DateOfShipment = BegOfDay(CommonClient.SessionDate()) Then
			FillInShipForOrderPlusImplementationOption = True;
		EndIf;
		
		StructureOfActions.Insert("FillInShipForOrderPlusImplementationOption", FillInShipForOrderPlusImplementationOption);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, StringFields_, DateOfShipment = Undefined)
	
	DocumentParameters = ParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately, DateOfShipment);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
	Fields = New Structure(StringFields_);
	If Fields.Property("SupplyOption") Then
		
		FillInShipForOrderPlusImplementationOption = Undefined;
		If UseAdvancedFeaturesOfSalesOrder And Not Object.SimplifiedFulfillment
			And Object.NotShipInInstallments And Object.DateOfShipment = BegOfDay(CurrentSessionDate()) Then
			FillInShipForOrderPlusImplementationOption = True;
		EndIf;
		
		StructureOfActions.Insert("FillInShipForOrderPlusImplementationOption", FillInShipForOrderPlusImplementationOption);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfDocumentForm()
	
	DocumentParameters = ParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately, Undefined);
	ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(DocumentParameters);
	
EndProcedure

&AtServer
Procedure EnsuringToSetActionAfterQuestion(Response, Result)
	
	ResultStructure1 = ProvisionInDocumentsServer.SetActionAfterQuestion(Response, Result, ThisObject);
	AfterFillingOutCollateral(
		ResultStructure1.ChangesTable,
		ProvisionInDocumentsClientServer.ActionSelectionMode(),
		ResultStructure1);
	
EndProcedure

&AtClient
Procedure ProvidingSetActionWithQuestion(ActionCode)
	
	Result = ProvidingSetAction(ActionCode);
	
	QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisObject,
		Object.Goods,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
	
	If Not QuestionAsked Then
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
			ThisObject,
			Object.Goods,
			Result,
			"AfterQuestionRemoveFlagShipByOneDate");
			
		EndIf;
		
EndProcedure

&AtServer
Procedure UpdateColumnAvailableServer()
	
	ProvisionInDocumentsServer.UpdateColumnAvailable(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessWarehouseAndBatchSelection(ValueSelected, FormParameters) Export
	
	If Not ProvisionInDocumentsClient.ThereAreSelectedProducts(ValueSelected) Then
		Return;
	EndIf;
	
	ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDateAfterSelectingCollateral(
		ThisObject,
		ValueSelected,
		FormParameters,
		"ProcessSelectionWarehouseAndBatchAfterQuestion");
	
EndProcedure

&AtClient
Procedure ProcessSelectionWarehouseAndBatchAfterQuestion(Response, Var_Parameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	
	Notification = ProcessWarehouseAndBatchSelectionOnServer(
		Var_Parameters.ValueSelected,
		Var_Parameters.FormParameters,
		FillParameters);
	
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(Var_Parameters.FormParameters.Mode);
	ShowUserNotification(NotificationText1, , Notification);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterQuestionOfFillingPackageWithWholePackages(Response, Result) Export
	
	QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
		ThisObject,
		Object.Goods,
		Result,
		Response,
		"AfterQuestionRemoveFlagShipByOneDate");
		
	If Not QuestionAsked Then
		
		EnsuringToSetActionAfterQuestion(Response, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionRemoveFlagShipByOneDate(Response, Result) Export
	
	EnsuringToSetActionAfterQuestion(Response, Result);
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	ThereAreChangesInDateOfShipment = ProvisionInDocumentsServer.UpdateShipmentDate(
		FillParameters,
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.Goods,
		"DateOfShipment");
		
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		ThereAreChangesInDateOfShipment = ThereAreChangesInDateOfShipment Or ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
			Changes.UnloadColumn("String"),
			"DateOfShipment",
			Object.NotShipInInstallments,
			Object.DateOfShipment);
			
	EndIf;
	SetVisibilityOfShippingDateFormElements();
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.Goods);
	Attributes = "Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount,"
				 + DependentPropsByString();
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(Changes, Attributes);
	
	If ThisIsImplementation(Object.DocumentCreationOption)
		Or ThisIsTransferOfGoods(Object.DocumentCreationOption) Then
		
		If ThisIsOrderWithImplementationOfTransfer(Object.DocumentCreationOption) Then
			FillInStatusesOfSpecifyingSerialOrderWithImplementationOfTransfer(SeriesSpecificationParameters);
		Else
			ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SaleOfGoodsAndServices);
		EndIf;
		
	Else
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.OrderDocument);
	EndIf;
	
	StructureOfActions = New Structure();
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = Changes.UnloadColumn("String");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure WhatIsSoftwareOptionWhenChangingOnServer(FillParameters)
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.Goods.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	
EndProcedure

&AtClient
Procedure GoodsCollateralOptionWhenChangedAfterIssue(Response, AdditionalParameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	WhatIsSoftwareOptionWhenChangingOnServer(FillParameters);
	
EndProcedure

&AtServer
Procedure SetSoftwareVisibility()
	
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight
		And UseShipmentByRowsInSalesOrder
		And (Object.DocumentCreationOption
					= Enums.OptionsOfRegisteringSalesDocuments.SalesOrder
			Or Object.DocumentCreationOption
					= Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer
			Or Object.DocumentCreationOption
					= Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
	
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
	Items.DateOfShipment.ToolTip = ProvisionInDocumentsServer.HintShipmentDate();
	
EndProcedure

&AtServer
Function SoftwareSelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Items.Goods.CurrentRow,
		Mode);
	
	Return FormParameters;
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters();
	
	If Not SupplyClient.CheckFilling(
			Object,
			Object.Goods,
			Items.Goods.CurrentRow,
			CheckParameters,
			Object.Warehouse,
			Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	
	If CurrentRow.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder") Then
		FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.OrderDocument;
	Else
		FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.SaleOfGoodsAndServices;
	EndIf;
	
	Return FormParameters;
	
EndFunction

&AtServer
Procedure SetSoftwareAvailability()
	
	DesignOptionIsNotCommercialOffer = 
		Not Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
	
	AssuranceTeamsAreAvailable = AssuranceTeamsAreAvailable(ThisObject);
		
	Items.FillInShipmentDate.Visible                  = AssuranceTeamsAreAvailable;
	Items.GoodsFillInTheWarehouseInSelectedLines.Visible = DesignOptionIsNotCommercialOffer;
	
	VisibilityOfSoftwareOption = Not Object.SimplifiedFulfillment
		And AssuranceTeamsAreAvailable;
	
	Items.GoodsSupplyOption.Visible = VisibilityOfSoftwareOption;
	Items.GoodsShip.Visible = VisibilityOfSoftwareOption;
	Items.GoodsToReserve_.Visible = VisibilityOfSoftwareOption;
	Items.GoodsToSupply.Visible = VisibilityOfSoftwareOption;
	Items.GoodsReserveAsReceived.Visible = VisibilityOfSoftwareOption;
	Items.GoodsNotProvide.Visible = VisibilityOfSoftwareOption;
	Items.GoodsContextMenuShip.Visible = VisibilityOfSoftwareOption;
	Items.GoodsContextMenuToReserve_.Visible = VisibilityOfSoftwareOption;
	Items.GoodsContextMenuToSupply.Visible = VisibilityOfSoftwareOption;
	Items.GoodsContextMenuReserveAsReceived.Visible = VisibilityOfSoftwareOption;
	Items.GoodsContextMenuNotProvide.Visible = VisibilityOfSoftwareOption;
	
	YouCanRemoveFlagSeparately = Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal");
	FlagManagement = YouCanRemoveFlagSeparately And AssuranceTeamsAreAvailable;
	FlagVisibility = AssuranceTeamsAreAvailable;
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsEnableStandAloneSoftware",
		"Visible",
		FlagManagement);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsDisableStandAloneSoftware",
		"Visible",
		FlagManagement);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsWithAssignment",
		"Visible",
		FlagVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsWithAssignment",
		"Enabled",
		FlagManagement);

	Items.GoodsAvailable.Visible = AssuranceTeamsAreAvailable
		And (Not Object.SimplifiedFulfillment
			Or Object.SimplifiedFulfillment
				And (Object.SupplyOption = Enums.SupplyOptions.ReserveAsReceived
					Or Object.SupplyOption = Enums.SupplyOptions.NotRequired
					Or Object.SupplyOption = Enums.SupplyOptions.ToSupply));
	
EndProcedure

&AtClientAtServerNoContext
Function AssuranceTeamsAreAvailable(Form)
	
	Result = (Form.Object.DocumentCreationOption
					 		= PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder")
						Or Form.Object.DocumentCreationOption
							= PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer")
						Or Form.Object.DocumentCreationOption
							= PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice"))
					And Form.UseShipmentByRowsInSalesOrder;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetCollateralOptionAndFlagSeparately(SupplyOption, Terms, SalesOrderStatus)

	OptionAndFlag = New Structure("SupplyOption, WithAssignment", SupplyOption, False);
	Return SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Terms,
		SalesOrderStatus,
		OptionAndFlag);

EndFunction

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfNextOrder" Then
		NextDeliveryDateOnChange(Items.DateOfNextOrder);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
