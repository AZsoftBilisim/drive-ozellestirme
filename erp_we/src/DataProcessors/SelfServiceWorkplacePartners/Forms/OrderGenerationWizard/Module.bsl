
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Partner") Then
		Partner = Parameters.Partner;
	Else
		Return;
	EndIf;
	
	If Parameters.Property("Terms") Then
		Terms = Parameters.Terms;
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	CustomerTermsOfSales.Description AS AgreementLine,
		|	CustomerTermsOfSales.PaymentSchedule,
		|	ISNULL(PaymentSchedules.PaymentMethod, CustomerTermsOfSales.PaymentMethod) AS PaymentMethod,
		|	CustomerTermsOfSales.Currency,
		|	CustomerTermsOfSales.PriceIncludesVAT,
		|	CustomerTermsOfSales.Counterparty,
		|	CustomerTermsOfSales.Organization,
		|	CustomerTermsOfSales.Warehouse,
		|	CustomerTermsOfSales.BusinessOperation,
		|	CustomerTermsOfSales.ContractsAreUsed,
		|	CustomerTermsOfSales.ContactPerson,
		|	CustomerTermsOfSales.ARAPObjectSettings,
		|	CustomerTermsOfSales.ReturnReusablePackage AS ToReturnReusablePackage,
		|	CustomerTermsOfSales.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
		|	CustomerTermsOfSales.PackageDepositIsRequired AS PackageDepositIsRequired, 
		|	CustomerTermsOfSales.DeliveryPlanning AS DeliveryPlanning, 
		|	&Partner AS Partner
		|FROM
		|	Catalog.TermsOfSale AS CustomerTermsOfSales
		|		LEFT JOIN Catalog.PaymentSchedules AS PaymentSchedules
		|		ON CustomerTermsOfSales.PaymentSchedule = PaymentSchedules.Ref
		|WHERE
		|	CustomerTermsOfSales.Ref = &Terms";
		
		Query.SetParameter("Terms", Terms);
		Query.SetParameter("Partner", Partner);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FillPropertyValues(ThisForm,Selection);
		EndIf;
		
	Else
		
		Cancel = True;
		Return;
		
	EndIf;
	
	If Parameters.Property("ContactPerson") Then
		ContactPerson = Parameters.ContactPerson;
		If Parameters.Property("PartnerAuthorized") And Not Parameters.PartnerAuthorized Then
			AuthorizationObject = ContactPerson;
		Else
			AuthorizationObject = Partner;
		EndIf;
	Else
		AuthorizationObject = Partner;
	EndIf;
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If Parameters.Property("Warehouse") Then
		Warehouse = Parameters.Warehouse;
		WarehouseIsAGroupOfWarehouses = Common.ObjectAttributeValue(Warehouse, "IsFolder");
	EndIf;
	
	FillInSalesVATTaxation();
	
	If Parameters.Property("BucketAddress") Then
		CreateProductsTableBasedOnBasketData(Parameters.BucketAddress);
	EndIf;
	
	OrderIssueOption = 1;
	
	TemplateSummary = DataProcessors.SelfServiceWorkplacePartners.GetTemplate("RegisterOrder").GetText();
	SelfServiceServer.SetBackgroundColorOfHTML5Information(TemplateSummary);
	
	If Not ValueIsFilled(ContactPerson) Then
		ContactPerson = PartnersAndCounterparties.GetDefaultPartnerContactPerson(Partner);
	EndIf;
	
	UseDeliveryManagement = GetFunctionalOption("UseDeliveryManagement");
	DeliveryMethod = Enums.TransportMethods.SelfPickup;
	DeliveryMethod25 = Enums.TransportMethods25.SelfPickup;
	GoodsDelivery.SetAvailabilityOfDeliveryAddresses(Items);
	
	AddressFillingParameters = New Structure;
	AddressFillingParameters.Insert("Partner", Partner);
	AddressFillingParameters.Insert("Ref", Documents.CustomerInvoice.EmptyRef());
	FillInAndSetDeliveryAttributesServer("Partner");
	
	If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
		And Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
		NotShipInInstallments = True;
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		GoodsDelivery.FillInListsForSelectingRecipientSenderAddresses(
			Items,
			AddressFillingParameters,
			True);
		
		SetDeliveryPage(Items, DeliveryMethod25);
		
	Else
		
		GoodsDelivery.FillInListsForSelectingRecipientSenderAddresses(
			Items,
			AddressFillingParameters);
		
	EndIf;
	
	AvailabilityControlServer(Selection);
	SalesServer.FillInAddressSelectionList(Items.DeliveryAddress, Partner);
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CounterpartyOnChange(Item)
	
	If ContractsAreUsed Then
		CounterpartyOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	FillInSalesVATTaxation();
	
