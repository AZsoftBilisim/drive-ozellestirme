#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the document details by default
//
Procedure FillDefaultAttributes() Export
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Partners") Then
		FillInDocumentBasedOnPartner(FillingData);
	EndIf;

	InitializeCatalog();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// The start date of the agreement must be no less than the date of the document.
	If ValueIsFilled(Date) And ValueIsFilled(ValidityStartDate) Then	
			
		If BegOfDay(Date) > ValidityStartDate Then
				
			ErrorText = NStr("vi = 'Ngày bắt đầu hiệu lực của thỏa thuận không được nhỏ hơn ngày thỏa thuận';
							|ru = 'Дата начала действия соглашения должна быть не меньше даты соглашения';
							|en = 'Agreement effective date cannot be less than the agreement date'; fa = 'Agreement effective date cannot be less than the agreement date';
							|it = 'La data di entrata in vigore dell''accordo non deve essere inferiore la data dell''accordo';
							|pl = 'Data wejścia w życie porozumienia nie może być wcześniejsza od daty porozumienia';
							|tr = 'Anlaşmanın başlangıç tarihi, anlaşma tarihinden daha önce olmamalıdır'");

			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"ValidityStartDate",
				,
				Cancel);

		EndIf;

	EndIf;

	// The expiration date of the agreement must be no less than the date of the document.
	If ValueIsFilled(Date) And ValueIsFilled(ValidityEndDate) Then	
			
		If BegOfDay(Date) > ValidityEndDate Then
				
			ErrorText = NStr("vi = 'Ngày hết hiệu lực của thỏa thuận không được nhỏ hơn ngày thỏa thuận';
							|ru = 'Дата окончания действия соглашения должна быть не меньше даты соглашения';
							|en = 'Agreement expiration date cannot be less than agreement date'; fa = 'Agreement expiration date cannot be less than agreement date';
							|it = 'La data di fine dell''accordo non deve essere inferiore la data dell''accordo';
							|pl = 'Data wygaśnięcia porozumienia nie może być wcześniejsza od daty porozumienia';
							|tr = 'Anlaşmanın sona erme tarihi, anlaşma tarihinden önce olmamalıdır.'");

			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"ValidityEndDate",
				,
				Cancel);

		EndIf;

	EndIf;

	// The expiration date of the agreement must not be less than the start date of the agreement.
	If ValueIsFilled(ValidityStartDate) And ValueIsFilled(ValidityEndDate) Then
				
		If ValidityStartDate > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày hết hiệu lực của thỏa thuận không được nhỏ hơn ngày bắt đầu hiệu lực';
							|ru = 'Дата окончания действия соглашения должна быть не меньше даты начала действия';
							|en = 'Agreement expiration date cannot be less than effective date'; fa = 'Agreement expiration date cannot be less than effective date';
							|it = 'La data di scadenza dell''accordo non deve essere inferiore della data di entrata in vigore';
							|pl = 'Data wygaśnięcia porozumienia nie może być wcześniejsza od daty wejścia w życie';
							|tr = 'Anlaşmanın sona erme tarihi, anlaşmanın başlangıç tarihinden önce olmamalıdır.'");

			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"ValidityEndDate",
				,
				Cancel);
		
		EndIf;

	EndIf;

	If CalculatePackageReturnDateAccordingToCalendar And ReturnReusablePackage And Not ValueIsFilled(ScheduleOfPackageReturn) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra lịch để ghi nhận việc trả lại bao bì theo ngày làm việc.';
						|ru = 'Не указан календарь для учета возврата тары по рабочим дням.';
						|en = 'Calendar for package return tracking by workdays is not specified.'; fa = 'Calendar for package return tracking by workdays is not specified.';
						|it = 'Nessun calendario è specificato per tenere conto della restituzione della confezione nei giorni lavorativi.';
						|pl = 'Nie wskazano kalendarza do ewidencji zwrotu tary w dni robocze.';
						|tr = 'İş gününe göre dara iadelerini hesaba katmak için herhangi bir takvim belirtilmemiştir.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			"Object.ScheduleOfPackageReturn",
			,
			Cancel);
		
	EndIf;
		
	If BusinessOperation = Enums.BusinessTransactions.AgentServicesDelivery
		And UseSpecifiedAgentServices
		And AgentServices.Count() = 0 
	Then
		ErrorText = NStr("vi = 'Chưa chọn dịch vụ môi giới.';
						|ru = 'Не выбраны агентские услуги.';
						|en = 'No agent services selected.'; fa = 'No agent services selected.';
						|it = 'Nessun servizio di agenzia selezionato.';
						|pl = 'Nie wybrano usług agencyjnych.';
						|tr = 'Acente hizmetleri seçilmemiştir.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			"Object.UseSpecifiedAgentServices",
			,
			Cancel);
	EndIf;
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Catalogs.TermsOfPurchaseFromVendors.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If ContractsAreUsed Then
		NotCheckedAttributeArray.Add("ARAPObjectSettings");
		NotCheckedAttributeArray.Add("ARAPCurrency");
	EndIf;
	
	NotCheckedAttributeArray.Add("PaymentScheduleSteps.PackageDepositPercentage");
	If PackageDepositIsRequired Then
		NotCheckedAttributeArray.Add("PaymentScheduleSteps.PaymentPercentage");
		For Each PaymentStage In PaymentScheduleSteps Do
			If Not ValueIsFilled(PaymentStage.PaymentPercentage) And Not ValueIsFilled(PaymentStage.PackageDepositPercentage) Then
				ErrorText = NStr("vi = 'Đối với giai đoạn này cần chỉ ra phần trăm thanh toán hoặc phần trăm ký cược bao bì tại dòng %LineNumber% trong danh sách ""Giai đoạn của lịch biểu thanh toán""';
								|ru = 'Для этапа должен быть указан процент платежа или процент залога за тару в строке %LineNumber% списка ""Этапы графика оплаты""';
								|en = 'Line #%LineNumber%, Payment milestones tab. Percent is required.'; fa = 'Line #%LineNumber%, Payment milestones tab. Percent is required.';
								|it = 'Per la fase, la percentuale di pagamento o la percentuale di deposito per il contenitore deve essere indicata nella riga %LineNumber% della lista ""Fasi del programma di pagamento""';
								|pl = 'Dla etapu należy wskazać procent płatności lub procent kaucji za tarę w wierszu %LineNumber% listy ""Etapy harmonogramu płatności""';
								|tr = 'Ödeme yüzdesi veya dara depozitosunun yüzdesi, ""ödeme planının aşamaları"" listenin %LineNumber% satırında aşama için belirtilmelidir'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", PaymentStage.LineNumber);
				CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("PaymentScheduleSteps", PaymentStage.LineNumber, "PaymentPercentage"),
					,
					Cancel);
			EndIf;
		EndDo;
		
		If PaymentScheduleSteps.Total("PackageDepositPercentage") <> 100 And PaymentScheduleSteps.Count() > 0 Then	
			ErrorText = NStr("vi = 'Tỷ lệ thế chấp bao bì theo tất cả các giai đoạn thanh toán phải bằng 100%';
							|ru = 'Процент залога за тару по всем этапам оплаты должен быть равен 100%';
							|en = 'Percentage of the packaging deposit at all stages of payment should be equal to 100%'; fa = 'Percentage of the packaging deposit at all stages of payment should be equal to 100%';
							|it = 'La percentuale del deposito per l''imballaggio deve essere pari al 100% in tutte le fasi';
							|pl = 'Procent kaucji za opakowanie dla wszystkich etapów płatności powinien wynosić 100%';
							|tr = 'Tüm ödeme aşamaları için dara depozitosunun yüzdesi 100% olmalıdır'");
			ErrorAddress = "Object.PaymentScheduleSteps";
			CommonClientServer.MessageToUser(ErrorText, , ErrorAddress, , Cancel);
		EndIf;
		
	EndIf;
	
	SeparateProcurementOptionIsUsed = False;
	If (BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU)
		And (GetFunctionalOption("UseUninvoicedDeliveries")
			Or GetFunctionalOption("UseGoodsInTransitFromVendors"))
		And (GoodsReceiptOption = Enums.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed
			Or GoodsReceiptOption = Enums.GoodsReceiptOptions.NotDividedByOrdersAndInvoices
			Or GoodsReceiptOption = Enums.GoodsReceiptOptions.NotSeparatedByInvoices) Then
		SeparateProcurementOptionIsUsed = True;

	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale 
		And Not SeparateProcurementOptionIsUsed Then
		NotCheckedAttributeArray.Add("VendorPriceKind");
	EndIf;
	
	OptionsArray = New Array();
	OptionsArray.Add(PredefinedValue("Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed"));
	OptionsArray.Add(PredefinedValue("Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices"));
	OptionsArray.Add(PredefinedValue("Enum.GoodsReceiptOptions.NotSeparatedByInvoices"));
	
	If OptionsArray.Find(GoodsReceiptOption) = Undefined Then
		NotCheckedAttributeArray.Add("DeliveryMethod");
		NotCheckedAttributeArray.Add("CarrierPartner");
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
	EndIf;
	
	If Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(GoodsReceiptOption)
		And GoodsDeliveryClientServer.ShippingIsUsed(DeliveryMethod, 
		GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers")) Then
		CheckedAttributes.Add("Warehouse");
	EndIf;
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);

	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
	CheckAgencyServices(Cancel);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
EndProcedure // Processing of the Fill check()

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.ChangeCatalogConsistencyFlag(
		ThisObject,
		Enums.StatusesOfTermsOfPurchase.NotApproved);
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Catalogs.TermsOfPurchaseFromVendors.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	If ContractsAreUsed Then
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
	EndIf;
	
	If DeletionMark Then
		Status = Enums.StatusesOfTermsOfPurchase.Closed;
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
EndProcedure // Before recording()

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Status                  = Enums.StatusesOfTermsOfPurchase.NotApproved;
	Approved              = False;
	ValidityStartDate      = '00010101';
	ValidityEndDate   = '00010101';

	InitializeCatalog(False);

EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	RemoveServiceLoggers(Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export
	
	TabRow = Table.Add();
	TabRow.AccessValue = Partner;

	If ValueIsFilled(Organization) Then
		TabRow = Table.Add();
		TabRow.AccessValue = Organization;
	EndIf;

	If ValueIsFilled(Warehouse) Then
		TabRow = Table.Add();
		TabRow.AccessValue = Warehouse;
	EndIf;
	
EndProcedure

#Region InitializationAndFilling

// Fills in the agreement with the supplier based on the partner
//
// Parameters:
//	Basis - CatalogRef.Partners - link to the partner.
//
Procedure FillInDocumentBasedOnPartner(Val Basis)
	
	Partner = Basis;
	PurchasesServer.CheckPossibilityOfEnteringBasedOnPartnerSupplierCompetitor(Partner);
	FillDefaultAttributes();
	
EndProcedure

// Fills in the agreement with the supplier in accordance with the selection.
//
// Parameters:
//	FillingData - Structure - Structure with the values filled in.
//
Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("BusinessOperation") Then
		
		BusinessOperation = FillingData.BusinessOperation;
		If BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
			ContractsAreUsed = True;
		EndIf;
	EndIf;
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		PurchasesServer.CheckPossibilityOfEnteringBasedOnPartnerSupplierCompetitor(Partner);
		FillDefaultAttributes();
		
	EndIf;
	
	If FillingData.Property("Organization") Then
		Organization = FillingData.Organization;
	EndIf;
	
EndProcedure

// Initializes the agreement with the supplier
//
Procedure InitializeCatalog(FillInAllDetails = True)

	Manager = Users.CurrentUser();
	MetadataObjectStatus = Metadata().Attributes.Status; // MetadataObjectAttribute
	Status = MetadataObjectStatus.FillValue;
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
	EndIf;

	If FillInAllDetails Then
		
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
		ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(ARAPCurrency);
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse, GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments"));
		ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
		FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation);
		GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
		
		Attributes = New Structure("ContractsAreUsed,ARAPObjectSettings");
		ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, Attributes);
		
	EndIf;
	
