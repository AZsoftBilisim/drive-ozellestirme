
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseStatusesOfGoodsServicesSales       = GetFunctionalOption("UseStatusesOfGoodsServicesSales");
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
	ParametersStructure = GetParameters(Parameters);
	FillPropertyValues(ThisForm, ParametersStructure);
	
	ThereIsARightToPrintCashReceiptStatement = AccessRight("Insert",Metadata.Documents.CashAccountReceiptNote);
	If Not ThereIsARightToPrintCashReceiptStatement Then
		CreateCashAccountReceiptNote = False;
	EndIf;
	EstablishAvailabilityOfIncomingCashOrder(ThisForm);
	
	RadioButtonSupply = Number(SimplifiedFulfillment);
	
	SalesForecastingMethodFillSelectionList();
	
	InitializeOptionsForProcessingSalesDocuments();
	EstablishAvailabilityOfInvoiceForPaymentOfIncomingCashOrder(ThisForm);
	SetAvailabilityOfCommercialOffer(ThisForm);
	SetCustomerOrderAvailability(ThisForm);
	SetAvailabilityOfRefundRequest(ThisForm);
	SetAvailabilityOfSalesDocument(ThisForm);
	EstablishAvailabilityOfGoodsTransferToCustodian(ThisForm);
	SetAvailabilityVisibilityOfConsignmentNote(ThisForm);
	EstablishAvailabilityOfPowerOfAttorneyToReceiveCash(ThisForm);
	SetCurPageOfDesignOptions(ThisForm);
	SetAvailabilityOfFillingSettings(ThisForm);
	SetSoftwareGroupAvailability(ThisForm);
	
	InstallSoftwareAvailability(ThisForm);
	SetAvailabilityOfPredictionElements(ThisForm);
	
	SetFiscalizationAvailability(ThisForm);
	
	UpdateFiscalEquipmentHyperlink();
	
	Enums.SalesOrderStatuses.FillChoiceList(Items.SalesOrderStatus.ChoiceList, SalesOrderStatus);
	Enums.SalesOrderStatuses.FillChoiceList(Items.SalesOrderStatusOrderImplementation.ChoiceList, SalesOrderStatus);
	Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.FillChoiceList(Items.StatusOfRequestForReturnOfGoodsFromCustomers.ChoiceList, StatusOfRequestForReturnOfGoodsFromCustomers);
	Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.FillChoiceList(Items.StatusOfRequestForReturnOfGoodsFromCustomersOrderImplementation.ChoiceList, StatusOfRequestForReturnOfGoodsFromCustomers);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForcefullyCloseTheForm Then
		Return;
	EndIf;
	
	If Modified And Not SaveParameters And Not Exit Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
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
		
		Cancel = True;
		AdditionalParameters = New Structure;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject, AdditionalParameters),
			NStr("vi = 'Tham số trợ giúp bán hàng đã được thay đổi. Đóng mà không lưu cài đặt?';
				|ru = 'Параметры помощника продаж были изменены. Закрыть без сохранения параметров?';
				|en = 'Sales wizard parameters were changed. Close without saving the parameters?'; fa = 'Sales wizard parameters were changed. Close without saving the parameters?';
				|it = 'Parametri dell''assistente di vendita sono stati modificati. Chiudere senza salvare i parametri?';
				|pl = 'Opcje asystenta sprzedaży zostały zmienione. Zamknij bez zapisywania parametrów?';
				|tr = 'Satış sihirbazının parametreleri değiştirildi. Parametreler kaydedilmeden kapatılsın mı?'"),
			ButtonsList);
		Return;
		
	EndIf;
	
	BeforeCloseCompletion(Cancel);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Cancel)
	
	If SaveParameters Then
		
		ClearMessages();
		
		If CreateCommercialProposal And Not ValueIsFilled(CommercialProposalStatus) Then
		
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền trường ""Trạng thái báo giá""';
					|ru = 'Поле ""Статус коммерческого предложения"" не заполнено';
					|en = '""Sales quotation status"" is required'; fa = '""Sales quotation status"" is required';
					|it = 'Il campo ""Stato dell''offerta commerciale"" non è compilato';
					|pl = 'Pole ""Oferty cenowej"" nie zostało wypełnione';
					|tr = '""Teklifin durumu"" alanı doldurulmamış'"),
				,
				"CommercialProposalStatus",
				,
				Cancel);
			SaveParameters = False;
		
		EndIf;
		
		If UseAdvancedFeaturesOfSalesOrder And CreateSalesOrder And Not ValueIsFilled(SalesOrderStatus) Then
		
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền trường ""Trạng thái đơn hàng của khách""';
					|ru = 'Поле ""Статус заказа клиента"" не заполнено';
					|en = '""Sales order status"" is required'; fa = '""Sales order status"" is required';
					|it = 'Il campo ""Stato dell''ordine cliente"" non è compilato';
					|pl = 'Pole ""Status zamówienia sprzedaży"" nie zostało wypełnione';
					|tr = '""Müşteri siparişinin durumu"" alanı doldurulmamış'"),
				,
				"SalesOrderStatus",
				,
				Cancel);
			SaveParameters = False;
		
		EndIf;
		
		If UseStatusesOfGoodsServicesSales
			And CreateSalesDocument
			And Not ValueIsFilled(StatusOfCustomerInvoice) Then
		
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền trường ""Trạng thái giao hàng""';
					|ru = 'Поле ""Статус реализации"" не заполнено';
					|en = '""Sale status"" is required'; fa = '""Sale status"" is required';
					|it = 'Il campo ""Stato di realizzo"" non è compilato';
					|pl = 'Pole ""Status sprzedaży"" nie zostało wypełnione';
					|tr = '""Satış durumu"" alanı doldurulmamış'"),
				,
				"StatusOfCustomerInvoice",
				,
				Cancel);
			SaveParameters = False;
		
		EndIf;
		
		If Not ValueIsFilled(DocumentCreationOption) Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền trường ""Lập chứng từ""';
					|ru = 'Поле ""Оформить"" не заполнено';
					|en = '""Register"" is required'; fa = '""Register"" is required';
					|it = 'Il campo ""Formalizzare"" non è compilato';
					|pl = 'Pole ""Sporządź"" nie zostało wypełnione';
					|tr = '""Düzenle"" alanı doldurulmamış'"),
				,
				"DocumentCreationOption",
				,
				Cancel);
		EndIf;
		
		If RadioButtonSupply = 1 And Not ValueIsFilled(SupplyOption) Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền trường ""Phương án đảm bảo""';
					|ru = 'Поле ""Вариант обеспечения"" не заполнено';
					|en = 'The ""Supply option"" field cannot be empty'; fa = 'The ""Supply option"" field cannot be empty';
					|it = 'Campo ""Opzione di approvvigionamento"" non è compilato';
					|pl = 'Nie wypełniono pola ""Wariant zaspokojenia"".';
					|tr = '""Teminat seçeneği"" alanı doldurulmamış'"),
				,
				"SupplyOption",
				,
				Cancel);
		EndIf; 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "NotClose" Then
		SaveParameters = False;
	EndIf;
	
	If UserAnswer = "Close" Then
		ForcefullyCloseTheForm = True;
	EndIf;
	
	Cancel = False;
	BeforeCloseCompletion(Cancel);
	If Cancel = True Then
		ForcefullyCloseTheForm = False;
	EndIf;
	
	If ForcefullyCloseTheForm Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters And Not Exit Then
		
		ParametersStructure = GetParameters(ThisForm);
		NotifyChoice(ParametersStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CreateCommercialInvoiceOnChange(Item)
	
	SetAvailabilityOfInvoiceForPayment(ThisForm);
	
EndProcedure

&AtClient
Procedure CreateCashAccountReceiptNoteOnChange(Item)
	
	If Not ThereIsARightToPrintCashReceiptStatement Then
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Không đủ quyền tạo phiếu thu.';
												|ru = 'Недостаточно прав на создание ПКО.';
												|en = 'Insufficient rights to create an ""Incoming payment — Cash account"".'; fa = 'Insufficient rights to create an ""Incoming payment — Cash account"".';
												|it = 'I diritti per creare il Mandato Di Versamento In Cassa.';
												|pl = 'Nie masz wystarczających uprawnień na tworzenie POG.';
												|tr = 'Gelen ödeme - kasa hesabı oluşturmak için yetersiz haklar.'"));
	EndIf;
	
	EstablishAvailabilityOfIncomingCashOrder(ThisForm);
	
EndProcedure

&AtClient
Procedure CreateRequestForReturnOfGoodsFromCustomersOnChange(Item)
	
	SetAvailabilityOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure RadioButtonSupplyOnChange(Item)
	
	SimplifiedFulfillment = Boolean(RadioButtonSupply);
	InstallSoftwareAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure DisplayRecommendationsToPurchaseOnChange(Item)
	
	SetAvailabilityOfPredictionElements(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInGoodsByTermsOfSalesOnChange(Item)
	
	If FillInGoodsByTermsOfSales = False Then
		DisplayRecommendationsToPurchase = False;
	EndIf;
	SetAvailabilityOfPredictionElements(ThisForm);
	
EndProcedure

&AtClient
Procedure IssueAFiscalReceiptOnChange(Item)
	
	Items.PlugInHardwareSettingsImplementation.Visible = IssueAFiscalReceipt;
	Items.SettingsForConnectedHardwareOrderImplementation.Visible = IssueAFiscalReceipt;
	
EndProcedure

&AtClient
Procedure FiscalEquipmentNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	
	OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection", New Structure("NotToOutputError", True));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SaveParameters = True;
	ForcefullyCloseTheForm = False;
	Close();

EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CommercialProposalStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CreateCommercialProposal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CommercialProposalStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SalesOrderStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CreateSalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesOrderStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StatusOfCustomerInvoice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CreateSalesDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StatusOfCustomerInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CommercialProposalStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CommercialProposalStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SalesOrderStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesOrderStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StatusOfCustomerInvoice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StatusOfCustomerInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StatusOfRequestForReturnOfGoodsFromCustomers.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CreateRequestForReturnOfGoodsFromCustomers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StatusOfRequestForReturnOfGoodsFromCustomers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StatusOfRequestForReturnOfGoodsFromCustomers.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StatusOfRequestForReturnOfGoodsFromCustomers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

#Region Other

&AtClientAtServerNoContext
Function GetParameters(Source)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("PrintCustomerInvoiceWorksAndServices",                   Source.PrintCustomerInvoiceWorksAndServices);
	ParametersStructure.Insert("PrintSalesOrder",                          Source.PrintSalesOrder);
	ParametersStructure.Insert("PrintCommercialProposal",               Source.PrintCommercialProposal);
	ParametersStructure.Insert("PrintCashAccountReceiptNote",                Source.PrintCashAccountReceiptNote);
	ParametersStructure.Insert("PrintCustomerInvoice",                Source.PrintCustomerInvoice);
	ParametersStructure.Insert("PrintTheTransferOfGoodsToBailee",              Source.PrintTheTransferOfGoodsToBailee);
	ParametersStructure.Insert("PrintCommercialInvoice",                          Source.PrintCommercialInvoice);
	ParametersStructure.Insert("PrintTaxInvoice",                           Source.PrintTaxInvoice);
	ParametersStructure.Insert("CreateSalesDocument",                      Source.CreateSalesDocument);
	ParametersStructure.Insert("CreateSalesOrder",                         Source.CreateSalesOrder);
	ParametersStructure.Insert("CreateCommercialProposal",              Source.CreateCommercialProposal);
	ParametersStructure.Insert("CreateCashAccountReceiptNote",               Source.CreateCashAccountReceiptNote);
	ParametersStructure.Insert("CreateCommercialInvoice",                         Source.CreateCommercialInvoice);
	ParametersStructure.Insert("SalesOrderStatus",                           Source.SalesOrderStatus);
	ParametersStructure.Insert("CommercialProposalStatus",                Source.CommercialProposalStatus);
	ParametersStructure.Insert("StatusOfCustomerInvoice",                  Source.StatusOfCustomerInvoice);
	ParametersStructure.Insert("CreateTransferOfGoodsToBailee",             Source.CreateTransferOfGoodsToBailee);
	ParametersStructure.Insert("CreateDefaultConsignmentNote",     Source.CreateDefaultConsignmentNote);
	ParametersStructure.Insert("CreateAuthorizationLetterForReceivingCash", Source.CreateAuthorizationLetterForReceivingCash);
	ParametersStructure.Insert("DocumentCreationOption",                   Source.DocumentCreationOption);
	
	ParametersStructure.Insert("CreateRequestForReturnOfGoodsFromCustomers",     Source.CreateRequestForReturnOfGoodsFromCustomers);
	ParametersStructure.Insert("PrintRequestForReturnOfGoodsFromCustomer",      Source.PrintRequestForReturnOfGoodsFromCustomer);
	ParametersStructure.Insert("StatusOfRequestForReturnOfGoodsFromCustomers",        Source.StatusOfRequestForReturnOfGoodsFromCustomers);
	ParametersStructure.Insert("FillInGoodsByTermsOfSales",                   Source.FillInGoodsByTermsOfSales);
	ParametersStructure.Insert("DisplayRecommendationsToPurchase",                Source.DisplayRecommendationsToPurchase);
	ParametersStructure.Insert("ForecastingMethod",                   Source.ForecastingMethod);
	ParametersStructure.Insert("StatisticsCollectionPeriod",                         Source.StatisticsCollectionPeriod);
	ParametersStructure.Insert("SimplifiedFulfillment",                         Source.SimplifiedFulfillment);
	ParametersStructure.Insert("SupplyOption",                            Source.SupplyOption);
	ParametersStructure.Insert("DoNotAskSupply",                   Source.DoNotAskSupply);
	
	ParametersStructure.Insert("IssueAFiscalReceipt",                        Source.IssueAFiscalReceipt);
	
	Return ParametersStructure;
	
EndFunction

// Parameters:
// 	Attribute - Boolean - 
// 	DependentElements - Undefined, Array of FormField, FormField - 
// 	DependentAttribute - Undefined, Boolean -
//  
&AtClientAtServerNoContext
Procedure HandleFlagChange(Attribute, DependentElements = Undefined, DependentAttribute = Undefined)
	
	If TypeOf(DependentElements) = Type("Array") Then
		For Each DependentElement In DependentElements Do
			DependentElement.Enabled = Attribute;
		EndDo;
	ElsIf TypeOf(DependentElements) = Type("FormField") Then
		DependentElements.Enabled = Attribute;
	EndIf;
	
	If Not Attribute Then
		DependentAttribute = Undefined;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfInvoiceForPaymentOfIncomingCashOrder(Form)
	
	HandleFlagChange(
		Form.CreateSalesOrder Or Form.CreateSalesDocument,
		,
		Form.CreateCommercialInvoice);
		
	ArrayOfPrintInvoiceElements = New Array;
	ArrayOfPrintInvoiceElements.Add(Form.Items.PrintCommercialInvoice);
	ArrayOfPrintInvoiceElements.Add(Form.Items.PrintCommercialInvoiceOrderImplementation);
	ArrayOfPrintInvoiceElements.Add(Form.Items.ToPrintTheInvoiceForPaymentImplementation);
	
	HandleFlagChange(
		(Form.CreateSalesOrder Or Form.CreateSalesDocument) And Form.CreateCommercialInvoice,
		ArrayOfPrintInvoiceElements,
		Form.PrintCommercialInvoice);
		
	HandleFlagChange(
		Form.CreateSalesOrder Or Form.CreateSalesDocument,
		,
		Form.CreateCashAccountReceiptNote);
		
	ArrayOfElementsForICO = New Array;
	ArrayOfElementsForICO.Add(Form.Items.PrintCashAccountReceiptNote);
	ArrayOfElementsForICO.Add(Form.Items.PrintCashAccountReceiptNoteOrderImplementation);
	ArrayOfElementsForICO.Add(Form.Items.PrintACashReceipt);
	
	HandleFlagChange(
		(Form.CreateSalesOrder Or Form.CreateSalesDocument) And Form.CreateCashAccountReceiptNote,
		ArrayOfElementsForICO,
		Form.PrintCashAccountReceiptNote);

EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfCommercialOffer(Form)
	
	HandleFlagChange(
		Form.CreateCommercialProposal,
		Form.Items.PrintCommercialProposal,
		Form.PrintCommercialProposal);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCustomerOrderAvailability(Form)
	
	ArrayOfPrintOrderElements = New Array;
	ArrayOfPrintOrderElements.Add(Form.Items.PrintSalesOrder);
	ArrayOfPrintOrderElements.Add(Form.Items.PrintSalesOrderOrderImplementation);
	
	HandleFlagChange(
		Form.CreateSalesOrder,
		ArrayOfPrintOrderElements,
		Form.PrintSalesOrder);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfRefundRequest(Form)
	
	ArrayOfPrintOrderElements = New Array;
	ArrayOfPrintOrderElements.Add(Form.Items.PrintRequestForReturnOfGoodsFromCustomer);
	ArrayOfPrintOrderElements.Add(Form.Items.PrintRequestForReturnOfGoodsFromCustomerOrderImplementation);
	ArrayOfPrintOrderElements.Add(Form.Items.StatusOfRequestForReturnOfGoodsFromCustomers);
	ArrayOfPrintOrderElements.Add(Form.Items.StatusOfRequestForReturnOfGoodsFromCustomersOrderImplementation);
	ArrayOfPrintOrderElements.Add(Form.Items.PrintARequestForTheReturnOfGoodsFromCustomersCustomerOrderTransferOfGoodsToTheCustodian);
	ArrayOfPrintOrderElements.Add(Form.Items.StatusOfTheRequestForTheReturnOfGoodsFromCustomersCustomerOrderTransferOfGoodsToTheCustodian);
	
	HandleFlagChange(
		Form.CreateRequestForReturnOfGoodsFromCustomers,
		ArrayOfPrintOrderElements,
		Form.PrintRequestForReturnOfGoodsFromCustomer);
	
	Items = Form.Items;
	
	UseAdvancedFeaturesOfSalesOrder = Form.UseAdvancedFeaturesOfSalesOrder;
	Items.GroupReturnRequestCreatePrint2.Visible = UseAdvancedFeaturesOfSalesOrder;
	Items.GroupReturnRequestCreatePrintOrderImplementation2.Visible = UseAdvancedFeaturesOfSalesOrder;

	OrderTransfer = Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer");
	Items.GroupRequestForReturnOfGoodsCustomerSOrderTransferOfGoodsToTheCustodian.Visible = Not OrderTransfer;
	Items.GroupPrintRequestForReturnOfGoodsFromCustomersSalesOrderTransferOfGoodsToCustodian.Visible = UseAdvancedFeaturesOfSalesOrder And Not OrderTransfer;
	
	Items.DecorationCustomerSOrder.Visible = Not UseAdvancedFeaturesOfSalesOrder;
	Items.DecorationCustomerSOrderOrderImplementation.Visible = Not UseAdvancedFeaturesOfSalesOrder;
	Items.DecorationSalesOrderTransferOrder.Visible = Not UseAdvancedFeaturesOfSalesOrder;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfInvoiceForPayment(Form)
	
	ArrayOfPrintInvoiceElements = New Array;
	ArrayOfPrintInvoiceElements.Add(Form.Items.PrintCommercialInvoice);
	ArrayOfPrintInvoiceElements.Add(Form.Items.PrintCommercialInvoiceOrderImplementation);
	ArrayOfPrintInvoiceElements.Add(Form.Items.ToPrintTheInvoiceForPaymentImplementation);
	
	HandleFlagChange(
		(Form.CreateSalesOrder Or Form.CreateSalesDocument) And Form.CreateCommercialInvoice,
		ArrayOfPrintInvoiceElements,
		Form.PrintCommercialInvoice);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfSalesDocument(Form)
	
	ArrayOfElementsPrintImplementation = New Array;
	ArrayOfElementsPrintImplementation.Add(Form.Items.PrintSale);
	ArrayOfElementsPrintImplementation.Add(Form.Items.PrintSaleOrderImplementation);
	
	HandleFlagChange(
		Form.CreateSalesDocument,
		ArrayOfElementsPrintImplementation,
		Form.PrintCustomerInvoice);
		
	ArrayOfElementsToPrint = New Array;
	ArrayOfElementsToPrint.Add(Form.Items.PrintCertificate);
	ArrayOfElementsToPrint.Add(Form.Items.PrintCertificateOrderImplementation);
		
	HandleFlagChange(
		Form.CreateSalesDocument,
		ArrayOfElementsToPrint,
		Form.PrintCustomerInvoiceWorksAndServices);
		
	ArrayOfElementsInSF = New Array;
	ArrayOfElementsInSF.Add(Form.Items.PrintTaxInvoice);
	ArrayOfElementsInSF.Add(Form.Items.PrintTaxInvoiceOrderImplementation);
	
	HandleFlagChange(
		Form.CreateSalesDocument Or Form.CreateTransferOfGoodsToBailee,
		ArrayOfElementsInSF,
		Form.PrintTaxInvoice);
	
	ArrayOfElementsInSF = New Array;
	ArrayOfElementsInSF.Add(Form.Items.PrintInvoiceTransferOfItems);
	ArrayOfElementsInSF.Add(Form.Items.PrintInvoiceSalesOrderTransferOfItems);
	
	HandleFlagChange(
		Form.CreateTransferOfGoodsToBailee,
		ArrayOfElementsInSF,
		Form.PrintTaxInvoice);
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfGoodsTransferToCustodian(Form)
	
	PrintElements = New Array;
	PrintElements.Add(Form.Items.PrintTheTransferOfGoodsToBailee);
	PrintElements.Add(Form.Items.PrintTransferCustomerOrderTransferOfGoodsToTheCustodian);
	
	HandleFlagChange(Form.CreateTransferOfGoodsToBailee, PrintElements,
		Form.PrintTheTransferOfGoodsToBailee);
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfIncomingCashOrder(Form)
	
	If Form.ThereIsARightToPrintCashReceiptStatement Then
		ArrayOfElementsForICO = New Array;
		ArrayOfElementsForICO.Add(Form.Items.PrintCashAccountReceiptNote);
		ArrayOfElementsForICO.Add(Form.Items.PrintCashAccountReceiptNoteOrderImplementation);
		ArrayOfElementsForICO.Add(Form.Items.PrintACashReceipt);
			
		HandleFlagChange(
			Form.CreateCashAccountReceiptNote,
			ArrayOfElementsForICO,
			Form.PrintCashAccountReceiptNote); 
			
	Else
		Form.PrintCashAccountReceiptNote = False;
	EndIf;
	
	Form.Items.PrintCashAccountReceiptNote.Enabled = Form.CreateCashAccountReceiptNote And Form.ThereIsARightToPrintCashReceiptStatement;
	Form.Items.PrintCashAccountReceiptNoteOrderImplementation.Enabled =  Form.CreateCashAccountReceiptNote And Form.ThereIsARightToPrintCashReceiptStatement;
	Form.Items.PrintACashReceipt.Enabled =  Form.CreateCashAccountReceiptNote And Form.ThereIsARightToPrintCashReceiptStatement;
	Form.Items.CreateCashAccountReceiptNote.Enabled = Form.ThereIsARightToPrintCashReceiptStatement;
	Form.Items.CreateCashAccountReceiptNoteOrderImplementation.Enabled = Form.ThereIsARightToPrintCashReceiptStatement;
	Form.Items.CreateACashReceiptOrder_3.Enabled = Form.ThereIsARightToPrintCashReceiptStatement;

EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityVisibilityOfConsignmentNote(Form)
	
	Form.Items.BillOfLadingGroup.Enabled = Form.CreateSalesDocument;
	Form.Items.BillOfLadingGroupOrderImplementation.Enabled = Form.CreateSalesDocument;
	Form.Items.GroupBillOfLadingTransferOfGoodsToTheCustodian.Enabled = Form.CreateTransferOfGoodsToBailee;
	Form.Items.GroupBillOfLadingCustomerOrderTransferOfGoodsToTheCustodian.Enabled = Form.CreateTransferOfGoodsToBailee;
	
	If Not Form.CreateSalesDocument
		And Not Form.CreateTransferOfGoodsToBailee Then
		
		Form.CreateDefaultConsignmentNote = False;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfPowerOfAttorneyToReceiveCash(Form)
	
	AvailabilityOfPowerOfAttorney = Form.CreateSalesDocument Or Form.CreateSalesOrder;
	Form.Items.PowerOfAttorneyGroup.Enabled = AvailabilityOfPowerOfAttorney;
	Form.Items.GroupLetterOfAuthoritySales.Enabled = AvailabilityOfPowerOfAttorney; 
	Form.Items.GroupLetterOfAuthoritySalesOrderImplementation.Enabled = AvailabilityOfPowerOfAttorney;
	
	If Not AvailabilityOfPowerOfAttorney Then 
		Form.CreateAuthorizationLetterForReceivingCash = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure InstallSoftwareAvailability(Form)
	
	ThisIsOrderInvoice = Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice")
		Or Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer");
	
	If ThisIsOrderInvoice And Form.SimplifiedFulfillment Then
		
		If Form.SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship") Then
			Form.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
		EndIf;
		
	EndIf;
	
	HandleFlagChange(Form.SimplifiedFulfillment And Not ThisIsOrderInvoice, Form.Items.SupplyOption);
	HandleFlagChange(Form.SimplifiedFulfillment, Form.Items.DoNotAskSupply);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSoftwareGroupAvailability(Form)
	
	ThisIsTransferToGuardian = Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee");
	
	Form.Items.GroupSupply.Visible = Not ThisIsTransferToGuardian;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfPredictionElements(Form)
	
	HandleFlagChange(
		Form.DisplayRecommendationsToPurchase,
		Form.Items.ForecastingMethod);
	
	HandleFlagChange(
		Form.DisplayRecommendationsToPurchase,
		Form.Items.StatisticsCollectionPeriod);
	
	HandleFlagChange(
		Form.FillInGoodsByTermsOfSales,
		Form.Items.DisplayRecommendationsToPurchase);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFiscalizationAvailability(Form)
	
	FiscalizationIsAvailable = RetailSalesServerCall.FiscalizationIsAvailable();
	
	Form.Items.PunchAFiscalReceipt.Visible 					= FiscalizationIsAvailable;
	Form.Items.IssueAFiscalReceiptOrderImplementation.Visible 				= FiscalizationIsAvailable;
	Form.Items.PlugInHardwareSettingsImplementation.Visible 		= FiscalizationIsAvailable And Form.IssueAFiscalReceipt;
	Form.Items.SettingsForConnectedHardwareOrderImplementation.Visible 	= FiscalizationIsAvailable And Form.IssueAFiscalReceipt;
	
EndProcedure

&AtClient
Procedure DocumentCreationOptionOnChange(Item)
	
	SetCurPageOfDesignOptions(ThisForm);
	EstablishAvailabilityOfInvoiceForPaymentOfIncomingCashOrder(ThisForm);
	SetAvailabilityOfCommercialOffer(ThisForm);
	SetCustomerOrderAvailability(ThisForm);
	SetAvailabilityOfRefundRequest(ThisForm);
	SetAvailabilityOfSalesDocument(ThisForm);
	EstablishAvailabilityOfGoodsTransferToCustodian(ThisForm);
	SetAvailabilityVisibilityOfConsignmentNote(ThisForm);
	EstablishAvailabilityOfPowerOfAttorneyToReceiveCash(ThisForm);
	SetAvailabilityOfFillingSettings(ThisForm);
	InstallSoftwareAvailability(ThisObject);
	SetSoftwareGroupAvailability(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCurPageOfDesignOptions(Form)
	
	Items = Form.Items;
	DocumentCreationOption = Form.DocumentCreationOption;
	
	SetDefaultSalesForecastingHeaders(Form);
	
	If DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal") Then
		Items.OptionsPageGroup.CurrentPage = Items.TheGroupSCommercialOffer;
		Form.CreateCommercialProposal = True;
		Form.CreateSalesOrder = False;
		Form.CreateSalesDocument = False;
		Form.CreateRequestForReturnOfGoodsFromCustomers = False;
		Form.CreateTransferOfGoodsToBailee = False;
		Form.IssueAFiscalReceipt = False;
		
	ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder") Then
		Items.OptionsPageGroup.CurrentPage = Items.GroupPageCustomerOrder;
		Form.CreateCommercialProposal = False;
		Form.CreateSalesOrder = True;
		Form.CreateSalesDocument = False;
		Form.CreateTransferOfGoodsToBailee = False;
		Form.IssueAFiscalReceipt = False;
		
	ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice") Then
		Items.OptionsPageGroup.CurrentPage = Items.GroupPageImplementation;
		Form.CreateCommercialProposal = False;
		Form.CreateSalesOrder = False;
		Form.CreateSalesDocument = True;
		Form.CreateRequestForReturnOfGoodsFromCustomers = False;
		Form.CreateTransferOfGoodsToBailee = False;
		
	ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee") Then
		Items.OptionsPageGroup.CurrentPage = Items.GroupPageTransferOfProductsToTheCustodian;
		Form.CreateCommercialProposal = False;
		Form.CreateSalesOrder = False;
		Form.CreateSalesDocument = False;
		Form.CreateRequestForReturnOfGoodsFromCustomers = False;
		Form.CreateTransferOfGoodsToBailee = True;
		Form.IssueAFiscalReceipt = False;
		
		SetSalesForecastingHeadersForProductTransfers(Form);
		
	ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer") Then
		Items.OptionsPageGroup.CurrentPage = Items.GroupPageCustomerOrderTransferOfGoodsToTheCustodian;
		Form.CreateCommercialProposal = False;
		Form.CreateSalesOrder = True;
		Form.CreateSalesDocument = False;
		Form.CreateRequestForReturnOfGoodsFromCustomers = False;
		Form.CreateTransferOfGoodsToBailee = True;
		Form.IssueAFiscalReceipt = False;
		
		SetSalesForecastingHeadersForProductTransfers(Form);
		
	ElsIf DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice") Then
		Items.OptionsPageGroup.CurrentPage = Items.GroupPageCustomerOrderImplementation;
		Form.CreateCommercialProposal = False;
		Form.CreateSalesOrder = True;
		Form.CreateSalesDocument = True;
		Form.StatusOfCustomerInvoice = PredefinedValue("Enum.StatusesOfCustomerInvoices.Shipped");
		Form.CreateTransferOfGoodsToBailee = False;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetDefaultSalesForecastingHeaders(Form)
	
	Items = Form.Items;
	
	Items.DisplayRecommendationsToPurchase.Title = NStr("vi = 'Dự đoán doanh số cho khách hàng';
														|ru = 'Прогнозировать продажу клиенту';
														|en = 'Forecast a sale to customer'; fa = 'پیش‌بینی فروش به مشتری';
														|it = 'Prevedere la vendita al cliente';
														|pl = 'Prognozuj sprzedaż klientowi';
														|tr = 'Müşteriye satışı tahmin et'");
	Items.ForecastingMethod.Title = NStr("vi = 'Phương pháp dự báo bán hàng';
										|ru = 'Способ прогнозирования продаж';
										|en = 'Sales forecasting method'; fa = 'روش پیش‌بینی فروش';
										|it = 'Metodo di previsione delle vendite';
										|pl = 'Sposób prognozowania sprzedaży';
										|tr = 'Satış tahmini yöntemi'");
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSalesForecastingHeadersForProductTransfers(Form)
	
	Items = Form.Items;
	
	Items.DisplayRecommendationsToPurchase.Title = NStr("vi = 'Dự báo việc chuyển giao/giao hàng cho khách';
														|ru = 'Прогнозировать передачу/отгрузку товаров клиенту';
														|en = 'Forecast goods transfer/shipment to customer'; fa = 'Forecast goods transfer/shipment to customer';
														|it = 'Forecast goods transfer/shipment to customer';
														|pl = 'Forecast goods transfer/shipment to customer';
														|tr = 'Ürünlerin müşteriye transferini/sevkiyatını tahmin et'");
	Items.ForecastingMethod.Title = NStr("vi = 'Phương thức dự báo việc chuyển giao/giao hàng cho khách';
										|ru = 'Способ прогнозирования передачи/отгрузки товаров';
										|en = 'Goods transfer/shipment forecasting method'; fa = 'Goods transfer/shipment forecasting method';
										|it = 'Goods transfer/shipment forecasting method';
										|pl = 'Goods transfer/shipment forecasting method';
										|tr = 'Ürün transferi/sevkiyatı tahmini yöntemi'");
	
EndProcedure

&AtServer
Procedure InitializeOptionsForProcessingSalesDocuments()
	
	UseTransferAndStorage = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	UseSalesOrders = GetFunctionalOption("UseSalesOrders");
	UseRequestsForReturnOfGoodsFromCustomers = GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	UseLineByLineShipping = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	UseAgreements = GetFunctionalOption("ToUseTermsOfSales");
	UseSalesPlans = GetFunctionalOption("UseSalesPlans");
	UseSalesCommission = GetFunctionalOption("UseSalesCommission");
	
	Items.DocumentCreationOption.ChoiceList.Clear();
	
	If UseSalesOrders Then
		Items.DocumentCreationOption.ChoiceList.Add(Enums.OptionsOfRegisteringSalesDocuments.SalesOrder);
	EndIf;
	
	Items.DocumentCreationOption.ChoiceList.Add(Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice);
	
	If UseTransferAndStorage Or UseSalesCommission Then
		Items.DocumentCreationOption.ChoiceList.Add(
			Enums.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee);
	EndIf;
	
	If UseSalesOrders Then
		Items.DocumentCreationOption.ChoiceList.Add(Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice);
		If UseTransferAndStorage Or UseSalesCommission Then
			Items.DocumentCreationOption.ChoiceList.Add(
				Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer);
		EndIf;
	EndIf;
	
	If Items.DocumentCreationOption.ChoiceList.Count() > 1 Then
		Items.DocumentCreationOption.ReadOnly = False;
	Else
		Items.DocumentCreationOption.ReadOnly = True;
	EndIf;
	
	FiscalizationIsAvailable = RetailSalesServerCall.FiscalizationIsAvailable();
	Items.FiscalizationGroupOrderImplementation.Visible = FiscalizationIsAvailable;
	Items.FiscalizationImplementationGroup.Visible = FiscalizationIsAvailable;
	
	Items.CreateRequestForReturnOfGoodsFromCustomers.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.CreateRequestForReturnOfGoodsFromCustomersOrderImplementation.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.PrintRequestForReturnOfGoodsFromCustomer.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.PrintRequestForReturnOfGoodsFromCustomerOrderImplementation.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.StatusOfRequestForReturnOfGoodsFromCustomers.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.StatusOfRequestForReturnOfGoodsFromCustomersOrderImplementation.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.CreateARequestForTheReturnOfGoodsFromCustomersCustomerOrderTransferOfGoodsToTheCustodian.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.PrintARequestForTheReturnOfGoodsFromCustomersCustomerOrderTransferOfGoodsToTheCustodian.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	Items.StatusOfTheRequestForTheReturnOfGoodsFromCustomersCustomerOrderTransferOfGoodsToTheCustodian.Visible = UseRequestsForReturnOfGoodsFromCustomers;
	
	Items.SupplyOption.ChoiceList.Clear();
	Items.SupplyOption.ChoiceList.Add(Enums.SupplyOptions.NotRequired);
	Items.SupplyOption.ChoiceList.Add(Enums.SupplyOptions.ToSupply);
	Items.SupplyOption.ChoiceList.Add(Enums.SupplyOptions.ReserveAsReceived);
	Items.SupplyOption.ChoiceList.Add(Enums.SupplyOptions.FromWarehouse);
	Items.SupplyOption.ChoiceList.Add(Enums.SupplyOptions.Ship);
	
	Sales.WhenInitializingOptionsForProcessingSalesDocuments(ThisObject);
	
	Template = NStr("vi = 'Nếu đã chọn trạng thái ""%1"" thì trạng thái này sẽ chỉ được thiết lập khi có các giai đoạn trả trước trong lịch biểu thanh toán';
					|ru = 'Если выбран статус ""%1"", то он будет установлен только при наличии этапов предоплаты в графике оплат';
					|en = 'Selected status ""%1"" will be set only if prepayment milestones are available in the payment schedule'; fa = 'Selected status ""%1"" will be set only if prepayment milestones are available in the payment schedule';
					|it = 'Se è stato selezionato lo stato ""%1"", questo sarà impostato solo in presenza delle fasi di pagamento anticipato nel grafico dei pagamenti';
					|pl = 'Jeśli jest wybrany status ""%1"", to będzie on ustawiony tylko jeśli są etapy przedpłaty w harmonogramie płatności';
					|tr = '""%1"" durumu seçilirse, yalnızca ödeme planında ön ödeme aşamaları varsa ayarlanacaktır'");
	Items.StatusOfCustomerInvoice.ToolTip = StrTemplate(Template, Enums.StatusesOfCustomerInvoices.ForPrepayment);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfFillingSettings(Form)
	
	Items = Form.Items;
	
	UseLineByLineShipping = Form.UseLineByLineShipping;
	UseAgreements = Form.UseAgreements;
	UseSalesPlans = Form.UseSalesPlans;
	UseAdvancedFeaturesOfSalesOrder = Form.UseAdvancedFeaturesOfSalesOrder;
	
	ThisIsOrder = Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder")
				Or Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee")
				Or Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer")
				Or Form.DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice");
	
	Items.SupplyOption.Visible = UseLineByLineShipping And ThisIsOrder;
	Items.IndentTheActionAndTheFlag.Visible = UseLineByLineShipping And ThisIsOrder;
	Items.SoftwareManagementSwitch.Visible = UseLineByLineShipping And ThisIsOrder;
	Items.RadioButtonSupply.Visible = UseLineByLineShipping And ThisIsOrder;
	Items.DoNotAskSupply.Visible = UseLineByLineShipping And ThisIsOrder;
	Items.FillInGoodsByTermsOfSales.Visible = UseAgreements
	               And Form.DocumentCreationOption <> PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal");
	Items.DisplayRecommendationsToPurchase.Visible = UseAgreements And ThisIsOrder And UseAdvancedFeaturesOfSalesOrder;
	Items.ForecastingMethod.Visible = ThisIsOrder And UseAgreements And UseSalesPlans And UseAdvancedFeaturesOfSalesOrder;
	Items.StatisticsCollectionPeriod.Visible = UseAgreements And ThisIsOrder And UseAdvancedFeaturesOfSalesOrder;
	Items.DaysDecoration.Visible = UseAgreements And ThisIsOrder And UseAdvancedFeaturesOfSalesOrder;
	
	If Not ThisIsOrder Then
		Form.DisplayRecommendationsToPurchase = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SalesForecastingMethodFillSelectionList()
	
	ChoiceList = Items.ForecastingMethod.ChoiceList;
	ChoiceList.Clear();
	
	For Each EnumerationElement In Enums.SalesForecastingMethods Do
		
		If EnumerationElement = Enums.SalesForecastingMethods.BySalesPlans
			And Not AccessRight("Read",Metadata.AccumulationRegisters.SalesPlans) Then
			
			If ForecastingMethod = EnumerationElement Then
				ForecastingMethod = Undefined;
			EndIf; 
			Continue;

		EndIf; 
		
		ChoiceList.Add(EnumerationElement);
		
	EndDo; 
	
EndProcedure

&AtServer
Procedure UpdateFiscalEquipmentHyperlink()
	
	SettingsForConnectedHardware = New FormattedString(NStr("vi = 'Tùy chỉnh';
															|ru = 'Настройка';
															|en = 'Setting'; fa = 'تنظیم';
															|it = 'Impostazione';
															|pl = 'Konfiguracja';
															|tr = 'Ayarlar'"),, 
		StyleColors.HyperlinkColor,, "ConfigureHardware_");
	
EndProcedure

#EndRegion

#EndRegion