EndProcedure

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	If Not NotShipInInstallments Then
		DateOfShipment = '00010101';
	EndIf;
	Items.DateOfShipment.Visible = NotShipInInstallments;
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CurrentSessionDate = CommonClient.SessionDate();
	
	If ValueIsFilled(DateOfShipment) And DateOfShipment < BegOfDay(CurrentSessionDate) Then
		DateOfShipment = BegOfDay(CurrentSessionDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure PickedGoodsCalculatedDiscountsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "PickedGoodsCalculatedDiscountsProducts" 
		Or Field.Name = "PickedGoodsCalculatedDiscountsCharacteristic" Then
		
		OpenProductItemCard();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryMethod25OnChange(Item)
	
	SetDeliveryPage(Items, DeliveryMethod25);
	If Not ValueIsFilled(DeliveryPoint) Then
		
		DeliveryPoint = DefaultDeliveryPoint(Partner);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure DeliveryMethodOnChange(Item)
	
	If DeliveryMethod = PredefinedValue("Enum.TransportMethods.SelfPickup") Then
		DeliveryTimeFrom = Undefined;
		DeliveryTimeTo = Undefined;
		GoodsDeliveryClientServer.SetDeliveryPage(Items,DeliveryMethod)
	Else
		FillInAndSetDeliveryAttributesServer(Item.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	GoodsDeliveryClient.WhenChangingAddressPresentation(
	    Item,
		ThisForm["DeliveryAddress"],
		ThisForm["DeliveryAddressFieldValues"]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	DeliveryAddressOnChange(Item);
	
EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		ThisForm,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	DeliveryAddressOnChange(Item);
	
	DeliveryDetails_ = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails();
	FillPropertyValues(DeliveryDetails_, ThisForm);
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, DeliveryDetails_, Item.Name, ValueSelected);
	FillPropertyValues(ThisForm, DeliveryDetails_);
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	NavigateThroughPages(Command);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	NavigateThroughPages(Command);
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	CurrentData = Items.PickedGoodsCalculatedDiscounts.CurrentData;
	DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, FillInStructureUsingFormDetails(), ThisForm,
	                                                  SelfServiceClient.AdditionalParametersAppliedDiscounts());
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//Priority
	
	TMCommonUse.SetConditionalAppearanceOfPriority(ThisObject);
	
	//Package

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedProductsCalculatedDiscountsUnits.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PickedGoodsCalculatedDiscounts.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);

	//Characteristic

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PickedGoodsCalculatedDiscountsCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PickedGoodsCalculatedDiscounts.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	
EndProcedure

