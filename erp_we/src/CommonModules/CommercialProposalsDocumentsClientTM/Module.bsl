////////////////////////////////////////////////////////////////////////////////
// Subsystem "Objects UT11, KA2, UP2".
// General module.Commercial proposals and documentslientut.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region EventHandlersForChangingFormElements

// See CommercialProposalsDocumentsClientOverridable.WhenChangingProducts.
//
Procedure WhenChangingProducts(Form, CurrentRow, CurrentItem, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenProductRangeChanges(Form, CurrentRow, CurrentItem, ServerCallRequired__);
		
	EndIf;
	
	CommercialProposalsDocumentsClientLocalization.WhenChangingProducts(Form, CurrentRow, CurrentItem, ServerCallRequired__);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingCharacteristics.
//
Procedure WhenChangingCharacteristics(Form, CurrentRow, CurrentItem, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenCharacteristicsChange(Form, CurrentRow, CurrentItem, ServerCallRequired__)
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingUnitOfMeasurement.
//
Procedure WhenChangingUnitOfMeasurement(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingUnitOfMeasurement(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingQuantity.
//
Procedure WhenChangingQuantity(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenQuantityChanges(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingPriceType.
//
Procedure WhenChangingPriceType(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingTypeOfPrice(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingAmount.
//
Procedure WhenChangingAmount(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenAmountChanges(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingVATAmount.
//
Procedure WhenChangingVATAmount(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingAmountOfVAT(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenPriceChanges.
//
Procedure WhenPriceChanges(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenPriceChanges(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingVATRate.
//
Procedure WhenChangingVATRate(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenVATRateChanges(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingPercentageOfManualDiscount.
//
Procedure WhenChangingPercentageOfManualDiscount(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingPercentageOfManualDiscount(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingAmountOfManualDiscount.
//
Procedure WhenChangingAmountOfManualDiscount(Form, CurrentRow, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingAmountOfManualDiscount(Form, CurrentRow, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingPartner.
//
Procedure WhenChangingPartner(Form, ServerCallRequired__) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenPartnerChanges(Form, ServerCallRequired__);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenOrganizationChanges.
//
Procedure WhenOrganizationChanges(Form, ServerCallRequired__) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenOrganizationChanges(Form, ServerCallRequired__);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenBusinessTransactionChanges.
//
Procedure WhenBusinessTransactionChanges(Form, ServerCallRequired__) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientInCaseOfChangeOfBusinessOperation(Form, ServerCallRequired__);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingManager.
//
Procedure WhenChangingManager(Form, ServerCallRequired__) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenManagerChanges(Form, ServerCallRequired__);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingVATTaxation.
//
Procedure WhenChangingVATTaxation(Form, ServerCallRequired__) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientInCaseOfChangesInVATTaxation(Form, ServerCallRequired__);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.OnChangePriceIncludesVAT.
//
Procedure OnChangePriceIncludesVAT(Form, ServerCallRequired__) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingPriceIncludesVAT(Form, ServerCallRequired__);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingCurrency.
//
Procedure WhenChangingCurrency(Form, ServerCallRequired__) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenChangingWhenChangingCurrency(Form, ServerCallRequired__);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.TabularPartSelection.
//
Procedure TabularPartSelection(Form, Item, RowSelected, Field, StandardProcessing, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
	
		CommercialOfferToClientToChooseFrom(Form, Item, RowSelected, Field, StandardProcessing, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.TabularPartSelection.
//
Procedure AfterCompletingGoodsSelection(Form, FieldName, ProcessingResult) Export
	
		
	If ProcessingResult <> Undefined Then
		
		If FieldName <> "GoodsCommentForCustomer"
			Or FieldName <> "GoodsInternalComment" Then
			
			OpenForm("DataProcessor.EditSet.Form.Form", ProcessingResult, Form, Form.UUID);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.TabularPartSelection.
//
Procedure GoodsBeforeDeleteRow(Form, Item, CurrentData, Cancel) Export
	
	SetsClient.BeforeDeletingRowOfTablePart(Form, "Goods", Cancel, False, "Attachable_ProcessingProductSelectionResults");
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenStatusChanges.
//
Procedure WhenStatusChanges(Form, CurrentDate, ServerCallRequired__) Export
	
	CommercialProposalsDocumentsClientServerTM.GenerateStatePresentationByStatus(Form, Form.Object.Status, CurrentDate);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenChangingValidityPeriodOfCommercialOffer.
//
Procedure WhenChangingValidityPeriodOfCommercialOffer(Form, CurrentDate, ServerCallRequired__) Export
	
	CommercialProposalsDocumentsClientServerTM.GenerateStatePresentationByStatus(Form, Form.Object.Status, CurrentDate);
	
EndProcedure

#EndRegion

#Region FormsEventsHandlers

// See CommercialProposalsDocumentsClientOverridable.BeforeWrite
//
Procedure BeforeWrite(Form, Cancel, WriteParameters) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialProposalForCustomerBeforeWrite(Form, Cancel, WriteParameters);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.OnOpen
//
Procedure OnOpen(Form, Cancel) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenOpening(Form, Cancel);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.OnClose
//
Procedure OnClose(Form, Exit) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientAtClosing(Form);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.ExternalEvent
//
Procedure ExternalEvent(Form, Source, Event, Data) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientExternalEvent(Form, Source, Event, Data);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CommandHandlers

// See CommercialProposalsDocumentsClientOverridable.OpenProductSelectionForm_.
//
Procedure OpenProductSelectionForm_(Form, NotificationOnCompletion) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToCustomerOpenProductSelectionForm(Form, NotificationOnCompletion);
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.OpenUploadFormFromExternalFiles.
//
Procedure OpenUploadFormFromExternalFiles(Form, NotificationOnCompletion) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientToOpenDownloadFormFromExternalFiles(Form, NotificationOnCompletion);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInPaymentTerms.
//
Procedure WhenExecutingCommandFillInPaymentTerms(Form) Export
	
	ClearMessages();
	
	Object = Form.Object;
	
	If Not IsBlankString(Object.PaymentTermsText) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		
		QueryText = NStr("vi = 'Điều khoản thanh toán sẽ được bổ sung. Tiếp tục?';
						|ru = 'Условия оплаты будут перезаполнены. Продолжить?';
						|en = 'Payment terms will be repopulated. Continue?'; fa = 'Payment terms will be repopulated. Continue?';
						|it = 'Le condizioni di pagamento saranno ricompilate. Continuare?';
						|pl = 'Warunki płatności zostaną wypełnione ponownie. Kontynuować?';
						|tr = 'Ödeme şartları yeniden doldurulacaktır. Devam edilsin mi?'");
		NotificationAfterAnsweringQuestion = New CallbackDescription("AfterAnsweringQuestionAboutReFillingPaymentTerms", 
		                                                         ThisObject, 
		                                                         AdditionalParameters);
		
		ShowQueryBox(NotificationAfterAnsweringQuestion, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		SelectSourceOfPaymentTerms(Form);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInSupplierSPriceTypes.
//
Procedure WhenExecutingCommandFillInSupplierSPriceTypes(Form, CallbackDescription) Export
	
	Filter = New Structure;
	
	Filter.Insert("Owner",        Form.Object.Vendor);
	Filter.Insert("Currency",          Form.Object.Currency);
	Filter.Insert("PriceIncludesVAT", Form.Object.PriceIncludesVAT);
	
	FormParameters = New Structure("Filter", Filter);
	
	OpenForm("Catalog.VendorPriceTypes.ChoiceForm", FormParameters, Form, , , , CallbackDescription);
	
EndProcedure

#EndRegion

#Region SelectionOfTheNomenclature

// See CommercialProposalsDocumentsClientOverridable.SelectionProcessingProductSelection.
//
Procedure SelectionProcessingProductSelection(Form, NotificationOnCompletion, ValueSelected, ChoiceSource) Export

	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
			CommercialOfferToClientSelectionProcessingSelectionOfProducts(Form, NotificationOnCompletion, ValueSelected, ChoiceSource);
			
		ElsIf ChoiceSource.FormName = "DataProcessor.ImportGoodsFromExternalFiles.Form.Form" Then
			
			CommercialOfferToClientProcessingSelectionLoadingFromExternalFiles(Form, NotificationOnCompletion, ValueSelected, ChoiceSource);
			
		EndIf;
		
	EndIf;

EndProcedure

// See CommercialProposalsDocumentsClientOverridable.ProcessingAndSelectionOfProducts.
//
Procedure ProcessingAndSelectionOfProducts(Form, NotificationOnCompletion, EventName, Parameter, Source) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientNotificationProcessingSelectionOfProducts(Form, NotificationOnCompletion, EventName, Parameter, Source);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterProductSelectionProcess.
//
Procedure AfterProductSelectionProcess(Form, Result, AdditionalParameters, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferClientAfterInitialSelectionOfProductRange(Form, Result, AdditionalParameters, ServerCallRequired__);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterProcessingAndSelectingProducts.
//
Procedure AfterProcessingAndSelectingProducts(Form, ValueSelected, ProcessingResult, AdditionalParameters) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferCustomerAfterProcessingAndSelectionOfProducts(Form, ValueSelected, ProcessingResult, AdditionalParameters);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.SelectionProcessingProductSelection.
//
Procedure ShowBarcodeInput(Notification) Export
	
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterProcessingBarcodes_.
//
Procedure AfterProcessingBarcodes_(Form, ProcessingResult) Export
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(ProcessingResult, ProcessingResult.CachedValues, Form);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.StartLoadingDataFromTSD.
//
Procedure StartLoadingDataFromTSD(Form, CallbackOnCompletion) Export
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		CallbackOnCompletion, Form.UUID);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenReceivingDataFromTSD.
//
Procedure WhenReceivingDataFromTSD(CallbackOnCompletion, Var_ThisObject, ExecutionResult) Export
	
	If ExecutionResult.Result Then
		
		RunCallback(CallbackOnCompletion, ExecutionResult.TableOfGoods);
		
	Else
		
		MessageText = NStr("vi = 'Khi thực hiện thao tác đã xảy ra lỗi:""%ErrorDescription%"".';
							|ru = 'При выполнении операции произошла ошибка:""%ErrorDescription%"".';
							|en = 'An error occurred while executing the operation:""%ErrorDescription%"".'; fa = 'An error occurred while executing the operation:""%ErrorDescription%"".';
							|it = 'Si è verificato un errore durante esecuzione dell''operazione:""%ErrorDescription%"".';
							|pl = 'Przy wykonaniu operacji zaistniał błąd:""%ErrorDescription%"".';
							|tr = 'İşlem gerçekleştirilirken hata oluştu: ""%ErrorDescription%"".'");
		MessageText = StrReplace(MessageText, "%ErrorDescription%", ExecutionResult.ErrorDescription);
		CommonClient.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInPricesByPriceType.
//
Procedure WhenExecutingCommandFillInPricesByPriceType(Form, ChoiceNotification1) Export
	
	Object = Form.Object;
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Goods';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription =ChoiceNotification1;
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingCommandFillInPricesAccordingToTermsOfSale.
//
Procedure WhenExecutingCommandFillInPricesAccordingToTermsOfSale(Form, ChoiceNotification1) Export
	
	Object = Form.Object;
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Currency) Then
		
		MessageText = NStr("vi = 'Không có loại tiền được chỉ định. Giá không thể được điền.';
							|ru = 'Не указана валюта. Цены не могут быть заполнены.';
							|en = 'Currency is not specified. Prices cannot be populated.'; fa = 'Currency is not specified. Prices cannot be populated.';
							|it = 'Valuta non specificata. I prezzi non possono essere compilati.';
							|pl = 'Nie jest podana waluta. Ceny nie mogą być wypełnione.';
							|tr = 'Para birimi belirtilmedi. Fiyatlar doldurulamaz.'");
		CommonClient.MessageToUser(MessageText, , "Currency", "Object", Cancel);
		
	EndIf;
		
	If Object.Goods.Count() = 0 Then
		
		MessageText = NStr("vi = 'Phần bảng của ""Sản phẩm"" trống. Giá không thể được điền.';
							|ru = 'Табличная часть ""Товары"" пустая. Цены не могут быть заполнены.';
							|en = 'The ""Goods"" table is empty. Prices cannot be populated.'; fa = 'The ""Goods"" table is empty. Prices cannot be populated.';
							|it = 'Tabella ""Merci"" è vuota. I prezzi non possono essere compilati.';
							|pl = 'Część tabelaryczna ""Wiersze pozycji"" jest pusta. Ceny nie mogą być wypełnione.';
							|tr = '""Ürünler"" tablo kısmı boş. Fiyatlar doldurulamaz.'");
		CommonClient.MessageToUser(MessageText, , "Goods", "Object", Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Client) Then
		
		MessageText = NStr("vi = 'Không có khách hàng chỉ định. Giá không thể được điền.';
							|ru = 'Не указан клиент. Цены не могут быть заполнены.';
							|en = 'Customer is not specified. Prices cannot be populated.'; fa = 'Customer is not specified. Prices cannot be populated.';
							|it = 'Cliente non specificato. I prezzi non possono essere compilati.';
							|pl = 'Nie jest podany klient. Ceny nie mogą być wypełnione.';
							|tr = 'Müşteri belirtilmedi. Fiyatlar doldurulamaz.'");
		CommonClient.MessageToUser(MessageText, , "Client", "Object", Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		
		MessageText = NStr("vi = 'Không có hoạt động được chỉ định. Giá không thể được điền.';
							|ru = 'Не указана операция. Цены не могут быть заполнены.';
							|en = 'Transaction is not specified. Prices cannot be populated.'; fa = 'Transaction is not specified. Prices cannot be populated.';
							|it = 'Operazione non specificata. I prezzi  non possono essere compilati.';
							|pl = 'Nie jest podana operacja. Ceny nie mogą być wypełnione.';
							|tr = 'İşlem belirtilmedi. Fiyatlar doldurulamaz.'");
		CommonClient.MessageToUser(MessageText, , "BusinessOperation", "Object", Cancel);
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DocumentDate",         Object.Date);
	OpeningParameters.Insert("Partner",               Object.Client);
	OpeningParameters.Insert("BusinessOperation", 
		CommercialProposalsDocumentsClientServerTM.BusinessTransactionOfDocumentCommercialOfferToClient(Object.BusinessOperation));
		
		Filter = New Structure;
		Filter.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		
	If ValueIsFilled(Object.Organization) Then
		Filter.Insert("Organization", Object.Organization);
	EndIf;
	
	OpeningParameters.Insert("Filter", Filter);
	
	OpenForm("Catalog.TermsOfSale.ChoiceForm", OpeningParameters, Form,,,,
	             ChoiceNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingSplitLineCommand.
//
// Parameters:
//  Form                 - ClientApplicationForm
//  CurrentRow         - FormDataCollectionItem
//  CallbackOnCompletion - CallbackDescription
//
Procedure WhenExecutingSplitLineCommand(Form, CurrentRow, CallbackOnCompletion) Export
	
	FormTable  = Form.Items.Goods;
	TableData = Form.Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity          = "Count";
	StringSplittingParameters.AllowZeroCount = False;
	
	ProcessingOfTabularFormsClient.SplitRow(
		TableData,
		FormTable,
		CallbackOnCompletion,
		StringSplittingParameters);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingSplitLineCommand.
//
Procedure WhenExecutingCalculateDiscountsCommand(Form, ServerCallRequired__) Export
	
	ServerCallRequired__ = True;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingOpenDiscountInformationCommand.
//
Procedure WhenExecutingOpenDiscountInformationCommand(Form, ServerCallRequired__) Export
	
	ServerCallRequired__ = True;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingOpenDiscountInformationCommand.
//
Procedure WhenExecutingAssignManualDiscountCommand(Form, SelectedRows, StandardProcessing, ServerCallRequired__) Export
	
	StandardProcessing = False;
	Object = Form.Object;

	If DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Towary';
																									|tr = 'Ürünler'")) Then
		ServerCallRequired__ = True;
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingAssignAutomaticDiscountsCommand.
//
Procedure WhenExecutingAssignAutomaticDiscountsCommand(Form, CallbackOnCompletion, ServerCallRequired__) Export
	
	ServerCallRequired__ = True;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterAssigningAutomaticDiscount.
//
Procedure AfterAssigningAutomaticDiscount(Form, Result, ServerCallRequired__) Export
	
	Form.ManagedDiscounts = Result;
	ServerCallRequired__ = True;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterCalculatingAssignedAutomaticDiscounts.
//
Procedure AfterCalculatingAssignedAutomaticDiscounts(Form, Result) Export
	
	If TypeOf("Result") = Type("Structure") 
		And Result.Property("Messages")
		And Result.Messages.Count() > 0 
		And Result.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", Result, Form, Form.UUID);
	EndIf;
		
	ShowUserNotification(
		NStr("vi = 'Chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки)';
			|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
			|it = 'Sconti (sovrapprezzo)';
			|pl = 'Rabaty (marże)';
			|tr = 'İndirimler (zamlar)'"),
		,
		NStr("vi = 'Đã tính chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки) рассчитаны';
			|en = 'Discount (markups) are calculated'; fa = 'Discount (markups) are calculated';
			|it = 'Sconti (sovrapprezzi) sono calcolati';
			|pl = 'Rabaty (marże) są obliczone';
			|tr = 'İndirim (marj) uygulandı'"),
		PictureLib.Information32);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterPreparingAppointmentOfAutomaticDiscounts.
//
Procedure AfterPreparingAppointmentOfAutomaticDiscounts(Form, CallbackOnCompletion, Result) Export
	
	DiscountsMarkupsFillingClient.OpenManagedDiscountMarkUpAssignmentForm(Result, CallbackOnCompletion);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterPreparingAssignmentOfManualDiscounts.
//
// Parameters:
//  Form                                 - ClientApplicationForm
//  SelectedRows                      - Array
//  NotificationAfterAssigningManualDiscount - CallbackDescription
//  ProcessingResult                    - Arbitrary
//
Procedure AfterPreparingAssignmentOfManualDiscounts(Form, SelectedRows, NotificationAfterAssigningManualDiscount, ProcessingResult) Export
	
	NotificationAfterAssigningManualDiscount.AdditionalParameters.Insert("AddressInTempStorage", ProcessingResult);
	NotificationAfterAssigningManualDiscount.AdditionalParameters.Insert("StandardProcessing",      False);
	NotificationAfterAssigningManualDiscount.AdditionalParameters.Insert("ServerCallRequired__",   True);
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		ProcessingResult,
		Form.Object.Currency,
		NotificationAfterAssigningManualDiscount);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterCompletingAssignmentOfManualDiscounts.
//
Procedure AfterCompletingAssignmentOfManualDiscounts(Form, SelectedRows, Result) Export
	
	Object = Form.Object;
	
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(Result, Object.Currency);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingOpenDiscountInformationCommand.
//
Procedure WhenExecutingCancelManualDiscountsCommand(Form, SelectedRows, PriceIncludesVAT, Taxation, ServerCallRequired__) Export
	
	Object = Form.Object;
	
	If DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Towary';
																										|tr = 'Ürünler'")) Then
		ServerCallRequired__ = True;
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterCancelingManualDiscounts.
//
Procedure AfterCancelingManualDiscounts(Form, SelectedRows, ProcessingResult) Export
	
	 DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingOverridableCommand.
//
Procedure WhenExecutingOverridableCommand(Form, Command, ServerCallRequired__) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientWhenExecutingOverridableCommand(Form, Command, ServerCallRequired__);
		
	EndIf;
	
	FormEventsClient.ExecuteOverridableCommand(Form, Command);
		
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.ExecutePlugInIntegrationCommand.
//
Procedure ExecutePlugInIntegrationCommand(Command, Form, Object) Export
	
	CommercialProposalsDocumentsClientLocalization.ExecutePlugInIntegrationCommand(Command, Form, Object);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.SuggestUserToCalculateDiscounts.
//
Procedure SuggestUserToCalculateDiscounts(Var_ThisObject, Cancel, NotificationAfterClose) Export
	
	DiscountsMarkupsFillingClient.SuggestUserToCalculateDiscounts(NotificationAfterClose);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterExecutingRedefinedCommand.
//
Procedure AfterExecutingRedefinedCommand(Form, Command, Result) Export
	
	If Form.FormName = "Document.CommercialProposalForCustomer.Form.DocumentForm" Then
		
		CommercialOfferToClientAfterExecutingRedefinedCommand(Form, Command, Result);
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterCalculatingDiscounts.
//
Procedure AfterCalculatingDiscounts(Form, CalculationResult2) Export
	
	If CalculationResult2.Messages.Count() > 0 And CalculationResult2.AutomaticallyOpen Then
		OpenForm("CommonForm.MessagesOfDiscountsMarkups", CalculationResult2, Form, Form.UUID);
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки)';
			|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
			|it = 'Sconti (sovrapprezzo)';
			|pl = 'Rabaty (marże)';
			|tr = 'İndirimler (zamlar)'"),
		,
		NStr("vi = 'Đã tính chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки) рассчитаны';
			|en = 'Discount (markups) are calculated'; fa = 'Discount (markups) are calculated';
			|it = 'Sconti (sovrapprezzi) sono calcolati';
			|pl = 'Rabaty (marże) są obliczone';
			|tr = 'İndirim (marj) uygulandı'"),
		PictureLib.Information32);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterPreparingOpeningOfInformationAboutDiscounts.
//
Procedure AfterPreparingOpeningOfInformationAboutDiscounts(Form, Result) Export
	
	Items = Form.Items;
	Object   = Form.Object;
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("Messages")
		And Result.Messages.Count() > 0 
		And Result.AutomaticallyOpen Then
		
		OpenForm("CommonForm.MessagesOfDiscountsMarkups", Result, Form, Form.UUID);
		
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ColumnNameQuantity", "Count");
	DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, Form, OpeningParameters);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.OpenSupplierOrderListForm.
//
Procedure OpenSupplierOrderListForm(Val ReferencesArrray) Export

	FixedSettings = New DataCompositionSettings;
	
	CommonClientServer.SetFilterItem(FixedSettings.Filter,
				"Ref",
				ReferencesArrray,
				DataCompositionComparisonType.InList);
	
	OpeningParameters = New Structure("FixedSettings, ReadOnly", FixedSettings, True);
	
	OpenForm("Document.PurchaseOrder.ListForm", OpeningParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region CommercialProposalForCustomer

Procedure CommercialOfferToClientWhenOpening(Form, Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, Form, "BarcodeScanner");
	
EndProcedure

Procedure CommercialOfferToClientAtClosing(Form)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, Form);
	
EndProcedure

Procedure CommercialOfferToClientExternalEvent(Form, Source, Event, Data)
	
	If Not Form.IsInputAvailable() Then
		Return;
	EndIf;
	
	EventDescription1 = New Structure;
	EventDescription1.Insert("Source", Source);
	EventDescription1.Insert("Event" , Event);
	EventDescription1.Insert("Data"  , Data);
	
	Result = EquipmentManagerClient.GetEventFromDevice(EventDescription1); // EquipmentManagerClient.GetEventFromDevice
	
	If Result <> Undefined
		And Result.Source = "Peripherals"
		And Result.EventName = "ScanData"
		And StrFind(Form.SupportedPeripheralTypes, "BarcodeScanner") > 0 Then
		
		ClearMessages();
		
		BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Result.Parameter);
		
		If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
			Return;
		EndIf;
		
		RunCallback(New CallbackDescription("SearchByBarcodeCompletion", Form), BarcodeData_5);
		
	EndIf;
	
EndProcedure

Procedure CommercialProposalForCustomerBeforeWrite(Form, Cancel, WriteParameters)
	
	If Form.AccountingSettings.AutomaticDiscountsInSalesAreUsed
		And Not Form.Object.DiscountsAreCalculated Then
		WriteParameters.QuestionAboutCalculatingDiscountsIsRequired = True;
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientWhenProductRangeChanges(Form, CurrentRow, CurrentItem, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	CachedValues    = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);  
	ParametersFillInVATRate.VATTaxation = Form.VATTaxation;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",          CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner",       CurrentRow.UnitOfMeasure);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
		
	StructureOfActions.Insert("FillInVATRate",                          ParametersFillInVATRate);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);  
	ParametersFillInVATRate.VATTaxation = Form.VATTaxation;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);

	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",
		New Structure("Clear, QuantityName", True, "Count"));
		
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",
		New Structure("Clear, QuantityName", True, "Count"));
		
	StructureOfActions.Insert("ProductsOnChangeOverridable",    StructureOverridableActions(Form));
	
	CurRowStructure = BatchProcessingOfTablePartClientServer.GetCurLine(
		CurrentRow, StructureOfActions, CachedValues);
		
	CurRowStructure.Insert("Package", CurrentRow.UnitOfMeasure);
	CurRowStructure.Insert("NumberOfPackages", CurrentRow.Count);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurRowStructure, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentRow, CurRowStructure);
	CurrentRow.UnitOfMeasure    = CurRowStructure.Package;
	CurrentRow.QuantityIsTemporary = CurRowStructure.Count;
	CurrentRow.Count          = CurRowStructure.NumberOfPackages;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenCharacteristicsChange(Form, CurrentRow, CurrentItem, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInSalePrice",                        BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",         New Structure("Clear, QuantityName", True, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear, QuantityName", True, "Count"));
	StructureOfActions.Insert("CharacteristicOnChangeOverridable",  StructureOverridableActions(Form));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingUnitOfMeasurement(Form, CurrentRow, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	CachedValues    = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;

	If ValueIsFilled(CurrentRow.PriceKind) Then
		PriceFillingStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
		PriceFillingStructure.Insert("ColumnNamePackaging", "Package");
		StructureOfActions.Insert("FillInSalePrice", PriceFillingStructure);
	ElsIf CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.QuantityIsTemporary);
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",
		New Structure("Clear, QuantityName", False,   "Count"));
		
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",
		New Structure("Clear, QuantityName", True, "Count"));

	CurRowStructure = BatchProcessingOfTablePartClientServer.GetCurLine(
		CurrentRow, StructureOfActions, CachedValues);
		
	CurRowStructure.Insert("Package", CurrentRow.UnitOfMeasure);
	CurRowStructure.Insert("NumberOfPackages", CurrentRow.Count);
	CurRowStructure.Count = CurrentRow.QuantityIsTemporary;
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurRowStructure, StructureOfActions, CachedValues);
		
	FillPropertyValues(CurrentRow, CurRowStructure);

	CurrentRow.QuantityIsTemporary = CurRowStructure.Count;
	CurrentRow.Count = CurRowStructure.NumberOfPackages;
	CurrentRow.UnitOfMeasure = CurRowStructure.Package;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form)
	
EndProcedure

Procedure CommercialOfferToClientWhenQuantityChanges(Form, CurrentRow, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	CachedValues    = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",
		New Structure("Clear, QuantityName", False,   "Count"));
		
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",
		New Structure("Clear, QuantityName", True, "Count"));
	
	CurRowStructure = BatchProcessingOfTablePartClientServer.GetCurLine(
		CurrentRow, StructureOfActions, CachedValues);
		
	CurRowStructure.Insert("Package", CurrentRow.UnitOfMeasure);
	CurRowStructure.Insert("NumberOfPackages", CurrentRow.Count);
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurRowStructure, StructureOfActions, CachedValues);

	FillPropertyValues(CurrentRow, CurRowStructure);

	CurrentRow.QuantityIsTemporary = CurRowStructure.Count;
	CurrentRow.Count = CurRowStructure.NumberOfPackages;

	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingTypeOfPrice(Form, CurrentRow, ServerCallRequired__)
	
	ClearMessages();
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	CachedValues    = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",
		New Structure("Clear, QuantityName", False,   "Count"));
		
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",
		New Structure("Clear, QuantityName", True, "Count"));
		
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	CurRowStructure = BatchProcessingOfTablePartClientServer.GetCurLine(
		CurrentRow, StructureOfActions, CachedValues);
		
	CurRowStructure.Insert("Package", CurrentRow.UnitOfMeasure);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurRowStructure, StructureOfActions, CachedValues);
		
	FillPropertyValues(CurrentRow, CurRowStructure);

	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenPriceChanges(Form, CurrentRow, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice",                        BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",         New Structure("Clear, QuantityName", False,   "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear, QuantityName", True, "Count"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenVATRateChanges(Form, CurrentRow, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",         New Structure("Clear, QuantityName", False,   "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear, QuantityName", True, "Count"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenAmountChanges(Form, CurrentRow, ServerCallRequired__)
	
	Object = Form.Object;
	
	ThisIsTransferOfGoods = Object.BusinessOperation = PredefinedValue("Enum.KindsOfCommercialProposalProcedures.ConsignmentProcurement");
	
	StructureOfPriceConversion  = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInWHSales(Object, ThisIsTransferOfGoods);
	StructureOfPriceConversion.Insert("QuantityName", "Count");
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", StructureOfPriceConversion);
	StructureOfActions.Insert("RecalculateVATAmount",                   StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                  StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingAmountOfVAT(Form, CurrentRow, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingPercentageOfManualDiscount(Form, CurrentRow, ServerCallRequired__)
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount",                "Count");
	StructureOfActions.Insert("RecalculateAmount",                            "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",         New Structure("Clear, QuantityName", False,   "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateVATAmount",                         StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                        StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingAmountOfManualDiscount(Form, CurrentRow, ServerCallRequired__) 
	
	Object                  = Form.Object;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount",               "Count");
	StructureOfActions.Insert("RecalculateAmount",                             "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",          New Structure("Clear, RecalculateAmountOfManualDiscount_, QuantityName",
	                                                                                           False, False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount",  New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateVATAmount",                          StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                         StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.TabularPartSelection.
//
// Parameters:
//  Form                - ClientApplicationForm
//  Item              - FormTable
//  RowSelected      - Number
//  Field                 - FormField
//  StandardProcessing - Boolean
//  ServerCallRequired__ - Boolean
//
Procedure CommercialOfferToClientToChooseFrom(Form, Item, RowSelected, Field, StandardProcessing, ServerCallRequired__)
	
	Object = Form.Object; // DocumentObject.CommercialProposalForCustomer
	
	If Item.Name = "Goods" Then
	
		If ValueIsFilled(Form.Items.Goods.CurrentData.ProductsInSet) Then
			
			If Field.Name <> "GoodsCommentForCustomer"
				Or Field.Name <> "GoodsInternalComment" Then
			
				ServerCallRequired__ = True;
				
			EndIf;
			
		Else
			
			If Field.Name = "GoodsPrice" Then
			
				If ValueIsFilled(Form.Items.Goods.CurrentData.ProductsInSet) Then
					ServerCallRequired__ = True;
					Return;
				EndIf;
				
				CurrentData = Form.Items.Goods.CurrentData;
				If ValueIsFilled(CurrentData.PriceKind) Then
					ClearMessages();
					CommonClient.MessageToUser(
						NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
							|ru = 'Для редактирования цены очистите вид цены';
							|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
							|it = 'Для редактирования цены очистите вид цены';
							|pl = 'To edit the price, clear the price type';
							|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
						Object.Ref,
						CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
				EndIf;
				
			EndIf;
			
		EndIf;

	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientWhenPartnerChanges(Form, ServerCallRequired__)
	
	ServerCallRequired__ = True;
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientInCaseOfChangesInVATTaxation(Form, ServerCallRequired__)
	
	ServerCallRequired__ = True;
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingPriceIncludesVAT(Form, ServerCallRequired__)
	
	ServerCallRequired__ = True;
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	
EndProcedure

Procedure CommercialOfferToClientWhenChangingWhenChangingCurrency(Form, ServerCallRequired__)
	
	Object = Form.Object;
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, Form.DocumentCurrency) Then
		
		ServerCallRequired__ = True;
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(Form.DocumentCurrency, Object.Currency);
		
	EndIf;
	
	If Not ServerCallRequired__ Then
		Form.DocumentCurrency = Object.Currency;
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);

EndProcedure

Procedure CommercialOfferToClientWhenOrganizationChanges(Form, ServerCallRequired__)
	
	ServerCallRequired__ = True;
	
EndProcedure

Procedure CommercialOfferToClientInCaseOfChangeOfBusinessOperation(Form, ServerCallRequired__);
	
	ServerCallRequired__ = True;
	
EndProcedure

Procedure CommercialOfferToClientWhenManagerChanges(Form, ServerCallRequired__)

	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);

EndProcedure

Procedure CommercialOfferToCustomerOpenProductSelectionForm(Form, NotificationOnCompletion)
	
	Object = Form.Object; // DocumentObject
	
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
										|ru = 'Поле ""Валюта"" не заполнено';
										|en = '""Currency"" is required'; fa = '""Currency"" is required';
										|it = 'Il campo ""Valuta"" non è compilato';
										|pl = 'Pole ""Waluta"" nie jest wypełnione';
										|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency");
		Return;
	EndIf;
	
	If Form.AccountingSettings.TypesOfPricesAreUsed Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
		
		NotificationAfterSelectingPriceForSelection = New CallbackDescription("AfterSelectingPricesForSelection", ThisObject, AdditionalParameters);
		
		PriceTypePriceList_ = PriceManagementSystemServerCall.PriceTypePriceList_();
		If PriceTypePriceList_ <> Undefined Then
			RunCallback(NotificationAfterSelectingPriceForSelection, PriceTypePriceList_);
			Return;
		EndIf;
		
		StructureFilter = New Structure;
		StructureFilter.Insert("PriceIncludesVAT",        Object.PriceIncludesVAT);
		StructureFilter.Insert("UseWhileSellingToCustomers", True);
		
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("Filter", StructureFilter);
		FormOpenParameters.Insert("Title", NStr("vi = 'Dạng giá để hiển thị trong lựa chọn';
												|ru = 'Вид цены для отображения в подборе';
												|en = 'Price type for display in picking'; fa = 'Price type for display in picking';
												|it = 'Aspetto del prezzo da visualizzare nella selezione';
												|pl = 'Rodzaj ceny dla odzwierciedlenia w filtrze';
												|tr = 'Seçimde görüntüleme için fiyat türü'"));
		
		OpenForm("Catalog.TypesOfPrices.ChoiceForm",
		             FormOpenParameters,,,,,
		             NotificationAfterSelectingPriceForSelection);
		
	Else
		
		CommercialOfferToCustomerOpenProductSelectionFormContinued(Form, PredefinedValue("Catalog.TypesOfPrices.EmptyRef"), NotificationOnCompletion);
		
	EndIf;
	
EndProcedure

Procedure AfterSelectingPricesForSelection(Result, AdditionalParameters) Export

	If Result = Undefined Then
		PriceKind = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
	Else
		PriceKind = Result;
	EndIf;
	
	CommercialOfferToCustomerOpenProductSelectionFormContinued(AdditionalParameters.Form, 
	                                                                         PriceKind, 
	                                                                         AdditionalParameters.NotificationOnCompletion);
	
EndProcedure

Procedure CommercialOfferToCustomerOpenProductSelectionFormContinued(Form, PriceKind, NotificationOnCompletion) Export
	
	Object = Form.Object;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'Báo giá cho khách hàng';
																			|ru = 'коммерческое предложение клиенту';
																			|en = 'sales quotation'; fa = 'sales quotation';
																			|it = 'offerta commerciale al cliente';
																			|pl = 'oferta cenowa do klienta';
																			|tr = 'Satış teklifi'"));
	EndIf;
	
	ArrayOfSelectionsByProductType = CommercialProposalsDocumentsClientServerTM.ArrayOfSelectionsByProductType(Object.BusinessOperation);
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization",                         Object.Organization);
	FormParameters.Insert("PriceIncludesVAT",                     Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation",                  Form.VATTaxation);
	FormParameters.Insert("FilterByProductType",             ArrayOfSelectionsByProductType);
	FormParameters.Insert("HideManualDiscounts",                Object.BusinessOperation = PredefinedValue("Enum.KindsOfCommercialProposalProcedures.ConsignmentProcurement"));
	FormParameters.Insert("AllWarehouseBalance",                True);
	FormParameters.Insert("Currency",                              Object.Currency);
	FormParameters.Insert("Title",                           HeaderParameter_);
	FormParameters.Insert("Date",                                Object.Date);
	FormParameters.Insert("Document",                            Object.Ref);
	FormParameters.Insert("PriceKind",                             PriceKind);
	FormParameters.Insert("SelectionModeWithoutAgreementsWithCustomers", True);
	
	If Form.OnRequest Then
		
		FormParameters.Insert("DoNotSplitSetsByComponents",True);
		
		OptionsForPresentationOfSetInPrintedForms = New Array;
		OptionsForPresentationOfSetInPrintedForms.Add(PredefinedValue("Enum.OptionsOfSetPresentationInPrintForms.EmptyRef"));
		OptionsForPresentationOfSetInPrintedForms.Add(PredefinedValue("Enum.OptionsOfSetPresentationInPrintForms.OnlySet"));
		
		FormParameters.Insert("SelectionAccordingToVariantOfPresentationOfSetInPrintedForms", OptionsForPresentationOfSetInPrintedForms);
		
	EndIf;
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, Form, Form.UUID);
	
EndProcedure

Procedure CommercialOfferToClientSelectionProcessingSelectionOfProducts(Form, NotificationOnCompletion, ValueSelected, ChoiceSource)
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	RunCallback(NotificationOnCompletion, ValueSelected);
	
EndProcedure

Procedure CommercialOfferToClientProcessingSelectionLoadingFromExternalFiles(Form, NotificationOnCompletion, ValueSelected, ChoiceSource);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(Form);
	RunCallback(New CallbackDescription("ImportFromExternalFileCompletion", Form), ValueSelected);
	
EndProcedure

Procedure CommercialOfferToClientNotificationProcessingSelectionOfProducts(Form, NotificationOnCompletion, EventName, Parameter, Source)
	
	If Source = "Peripherals"
		And EventName = "UnknownBarcodes"
		And Parameter.OwnerForm = Form.UUID Then
		
		ClearMessages();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
			Return;
		EndIf;
		
		RunCallback(New CallbackDescription("SearchByBarcodeCompletion", Form), BarcodeData_5);
		
	ElsIf EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = Form.UUID Then
		
		Parameter.Insert("EditSet", True);
		RunCallback(NotificationOnCompletion, Parameter);
		
	ElsIf EventName = "EditSet"
		And Parameter.OwnerForm = Form.UUID Then
		
		Parameter.Insert("EditSet", True);
		RunCallback(NotificationOnCompletion, Parameter);
		
	EndIf;
	
EndProcedure

Procedure CommercialOfferClientAfterInitialSelectionOfProductRange(Form, Result, AdditionalParameters, ServerCallRequired__)
	
	If TypeOf(Result) = Type("String") Then
		
		If SetsClient.EditSetAction(Result) Then
			SetsClient.WhenRemovingComponents(Form, "Goods", AdditionalParameters)
		ElsIf SetsClient.DeleteEntireSetAction(Result) Then
			ServerCallRequired__ = True;
		EndIf;
		
	ElsIf TypeOf(Result) = Type("Structure") Then
		If Result.Property("GoodsAddressInStorage") Then
			ServerCallRequired__ = True;
		ElsIf Result.Property("EditSet") Then
			ServerCallRequired__ = True;
		ElsIf Result.Property("EditSet") Then
			ServerCallRequired__ = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure CommercialOfferCustomerAfterProcessingAndSelectionOfProducts(Form, ValueSelected, ProcessingResult, AdditionalParameters)
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		
		If ValueSelected.Property("EditSet") Then
		
			If ProcessingResult <> Undefined Then
				
				OpenForm("DataProcessor.EditSet.Form.Form", ProcessingResult, Form, Form.UUID);
				
			EndIf;
			
		ElsIf ValueSelected.Property("EditSet") Then
			
			Form.Attachable_CalculateFormTotals();
			Form.Modified = True;
			
		ElsIf ValueSelected.Property("GoodsAddressInStorage") Then
			
			Form.Attachable_CalculateFormTotals();
			Form.Modified = True;
			
		EndIf;
		
	ElsIf TypeOf(ValueSelected) = Type("String")
		And ValueSelected = "DeleteEntireSet" Then
		
		Form.Attachable_CalculateFormTotals();
		Form.Modified = True;
		
	EndIf;
	
EndProcedure

Procedure CommercialOfferToClientToOpenDownloadFormFromExternalFiles(Form, NotificationOnCompletion)
	
	Object = Form.Object;
	
	ArrayOfSelectionsByProductType = CommercialProposalsDocumentsClientServerTM.ArrayOfSelectionsByProductType(Object.BusinessOperation);
	
	FormParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	
	FormParameters.ImportPrices      = True;
	FormParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	FormParameters.Organization        = Object.Organization;
	FormParameters.VATTaxation = Form.VATTaxation;
	FormParameters.FillingDate     = Object.Date;
	FormParameters.FilterParameters.Insert("ItemsType", New FixedArray(ArrayOfSelectionsByProductType));
	
	ProcessingOfTabularFormsClient.ShowProductUploadForm(FormParameters, NotificationOnCompletion);
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.WhenExecutingOverridableCommand.
//
// Parameters:
//  Form                   - ClientApplicationForm
//  Command                 - FormCommand
//  ServerCallRequired__ - Boolean
//
Procedure CommercialOfferToClientWhenExecutingOverridableCommand(Form, Command, ServerCallRequired__)
	
	Items = Form.Items;
	
	If Command.Name = "ShowMessages" Then
		
		ServerCallRequired__ = True;
		
	ElsIf Command.Name = "ShowSets" Then
		
		Items.ProductsGroupSets.Visible = Not Items.ProductsGroupSets.Visible;
		Items.ShowSets.Check       = Not Items.ShowSets.Check;
		
	ElsIf Command.Name = "SetComposition" Then
		
		ServerCallRequired__ = True;
		
	EndIf;
	
EndProcedure

// See CommercialProposalsDocumentsClientOverridable.AfterExecutingRedefinedCommand.
//
// Parameters:
//  Form      - ClientApplicationForm
//  Command    - FormCommand
//  Result  - Arbitrary
//
Procedure CommercialOfferToClientAfterExecutingRedefinedCommand(Form, Command, Result)

	If Command.Name = "ShowMessages" Then
		
		DiscountsMarkupsFillingClient.OpenMessageForm(Result, Form);
		
	ElsIf Command.Name = "SetComposition" Then
		
		If Result <> Undefined Then
			
			OpenForm("DataProcessor.EditSet.Form.Form", Result, Form, Form.UUID);
			
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

Function StructureOverridableActions(Form) Export
	
	StructureOverridableActions = New Structure;
	StructureOverridableActions.Insert("FormName",          Form.FormName);
	StructureOverridableActions.Insert("TabularSectionName", "Goods");
	
	Return StructureOverridableActions;
	
EndFunction

Procedure SelectSourceOfPaymentTerms(Form)
	
	Object = Form.Object;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	
	DescriptionAboutSelectingConditions = New CallbackDescription("AfterChoosingPaymentTerms", ThisObject, AdditionalParameters);
	
	If Form.ToUseTermsOfSales Then
		
		Cancel = False;
		
		If Not ValueIsFilled(Object.Currency) Then
			
			MessageText = NStr("vi = 'Không có loại tiền được chỉ định. Giá không thể được điền.';
								|ru = 'Не указана валюта. Цены не могут быть заполнены.';
								|en = 'Currency is not specified. Prices cannot be populated.'; fa = 'Currency is not specified. Prices cannot be populated.';
								|it = 'Valuta non specificata. I prezzi non possono essere compilati.';
								|pl = 'Nie jest podana waluta. Ceny nie mogą być wypełnione.';
								|tr = 'Para birimi belirtilmedi. Fiyatlar doldurulamaz.'");
			CommonClient.MessageToUser(MessageText, , "Currency", "Object", Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(Object.Client) Then
			
			MessageText = NStr("vi = 'Không có khách hàng chỉ định. Giá không thể được điền.';
								|ru = 'Не указан клиент. Цены не могут быть заполнены.';
								|en = 'Customer is not specified. Prices cannot be populated.'; fa = 'Customer is not specified. Prices cannot be populated.';
								|it = 'Cliente non specificato. I prezzi non possono essere compilati.';
								|pl = 'Nie jest podany klient. Ceny nie mogą być wypełnione.';
								|tr = 'Müşteri belirtilmedi. Fiyatlar doldurulamaz.'");
			CommonClient.MessageToUser(MessageText, , "Client", "Object", Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(Object.BusinessOperation) Then
			
			MessageText = NStr("vi = 'Không có hoạt động được chỉ định. Giá không thể được điền.';
								|ru = 'Не указана операция. Цены не могут быть заполнены.';
								|en = 'Transaction is not specified. Prices cannot be populated.'; fa = 'Transaction is not specified. Prices cannot be populated.';
								|it = 'Operazione non specificata. I prezzi  non possono essere compilati.';
								|pl = 'Nie jest podana operacja. Ceny nie mogą być wypełnione.';
								|tr = 'İşlem belirtilmedi. Fiyatlar doldurulamaz.'");
			CommonClient.MessageToUser(MessageText, , "BusinessOperation", "Object", Cancel);
			
		EndIf;
		
		If Cancel Then
			Return;
		EndIf;
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("DocumentDate",         Object.Date);
		OpeningParameters.Insert("Partner",               Object.Client);
		OpeningParameters.Insert("BusinessOperation", 
		CommercialProposalsDocumentsClientServerTM.BusinessTransactionOfDocumentCommercialOfferToClient(Object.BusinessOperation));
		OpeningParameters.Insert("Organization",           Object.Organization);
		
		Filter = New Structure;
		Filter.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		
		OpeningParameters.Insert("Filter", Filter);
		
		OpenForm("Catalog.TermsOfSale.ChoiceForm", OpeningParameters, Form,,,,
		              DescriptionAboutSelectingConditions, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Form.UsePaymentSchedules Then
		
		OpenForm("Catalog.PaymentSchedules.ChoiceForm", OpeningParameters, Form,,,,
		              DescriptionAboutSelectingConditions, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

Procedure AfterAnsweringQuestionAboutReFillingPaymentTerms(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		
		SelectSourceOfPaymentTerms(AdditionalParameters.Form);
		
	EndIf;

EndProcedure

Procedure AfterChoosingPaymentTerms(Result, AdditionalParameters) Export

	If Result <> Undefined Then
		
		Form = AdditionalParameters.Form;
		
		Form.Object.PaymentTermsText = CommercialProposalsDocumentsTMServerCall.PaymentTermsByText(Result);
		
	EndIf;

EndProcedure

#EndRegion
