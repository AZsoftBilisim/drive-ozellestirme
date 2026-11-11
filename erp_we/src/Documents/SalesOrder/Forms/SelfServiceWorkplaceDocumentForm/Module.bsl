#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If PrintFormOpeningIsRequired Then
		Return;
	EndIf;
	
	EmbeddingParameters = Documents.SalesOrder.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.FillInEmbeddingParameters(ThisObject, EmbeddingParameters);

	BalanceViewIsAvailable = SelfServiceServer.YouCanViewBalancesInSelection();
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	Items.GoodsGroupCancel.Visible                        = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	Items.ProductsCanceledCancellationReasonsAreNotUsed.Visible = Not GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	Items.DateOfShipment.Visible = Object.NotShipInInstallments;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(Items.DeliveryTimeFrom);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(Items.DeliveryTimeTo);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, 
	                                                               "FormChangeHistory", 
	                                                               "Visible", 
	                                                                ObjectsVersioning.HasRightToReadObjectVersionData());

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	If CurrentObject.Posted And CurrentObject.Status <> Enums.SalesOrderStatuses.NotApproved Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	UseDiscountsMarkupsInSales = GetFunctionalOption("UseDiscountsMarkupsInSales");
	ToUseTermsOfSales          = GetFunctionalOption("ToUseTermsOfSales");
	UseReasonsForSalesOrderCancellations  = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	TermsOfSale.ContractsAreUsed,
	|	TermsOfSale.Warehouse,
	|	TermsOfSale.PaymentMethod,
	|	TermsOfSale.Counterparty,
	|	&Partner,
	|	ISNULL(Warehouses.IsFolder, FALSE) AS ThisIsWarehouseGroup,
	|	TermsOfSale.ProductSegment
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON TermsOfSale.Warehouse = Warehouses.Ref
	|WHERE
	|	TermsOfSale.Ref = &Terms";
	
	Query.SetParameter("Terms", CurrentObject.Terms);
	Query.SetParameter("Partner", CurrentObject.Partner);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	WarehouseIsDeterminedByTheAgreement        = ValueIsFilled(Selection.Warehouse) And Not Selection.ThisIsWarehouseGroup;
	
	FillInServiceDetailsForProductRange();
	UpdateNoReturnableContainerAttribute();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	AvailabilityManagementChangeOfAgreement(Selection);
	If ValueIsFilled(Object.Contract)
		And Items.Contract.ChoiceList.FindByValue(Object.Contract) = Undefined Then
		Items.Contract.ChoiceList.Add(Object.Contract);
	EndIf;
	CalculateOrderTotals(ThisForm);
	
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.AdditionalInformation);
	If Object.Status <> Enums.SalesOrderStatuses.NotApproved Then
		ReadOnly = True;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đơn hàng %1 ngày %2';
																			|ru = 'Заказ %1 от %2';
																			|en = 'Order %1 from %2'; fa = 'Order %1 from %2';
																			|it = 'Ordine %1 del %2';
																			|pl = 'Zamówienie %1 z dn. %2';
																			|tr = '%2 tarihli %1siparişi'"), Object.Number, Object.Date);
	
	DetermineVisibilityOfManualDiscounts(CurrentObject);
	
	AvailabilityControl(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
	EndIf;
	
	If EventName = "EditSet" Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns(ThisForm));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
		OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("Terms", Object.Terms);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
		OpeningParameters.Insert("HidePriceTypes", True);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	Cancel = False;
	
	If UseDiscountsMarkupsInSales Then
		
		If Not Object.DiscountsAreCalculated Then
			ApplyDiscountMarkUpChangesOnCustomer(Cancel);
		Else
			Object.DiscountsAreCalculated = True;
		EndIf;
		
	EndIf;
	
	BeforeWriteAtClientServer();
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	NumberOfOrderLines = Object.Goods.FindRows(New Structure("Canceled", False)).Count();
	
	If NumberOfOrderLines = 0 Then
		CommonClientServer.SupplementTable(PaymentScheduleStepsUnderTheAgreement, Object.PaymentScheduleSteps);
	EndIf;
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	FillInServiceDetailsForProductRange();
	UpdateNoReturnableContainerAttribute();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	SetsServer.FillInServiceDetails(ThisForm);
	
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.AdditionalInformation);
	ManagingRecordElements();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		Cancel = True;
		SelfServiceClient.PrintOrderDocument(Object.Ref);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
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
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectionResult = Undefined;

	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.SelectTermsOfSales",
	             New Structure("Partner,Terms",Object.Partner,Object.Terms),
	             ThisForm,,,, New CallbackDescription("TermsStartChoiceCompletion", ThisObject),
	             FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TermsStartChoiceCompletion(Result, AdditionalParameters) Export
	
	SelectionResult = Result;
	If SelectionResult <> Undefined And SelectionResult.Terms <> Object.Terms Then
		WarehouseIsDeterminedByTheAgreement  = ValueIsFilled(SelectionResult.Warehouse) And Not SelectionResult.ThisIsWarehouseGroup;
		TermsOnChangeServer(SelectionResult);
		Modified = True;
	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure TermsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure WarehouseClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	FillInAndDisplayPaymentStages();