&AtServer
Function FillInStructureUsingFormDetails()
	
	StructureForCalculatingDiscounts = New Structure;
	
	StructureForCalculatingDiscounts.Insert("Ref",Documents.SalesOrder.EmptyRef());
	StructureForCalculatingDiscounts.Insert("Date",CurrentSessionDate());
	StructureForCalculatingDiscounts.Insert("Terms",Terms);
	StructureForCalculatingDiscounts.Insert("Warehouse",Warehouse);
	StructureForCalculatingDiscounts.Insert("LoyaltyCard",Catalogs.LoyaltyCards.EmptyRef());
	StructureForCalculatingDiscounts.Insert("Partner",Partner);
	StructureForCalculatingDiscounts.Insert("PaymentSchedule",PaymentSchedule);
	StructureForCalculatingDiscounts.Insert("PaymentMethod",PaymentMethod);
	StructureForCalculatingDiscounts.Insert("Currency",Currency);
	StructureForCalculatingDiscounts.Insert("Counterparty",Counterparty);
	StructureForCalculatingDiscounts.Insert("ContactPerson", ContactPerson);
	StructureForCalculatingDiscounts.Insert("Manager",Undefined);
	StructureForCalculatingDiscounts.Insert("Organization",Organization);
	StructureForCalculatingDiscounts.Insert("VATTaxation",VATTaxation);
	StructureForCalculatingDiscounts.Insert("PriceIncludesVAT",PriceIncludesVAT);
	StructureForCalculatingDiscounts.Insert("DocumentAmount",DocumentAmount);
	StructureForCalculatingDiscounts.Insert("DiscountsAreCalculated",False);
	StructureForCalculatingDiscounts.Insert("DateOfShipment",DateOfShipment);
	StructureForCalculatingDiscounts.Insert("AdditionalInformation",AdditionalInformation);
	StructureForCalculatingDiscounts.Insert("BusinessOperation",BusinessOperation);
	StructureForCalculatingDiscounts.Insert("DeliveryTimeFrom",DeliveryTimeFrom);
	StructureForCalculatingDiscounts.Insert("DeliveryTimeTo",DeliveryTimeTo);
	StructureForCalculatingDiscounts.Insert("AdditionalDeliveryInformation",AdditionalDeliveryInformation);
	StructureForCalculatingDiscounts.Insert("DeliveryZone",DeliveryZone);
	StructureForCalculatingDiscounts.Insert("CarrierPartner",CarrierPartner);
	StructureForCalculatingDiscounts.Insert("DeliveryAddress", DeliveryAddress);
	StructureForCalculatingDiscounts.Insert("ToReturnReusablePackage", ToReturnReusablePackage);
	StructureForCalculatingDiscounts.Insert("ReusablePackageReturnCycleLength", ReusablePackageReturnCycleLength);
	StructureForCalculatingDiscounts.Insert("PackageDepositIsRequired", PackageDepositIsRequired);

	StructureForCalculatingDiscounts.Insert("NotShipInInstallments",NotShipInInstallments);
	If ContractsAreUsed Then
		StructureForCalculatingDiscounts.Insert("Contract",Contract);
	EndIf;
	
	StructureForCalculatingDiscounts.Insert("Goods",PickedGoodsCalculatedDiscounts);
	StructureForCalculatingDiscounts.Insert("DiscountsMarkups",DiscountsMarkups);
	StructureForCalculatingDiscounts.Insert("PaymentScheduleSteps",PaymentScheduleSteps);
	StructureForCalculatingDiscounts.Insert("AuthorizationObject", AuthorizationObject);
	StructureForCalculatingDiscounts.Insert("Priority", Priority);
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		
		StructureForCalculatingDiscounts.Insert("DeliveryMethod", DeliveryMethod);
		StructureForCalculatingDiscounts.Insert("DeliveryAddressFieldValues", DeliveryAddressFieldValues);
		StructureForCalculatingDiscounts.Insert("DeliveryAddressOfCarrier", DeliveryAddressOfCarrier);
		StructureForCalculatingDiscounts.Insert(
			"DeliveryAddressOfCarrierFieldValues",
			DeliveryAddressOfCarrierFieldValues);
		
	ElsIf GoodsDeliveryClientServer.UsedDelivery25() Then
		
		DeliveryIsRequired = (DeliveryMethod25 = Enums.TransportMethods25.OwnDelivery);
		StructureForCalculatingDiscounts.Insert("DeliveryIsRequired", DeliveryIsRequired);
		StructureForCalculatingDiscounts.Insert("DeliveryMethod25", DeliveryMethod25);
		
		If DeliveryIsRequired Then
			
			If Not ValueIsFilled(DeliveryPlanning) Then
				
				DeliveryPlanning = GoodsDelivery.TypeOfDeliveryPlanningByPartnerAgreement(
					Partner,
					Terms);
				
			EndIf;
			
			StructureForCalculatingDiscounts.Insert("DeliveryPoint", DeliveryPoint);
			StructureForCalculatingDiscounts.Insert("DeliveryPlanning", DeliveryPlanning);
			StructureForCalculatingDiscounts.Insert(
				"DeliverySpecificationMethod",
				Enums.DeliverySpecificationMethods.ForWholeDocument);
			
		EndIf;
		
	EndIf;
	
	Return StructureForCalculatingDiscounts;
	