EndProcedure

#EndRegion

// Checks Agency agreements for the absence of matching terms and services
// .
Procedure CheckAgencyServices(Cancel) Export
	
	If BusinessOperation <> Enums.BusinessTransactions.AgentServicesDelivery
		Or Status <> Enums.StatusesOfTermsOfPurchase.Valid
			And Status <> Enums.StatusesOfTermsOfPurchase.Closed Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Organization) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Đối với giao dịch kinh tế này cần chỉ ra doanh nghiệp';
												|ru = 'Для данной хозяйственной операции необходимо указание организации';
												|en = 'For this business transaction, company name is required'; fa = 'For this business transaction, company name is required';
												|it = 'Per questa transazione commerciale è richiesto indicare l''organizzazione';
												|pl = 'Dla danej operacji gospodarczej jest wymagane wskazanie firmy';
												|tr = 'Bu ticari işlem için iş yerinin belirtilmesi gerekmektedir'"),ThisObject,"Organization",,Cancel);
	EndIf;
	
	Query = New Query("
	|SELECT DISTINCT
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic
	|INTO SelectedServices
	|FROM
	|	&Services AS Services
	|;
	|///////////////////////////////////////////////
	|// For all services of the principal
	|SELECT
	|	DoubleAgreement.Description AS Description,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS Characteristic
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS DoubleAgreement
	|WHERE
	|	DoubleAgreement.Ref <> &Ref
	|	AND DoubleAgreement.Organization = &Organization
	|	AND DoubleAgreement.Partner = &Partner
	|	AND DoubleAgreement.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|	AND DoubleAgreement.Status IN (VALUE(Enum.StatusesOfTermsOfPurchase.Valid))
	|	AND (NOT DoubleAgreement.UseSpecifiedAgentServices
	|		OR &ForAllServices_)
	|	AND (&ValidityEndDate >= DoubleAgreement.ValidityStartDate
	|		OR &ValidityEndDate = DATETIME(1,1,1))
	|	AND (DoubleAgreement.ValidityEndDate >= &ValidityStartDate
	|		OR DoubleAgreement.ValidityEndDate = DATETIME(1,1,1))
	|
	|
	|UNION ALL
	|// For the specified agency services of the principal
	|SELECT DISTINCT
	|	DoubleAgreement.Description AS Description,
	|	SelectedServices.Products AS Products,
	|	SelectedServices.Characteristic AS Characteristic
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS DoubleAgreement
	|
	|	INNER JOIN SelectedServices AS SelectedServices
	|	ON TRUE
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS DuplicatesOfServices
	|	ON DoubleAgreement.Ref = DuplicatesOfServices.Ref
	|		AND SelectedServices.Products = DuplicatesOfServices.Products
	|		AND SelectedServices.Characteristic = DuplicatesOfServices.Characteristic
	|WHERE
	|	DoubleAgreement.Ref <> &Ref
	|	AND DoubleAgreement.Organization = &Organization
	|	AND DoubleAgreement.Partner = &Partner
	|	AND DoubleAgreement.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|	AND DoubleAgreement.Status IN (VALUE(Enum.StatusesOfTermsOfPurchase.Valid))
	|	AND (NOT (DuplicatesOfServices.Products IS NULL)
	|		OR NOT DoubleAgreement.UseSpecifiedAgentServices
	|	)
	|	AND (&ValidityEndDate >= DoubleAgreement.ValidityStartDate
	|		OR &ValidityEndDate = DATETIME(1,1,1))
	|	AND (DoubleAgreement.ValidityEndDate >= &ValidityStartDate
	|		OR DoubleAgreement.ValidityEndDate = DATETIME(1,1,1))
	|");
	
	Query.SetParameter("Ref",Ref);
	Query.SetParameter("Organization",Organization);
	Query.SetParameter("Partner",Partner);
	Query.SetParameter("Services",AgentServices.Unload(,"Products, Characteristic"));
	Query.SetParameter("ForAllServices_",Not UseSpecifiedAgentServices);
	Query.SetParameter("ValidityStartDate",ValidityStartDate);
	Query.SetParameter("ValidityEndDate",ValidityEndDate);
	
	MessageTemplate = NStr("vi = 'Đã tìm thấy thỏa thuận hiện có %Description%%ForAService%';
							|ru = 'Обнаружено существующее соглашение %Description%%ForAService%';
							|en = 'The existing %Description% %ForAService% agreement is detected'; fa = 'The existing %Description% %ForAService% agreement is detected';
							|it = 'Rilevato accordo esistente %Description%%ForAService%';
							|pl = 'Wykryto istniejącą umowę %Description%%ForAService%';
							|tr = 'Mevcut anlaşma bulundu %Description%%ForAService%'");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		MessageText = StrReplace(MessageTemplate, "%Description%", String(Selection.Description));
		If ValueIsFilled(Selection.Products) Then
			MessageText = StrReplace(MessageText, "%ForAService%", " " + NStr("vi = 'dành cho dịch vụ';
																				|ru = 'для услуги';
																				|en = 'for a service'; fa = 'for a service';
																				|it = 'per il servizio';
																				|pl = 'dla usługi';
																				|tr = 'hizmetler için'") + " " 
				+ Selection.Products + ?(ValueIsFilled(Selection.Characteristic), ", " + Selection.Characteristic, ""));
		Else
			MessageText = StrReplace(MessageText, "%ForAService%", "");
		EndIf;
		CommonClientServer.MessageToUser(MessageText,,,"Object",Cancel);
	EndDo;
	
EndProcedure

Function KeySynchronizationSettings()
	
	Result = New Map;
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Document.VendorContractVendorAgreementRecorder", "DeletionMark");
	
	Return Result;
	
EndFunction

#Region Other

Procedure RemoveServiceLoggers(Cancel)
	
	Query = New Query(
		"SELECT
		|	Recorders.Ref AS Ref
		|FROM
		|	Document.VendorContractVendorAgreementRecorder AS Recorders
		|WHERE
		|	Recorders.ReferenceOrder = &Ref");
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		DocObject = Selection.Ref.GetObject();
		DocObject.Delete();
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