EndProcedure

#EndRegion

#Region EventHandlersDelivery

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.WhenChangingAddressPresentation(
		Item,
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]);
	
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
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);

EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	DeliveryAddressOnChange(Item);
	
	DeliveryDetails_ = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails();
	FillPropertyValues(DeliveryDetails_, Object);
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, DeliveryDetails_, Item.Name, ValueSelected);
	FillPropertyValues(Object, DeliveryDetails_);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	SpecialTransportationConditionsOnChangeServer();
EndProcedure

#EndRegion

#Region EventHandlersForTablePartGoods

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Items.Goods.CurrentData.RowCode = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	CalculateOrderTotals(ThisForm);
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined And Object.NotShipInInstallments Then
		CurrentData.DateOfShipment = Object.DateOfShipment;
	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm, True);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm, True);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);	
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm, True);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "GoodsProducts" 
		Or Field.Name = "GoodsCharacteristic" Then
		
		OpenProductItemCard();
		
	ElsIf Field.Name = "GoodsProductsInSet" 
		Or Field.Name = "GoodsItemVariantOfSet" Then
		
		OpenRecruitmentCard();
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CancelSelectedLines(Command)
	
	If Not SalesClient.YouMustFillInReasonsForCancelingSelectedLines(Object.Goods, NStr("vi = 'Hàng hóa';
																						|ru = 'Товары';
																						|en = 'Goods'; fa = 'کالاها';
																						|it = 'Merci';
																						|pl = 'Goods';
																						|tr = 'Ürünler'"), Items.Goods.SelectedRows) Then
		Return;
	EndIf;

	CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	If UseReasonsForSalesOrderCancellations Then
		FormParameters = New Structure("ForExternalUser", True);
		OpenForm("Catalog.ReasonsForSaleOrderCancellation.ChoiceForm", FormParameters,,,,, New CallbackDescription("CancelSelectedLinesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	UndoSelectedLineSnippet(CancellationReason);
EndProcedure

&AtClient
Procedure CancelSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    CancellationReason = Result;
    If Not ValueIsFilled(CancellationReason) Then
        Return;
    EndIf;
    
    UndoSelectedLineSnippet(CancellationReason);

EndProcedure

&AtClient
Procedure UndoSelectedLineSnippet(Val CancellationReason)
    
    StructureOfActions = New Structure();
    StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
    StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
    
    SelectedRows = AddToFullSet();
    
    SalesClient.CancelSelectedLines(
    Object.Goods,
    SelectedRows,
    CancellationReason,
    StructureOfActions);
    CalculateOrderTotals(ThisForm, True);
    
    SalesClient.NotifyAboutCancellationOfSelectedLines(CancellationReason);
    DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);

EndProcedure

&AtClient
Procedure HideCanceledLines(Command)
	
	HideCanceledLines = Not HideCanceledLines;
	
	If HideCanceledLines Then
		Items.Goods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.Goods.RowFilter = Undefined;
	EndIf;
	
	Items.GoodsHideCanceledLines.Check = HideCanceledLines;
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.SalesOrder.SelfServiceWorkplaceDocumentForm.Command.OpenSelection");
	
	FormParameters = New Structure;
	FormParameters.Insert("TransferHeader",                            NStr("vi = 'Chuyển vào chứng từ';
																			|ru = 'Перенести в документ';
																			|en = 'Add to document'; fa = 'افزودن به سند';
																			|it = 'Trasferire nel documento';
																			|pl = 'Przenieś do dokumentu';
																			|tr = 'Belgeye taşı'"));
	FormParameters.Insert("Terms",                                    Object.Terms);
	FormParameters.Insert("Organization",                                   Object.Organization);
	FormParameters.Insert("Warehouse",                                         Object.Warehouse);
	FormParameters.Insert("Currency",                                        Object.Currency);
	FormParameters.Insert("Title",                                     NStr("vi = 'Chọn hàng hóa vào';
																			|ru = 'Подбор товаров в';
																			|en = 'Pick goods in'; fa = 'Pick goods in';
																			|it = 'Selezione prodotti in';
																			|pl = 'Wybór towarów w';
																			|tr = 'İçindeki ürünlerin seçimi'") + " " + Object.Ref);
	FormParameters.Insert("ProductSegment",                           ProductSegment);
	FormParameters.Insert("BusinessOperation",                         Object.BusinessOperation);
	FormParameters.Insert("VATTaxation",                            Object.VATTaxation);
	FormParameters.Insert("Document",                                      Object.Ref);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",               ?(BalanceViewIsAvailable, False, True));
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",               ?(BalanceViewIsAvailable, False, True));
	FormParameters.Insert("PriceIncludesVAT",                               Object.PriceIncludesVAT);
	FormParameters.Insert("ReturnReusablePackage",                  Object.ToReturnReusablePackage);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
	             SelfServiceClient.StructureOfParametersForSelection(FormParameters),
	             ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	If Not Object.DiscountsAreCalculated Then
		ShowQueryBox(New CallbackDescription("OpenInformationAboutDiscountsCompletion", ThisObject), 
			NStr("vi = 'Chưa tính chiết khấu (phụ thu), tính chiết khấu (phụ thu)?';
				|ru = 'Скидки (наценки) не рассчитаны, рассчитать?';
				|en = 'Discounts (markups) are not calculated, calculate?'; fa = 'Discounts (markups) are not calculated, calculate?';
				|it = 'Gli sconti (sovrapprezzi) non sono stati calcolati, calcolare?';
				|pl = 'Rabaty (marże) nie są obliczane, obliczyć?';
				|tr = 'İndirimler uygulanmadı. Uygulamak istiyor musunuz?'"), QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	OpenDiscountInformationFragment();
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscountsCompletion(QuestionResult, AdditionalParameters) Export
    
    Result = QuestionResult;
    If Result = DialogReturnCode.No Then
        Return;
    Else
        
        CalculateDiscountsMarginsOnServer(StructureOfParametersCalculationOfDiscounts());
        
    EndIf;
    
    OpenDiscountInformationFragment();

EndProcedure

&AtClient
Procedure OpenDiscountInformationFragment()
    
    Var CurrentData;
    
    If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
        CalculateDiscountsWithoutApplyingToObject();
    EndIf;
    
    CurrentData = Items.Goods.CurrentData;
    DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisForm,
    SelfServiceClient.AdditionalParametersAppliedDiscounts());

EndProcedure

&AtClient
Procedure CalculateDiscountsMarkups(Command)
	
	CalculateDiscountsMarkupsClient();
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkupsClient()
	
	CalculateDiscountsMarginsOnServer(StructureOfParametersCalculationOfDiscounts());
	
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
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure PricesAmountsByTermsOfSales(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("BucketData", Object.Goods);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.PricesAmountsByTermsOfSales", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StockInWarehouses(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("BucketData", Object.Goods);
	FormParameters.Insert("Terms", Object.Terms);
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.StockInWarehouses", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	SelfServiceClient.PrintOrderDocument(Object.Ref);
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ClearMessages();
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	RowSelected = Items.Goods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns", DialColumns(ThisForm));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("ProhibitPriceEditing", True);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	OpeningParameters.Insert("HidePriceTypes", True);
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );

EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeHistory(Command)
	
	OpenForm("InformationRegister.ObjectsVersions.Form.SelectStoredVersions",
	             New Structure("Ref", Object.Ref),
	             ThisObject);
	
EndProcedure

&AtClient
Procedure StockAvailability(Command)
	
	SelfServiceClient.OpenProductBalancesAndAvailabilityReport(ThisObject);
	
EndProcedure

&AtClient
Procedure SupplyState(Command)
	
	FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("TABLE");
	FormParameters.AvailableRemainingDocumentParameters =
		ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisObject);
	FormParameters.OrderDocument = Object.Ref;
	FormParameters.AcceptableSecurityOptions = New Map();
	FormParameters.ReadOnly = ReadOnly;
	FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsLineNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsItemsType.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsSKU.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountIncludingVAT.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentRateOfAutomaticDiscountMarkup.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDiscountMarkupAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsManualDiscount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCancellationReason.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CancellationReason");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	SetsServer.SetConditionalAppearance(ThisForm, "Goods");
	
EndProcedure

#Region Sets

&AtServer
Function AddToFullSet()
	
	TabularSection = Object.Goods;
	SelectedRows = Items.Goods.SelectedRows;
	
	RowsArray = New Array;
	For Each CurRow In SelectedRows Do
		TableRow = TabularSection.FindByID(CurRow);
		RowsArray.Add(TableRow);
	EndDo;
	
	SetsServerCall.AddToFullSet(TabularSection, RowsArray);
	
	Result = New Array;
	For Each TSRow In RowsArray Do
		Result.Add(TSRow.GetID());
	EndDo;
	
	Return Result;
	
EndFunction

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
	
	If (Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		Or Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale")) Then
		
		If Form.ThereAreManualDiscounts Then
			Columns.Add("PercentRateOfManualDiscount");
			Columns.Add("ManualDiscount");
		EndIf;
		
		If Form.UseDiscountsMarkupsInSales Then
			Columns.Add("PercentRateOfAutomaticDiscountMarkup");
			Columns.Add("DiscountMarkupAmount");
		EndIf;
		
	EndIf;
	
	Columns.Add("CancellationReason");
	Columns.Add("Canceled");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");
	
	Return Columns;
	
EndFunction

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisForm, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithModifiedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInContent",
	       BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisForm));
	
	SetsServer.AtEndOfEditingSet(ThisForm, "Goods", DataParameters);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Function ThereAreManualDiscounts(CurrentObject)
	
	If GetFunctionalOption("UseDiscountAdjustmentsInSales") Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	Goods.LineNumber,
		|	Goods.ManualDiscount
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.ManualDiscount <> 0";
		
		Query.SetParameter("Goods", CurrentObject.Goods.Unload());
		
		QueryResult = Query.Execute();
		
		ThereAreManualDiscounts = Not QueryResult.IsEmpty();
		
	Else
		
		ThereAreManualDiscounts = False;
		
	EndIf;
	
	Return ThereAreManualDiscounts;
	
EndFunction

&AtClient
Procedure OpenRecruitmentCard()

	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	UseDeliveryManagement   = GetFunctionalOption("UseDeliveryManagement");
	UsePaymentSchedules         = GetFunctionalOption("UsePaymentSchedules");
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UseDeliveryManagement25 = GoodsDeliveryClientServer.UsedDelivery25();
	
	If UseDeliveryManagement Then
		
		If UseDeliveryManagement25 Then
			
			FillInDeliveryDetailsForDisplay();
			SetUpDeliveryPage();
			
		Else
			
			TheStructureOfTheDeliveryDetailsBeforeTheChangeInTheForm = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails();
			FillPropertyValues(TheStructureOfTheDeliveryDetailsBeforeTheChangeInTheForm,Object);
			
			If Object.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress Then
				// When delivering to the carrier, the manager specifies the time of delivery to the carrier
				Items.DeliveryTimeFrom.Visible  = False;
				Items.DeliveryTimeTo.Visible = False;
				DeliveryMethod = Enums.TransportMethods.ToCustomer;
			ElsIf Object.DeliveryMethod = Enums.TransportMethods.ByCarrier Then
				DeliveryMethod = Enums.TransportMethods.SelfPickup;
			ElsIf Object.DeliveryMethod = Enums.TransportMethods.ToCustomerByCourier Then
				
				DeliveryMethod = Enums.TransportMethods.ToCustomer;
				
			Else
				DeliveryMethod = Object.DeliveryMethod;
			EndIf;
			
			DeliveryDetails_ = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails();
			DeliveryDetails_.Insert("Partner", Object.Partner);
			DeliveryDetails_.Insert("Ref",  Object.Ref);
			FillPropertyValues(DeliveryDetails_, Object);
			DeliveryDetails_.DeliveryMethod = DeliveryMethod;
			
			GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, DeliveryDetails_);
			FillPropertyValues(Object, DeliveryDetails_);
			
		EndIf;
		
	Else
		Items.DeliveryPage.Visible = False;
	EndIf;
	
	SetsServer.FillInServiceDetails(ThisForm);
	
	ManagingRecordElements();
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		,
		Not Object.ThisIsOrderAsInvoice);
	
EndProcedure

&AtServer
Procedure AvailabilityManagementChangeOfAgreement(Data)
	
	ContractsAreUsed = Data.ContractsAreUsed;
	ProductSegment              = Data.ProductSegment;
	SelfServiceServer.GenerateTextPresentationsOfDocumentFormFields(ThisForm);
	
	TransferOperations_ = SalesServer.GoodsTransferOperations();
	
	DiscountVisibility = GetFunctionalOption("UseDiscountsMarkupsInSales")
	                  And TransferOperations_.Find(Object.BusinessOperation) = Undefined;
	
	Items.GroupProductsDiscountsMargins.Visible = DiscountVisibility;
	Items.DiscountAmount.Visible               = DiscountVisibility;
	Items.PagesCalculateDiscounts.Visible  = DiscountVisibility;
	
	SelfServiceServer.ManagingCounterpartyFormElement(Object, Data, Items.Counterparty);
	SelfServiceServer.ManagingContractFormElement(Object, Items.Contract, ContractsAreUsed);
	SelfServiceServer.ManagingWarehouseFormElement(Object, Data, Items.Warehouse);
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer(SelectionResult)

	Object.Terms = SelectionResult.Terms;
	Object.Currency                          = SelectionResult.Currency;
	Object.Organization                     = SelectionResult.Organization;
	Object.BusinessOperation           = SelectionResult.BusinessOperation;
	Object.PaymentSchedule                    = SelectionResult.PaymentSchedule;
	Object.PriceIncludesVAT                 = SelectionResult.PriceIncludesVAT;
	Object.ToReturnReusablePackage       = SelectionResult.ToReturnReusablePackage;
	Object.ReusablePackageReturnCycleLength  = SelectionResult.ReusablePackageReturnCycleLength;
	Object.PackageDepositIsRequired            = SelectionResult.PackageDepositIsRequired;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	ProductSegment          = SelectionResult.ProductSegment;
	
	FillInSalesVATTaxation();
	
	AvailabilityManagementChangeOfAgreement(SelectionResult);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfDiscountActions = New Structure;
	StructureOfDiscountActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	StructureOfDiscountActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfDiscountActions.Insert("RecalculateAmount","NumberOfPackages");
	StructureOfDiscountActions.Insert("RecalculateAmountWithVAT",StructureOfRecalculationOfAmount);
	StructureOfDiscountActions.Insert("RecalculateVATAmount",StructureOfRecalculationOfAmount);
	StructureOfDiscountActions.Insert("RecalculateAmountOfManualDiscount","NumberOfPackages");
	StructureOfDiscountActions.Insert("ClearAutomaticDiscount",Undefined);
	StructureOfDiscountActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfDiscountActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfDiscountActions.Insert("FillInDuplicateDependentDetails",DependentDetails());
	
	PriceFillingParameters = New Structure;
	PriceFillingParameters.Insert("Date",              Object.Date);
	PriceFillingParameters.Insert("Currency",            Object.Currency);
	PriceFillingParameters.Insert("Terms",        Object.Terms);
	PriceFillingParameters.Insert("CalculateSets", True);
	PriceFillingParameters.Insert("Organization", Object.Organization);
	PriceFillingParameters.Insert("VATTaxation", Object.VATTaxation);
	PriceFillingParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	PriceFillingParameters.Insert("PopulationFields",    "Price, VATRate, PriceKind, DeliveryPeriodDays");
	
	EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		, // Array of rows or selection structure
		PriceFillingParameters,
		StructureOfDiscountActions);
	
	CalculateDiscountsMarginsOnServer(StructureOfParametersCalculationOfDiscounts());
	FillInAndDisplayPaymentStages();
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		,
		Not Object.ThisIsOrderAsInvoice);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	FillInSalesVATTaxation();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	FillInSalesVATTaxation();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInAndDisplayPaymentStages()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject,"Date");
	CalculateOrderTotals(ThisObject, True);

EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	SelfServiceServer.ManagingContractFormElement(Object, Items.Contract, ContractsAreUsed);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateOrderTotals(Form, CalculatePaymentStages = False)
	
	// Filling in the totals according to the "Products" table
	CollectionProducts = Form.Object.Goods;
	Form.AmountOrdered     = ?(Form.Object.PackageDepositIsRequired,
	    CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled"),
	    CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	Form.PackageDepositValue = ?(Form.Object.PackageDepositIsRequired,(CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled"))
			- (CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages")),0);
	Form.AmountNDSOrdered  = ?(Form.Object.PackageDepositIsRequired,
	    CollectionProducts.Total("VATAmount") - CollectionProducts.Total("VATAmountCanceled"),
	    CollectionProducts.Total("VATAmountWithoutReusablePackages") - CollectionProducts.Total("VATAmountCanceledWithoutReusablePackages"));
	Form.DiscountAmount       = ?(Form.Object.PackageDepositIsRequired,
	    CollectionProducts.Total("DiscountMarkupAmount") - CollectionProducts.Total("DiscountMarkupAmountCanceled")
	    + CollectionProducts.Total("ManualDiscount") - CollectionProducts.Total("ManualDiscountCanceled"),
		CollectionProducts.Total("DiscountMarkupAmountWithoutReusablePackages") - CollectionProducts.Total("DiscountMarkupAmountCanceledWithoutReusablePackages")
		+ CollectionProducts.Total("ManualDiscountWithoutReusablePackages") - CollectionProducts.Total("ManualDiscountCanceledWithoutReusablePackages"));
	Form.SumCanceled     = ?(Form.Object.PackageDepositIsRequired,
	    CollectionProducts.Total("AmountIncludingVATCanceled"),
	    CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	
	If CollectionProducts.Total("AmountIncludingVATCanceled") = CollectionProducts.Total("AmountIncludingVAT") Then
		Form.AllLinesAreCanceled = True;
	Else
		Form.AllLinesAreCanceled = False;
	EndIf;
	
	AmountOrdered     = CollectionProducts.Total("Sum") - CollectionProducts.Total("SumCanceled");
	
	If AmountOrdered > 0 Then
		Form.DiscountPercentage    = Form.DiscountAmount * 100 / (AmountOrdered + Form.DiscountAmount);
	ElsIf Form.DiscountAmount > 0 Then
		Form.DiscountPercentage   = 100;
	Else
		Form.DiscountPercentage   = 0;
	EndIf;
	
	If CalculatePaymentStages Then
		
		DistributedAmount = 0;
		DistributedTareAmount = 0;
		PercentageOfTare = 0;
		NumberOfStages = Form.Object.PaymentScheduleSteps.Count();
		For Each Stage In Form.Object.PaymentScheduleSteps Do
			
			PercentageOfTare = PercentageOfTare + Stage.PackageDepositPercentage;
			StageAmount          = Round((Form.AmountOrdered-Form.PackageDepositValue) * Stage.PaymentPercentage / 100, 2, RoundMode.Round15as20);
			TareAmount          = Round(Form.PackageDepositValue * Stage.PackageDepositPercentage / 100, 2, RoundMode.Round15as20);
			Stage.PaymentAmount   = ?(Stage.LineNumber = NumberOfStages, Form.AmountOrdered - Form.PackageDepositValue - DistributedAmount, StageAmount);
			Stage.PackageDepositValue   = ?(PercentageOfTare = 100, Form.PackageDepositValue - DistributedTareAmount, TareAmount);
			DistributedAmount = DistributedAmount + Stage.PaymentAmount;
			DistributedTareAmount = DistributedTareAmount + Stage.PackageDepositValue;
			
		EndDo;
	EndIf;
	
	// Filling in the totals by payment stages
	PreviousDateValue = Date(1,1,1);
	TotalPaymentPercentage = 0;
	
	Form.AmountPrepaymentBeforeGoodsIssue = 0;
	Form.AmountOfPrepaymentBeforeShipment = 0;
	Form.CreditAmountAfterShipment = 0;
	Form.PercentageOfAdvancePaymentBeforeCollateral = 0;
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
		TotalPaymentPercentage = TotalPaymentPercentage + CurRow.PaymentPercentage;
		CurRow.PercentageIsFilledInIncorrectly = (TotalPaymentPercentage > 100);
		CurRow.DateIsFilledInIncorrectly = (PreviousDateValue > CurRow.PaymentDate);
		PreviousDateValue = CurRow.PaymentDate;
		If TotalPaymentPercentage = 100 Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
		ItemsNames = MatchingPaymentOptions[CurRow.PaymentOption];
		If ItemsNames <> Undefined Then
			Form[ItemsNames.Sum] = Form[ItemsNames.Sum] + CurRow.PaymentAmount;
			Form[ItemsNames.Interests] = Form[ItemsNames.Interests] + CurRow.PaymentPercentage;
		EndIf;
	EndDo;
	
	// Selecting the VAT display page
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure("WithoutReusablePackages, CanceledWithoutReusablePackages, Canceled",
	                        "Sum, AmountIncludingVAT, VATAmount, DiscountMarkupAmount, ManualDiscount",
	                        "Sum, AmountIncludingVAT, VATAmount, DiscountMarkupAmount, ManualDiscount",
	                        "Sum, AmountIncludingVAT, VATAmount, DiscountMarkupAmount, ManualDiscount");
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	ProductTableIsNotEmpty = Form.Object.Goods.Count() > 0;
	
	Form.Items.GoodsOpenSelection.Enabled = ValueIsFilled(Form.Object.Terms) 
	                                                 And ValueIsFilled(Form.Object.Warehouse);
	
	Form.Items.PagesCalculateDiscounts.CurrentPage = ?(Form.Object.DiscountsAreCalculated,
	                                                            Form.Items.PageDiscountsAreCalculated,
	                                                            Form.Items.PageDiscountsAreNotCalculated);
	
	Form.Items.CustomerShoppingCartPricesAmountsByTermsOfSales.Enabled = ValueIsFilled(Form.Object.Terms) 
	                                                                     And ValueIsFilled(Form.Object.Warehouse)
	                                                                     And Form.Object.Goods.Count() > 0;
	
	Form.Items.GoodsSupplyState.Enabled = Form.Object.Goods.Count() > 0;

EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	FillInSeparately = Common.ObjectAttributeValue(Object.Terms, "EnableAssigmentSupplyForOrders");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
		
	AddCollateralActionsOnServer(StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct,
		                         "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, Warehouse, DateOfShipment, PriceKind, Price, NumberOfPackages");
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	
	CalculateOrderTotals(ThisObject, True);
	
EndProcedure

&AtServer
Procedure CalculateDiscountsWithoutApplyingToObject()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject = False;
	ParametersStructure1.OnlyPreliminaryCalculation = False;
	ParametersStructure1.RestoreManagedDiscounts = True;
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
	AddressOfAppliedDiscountsInTheTemporaryStorage = 
			PutToTempStorage(AppliedDiscounts, UUID);
	
EndProcedure

&AtServer
Procedure CalculateDiscountsMarginsOnServer(ParametersStructure1, TakeFromTemporaryStorage = False)
	
	If TakeFromTemporaryStorage Then
		AppliedDiscounts = GetFromTempStorage(AddressOfAppliedDiscountsInTheTemporaryStorage);
		DiscountsMarkupsFillingServer.ApplyCalculationResult(Object, AppliedDiscounts);
	Else
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		AddressOfAppliedDiscountsInTheTemporaryStorage = 
				PutToTempStorage(AppliedDiscounts, UUID);
	EndIf;

	Object.DiscountsAreCalculated = True;
	UpdateNoReturnableContainerAttribute();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateOrderTotals(ThisForm, True);
	
EndProcedure

&AtClient
Procedure ApplyDiscountMarkUpChangesOnCustomer(Cancel)
	
	CalculateDiscountsMarginsOnServer(StructureOfParametersCalculationOfDiscounts());
	
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
	
EndProcedure

&AtClientAtServerNoContext
Function StructureOfParametersCalculationOfDiscounts()

	ReturnStructure = New Structure;
	ReturnStructure.Insert("ApplyToObject",                True);
	ReturnStructure.Insert("OnlyPreliminaryCalculation",      False);
	ReturnStructure.Insert("RestoreManagedDiscounts", True);
	ReturnStructure.Insert("ManagedDiscounts",                Undefined);

	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtServer
Procedure DetermineVisibilityOfManualDiscounts(CurrentObject)

	ThereAreManualDiscounts = ThereAreManualDiscounts(CurrentObject);

	Items.GoodsManualDiscount.Visible = ThereAreManualDiscounts;
	Items.GoodsPercentRateOfManualDiscount.Visible = ThereAreManualDiscounts;

EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
EndProcedure

&AtServer
Procedure UpdateNoReturnableContainerAttribute()
	
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	
EndProcedure

&AtServer
Procedure ManagingRecordElements()
	
	Items.FormWrite.Visible = Not Object.Posted;
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormPost", "Title",
	                                                               ?(Object.Posted, NStr("vi = 'Ghi lại';
																						|ru = 'Записать';
																						|en = 'Save'; fa = 'ذخیره';
																						|it = 'Salvare';
																						|pl = 'Save';
																						|tr = 'Kaydet'"), NStr("vi = 'Cần thống nhất';
																												|ru = 'На согласование';
																												|en = 'For approval'; fa = 'برای تأیید';
																												|it = 'Da concordare';
																												|pl = 'Do uzgodnienia';
																												|tr = 'Onay için'")));
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormPost", "Picture", 
	                                                               ?(Object.Posted, PictureLib.Write, PictureLib.CheckSyntax));
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormPostAndClose", "Title",
	                                                               ?(Object.Posted, NStr("vi = 'Ghi lại và đóng';
																						|ru = 'Записать и закрыть';
																						|en = 'Save and close'; fa = 'ذخیره و بستن';
																						|it = 'Salvare e chiudere';
																						|pl = 'Zapisz i zamknij';
																						|tr = 'Kaydet ve kapat'"), NStr("vi = 'Cần thống nhất và đóng';
																														|ru = 'На согласование и закрыть';
																														|en = 'For approval and close'; fa = 'For approval and close';
																														|it = 'Da concordare e chiudere';
																														|pl = 'Do uzgodnienia i zamknięcia';
																														|tr = 'Onayla ve kapat'")));
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
EndProcedure


#EndRegion

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form, SecurityOptionAndFlagSeparately)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                                 Form);
	DocumentParameters.Insert("Collection",                             Form.Object.Goods);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately",    SecurityOptionAndFlagSeparately);
	
	Return DocumentParameters;
	
EndFunction

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, "SupplyOption", DocumentParameters);
	
EndProcedure

&AtServer
Function AddressOfMovementTableInRepository()
	
	Return ProvisionInDocumentsServer.AddressOfMovementTableInRepository(ThisObject);
	
EndFunction

&AtServer
Procedure SetUpDeliveryPage()
	
	If Not Object.DeliveryIsRequired Then
		
		PageDelivery = Items.PagePickup;
		DeliveryMethodToDisplay = Enums.TransportMethods25.SelfPickup;
		
	ElsIf Object.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows
		  Or Object.DeliveryMethod25 = Enums.TransportMethods25.OwnDelivery
		  Or Object.DeliveryMethod25 = Enums.TransportMethods25.OurCourier Then
		
		PageDelivery = Items.PageDeliveryToRecipient25;
		DeliveryMethodToDisplay = Enums.TransportMethods25.OwnDelivery;
		
	ElsIf Object.DeliveryMethod25 = Enums.TransportMethods25.DefinedByDeliveryService Then
		
		PageDelivery = Items.PageDeliveryToRecipient25;
		DeliveryMethodToDisplay = Enums.TransportMethods25.DefinedByDeliveryService;
		
	Else
		
		PageDelivery = Items.PagePickup;
		DeliveryMethodToDisplay = Enums.TransportMethods25.SelfPickup;
		
	EndIf;
	
	Items.DeliveryPage.ReadOnly = True;
	Items.DeliveryPages.CurrentPage = PageDelivery;
	
EndProcedure

&AtServer
Procedure FillInDeliveryDetailsForDisplay()
	
	If Not Object.DeliveryIsRequired Then
		Return;
	EndIf;
	
	If Object.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
		
		DeliveryPointToDisplay = Object.DeliveryPoint;
		DeliveryTimeWithForDisplay = Object.DeliveryTimeFrom;
		SoftwareDeliveryTimeForDisplay = Object.DeliveryTimeTo;
		AdditionalInformationToDisplay = Object.AdditionalDeliveryInformation;
		
	ElsIf Object.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows Then 
		
		SourceRow = Undefined;
		
		For Each DeliveryLine In Object.GoodsToDeliver Do
			
			If ValueIsFilled(DeliveryLine.DeliveryPoint) Then
				
				SourceRow = DeliveryLine;
				Break;
				
			EndIf;
			
		EndDo;
		
		If SourceRow <> Undefined Then
			
			DeliveryPointToDisplay = SourceRow.DeliveryPoint;
			DeliveryTimeWithForDisplay = SourceRow.DeliveryTimeFrom;
			SoftwareDeliveryTimeForDisplay = SourceRow.DeliveryTimeTo;
			AdditionalInformationToDisplay = SourceRow.AdditionalDeliveryInformation;
			
		EndIf;
		
	EndIf;
	
EndProcedure

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