EndFunction

&AtServer
Procedure CalculateDiscounts()
	
	StructureForCalculatingDiscounts = FillInStructureUsingFormDetails();
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject = True;
	ParametersStructure1.OnlyPreliminaryCalculation = False;
	ParametersStructure1.RestoreManagedDiscounts = False;
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(StructureForCalculatingDiscounts,ParametersStructure1);
	AddressOfAppliedDiscountsInTheTemporaryStorage = 
		PutToTempStorage(AppliedDiscounts,UUID);
	DocumentAmount = StructureForCalculatingDiscounts.DocumentAmount;
	
EndProcedure

&AtServer
Procedure AvailabilityControlServer(Data)
	
	Items.PaymentMethod.ReadOnly = ValueIsFilled(PaymentMethod);
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Not GetFunctionalOption("UseDiscountsMarkupsInSales") Then
		Items.GroupProductsDiscountsMargins.Visible = False;
		Items.DecorationProducts.Title = NStr("vi = 'Hãy kiểm tra hàng hóa đã lọc ra để lập đơn hàng';
												|ru = 'Проверьте отобранные для оформления заказа товары';
												|en = 'Check the goods selected for the order'; fa = 'Check the goods selected for the order';
												|it = 'Controllate le merci selezionate per la registrazione dell''ordine';
												|pl = 'Sprawdź wybrane do sporządzenia zamówienia wiersze pozycji';
												|tr = 'Ödeme için seçilen ürünleri kontrol et'");
	EndIf;
	
	SelfServiceServer.ManagingCounterpartyFormElement(ThisForm, Data, Items.Counterparty);
	SelfServiceServer.ManagingContractFormElement(ThisForm, Items.Contract, ContractsAreUsed);
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		ShowHideDeliveryDetails();
		
	Else
		
		Items.DeliveryAddress.Visible = Not UseDeliveryManagement;
		Items.RecipientDeliveryAddress.Visible = UseDeliveryManagement;
		
	EndIf;
	
	Items.DeliveryGroup.Visible                          = UseDeliveryManagement;
	
	If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
		And Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
		Items.NotShipInInstallments.Visible = False;
	EndIf;
	Items.DateOfShipment.Visible = NotShipInInstallments;
	
EndProcedure

&AtClient
Procedure FillInSummaryInformation()
	
	Summary = TemplateSummary;
	
	Summary = StrReplace(Summary,"#AgreementWithCustomer#",AgreementLine);
	Summary = StrReplace(Summary,"#Warehouse#",Warehouse);
	Summary = StrReplace(Summary,"#PaymentSchedule#",PaymentSchedule);
	Summary = StrReplace(Summary,"#PaymentMethod#",PaymentMethod);
	If Not UsePartnersAsCounterparties Then
		Summary = StrReplace(Summary,"#Counterparty#",Counterparty);
		Summary = StrReplace(Summary,"#CP#","");
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(Summary,"#CP#");
	EndIf;
	Summary = StrReplace(Summary,"#Priority#", Priority);
	Summary = StrReplace(Summary,"#ContactPerson#", ContactPerson);
	Summary = StrReplace(Summary,"#VATTaxation#",VATTaxation);
	Summary = StrReplace(Summary,"#DeliveryAddress#",DeliveryAddress);
	Summary = StrReplace(Summary,"#DateOfShipment#",Format(DateOfShipment,"DLF=D")); 
	Summary = StrReplace(Summary,"#NotShipInInstallments#",
	                                ?(NotShipInInstallments,NStr("vi = 'Không giao hàng theo từng phần';
																|ru = 'Не отгружать частями';
																|en = 'Send in one shipment'; fa = 'ارسال در یک محموله';
																|it = 'Non spedire in parti';
																|pl = 'Nie wysyłaj częściowo';
																|tr = 'Parçalar halinde sevk etmeyin'"),NStr("vi = 'Có thể giao hàng theo từng phần';
																									|ru = 'Возможна отгрузка частями';
																									|en = 'Ship in installments is possible'; fa = 'Ship in installments is possible';
																									|it = 'È possibile la spedizione in parti';
																									|pl = 'Jest możliwa wysyłka częściami';
																									|tr = 'Bölümlerle sevkiyat mümkün'")));
	Summary = StrReplace(Summary,"#NumberOfPositions#",String(PickedGoodsCalculatedDiscounts.Count()));
	Summary = StrReplace(Summary,"#DocumentAmount#",Format(DocumentAmount,"NFD=2"));
	Summary = StrReplace(Summary,"#Currency#",Currency);
	If UseDeliveryManagement Then
		DeliveryDetails_ = NStr("vi = 'Phương thức giao nhận';
								|ru = 'Способ доставки';
								|en = 'Delivery method'; fa = 'روش تحویل';
								|it = 'Metodo di consegna';
								|pl = 'Sposób dostarczenia';
								|tr = 'Teslimat yöntemi'") + ": <EM>"
			+ DeliveryMethod + "</EM>" + "<BR>";
		If ValueIsFilled(DeliveryTimeFrom)
			Or ValueIsFilled(DeliveryTimeTo) Then
			DeliveryDetails_ = DeliveryDetails_
				+ NStr("vi = 'Thời gian giao hàng mong muốn';
						|ru = 'Желаемое время доставки';
						|en = 'Required delivery time'; fa = 'زمان تحویل لازم';
						|it = 'Orario di consegna preferibile';
						|pl = 'Pożądany czas dostawy';
						|tr = 'İstenilen teslimat süresi'") +": <EM>"
				+ ?(ValueIsFilled(DeliveryTimeFrom), NStr("vi = 'c';
															|ru = 'c';
															|en = 'c'; fa = 'از';
															|it = 'c';
															|pl = 'c';
															|tr = 'c'") + " " + Format(DeliveryTimeFrom,"DF=HH:mm; DLF=T") + " ","")
				+ ?(ValueIsFilled(DeliveryTimeTo),NStr("vi = 'đến';
														|ru = 'до';
														|en = 'to'; fa = 'تا';
														|it = 'al';
														|pl = 'do';
														|tr = 'kadar'") + " " + Format(DeliveryTimeTo,"DF=HH:mm; DLF=T"),"")
				+ "</EM>" + "<BR>";
		EndIf;
	Else
		DeliveryDetails_ = "";
	EndIf;
	Summary  = StrReplace(Summary,"#DeliveryDetails#",DeliveryDetails_);
	
	LineStagesOfPaymentSchedule = "";
	
	If PaymentScheduleSteps.Count() = 0 Then
		TMCommonUseClientServer.RemoveSubstringFromString(Summary,"#PS#")
	Else
		For Each String In PaymentScheduleSteps Do
			
			LineStagesOfPaymentSchedule = LineStagesOfPaymentSchedule +  Format(String.PaymentDate,"DLF=D") 
			                           + " - " + String.PaymentOption + ": "
			                           + Format(String.PaymentAmount,"NFD=2") + " "
			                           + String(Currency)+ " (" + String.PaymentPercentage 
			                           + " "  +  NStr("vi = '% từ số tiền đặt hàng)';
														|ru = '% от суммы заказа)';
														|en = '% of the order amount)'; fa = '% of the order amount)';
														|it = '% dalla somma dell''ordine)';
														|pl = '% od wartości zamówienia)';
														|tr = 'sipariş tutarından %)'") + " " + "<br>";
			
		EndDo;
		Summary = StrReplace(Summary,"#PS#","");	
	EndIf;
	
	Summary = StrReplace(Summary,"#PaymentScheduleStage#",LineStagesOfPaymentSchedule);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SelfServiceServer.ManagingContractFormElement(ThisForm, Items.Contract, ContractsAreUsed);
	
EndProcedure 

&AtClient
Function PageClickConditionsNotMet(Command)
	
	Cancel = False;
	ClearMessages();
	
	If Items.Pages_Main.CurrentPage = Items.AdditionalAttributesPage Then
		If Command.Name = "Next" Then
			
			If Not ValueIsFilled(PaymentMethod) Then
				CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra biểu mẫu thanh toán.';
														|ru = 'Не указана форма оплаты.';
														|en = 'Payment method is not specified.'; fa = 'Payment method is not specified.';
														|it = 'La forma di pagamento non è indicata.';
														|pl = 'Nie wskazano formy płatności.';
														|tr = 'Ödeme formu belirtilmedi.'"),,"PaymentMethod");
				Cancel = True;
			EndIf;
			
			If Not ValueIsFilled(Counterparty) Then
				CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra đối tác.';
														|ru = 'Не указан контрагент.';
														|en = 'Counterparty is not specified.'; fa = 'Counterparty is not specified.';
														|it = 'Nessun contraente specificato.';
														|pl = 'Nie wskazano kontrahenta.';
														|tr = 'Cari hesap belirtilmedi.'"),,"Counterparty");
				Cancel = True;
			EndIf;
			
			If ContractsAreUsed And Not ValueIsFilled(Contract) Then
				CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra hợp đồng.';
														|ru = 'Не указан договор.';
														|en = 'Contract is not specified.'; fa = 'Contract is not specified.';
														|it = 'Nessun contratto specificato.';
														|pl = 'Nie wskazano kontraktu.';
														|tr = 'Sözleşme belirtilmedi.'"),,"Contract");
				Cancel = True;
			EndIf;
			
			UsedDelivery20 = GoodsDeliveryClientServer.UsedDelivery20();
			UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
			
			If UsedDelivery20 Then
				
				If Not ValueIsFilled(DeliveryMethod)
				 Or DeliveryMethod =  PredefinedValue("Enum.TransportMethods.SelfPickup") Then
					// No required fields;
				ElsIf DeliveryMethod = PredefinedValue("Enum.TransportMethods.ToCustomer")
						And Not ValueIsFilled(DeliveryAddress) Then
					
					MessageText = NStr("vi = 'Chưa điền địa chỉ giao hàng.';
										|ru = 'Не заполнен адрес доставки.';
										|en = 'Delivery address is not filled in.'; fa = 'Delivery address is not filled in.';
										|it = 'Indirizzo di consegna non compilato.';
										|pl = 'Nie wypełniono adresu dostawy.';
										|tr = 'Teslimat adresi belirtilmedi.'");
					CommonClient.MessageToUser(MessageText,, "DeliveryAddress",, Cancel);
					
				EndIf;
				
			EndIf;
			
			If UsedDelivery25
				And DeliveryMethod25 = PredefinedValue("Enum.TransportMethods25.OwnDelivery")
				And Not ValueIsFilled(DeliveryPoint) Then 
				
				MessageText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Точка доставки';
																			|vi = 'Delivery point';
																			|en = 'Delivery point'; fa = 'نقطه تحویل';
																			|it = 'Delivery point';
																			|pl = 'Delivery point';
																			|tr = 'Teslimat noktası'"));
				CommonClient.MessageToUser(MessageText,, Items.DeliveryPoint.Name,, Cancel);
				
			EndIf;
			
		EndIf;
		
	ElsIf Items.Pages_Main.CurrentPage = Items.GoodsPage Then	 
		
		If PickedGoodsCalculatedDiscounts.Count() = 0 Then
			
			CommonClientServer.MessageToUser(NStr("vi = 'Không có hàng hóa để lập đơn hàng.';
													|ru = 'Нет товаров для оформления заказа.';
													|en = 'No goods for order registration.'; fa = 'No goods for order registration.';
													|it = 'Non ci sono merci per la registrazione dell''ordine.';
													|pl = 'Brak towarów do sporządzenia zamówienia.';
													|tr = 'Siparişin düzenlemesi için ürün yok.'")
			                                                  ,,"PickedGoodsCalculatedDiscounts");
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtClient
Procedure NavigateThroughPages(Command)
	
	If PageClickConditionsNotMet(Command) Then
		Return;
	EndIf;
	
	If Items.Pages_Main.CurrentPage = Items.AdditionalAttributesPage Then
		If Command.Name = "Next" Then
			
			Items.Pages_Main.CurrentPage = Items.GoodsPage;
			Items.PagesButtons.CurrentPage   = Items.PageButtonsBackNextCancel;
			Items.ButtonNextPageBackNextCancel.DefaultButton = True;
			
			UpdateDiscountsPaymentStages();
			
		EndIf;
	ElsIf Items.Pages_Main.CurrentPage = Items.GoodsPage Then
		
		If Command.Name = "Back" Then
			
			Items.Pages_Main.CurrentPage = Items.AdditionalAttributesPage;
			Items.PagesButtons.CurrentPage   = Items.PageButtonsNextCancel;
			Items.NextButtonNextPageCancel.DefaultButton = True;
			
		ElsIf Command.Name = "Next" Then
			
			FillInSummaryInformation();
			Items.Pages_Main.CurrentPage = Items.PageSummary;
			Items.PagesButtons.CurrentPage   = Items.PageButtonsCancelBackRegister;
			Items.TheProceedToCheckoutButton.DefaultButton = True;
			
		EndIf;
		
	ElsIf Items.Pages_Main.CurrentPage = Items.PageSummary Then
		
		If Command.Name = "Next" Then
			
			RegisterOrder();
			Notify("Write_SalesOrder", New Structure("AuthorizationObject", AuthorizationObject));
			Close(); 
			
		ElsIf Command.Name = "Back" Then
			
			Items.Pages_Main.CurrentPage = Items.GoodsPage;
			Items.PagesButtons.CurrentPage   = Items.PageButtonsBackNextCancel;
			Items.ButtonNextPageBackNextCancel.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateProductsTableBasedOnBasketData(BucketAddressInStorage)
	
	BucketData = GetFromTempStorage(BucketAddressInStorage);
	
	If BucketData = Undefined Or BucketData.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	BucketData.ProductsInSet,
	|	BucketData.ItemVariantOfSet,
	|	BucketData.Products,
	|	BucketData.Characteristic,
	|	BucketData.Package,
	|	BucketData.NumberOfPackages,
	|	BucketData.Price,
	|	BucketData.Sum,
	|	BucketData.VATAmount,
	|	BucketData.AmountIncludingVAT,
	|	BucketData.Count,
	|	BucketData.PriceKind,
	|	BucketData.VATRate,
	|	BucketData.ToRegister,
	|	BucketData.ExcisableGoods
	|INTO BucketData
	|FROM
	|	&BucketData AS BucketData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BucketData.ProductsInSet,
	|	BucketData.ItemVariantOfSet,
	|	BucketData.Products,
	|	BucketData.Characteristic,
	|	BucketData.Package,
	|	BucketData.Products.DescriptionFull AS FullNameOfProduct,
	|	BucketData.Characteristic.DescriptionFull AS FullNameOfTheCharacteristic_3,
	|	BucketData.Products.SaleRegistrationOption AS SaleRegistrationOption,
	|	BucketData.NumberOfPackages,
	|	BucketData.Price,
	|	BucketData.Sum,
	|	BucketData.VATAmount,
	|	BucketData.AmountIncludingVAT AS AmountIncludingVAT,
	|	BucketData.Count,
	|	BucketData.PriceKind,
	|	BucketData.VATRate,
	|	BucketData.ExcisableGoods,
	|	CASE
	|		WHEN &WarehouseIsAGroupOfWarehouses 
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		WHEN CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN &Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CAST("""" AS STRING(1000)) AS Content
	|FROM
	|	BucketData AS BucketData
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON BucketData.Products = CatProducts.Ref
	|WHERE
	|	BucketData.ToRegister
	|	AND BucketData.Price > 0
	|	AND CASE
	|			WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|				THEN BucketData.ExcisableGoods = FALSE
	|			ELSE TRUE
	|		END";
	
	Query.SetParameter("BucketData",BucketData);
	Query.SetParameter("VATTaxation",VATTaxation);
	Query.SetParameter("Warehouse",Warehouse);
	Query.SetParameter("WarehouseIsAGroupOfWarehouses",WarehouseIsAGroupOfWarehouses);
	
	BucketDataTable = Query.Execute().Unload();
	
	For Each CurRow In BucketDataTable Do
	
		If CurRow.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoiceServices Then
			CurRow.Content = ProductsClientServer.PresentationOfProductsForPrinting(
				CurRow.FullNameOfProduct, 
				CurRow.FullNameOfTheCharacteristic_3);
			
		EndIf;
	
	EndDo;
	
	PickedGoodsCalculatedDiscounts.Load(BucketDataTable);
	
	UpdateDiscountsPaymentStages();
	
EndProcedure

&AtServer
Procedure RegisterOrder()

	SelfServiceServer.RegisterOrder(FillInStructureUsingFormDetails(),
	                                    ?(OrderIssueOption = 1, True, False));

EndProcedure 

&AtServer
Procedure UpdateDiscountsPaymentStages()
	
	If Not BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		CalculateDiscounts();
	Else
		DocumentAmount = PickedGoodsCalculatedDiscounts.Total("AmountIncludingVAT");
	EndIf;
	SetPrivilegedMode(True);
	If Not (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent 
		Or  ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments) Then
		
		FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
		FillPropertyValues(FillParameters, ThisForm);
		FillParameters.TheseAreSettlementsWithCustomers = True;
		PaymentStepsServer.FillInPaymentStages(PaymentScheduleSteps, FillParameters);
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#Region Delivery

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName);
	
	If Not UseDeliveryManagement Then
		Return;
	EndIf;
	
	DeliveryDetails_ = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails();
	DeliveryDetails_.Insert("Partner", Partner);
	DeliveryDetails_.Insert("Ref",  Documents.SalesOrder.EmptyRef());
	FillPropertyValues(DeliveryDetails_, ThisForm);
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, DeliveryDetails_);	
	
	FillPropertyValues(ThisForm, DeliveryDetails_);
	
EndProcedure

&AtClient
Procedure ContactPersonStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Owner", Partner);
	ChoiceFormParameters = New Structure("Filter", FilterStructure1);
	ChoiceFormParameters.Insert("ChoiceMode", True);
	ChoiceFormParameters.Insert("CloseOnChoice", True);
	
	OpenForm("Catalog.ContactPersonsForPartners.ChoiceForm", ChoiceFormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.ContactPersonsForPartners") Then
		ContactPerson = ValueSelected;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.PickedGoodsCalculatedDiscounts.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Organization;
	FillParameters.Warehouse = Warehouse;
	FillParameters.Contract = Contract;
	FillParameters.ThisIsOrder = True;
	
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Or
		BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle  Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	EndIf;
	
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetDeliveryPage(FormItems, DeliveryMethod)
	
	VisibilityOfParameters = (DeliveryMethod <> PredefinedValue("Enum.TransportMethods25.SelfPickup"));
	
	FormItems.PageDeliveryToRecipient.Visible = VisibilityOfParameters;
	
	If VisibilityOfParameters Then
		
		CurrentPage = FormItems.PageDeliveryToRecipient;
		
	Else
		
		CurrentPage = FormItems.PagePickup;
		
	EndIf;
	
	FormItems.DeliveryPages.CurrentPage = CurrentPage;
	
EndProcedure

&AtServer
Procedure ShowHideDeliveryDetails()
	
	DeliveryItems = New Array; // Array of String
	DeliveryItems.Add(Items.DeliveryAddress.Name);
	DeliveryItems.Add(Items.RecipientDeliveryAddress.Name);
	
	ThereAreActiveDeliveryPoints = GoodsDelivery.ThereAreActiveDeliveryPoints(Partner);
	
	If Not ThereAreActiveDeliveryPoints Then
		
		DeliveryItems.Add(Items.PageDeliveryToRecipient.Name);
		DeliveryItems.Add(Items.DeliveryMethod25.Name);
		
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, DeliveryItems, "Visible", False);
	
EndProcedure

&AtServerNoContext
Function DefaultDeliveryPoint(Val Partner)
	
	DataOfMainTD = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Partner);
	Return DataOfMainTD.DeliveryPoint;
	
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
	If Item.Name = "sh_ShamsiInput_F_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
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
