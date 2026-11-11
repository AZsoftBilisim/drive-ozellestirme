
////////////////////////////////////////////////////////////////////////////////
// The "Divergenclient" module contains client procedures and functions for 
// the operation of documents to reflect discrepancies after shipment.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region ListAndSelectionForms

Function SelectionParametersOfListOfDocumentsOfActOfDiscrepanciesAfterShipment() Export
	
	Array = New Array();
	Array.Add("Currency");
	Array.Add("Organization");
	Array.Add("Partner");
	Array.Add("Counterparty");
	
	Return Array;
	
EndFunction

Function ParametersForSelectingListOfDocumentsInDiscrepancyReportAfterMoving() Export
	
	Array = New Array();
	Array.Add("Organization");
	Array.Add("CompanyRecipient");
	Array.Add("SourceWarehouse");
	Array.Add("DestinationWarehouse");
	
	Return Array;
	
EndFunction

// Parameters:
// 	Form							 - ClientApplicationForm - The Form Of The client application contains, among other things:
// 		* List - DynamicList - Dynamic list on the form
// 	Item							 - FormTable - form table
// 	Cancel							 - Boolean - Flag for refusing to add an item
// 	Copy						 - Boolean - Defines the copy mode
// 	ThisIsActOfDiscrepanciesAfterShipment_	 - Boolean - Defines the document type.
// 
Procedure ActOnDiscrepanciesListBeforeStartOfAddition(Form, Item, Cancel, Copy, ThisIsActOfDiscrepanciesAfterShipment_) Export

	Cancel = True;
	
	If ThisIsActOfDiscrepanciesAfterShipment_ Then
		DefaultActionType = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice");
		If UsersClient.IsExternalUserSession() Then
			NameOfFormToOpen_ = "Document.DiscrepancyReportFollowingShipment.Form.SelfServiceWorkplaceDocumentForm";
		Else
			NameOfFormToOpen_ = "Document.DiscrepancyReportFollowingShipment.Form.DocumentForm";
		EndIf;
	Else
		DefaultActionType = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice");
		NameOfFormToOpen_ = "Document.DiscrepancyReportFollowingReceipt.Form.DocumentForm";
	EndIf;
	
	FilterParameters = SelectionParametersOfListOfDocumentsOfActOfDiscrepanciesAfterShipment();
	FormParameters = ReportOfDiscrepanciesListAndFillInParameters(Item.CurrentRow, 
		Form.List.SettingsComposer.UserSettings.Items, FilterParameters, Copy);
		
	If Not Copy Then
		FormParameters.FillingValues.Insert("TypeOfBaseDocumentForNonConformanceCertificate",
			?(ValueIsFilled(Form.TypeOfBaseDocumentForNonConformanceCertificate),
				Form.TypeOfBaseDocumentForNonConformanceCertificate,
				DefaultActionType));
	EndIf;
	
	OpenForm(NameOfFormToOpen_, FormParameters, Form.Items.List, Form);
	
EndProcedure

// Returns data for filling in the form of a new document Actorextensions
//
// Parameters:
//  CurrentRow				 - DocumentRef.DiscrepancyReportFollowingShipment, DocumentRef.DiscrepancyReportFollowingTransfer - 
//  UserSettings	 - DataCompositionUserSettingsItemCollection - Document list form settings
//  FilterParameters				 - Array - Array of strings with names of key fields in the document header
//  Copy					 - Boolean - Defines the copy mode
// 
// Returns:
//   Structure - 
//
Function ReportOfDiscrepanciesListAndFillInParameters(CurrentRow, UserSettings, FilterParameters, Copy) Export
	
	FormParameters = New Structure;
	
	If Copy And CurrentRow <> Undefined Then
		FormParameters.Insert("CopyingValue", CurrentRow);
	Else
		
		SelectingUserSettings = Undefined;
		
		For Each SettingsItem In UserSettings Do
			If TypeOf(SettingsItem) = Type("DataCompositionFilter") Then
				SelectingUserSettings = SettingsItem;
			EndIf;
		EndDo;
		
		FillingValues = New Structure;
		
		If SelectingUserSettings <> Undefined Then
			
			For Each FilterElement In SelectingUserSettings.Items Do
				If TypeOf(FilterElement) = Type("DataCompositionFilterItem") 
					And FilterElement.Use = True
					And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
					And FilterParameters.Find(String(FilterElement.LeftValue)) <> Undefined Then
					
						FillingValues.Insert(String(FilterElement.LeftValue), FilterElement.RightValue);
					
				EndIf;
			EndDo;
			
		EndIf;
		
		FormParameters.Insert("FillingValues", FillingValues);
	
	EndIf;
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region HeaderOfReportsOnDiscrepancies

Procedure DocumentsBasisSubmissionClick(Form, Item, StandardProcessing) Export
	
	StandardProcessing = False;
	If Form.BasisDocuments.Count() = 1 Then
		ShowValue(, Form.BasisDocuments[0].SaleOfGoodsAndServices);
	ElsIf Form.BasisDocuments.Count() > 1 Then
		
		DocumentsList = New ValueList;
		For Each TableRow In Form.BasisDocuments Do
			DocumentsList.Add(TableRow.SaleOfGoodsAndServices); 
		EndDo;
		
		If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			TitleOfViewForm = NStr("vi = 'Giao hàng và cung cấp dịch vụ (%DocumentsCount%)';
									|ru = 'Реализации товаров и услуг (%DocumentsCount%)';
									|en = 'Customer invoice (%DocumentsCount%)'; fa = 'Customer invoice (%DocumentsCount%)';
									|it = 'Vendita di merci e servizi (%DocumentsCount%)';
									|pl = 'Sprzedaż towarów i usług (%DocumentsCount%)';
									|tr = 'Mal ve hizmet faturası (%DocumentsCount%)'");
		ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			TitleOfViewForm = NStr("vi = 'Giao hàng cho khách (%DocumentsCount%)';
									|ru = 'Отгрузки товаров клиенту (%DocumentsCount%)';
									|en = 'Goods shipments to customer (%DocumentsCount%)'; fa = 'Goods shipments to customer (%DocumentsCount%)';
									|it = 'Goods shipments to customer (%DocumentsCount%)';
									|pl = 'Goods shipments to customer (%DocumentsCount%)';
									|tr = 'Müşteri ürünlerinin sevkiyatları (%DocumentsCount%)'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer") Then
			TitleOfViewForm = NStr("vi = 'Nhận trả lại hàng hóa từ khách hàng (%DocumentsCount%)';
									|ru = 'Возвраты товаров от клиента (%DocumentsCount%)';
									|en = 'Returns of goods from the customer (%DocumentsCount%)'; fa = 'Returns of goods from the customer (%DocumentsCount%)';
									|it = 'Reso di merci dal cliente (%DocumentsCount%)';
									|pl = 'Zwroty towarów od klienta (%DocumentsCount%)';
									|tr = 'Müşteriden gelen malların iadesi (%DocumentsCount%)'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice") Then
			TitleOfViewForm = NStr("vi = 'Mua hàng hóa và dịch vụ (%DocumentsCount%)';
									|ru = 'Приобретения товаров и услуг (%DocumentsCount%)';
									|en = 'Vendor invoices (%DocumentsCount%)'; fa = 'Vendor invoices (%DocumentsCount%)';
									|it = 'Acquisizione di merci e servizi (%DocumentsCount%)';
									|pl = 'Zakup towarów i usług (%DocumentsCount%)';
									|tr = 'Satın alma faturaları (%DocumentsCount%)'");
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			TitleOfViewForm = NStr("vi = 'Chuyển giao hàng hóa cho bên lưu kho (%DocumentsCount%)';
									|ru = 'Передачи товаров хранителю (%DocumentsCount%)';
									|en = 'VMI fill-up (%DocumentsCount%)'; fa = 'VMI fill-up (%DocumentsCount%)';
									|it = 'Trasferimento di merci al custode(%DocumentsCount%)';
									|pl = 'Przekazanie towarów do depozytariusza (%DocumentsCount%)';
									|tr = 'VMI doldurma (%DocumentsCount%)'");
			If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor") Then
				TitleOfViewForm = NStr("vi = 'Chuyển giao hàng hóa cho bên nhận gia công (%DocumentsCount%)';
										|ru = 'Передачи товаров переработчику (%DocumentsCount%)';
										|en = 'Goods transfer to subcontractor (%DocumentsCount%)'; fa = 'Goods transfer to subcontractor (%DocumentsCount%)';
										|it = 'Trasferimento articoli all''elaboratore (%DocumentsCount%)';
										|pl = 'Przekazanie towarów do przetwórcy (%DocumentsCount%)';
										|tr = 'Malların fason üreticiye transferi (%DocumentsCount%)'");
			EndIf;
		ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			TitleOfViewForm = NStr("vi = 'Tiếp nhận hàng hóa từ bên lưu kho (%DocumentsCount%)';
									|ru = 'Поступления товаров от хранителя (%DocumentsCount%)';
									|en = 'VMI returns (%DocumentsCount%)'; fa = 'VMI returns (%DocumentsCount%)';
									|it = 'Ricezione di merci dal custode (%DocumentsCount%)';
									|pl = 'Odbiór towarów od depozytariusza (%DocumentsCount%)';
									|tr = 'Malların VMI''dan teslim alınmaları (%DocumentsCount%)'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
			TitleOfViewForm = NStr("vi = 'Nhập kho hàng hóa để bảo quản (%DocumentsCount%)';
									|ru = 'Приемки товаров на хранение (%DocumentsCount%)';
									|en = 'Goods receipts for storage (%DocumentsCount%)'; fa = 'Goods receipts for storage (%DocumentsCount%)';
									|it = 'Ricevimento delle merci per la custodia (%DocumentsCount%)';
									|pl = 'Przyjęcia towarów do magazynu (%DocumentsCount%)';
									|tr = 'Malların depoya girişi (%DocumentsCount%)'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider") Then
			TitleOfViewForm = NStr("vi = 'Tiếp nhận nguyên vật liệu từ bên đặt gia công (%DocumentsCount%)';
									|ru = 'Поступления сырья от давальца (%DocumentsCount%)';
									|en = 'Goods receipt — Subcontracting services delivered (%DocumentsCount%)'; fa = 'Goods receipt — Subcontracting services delivered (%DocumentsCount%)';
									|it = 'Ricezione materie prime dal fornitore (%DocumentsCount%)';
									|pl = 'Przyjęcie surowców od właściciela surowców (%DocumentsCount%)';
									|tr = 'Hammaddelerin sağlayıcıdan teslim alınması (%DocumentsCount%)'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider") Then
			TitleOfViewForm = NStr("vi = 'Chuyển giao cho bên đặt gia công (%DocumentsCount%)';
									|ru = 'Передачи давальцу (%DocumentsCount%)';
									|en = 'Transfers to provider (%DocumentsCount%)'; fa = 'Transfers to provider (%DocumentsCount%)';
									|it = 'Trasferimenti al fornitore (%DocumentsCount%)';
									|pl = 'Przekazania właścicielowi surowców (%DocumentsCount%)';
									|tr = 'Tedarikçiye transfer (%DocumentsCount%)'");
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider") Then
			TitleOfViewForm = NStr("vi = 'Trả lại cho bên đặt gia công (%DocumentsCount%)';
									|ru = 'Возвраты давальцу (%DocumentsCount%)';
									|en = 'Goods return — Subcontracting services delivered (%DocumentsCount%)'; fa = 'Goods return — Subcontracting services delivered (%DocumentsCount%)';
									|it = 'Goods return — Subcontracting services delivered (%DocumentsCount%)';
									|pl = 'Goods return — Subcontracting services delivered (%DocumentsCount%)';
									|tr = 'Sağlayıcı iadesi (%DocumentsCount%)'");
		ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			TitleOfViewForm = NStr("vi = 'Trả lại cho nhà cung cấp (%DocumentsCount%)';
									|ru = 'Возвраты поставщику (%DocumentsCount%)';
									|en = 'Returns to vendor (%DocumentsCount%)'; fa = 'Returns to vendor (%DocumentsCount%)';
									|it = 'Resi al fornitore (%DocumentsCount%)';
									|pl = 'Zwroty do dostawcy (%DocumentsCount%)';
									|tr = 'Tedarikçiye iade (%DocumentsCount%)'");
		ElsIf DiscrepanciesClientServer.TypeOfBasisRefundFromCommissionAgent(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			TitleOfViewForm = NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi (%DocumentsCount%)';
									|ru = 'Поступления товаров от комиссионера (%DocumentsCount%)';
									|en = 'Receipts of goods from the consignee (%DocumentsCount%)'; fa = 'Receipts of goods from the consignee (%DocumentsCount%)';
									|it = 'Ricezione articoli dal commissionario (%DocumentsCount%)';
									|pl = 'Przyjęcia towarów od komisanta (%DocumentsCount%)';
									|tr = 'Malların komisyon acentesinden teslim alınması (%DocumentsCount%)'");
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			TitleOfViewForm = NStr("vi = 'Chuyển giao hàng hóa cho người nhận ký gửi (%DocumentsCount%)';
									|ru = 'Передачи товаров комиссионеру (%DocumentsCount%)';
									|en = 'Goods transfers to the consignee (%DocumentsCount%)'; fa = 'Goods transfers to the consignee (%DocumentsCount%)';
									|it = 'Trasferimento articoli al commissionario (%DocumentsCount%)';
									|pl = 'Wydania towarów komisantowi (%DocumentsCount%)';
									|tr = 'Malların komisyon acentesine devri (%DocumentsCount%)'");
		Else
			TitleOfViewForm = NStr("vi = 'Xuất kho từ nơi cất giữ (%DocumentsCount%)';
									|ru = 'Отгрузки товаров с хранения (%DocumentsCount%)';
									|en = 'VMI pick-up requests from vendor (%DocumentsCount%)'; fa = 'VMI pick-up requests from vendor (%DocumentsCount%)';
									|it = 'Scarico delle merci dalla custodia (%DocumentsCount%)';
									|pl = 'Wysyłki towarów z magazynu (%DocumentsCount%)';
									|tr = 'Malların VMI''dan sevkiyat talebi (%DocumentsCount%)'");
		EndIf;
		
		OpeningParameters = New Structure("DocumentsList, Title", DocumentsList, TitleOfViewForm);
		
		OpenForm("CommonForm.ViewingListOfDocuments", OpeningParameters, Form);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
Procedure ChangeBaseDocuments(Form) Export
	
	FormParameters = SelfServiceClient.StructureOfBaseSelectionFormParameters();
	FillPropertyValues(FormParameters, Form.Object);
	If Not Form.UseCustomerContracts 
		And (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer")) Then
		
		FormParameters.ContractIsNotRequired = True;
		
	ElsIf Not Form.UseContractsWithVendors
		And (DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage")
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")) Then
		
		FormParameters.ContractIsNotRequired = True;
		
	ElsIf Form.ToUseTermsOfSales 
		And (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer")) Then
		
		FormParameters.ContractIsNotRequired = Not Form.Items.Contract.Visible;
		
	ElsIf Form.UseTermsOfPurchases
		And (DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage")
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")) Then
		
		FormParameters.ContractIsNotRequired = Not Form.Items.Contract.Visible;
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		FormParameters.ContractIsNotRequired = False;
	ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor")
		  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor")
		  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor") Then
		
		FormParameters.ContractIsNotRequired = False;
	ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
		  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider") Then
		
		FormParameters.ContractIsNotRequired = False;
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
	
		FormParameters.ContractIsNotRequired = False;
	
	Else
		FormParameters.ContractIsNotRequired = Not ValueIsFilled(Form.Object.Contract);
	EndIf;
	
	ListOfFoundationDocuments = New ValueList;
	For Each TableRow In Form.BasisDocuments Do
		ListOfFoundationDocuments.Add(TableRow.SaleOfGoodsAndServices);
	EndDo;
	
	FormParameters.TabularSectionIsNotEmpty = Form.Object.Goods.Count() > 0;
	FormParameters.BasisDocuments = ListOfFoundationDocuments;
	FormParameters.TypeOfBaseDocumentForNonConformanceCertificate = Form.Object.TypeOfBaseDocumentForNonConformanceCertificate;
	OpenForm("DataProcessor.ProcessingOfDiscrepancyReports.Form.BaseDocumentChoiceForm",
	             FormParameters,
	             Form);
	
EndProcedure

#EndRegion

#Region TabularPartProducts

// Sets the passed action option for the selected PM Lines.
//
// Parameters:
// 	Form                                   - ClientApplicationForm - Change shape
// 	ActionWithShortageDocument            - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue - 
// 	ActionWithSurplusDocument              - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue -
// 	ActionWithShortageGoods               - EnumRef.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue -
// 	ActionWithSurplusGoods                 - EnumRef.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue -
// 	ThirdPartyIsGuilty                 - Boolean -
//
// Returns:
// 	Structure - consists of:
// 	* NumberOfModifiedRowsMatching - Map -
// 	* NeedServerCall                   - Boolean -
// 	* RowsForRecalculatingSeries               - Array of Number - a list of line numbers for updating the Status of the series indication.
//
Function SetActionOptionForSelectedLines(
	Form,
	ActionWithShortageDocument,
	ActionWithSurplusDocument,
	ActionWithShortageGoods = Undefined,
	ActionWithSurplusGoods = Undefined,
	ThirdPartyIsGuilty = Undefined) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("NeedServerCall", False);
	ReturnStructure.Insert("RowsForRecalculatingSeries", New Array);
	NumberOfModifiedRowsMatching = New Map;
	
	NumberOfModifiedRowsMatching.Insert(ActionWithShortageDocument, 0);
	NumberOfModifiedRowsMatching.Insert(ActionWithSurplusDocument, 0);
	If ActionWithShortageGoods <> Undefined Then
		NumberOfModifiedRowsMatching.Insert(ActionWithShortageGoods, 0);
	EndIf;
	If ActionWithSurplusGoods <> Undefined Then
		NumberOfModifiedRowsMatching.Insert(ActionWithSurplusGoods, 0);
	EndIf;
	
	If Not ValueIsFilled(ActionWithShortageDocument)
		And Not ValueIsFilled(ActionWithSurplusDocument) Then
		Return ReturnStructure;
	EndIf;
	
	For Each SelectedRow In Form.Items.Goods.SelectedRows Do
		
		CurrentRow = Form.Object.Goods.FindByID(SelectedRow);
		
		If ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(CurrentRow.BatchesIndicationStatus, Form.SeriesSpecificationParameters) Then
			
			ReturnStructure.NeedServerCall = True;
			ReturnStructure.Insert("NumberOfModifiedRowsMatching", NumberOfModifiedRowsMatching);
			
			Return ReturnStructure;
			
		Else
			
			If ValueIsFilled(ActionWithShortageDocument)
				And CurrentRow.NumberOfDiscrepancyPackaging < 0 Then
				VariantOfActionWithDocument = ActionWithShortageDocument;
			Else
				VariantOfActionWithDocument = ActionWithSurplusDocument;
			EndIf;
			
			If ValueIsFilled(ActionWithShortageGoods)
				And CurrentRow.NumberOfDiscrepancyPackaging < 0 Then
				VariantOfActionWithGoods = ActionWithShortageGoods;
			ElsIf ValueIsFilled(ActionWithSurplusGoods)
				And CurrentRow.NumberOfDiscrepancyPackaging> 0 Then
				VariantOfActionWithGoods = ActionWithSurplusGoods;
			EndIf;
			
			ChangeActionInLine = DiscrepanciesClientServer.ChangeActionInLine(
				CurrentRow,
				ActionWithShortageDocument,
				ActionWithSurplusDocument,
				ActionWithShortageGoods,
				ActionWithSurplusGoods,
				ThirdPartyIsGuilty);
				
			If ChangeActionInLine Then
				NumberOfModifiedRowsMatching[VariantOfActionWithDocument] = NumberOfModifiedRowsMatching[VariantOfActionWithDocument] + 1;
				If ValueIsFilled(VariantOfActionWithGoods) Then
					NumberOfModifiedRowsMatching[VariantOfActionWithGoods] = NumberOfModifiedRowsMatching[VariantOfActionWithGoods] + 1;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ReturnStructure;

EndFunction

Procedure NotifyAboutActionInstallation(NumberOfModifiedRowsMatching) Export
	
	NotificationText1 =  NStr("vi = 'Thay đổi tùy chọn hành động theo hàng';
								|ru = 'Изменение варианта действия в строках';
								|en = 'Action option change in lines'; fa = 'Action option change in lines';
								|it = 'Modifica della variante di azione nelle righe';
								|pl = 'Zmiana wariantu działania w wierszach';
								|tr = 'Satırlardaki eylem seçeneğinin değiştirilmesi'");
	Template = NStr("vi = 'Đặt ""%Action%"" trong %RowsCount%.';
					|ru = 'Установлено ""%Action%"" в %RowsCount%.';
					|en = 'Set ""%Action%"" in %RowsCount%.'; fa = 'Set ""%Action%"" in %RowsCount%.';
					|it = 'Impostato ""%Action%"" in %RowsCount%.';
					|pl = 'Ustawiono ""%Action%"" w %RowsCount%.';
					|tr = '%RowsCount%''da ""%Action%"" kuruldu.'");
	ExplanationText = "";
	For Each KeyAndValue In NumberOfModifiedRowsMatching Do
		If KeyAndValue.Value > 0 Then
			ExplanationText = ExplanationText + StrReplace(Template, "%action%", String(KeyAndValue.Key));
			ExplanationText = StrReplace(ExplanationText, "%RowsCount%",
				StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(KeyAndValue.Value,"history_1_,lines_,lines_"));
			ExplanationText = ExplanationText + Chars.LF;
		EndIf;
	EndDo;
	If Not IsBlankString(ExplanationText) Then
		ExplanationText = Left(ExplanationText, StrLen(ExplanationText) - 1);
		ShowUserNotification(NotificationText1,,ExplanationText);
	EndIf;
	
EndProcedure

Procedure GoodsDocumentGroundsForChange(CurrentRow, BasisDocuments) Export

	OrderEmptyLink = PredefinedValue("Document.TransferOrder.EmptyRef");

	If CurrentRow = Undefined Then
		Return;
	EndIf;

	If Not ValueIsFilled(CurrentRow.DocumentBasis) Then
		CurrentRow.OrderDocument = OrderEmptyLink;
		Return;
	EndIf;

	FoundRows = BasisDocuments.FindRows(New Structure("DocumentBasis", CurrentRow.DocumentBasis));
	If FoundRows.Count() = 0 Then
		CurrentRow.OrderDocument = OrderEmptyLink;
		Return;
	EndIf;
	
	FoundRow = FoundRows[0];

	If ValueIsFilled(CurrentRow.OrderDocument) Then
		If FoundRow.BasisOrders.FindByValue(CurrentRow.OrderDocument) = Undefined Then
			CurrentRow.OrderDocument = OrderEmptyLink;
		EndIf;
	EndIf;
	
	DiscrepanciesClientServer.SetBasedOnOrdersAttribute(CurrentRow, FoundRow);
	DiscrepanciesClientServer.FillInOrderInLine(CurrentRow, BasisDocuments);

EndProcedure

Procedure GoodsBeforeDeleteRow(CurrentRow, Cancel, ThisIsAboutDiscrepanciesAfterShipment) Export
	
	AttributesNames = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(ThisIsAboutDiscrepanciesAfterShipment);
	
	If CurrentRow[AttributesNames.FilledUsingBaseDocument] Then
		WarningText =  NStr("vi = 'Cấm xóa các dòng điền vào chứng từ cơ sở';
							|ru = 'Запрещено удалять строки, заполненные по документу-основанию';
							|en = 'You cannot delete the lines filled in by base document'; fa = 'You cannot delete the lines filled in by base document';
							|it = 'È vietato cancellare le righe compilate secondo il documento-causale';
							|pl = 'Zabrania się usuwać wiersze, wypełnione w dokumencie-podstawie';
							|tr = 'Belgeye dayalı olarak doldurulan satırların silinmesi yasaktır'");
		ShowMessageBox(,WarningText);
		Cancel = True;
	EndIf;
	
EndProcedure

// Displays the edit form for the string details of the table part
//
// Parameters:
//  Form                  - ClientApplicationForm - Change shape
//  FieldNameComment     - String                     - Name of the detail that stores the string to be edited
//  FieldNameIsComment - String                     - Name of the Boolean attribute that stores a sign that the field is filled in.
//  NameOfEditField  - String                     - Name of the editing field.
//
Procedure CommentStartChoice(Form, FieldNameComment, FieldNameIsComment, NameOfEditField) Export

	CurrentData = Form.Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentData", CurrentData);
	AdditionalParameters.Insert("AttributeNameComment", FieldNameComment);
	AdditionalParameters.Insert("PropsNameHasComment", FieldNameIsComment);
	AdditionalParameters.Insert("Form", Form);

	CallbackDescriptionCompletion = New CallbackDescription("EditCommentCompletion", DiscrepanciesClient, AdditionalParameters);
	CommonClient.ShowMultilineTextEditingForm(CallbackDescriptionCompletion, Form.Items[NameOfEditField].EditText);

EndProcedure

Procedure EditCommentCompletion(EditResult, AdditionalParameters) Export
	
	If EditResult = Undefined Then
		Return;
	EndIf;
		
	If EditResult <> AdditionalParameters.CurrentData[AdditionalParameters.AttributeNameComment] Then
		AdditionalParameters.CurrentData[AdditionalParameters.AttributeNameComment]     = EditResult;
		AdditionalParameters.CurrentData[AdditionalParameters.PropsNameHasComment] = Not IsBlankString(EditResult);
		AdditionalParameters.Form.Modified = True;
	EndIf;
	
EndProcedure

// Parameters:
// 	CurrentData       - FormDataCollectionItem - contains including:
// 		* Action - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue - 
// 	Object              - FormDataStructure, DocumentObject - 
// 	Form               - ClientApplicationForm - 
// 	TypeOfAct             - String -
// 	ShowExplanation - Boolean - 
// 
Procedure ProductsActionStartSelection(CurrentData, Object, Form, TypeOfAct, ShowExplanation = False) Export
	
	If Not CurrentData.ThereAreDiscrepancies Then
		Return;
	EndIf;
	
	Form.Modified = True;
	
	If Not TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		
		ThereIsPackage = (CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		
		FormParameters = New Structure();
		FormParameters.Insert("TypeOfAct",                       TypeOfAct);
		FormParameters.Insert("ChosenAction",             CurrentData.Action);
		FormParameters.Insert("GroupUpdate",            False);
		FormParameters.Insert("NumberOfDiscrepancyPackaging", CurrentData.NumberOfDiscrepancyPackaging);
		FormParameters.Insert("DiscrepanciesPostingMethod",    Object.DiscrepanciesPostingMethod);
		FormParameters.Insert("TheLineToOrder",                ValueIsFilled(CurrentData.RowCode));
		FormParameters.Insert("ShowExplanation",           ShowExplanation);
		FormParameters.Insert("BusinessOperation",         Object.BusinessOperation);
		FormParameters.Insert("ItemsType",               CurrentData.ItemsType);
		FormParameters.Insert("ThereIsPackage",                      ThereIsPackage);
		
		If TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
			FormParameters.Insert("SelectedDocumentAction", CurrentData.Action);
			FormParameters.Insert("SelectedActionWithGoods", CurrentData.DiscrepancyTreatment);
			FormParameters.Insert("Contract", Object.Contract);
		ElsIf TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
			FormParameters.Insert("SelectedDocumentAction", CurrentData.Action);
			FormParameters.Insert("Contract", Undefined);
		Else
			FormParameters.Insert("ChosenAction", CurrentData.Action);
		EndIf;
		
		If Not TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
			FormParameters.Insert("TypeOfBaseDocumentForNonConformanceCertificate",  Object.TypeOfBaseDocumentForNonConformanceCertificate);
		EndIf;
		If Not TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingTransfer")
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
			FormParameters.Insert("ShipmentToPrincipal", True);
		EndIf;
		If TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment")
			Or TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
			FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue";
		Else
			FormName = "Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Form.ChoiceForm";
			FormParameters.Insert("ThirdPartyIsGuilty", CurrentData.ThirdPartyIsGuilty);
			FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
		EndIf;
		
		OpenForm(
			FormName,
			FormParameters,,,,, 
			New CallbackDescription("ActionChoiceCompletion", Form),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Object              - FormDataStructure, DocumentObject - must contain, among other things:
// 		* Goods - FormDataCollection:
// 			** NumberOfDiscrepancyPackaging - Number
// 			** Action - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue 
// 						- EnumRef.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt
// 	Form               - ClientApplicationForm
// 	TypeOfAct             - String
// 	ShowExplanation - Boolean
//
Procedure ChangeActionOfSelectedLines(Object, Form, TypeOfAct, ShowExplanation = False) Export
	
	If TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		ChangeActionOfSelectedLinesInReportAfterShipment(Object, Form, TypeOfAct, ShowExplanation);
	Else
		ChangeActionOfSelectedLinesInReportAfterTransferIsAccepted(Object, Form, TypeOfAct, ShowExplanation);
	EndIf;
	
EndProcedure

Procedure ChangeActionOfSelectedLinesInReportAfterShipment(Object, Form, TypeOfAct, ShowExplanation = False)
	
	ClearMessages();
	
	FormParameters = New Structure();
	FormParameters.Insert("TypeOfAct", TypeOfAct);
	FormParameters.Insert("GroupUpdate", True);
	FormParameters.Insert("DiscrepanciesPostingMethod", Object.DiscrepanciesPostingMethod);
	FormParameters.Insert("ShowExplanation", ShowExplanation);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("Contract", Object.Contract);
	If Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		FormParameters.Insert("ShipmentToPrincipal", True);
	EndIf;
	
	ArrayOfActionsWithDocumentOnShortages = New Array;
	ArrayOfActionsWithDocumentOnSurplus = New Array;
	
	ArrayOfActionsWithProductForShortages = New Array;
	ArrayOfActionsWithGoodsBySurplus = New Array;
	
	ThirdPartyIsGuilty = False;
	ThereIsPackage = False;
	
	For Each SelectedRow In Form.Items.Goods.SelectedRows Do
		
		RowData = Object.Goods.FindByID(SelectedRow); // DocumentTabularSectionRow.DiscrepancyReportFollowingShipment.Goods
		
		ItSSurplus = False;
		TheseAreShortages = False;
		
		If RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			ThereIsPackage = True;
		EndIf;
		
		If RowData.NumberOfDiscrepancyPackaging < 0 Then
			TheseAreShortages = True;
		ElsIf RowData.NumberOfDiscrepancyPackaging > 0 Then
			ItSSurplus = True;
		Else
			Continue;
		EndIf;
		
		If ItSSurplus Then
			
			If ArrayOfActionsWithDocumentOnSurplus.Find(RowData.Action) = Undefined Then
				ArrayOfActionsWithDocumentOnSurplus.Add(RowData.Action);
			EndIf;
			
			If ArrayOfActionsWithGoodsBySurplus.Find(RowData.DiscrepancyTreatment) = Undefined Then
				ArrayOfActionsWithGoodsBySurplus.Add(RowData.DiscrepancyTreatment);
			EndIf;
			
		EndIf;
		
		If TheseAreShortages Then
			
			If ArrayOfActionsWithDocumentOnShortages.Find(RowData.Action) = Undefined Then
				ArrayOfActionsWithDocumentOnShortages.Add(RowData.Action);
			EndIf;
			
			If ArrayOfActionsWithProductForShortages.Find(RowData.DiscrepancyTreatment) = Undefined Then
				ArrayOfActionsWithProductForShortages.Add(RowData.DiscrepancyTreatment);
			EndIf;
			
		EndIf;
		
		RowData.Property("ThirdPartyIsGuilty", ThirdPartyIsGuilty);
		
	EndDo;
	
	If ArrayOfActionsWithDocumentOnSurplus.Count() = 0
		And ArrayOfActionsWithDocumentOnShortages.Count() = 0 Then
		
		MessageText = NStr("vi = 'Trong các dòng đã chọn không có sự chênh lệch. Không cần xử lý chênh lệch.';
							|ru = 'В выделенных строках нет расхождений. Указание способа отработки расхождений не требуется.';
							|en = 'No discrepancies in highlighted lines. It is not required to specify the discrepancy processing method.'; fa = 'No discrepancies in highlighted lines. It is not required to specify the discrepancy processing method.';
							|it = 'Nelle righe selezionate non sono presenti discrepanze. Non è necessario indicare il metodo di elaborazione delle discrepanze.';
							|pl = 'W wybranych wierszach nie ma odchylenie. Wskazanie sposobu odpracowania odchylenia nie jest wymagane.';
							|tr = 'Seçili satırlarda herhangi bir tutarsızlık yoktur. Tutarsızlıkların nasıl ele alınacağını belirtmek gerekli değildir.'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	If ArrayOfActionsWithDocumentOnSurplus.Count() = 1 Then
		FormParameters.Insert("ActionWithSurplusDocument", ArrayOfActionsWithDocumentOnSurplus[0]);
	Else
		FormParameters.Insert("ActionWithSurplusDocument", Undefined);
	EndIf;
	
	If ArrayOfActionsWithDocumentOnShortages.Count() = 1 Then
		FormParameters.Insert("ActionWithShortageDocument", ArrayOfActionsWithDocumentOnShortages[0]);
	Else
		FormParameters.Insert("ActionWithShortageDocument", Undefined);
	EndIf;
	
	If ArrayOfActionsWithGoodsBySurplus.Count() = 1 Then
		FormParameters.Insert("ActionWithSurplusGoods", ArrayOfActionsWithGoodsBySurplus[0]);
	Else
		FormParameters.Insert("ActionWithSurplusGoods", Undefined);
	EndIf;
	
	If ArrayOfActionsWithProductForShortages.Count() = 1 Then
		FormParameters.Insert("ActionWithShortageGoods", ArrayOfActionsWithProductForShortages[0]);
	Else
		FormParameters.Insert("ActionWithShortageGoods", Undefined);
	EndIf;
	
	FormParameters.Insert("ThereAreSurpluses",   ArrayOfActionsWithDocumentOnSurplus.Count() > 0);
	FormParameters.Insert("ThereIsShortages", ArrayOfActionsWithDocumentOnShortages.Count() > 0);
	FormParameters.Insert("ThereIsPackage",      ThereIsPackage);
	
	OpenForm(
		"DataProcessor.ProcessingOfDiscrepancyReports.Form.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue",
		FormParameters,
		,
		,
		,
		,
		New CallbackDescription("ChangeActionOfSelectedLinesCompletion", Form),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure ChangeActionOfSelectedLinesInReportAfterTransferIsAccepted(Object, Form, TypeOfAct, ShowExplanation = False)
	
	ClearMessages();
	
	FormParameters = New Structure();
	FormParameters.Insert("TypeOfAct", TypeOfAct);
	FormParameters.Insert("GroupUpdate", True);
	FormParameters.Insert("DiscrepanciesPostingMethod", Object.DiscrepanciesPostingMethod);
	FormParameters.Insert("ShowExplanation", ShowExplanation);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("Contract", Undefined);
	
	ArrayOfActionsForShortages = New Array;
	ArrayOfActionsForSurpluses   = New Array;
	
	ThirdPartyIsGuilty = False;
	ThereIsPackage = False;
	
	For Each SelectedRow In Form.Items.Goods.SelectedRows Do
		
		RowData = Object.Goods.FindByID(SelectedRow); // DocumentTabularSectionRow.DiscrepancyReportFollowingShipment.Goods
		
		ItSSurplus   = False;
		TheseAreShortages = False;
		
		If RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			ThereIsPackage = True;
		EndIf;
		
		If RowData.NumberOfDiscrepancyPackaging < 0 Then
			TheseAreShortages = True;
		ElsIf RowData.NumberOfDiscrepancyPackaging > 0 Then
			ItSSurplus = True;
		Else
			Continue;
		EndIf;
		
		If ItSSurplus And ArrayOfActionsForSurpluses.Find(RowData.Action) = Undefined Then
			ArrayOfActionsForSurpluses.Add(RowData.Action);
		ElsIf TheseAreShortages And ArrayOfActionsForShortages.Find(RowData.Action) = Undefined Then
			ArrayOfActionsForShortages.Add(RowData.Action);
		EndIf;
		RowData.Property("ThirdPartyIsGuilty", ThirdPartyIsGuilty);
		
	EndDo;
	
	If ArrayOfActionsForSurpluses.Count() = 0
		And ArrayOfActionsForShortages.Count() = 0 Then
		
		MessageText = NStr("vi = 'Trong các dòng đã chọn không có sự chênh lệch. Không cần xử lý chênh lệch.';
							|ru = 'В выделенных строках нет расхождений. Указание способа отработки расхождений не требуется.';
							|en = 'No discrepancies in highlighted lines. It is not required to specify the discrepancy processing method.'; fa = 'No discrepancies in highlighted lines. It is not required to specify the discrepancy processing method.';
							|it = 'Nelle righe selezionate non sono presenti discrepanze. Non è necessario indicare il metodo di elaborazione delle discrepanze.';
							|pl = 'W wybranych wierszach nie ma odchylenie. Wskazanie sposobu odpracowania odchylenia nie jest wymagane.';
							|tr = 'Seçili satırlarda herhangi bir tutarsızlık yoktur. Tutarsızlıkların nasıl ele alınacağını belirtmek gerekli değildir.'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	If TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue";
		NameOfActionSurplusParameter = "ActionWithSurplusDocument";
		NameOfShortageActionParameter = "ActionWithShortageDocument";
	Else
		FormName = "Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Form.ChoiceForm";
		FormParameters.Insert("ThirdPartyIsGuilty", ThirdPartyIsGuilty);
		NameOfActionSurplusParameter = "ActionSurplus";
		NameOfShortageActionParameter = "ShortfallAction";
	EndIf;
	
	If ArrayOfActionsForSurpluses.Count() = 1 Then
		FormParameters.Insert(NameOfActionSurplusParameter, ArrayOfActionsForSurpluses[0]);
	Else
		FormParameters.Insert(NameOfActionSurplusParameter, Undefined);
	EndIf;
	
	If ArrayOfActionsForShortages.Count() = 1 Then
		FormParameters.Insert(NameOfShortageActionParameter, ArrayOfActionsForShortages[0]);
	Else
		FormParameters.Insert(NameOfShortageActionParameter, Undefined);
	EndIf;
	
	FormParameters.Insert("ThereAreSurpluses",   ArrayOfActionsForSurpluses.Count() > 0);
	FormParameters.Insert("ThereIsShortages", ArrayOfActionsForShortages.Count() > 0);
	FormParameters.Insert("ThereIsPackage",      ThereIsPackage);
	
	OpenForm(
		FormName,
		FormParameters,
		,
		,
		,
		,
		New CallbackDescription("ChangeActionOfSelectedLinesCompletion", Form),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure OpenSelection(Form, ThisIsActOfDiscrepanciesAfterShipment) Export
	
	FormParameters = New Structure;
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer") Then
		
		HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
								|ru = 'Подбор товаров в %Document%';
								|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
								|it = 'Selezione merci in %Document%';
								|pl = 'Wybór towarów w %Document%';
								|tr = '%Document% içindeki ürünlerin seçimi'");
		
		If ValueIsFilled(Form.Object.Ref) Then
			HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Form.Object.Ref);
		Else
			HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'biên bản chênh lệch sau';
																				|ru = 'акт о расхождения после';
																				|en = 'discrepancy report following'; fa = 'discrepancy report following';
																				|it = 'atto di discrepanza dopo';
																				|pl = 'protokół o odchyleniu po';
																				|tr = '''dan sonra tutarsızlık raporu'") 
			                                                   + " " 
			                                                   + ?(ThisIsActOfDiscrepanciesAfterShipment,
			                                                       NStr("vi = 'xuất kho';
																		|ru = 'отгрузки';
																		|en = 'shipment'; fa = 'shipment';
																		|it = 'spedizioni';
																		|pl = 'wysyłki';
																		|tr = 'sevkiyatlar'"),
			                                                       NStr("vi = 'nhập hàng';
																		|ru = 'приемки';
																		|en = 'receipts'; fa = 'receipts';
																		|it = 'di accettazione';
																		|pl = 'odbiory';
																		|tr = 'kabuller'")));
		EndIf;
		
		FormParameters.Insert("Title", HeaderParameter_);
	EndIf;
	
	FormParameters.Insert("Terms",              Form.Object.Terms);
	FormParameters.Insert("Organization",             Form.Object.Organization);
	FormParameters.Insert("VATTaxation",      Form.Object.VATTaxation);
	FormParameters.Insert("PriceIncludesVAT",         Form.Object.PriceIncludesVAT);
	FormParameters.Insert("Currency",                  Form.Object.Currency);
	FormParameters.Insert("Date",                    Form.Object.Date);
	FormParameters.Insert("Document",                Form.Object.Ref);
	FormParameters.Insert("Partner",                 Form.Object.Partner);
	FormParameters.Insert("HideManualDiscounts",    True);
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer") Then
		
		If ThisIsActOfDiscrepanciesAfterShipment Then
			FormParameters.Insert("ProductSegment", Form.ProductSegment);
		EndIf;
		
		If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or ThisIsActOfDiscrepanciesAfterShipment Then
			
			FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer());
			
			FormParameters.Insert("FilterByProductType", FilterByProductType);
			
		EndIf;
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor")
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor")
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor") Then
			FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
		EndIf;
		FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders", True);
		FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
		
		OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, Form, Form.UUID);
		
	Else
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
		 Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
		 					PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider") Then
			FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders", True);
			FormParameters.Insert("SelectionModeWithoutAmountParameters",            True);
		EndIf;
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
		
		OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, Form, Form.UUID);
		
	EndIf;
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * Form - ClientApplicationForm, DocumentObject - 
// 
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("Form");
	Return Result;
	
EndFunction

Procedure IssueDocumentsClick(Form) Export
	
	If Form.Modified Then
		
		If Form.Object.Posted Then
			StringAction = NStr("vi = 'kết chuyển lại';
								|ru = 'перепроведение';
								|en = 'reposting'; fa = 'reposting';
								|it = 'riregistrazione';
								|pl = 'ponowne sprawdzenie';
								|tr = 'aktarım'");
		Else
			StringAction = NStr("vi = 'bản ghi';
								|ru = 'запись';
								|en = 'record'; fa = 'record';
								|it = 'registrazione';
								|pl = 'zapis';
								|tr = 'kayıt'");
		EndIf;
		
		AdditionalParameters = AdditionalCompletionProcessingParameters();
		AdditionalParameters.Form = Form;
		
		NotifyDescriptionQuestion = New CallbackDescription("IssueDocumentsClickCompletion", ThisObject, AdditionalParameters);
		QueryText = StrTemplate(NStr("vi = 'Biên bản chênh lệch đã được sửa đổi. Thực hiện  %1 chứng từ?';
									|ru = 'Акт о расхождениях был изменен. Выполнить %1 документа?';
									|en = 'Discrepancy report was changed. %1 document?'; fa = 'Discrepancy report was changed. %1 document?';
									|it = 'L''atto sulle discrepanze è stato modificato. Effettuare %1 del documento?';
									|pl = 'Protokół o odchyleniu został zmieniony. Wykonać %1 dokumentu?';
									|tr = 'Tutarsızlık raporu değiştirildi. Belge %1 onaylansın mı?'"), StringAction);
		ShowQueryBox(NotifyDescriptionQuestion, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		OpenDocumentsBeingProcessed(Form);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	QuestionResult - DialogReturnCode - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
//
Procedure IssueDocumentsClickCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		 Return;
	EndIf;
	
	ClearMessages();
	
	Form = AdditionalParameters.Form;
	Form.Write();
	
	If Not Form.Modified Then
		OpenDocumentsBeingProcessed(Form);
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - The Form contains, among other things:
// 		* Object - DocumentObject - 
// 
Procedure OpenDocumentsBeingProcessed(Form)
	
	FormParameters = New Structure;
	FormParameters.Insert("DiscrepancyCertificate", Form.Object.Ref);
	OpenForm("DataProcessor.ProcessingOfDiscrepancyReports.Form.RegisteredDocuments", FormParameters, Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 	CachedValues - Structure - stored values of parameters used in processing
// 
Procedure GoodsNumberOfPackagesOnChange(Form, CachedValues) Export
	
	CurrentRow = Form.Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	SelfServiceClientServer.AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form.Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesByDocument Then
		
		CurrentRow.Sum            = CurrentRow.SumByDocument;
		CurrentRow.DiscrepancyAmount = 0;
		
	EndIf;
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - 
//  Item - FormField -
//  Cancel - Boolean -
//  Copy - Boolean -
//  CachedValues - Structure - stored values of parameters used in processing 
// 
Procedure GoodsBeforeAddRow(Form, Item, Cancel, Copy, CachedValues) Export
	
	AttributesNames = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment"));
	
	CurrentData = Form.Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If Copy And CurrentData[AttributesNames.FilledUsingBaseDocument] Then
		Cancel = True;
		
		NewRow = Form.Object.Goods.Add();
		StringOfExcludedProperties = AttributesNames.FilledUsingBaseDocument 
		                           + ", CountByDocument, NumberOfPackagesByDocument, SumByDocument, VATAmountByDocument, AmountIncludingVATByDocument, RowCode";
		FillPropertyValues(NewRow, CurrentData, , StringOfExcludedProperties);
		Form.Items.Goods.CurrentRow = NewRow.GetID();
		DiscrepanciesClient.GoodsNumberOfPackagesOnChange(Form, CachedValues);
		DiscrepanciesClientServer.AvailabilityControl(Form);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - 
// Item - FormField - 
// CachedValues - Structure - stored values of parameters used in processing 
// 
Procedure GoodsVATRateOnChange(Form, Item, CachedValues) Export
	
	CurrentRow = Form.Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	Else
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - 
//  Item - FormField - 
// CachedValues - Structure - stored values of parameters used in processing 
// 
Procedure GoodsSumOnChange(Form, Item, CachedValues) Export
	
	CurrentRow = Form.Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	Else
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - 
//  Item - FormField -
//  CachedValues - Structure - stored values of parameters used in processing 
// 
Procedure GoodsVATAmountOnChange(Form, Item, CachedValues) Export
	
	CurrentRow = Form.Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	Else
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - 
// CachedValues - Structure - stored values of parameters used in processing 
// 
Procedure GoodsPackageOnChange(Form, CachedValues) Export
	
	CurrentRow = Form.Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Form.Object.Partner);
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	RecalculatePricePerPackage = True;
	RecalculatePricePerPackage =
		Form.Object.TypeOfBaseDocumentForNonConformanceCertificate <>
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
		And Form.Object.TypeOfBaseDocumentForNonConformanceCertificate <>
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider");
	If CurrentRow.Count > 0 And RecalculatePricePerPackage Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ValueIsFilled(Form.Object.Terms) Then
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice") Then
			StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Form.Object));
		ElsIf DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
				Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
				Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Then
			
			StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Form.Object));
			
		EndIf;
	EndIf;
	
	If RecalculatePricePerPackage Then
		
		If Not DiscrepanciesClientServer.VATIsNotRecorded(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		EndIf;
		
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountOfDiscrepancy");
		
	EndIf;
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	Else
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
EndProcedure

// Products price when changed.
// 
// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
//   * Object - DocumentObject - 
//  Item - FormField -
//  CachedValues - Structure - stored values of parameters used in processing
Procedure GoodsPriceOnChange(Form, Item, CachedValues) Export
	
	CurrentRow = Form.Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterShipment");
	Else
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - 
// 
Procedure OnlyDiscrepanciesExecute(Form) Export
	
	Form.OnlyDiscrepancies = Not Form.OnlyDiscrepancies;
	Form.Items.GoodsOnlyDiscrepancies.Check = Form.OnlyDiscrepancies;
	
	If Form.OnlyDiscrepancies Then
		Form.Items.Goods.RowFilter = New FixedStructure("ThereAreDiscrepancies", True);
	Else
		Form.Items.Goods.RowFilter = Undefined;
	EndIf;
	
EndProcedure

Procedure ShowWarningForFilledBasedOnRows() Export
	
	MessageText = NStr("vi = 'Đối với các dòng đã điền theo cơ sở, có thể soạn cột ""Số lượng thực tế"", ""Số hóa đơn"".
		|Sau khi phản ánh chênh lệch theo số lượng, sẽ cho phép soạn các cột ""Số tiền (thực tế)"", ""Thuế GTGT (thực tế)"" và ""Làm thế nào để xử lý chênh lệch"".';
		|ru = 'Для строк, заполненных по основанию, возможно редактирование колонок ""Фактическое количество"", ""Номер паспорта"".
		|После отражения расхождений по количеству становятся доступны для редактирования колонки ""Сумма (факт)"", ""НДС (факт)"" и ""Как отработать расхождения"".';
		|en = 'For lines filled from the base document, you can edit only the ""Actual quantity"" and ""Certificate number"" columns.
		|The ""Amount (actual)"", ""VAT (actual)"" and ""Discrepancy treatment"" columns can be edited after discrepancies in quantity are recorded.'; fa = 'For lines filled from the base document, you can edit only the ""Actual quantity"" and ""Certificate number"" columns.
		|The ""Amount (actual)"", ""VAT (actual)"" and ""Discrepancy treatment"" columns can be edited after discrepancies in quantity are recorded.';
		|it = 'For lines filled from the base document, you can edit only the ""Actual quantity"" and ""Certificate number"" columns.
		|The ""Amount (actual)"", ""VAT (actual)"" and ""Discrepancy treatment"" columns can be edited after discrepancies in quantity are recorded.';
		|pl = 'For lines filled from the base document, you can edit only the ""Actual quantity"" and ""Certificate number"" columns.
		|The ""Amount (actual)"", ""VAT (actual)"" and ""Discrepancy treatment"" columns can be edited after discrepancies in quantity are recorded.';
		|tr = 'Temel olarak doldurulan satırlar için ""Fiilî miktar"" ve ""Pasaport numarası"" sütunları düzenlenebilir.
		|Miktarlardaki tutarsızlıklar yansıtıldıktan sonra, ""Tutar (fiilî)"", ""KDV (fiilî)"" ve ""Tutarsızlıkların giderilme biçimi"" sütunları düzenlenebilir hale gelir.'");
	ShowMessageBox(, MessageText);
	
EndProcedure

Procedure GoodsAfterDeleteRow(Form) Export
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	DiscrepanciesClientServer.AvailabilityControl(Form);
	
EndProcedure

#EndRegion

#Region SetOfSeries

// process the series when splitting the goods line in the discrepancy reports.
// 
// Parameters:
//  Form - ClientApplicationForm - Change shape:
//  	* Object - FormDataStructure:
//  		** Ref - DocumentRef
//  		** SetOfSeries - FormDataCollection:
//  			*** Count - Number - Count
//  			*** CountByDocument - Number - quantity per document
//  CurrentRow - FormDataCollectionItem - Split line.
//  NewRow - FormDataCollectionItem - A new line obtained as a result of splitting.
Procedure ProcessSeriesWhenSplittingGoodsLine(Form, CurrentRow, NewRow) Export
	
	SeriesSpecificationParameters = Form.SeriesSpecificationParameters;
	If Not ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(CurrentRow.BatchesIndicationStatus, SeriesSpecificationParameters) Then
		Return;
	EndIf;

	InitialAction = CurrentRow.Action;
	QuantityToSplit = NewRow.NumberOfPackages;
	AttributesNames = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment"));
	If SeriesSpecificationParameters.FullObjectName = "Document.DiscrepancyReportFollowingTransfer"
		Or SeriesSpecificationParameters.FullObjectName = "Document.DiscrepancyReportFollowingShipment" Then
		EmptyAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
	Else
		EmptyAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef");
	EndIf;
	
	// define the connection fields and the search structure
	LinkFieldText = "";
	For Each LinksField In SeriesSpecificationParameters.LinkFields Do
		LinkFieldText = LinkFieldText + "," + LinksField;
	EndDo;
	TheStructureOfTheSearch = New Structure("Products,Characteristic" + LinkFieldText); 
	FillPropertyValues(TheStructureOfTheSearch, CurrentRow);

	// if the key fields in the new line have not changed, you do not need to reassign the series
	If TMCommonUseClientServer.StructuresAreEqual(NewRow, CurrentRow, "Products,Characteristic"+LinkFieldText) Then
		Return;
	EndIf;

	// select the lines with excess, determine the amount of excess
	FoundSeriesRows_ = Form.Object.SetOfSeries.FindRows(TheStructureOfTheSearch);
	LinesWithExcess = New Array;
	TotalSurplus = 0;
	For Each String In FoundSeriesRows_ Do
		Delta = String.Count - String.CountByDocument;
		If Delta > 0 Then
			LinesWithExcess.Add(String);
			TotalSurplus = TotalSurplus + Delta;
		EndIf;
	EndDo;
	
	// we break the lines of the series
	For Each String In LinesWithExcess Do
		If QuantityToSplit = 0 Then
			Break;
		EndIf;
		Delta = String.Count - String.CountByDocument;
		NewRowSeries = Form.Object.SetOfSeries.Add();
		FillPropertyValues(NewRowSeries, String);
		NewRowSeries[AttributesNames.FilledUsingBaseDocument] = False;
		NewRowSeries.CountByDocument = 0;
		NewRowSeries.Count = Min(Delta, QuantityToSplit);
		NewRowSeries.Action = InitialAction;
		String.Count = String.Count - NewRowSeries.Count;
		QuantityToSplit = QuantityToSplit - NewRowSeries.Count;
	EndDo;
	
	// we delete rows of series with a zero number
	DeleteRows_ = New Array;
	For Each String In FoundSeriesRows_ Do
		// if the fact in the source line (and related lines of the series) matches the quantity in the document, the action is not necessary
		If TotalSurplus = NewRow.NumberOfPackages Then
			String.Action = EmptyAction;
		EndIf;
		If String.Count = 0
			And String.CountByDocument = 0 Then
			DeleteRows_.Add(String);
		EndIf;
	EndDo;
	For Each String In DeleteRows_ Do
		Form.Object.SetOfSeries.Delete(String);
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

// Performs an action when clicking a hyperlink in the "documents to be Processed" report for a discrepancy document.
//
// Parameters:
//  Form               - ClientApplicationForm - the form that the call comes from 
//  CommandDetails     - String - description of the action to be performed, "Edit" or " Issue"
//  DiscrepancyCertificate    - DocumentRef.DiscrepancyReportFollowingShipment - report of discrepancies being processed.
//  BasisOfAct       - DocumentRef.CustomerInvoice, DocumentRef.ReturnOfGoodsToVendor - the basis 
//                        of the act of discrepancies for which actions are performed.
//  CreatedDocument - DocumentRef, Structure - either an empty link of the type that is being created, or a structure consisting of the same link and utility services. operations.
//
Procedure ProcessingReportCommandProcessingDocuments(Form, CommandDetails, DiscrepancyCertificate, BasisOfAct, CreatedDocument) Export
	
	FormParameters = New Structure;
	
	If Not DiscrepanciesServerCall.StatusOfActToBeExecutedWorkedOut(DiscrepancyCertificate) Then
		WarningText = NStr("vi = 'Đối với %ActionKind% chứng từ, biên bản phải ở trạng thái ""Đang xử lý"" hoặc ""Đã xử lý""';
							|ru = 'Для %ActionKind% документов акт должен быть в статусе ""Отрабатывается"" или ""Отработано""';
							|en = 'Certificate should be in status ""Being processed"" or ""Processed"" for the %ActionKind% documents'; fa = 'Certificate should be in status ""Being processed"" or ""Processed"" for the %ActionKind% documents';
							|it = 'Per %ActionKind% dei documenti l''atto deve essere nello stato ""In elaborazione"" o ""Elaborato""';
							|pl = 'Dla %ActionKind% dokumentów akt musi być w statusie ""Odpracowuje się"" lub ""Odpracowano""';
							|tr = '%ActionKind%belgeler için, işlemin ""İşleniyor"" veya ""İşlendi"" durumunda olması gerekir'");
		ActionKind = ?(CommandDetails = "Change", NStr("vi = 'thay đổi';
														|ru = 'изменения';
														|en = 'changes'; fa = 'changes';
														|it = 'modifiche';
														|pl = 'zmiany';
														|tr = 'değişiklikler'"), NStr("vi = 'thực hiện';
																				|ru = 'оформления';
																				|en = 'registration'; fa = 'registration';
																				|it = 'regolarizzazioni';
																				|pl = 'sporządzenia';
																				|tr = 'biçimlendirmeler'"));
		WarningText = StrReplace(WarningText, "%ActionKind%", ActionKind);
		ShowMessageBox( , WarningText);
		Return;
	EndIf;
	
	If CommandDetails = "Change" Then
		
		DiscrepanciesServerCall.ChangeDocumentBasisOfActOfDiscrepancies(DiscrepancyCertificate, BasisOfAct);
		
	ElsIf CommandDetails = "ApplyAppearance" Then
		
		If TypeOf(CreatedDocument) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			OpenForm("Document.ReturnOfGoodsFromCustomer.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.GoodsReceiptFromCustomer") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			FormParameters.Insert("ReduceShipmentByReference", CreatedDocument.ReduceShipmentByReference);
			
			OpenForm(
				"Document.GoodsReceiptFromCustomer.Form.DocumentForm",
				New Structure("Basis", FormParameters),
				Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument") 
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.ReturnOfGoodsToVendor")
			And CreatedDocument.Property("Warehouse")
			And ValueIsFilled(CreatedDocument.Warehouse) Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			FormParameters.Insert("Warehouse", CreatedDocument.Warehouse);
			OpenForm("Document.ReturnOfGoodsToVendor.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.GoodsShipmentFromStorage") Then
			
			If CreatedDocument.Patch Then
				FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				FormParameters.Insert("BasisOfAct",    BasisOfAct);
				FormParameters.Insert("Patch",      True);
				OpenForm("Document.GoodsShipmentFromStorage.Form.DocumentForm",
					New Structure("Basis", FormParameters), Form);
			ElsIf CreatedDocument.ThereIsFix
				And Not ValueIsFilled(CreatedDocument.Warehouse) Then
				FormParameters.Insert("DiscrepancyCertificate",     DiscrepancyCertificate);
				FormParameters.Insert("BasisOfAct",        BasisOfAct);
				FormParameters.Insert("CorrectionOfBasis", CreatedDocument.DocumentPatch);
				OpenForm("Document.GoodsShipmentFromStorage.Form.DocumentForm",
					New Structure("Basis", FormParameters), Form);
			ElsIf ValueIsFilled(CreatedDocument.Warehouse) Then
				FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				FormParameters.Insert("BasisOfAct",    BasisOfAct);
				FormParameters.Insert("Warehouse",            CreatedDocument.Warehouse);
				If CreatedDocument.ThereIsFix Then
					FormParameters.Insert("CorrectionOfBasis", CreatedDocument.DocumentPatch);
				EndIf;
				OpenForm("Document.GoodsShipmentFromStorage.Form.DocumentForm",
					New Structure("Basis", FormParameters), Form);
			EndIf;
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.GoodsShipmentFromStorage") Then
			
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			
			Parameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.GoodsShipmentFromStorage.Form.DocumentForm", Parameters, Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			
			Parameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.ReceiptOfGoodsFromCustodian.Form.DocumentForm", Parameters, Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			If CreatedDocument.Patch Then
				FormParameters.Insert("Patch",  True);
			ElsIf CreatedDocument.ThereIsFix Then
				FormParameters.Insert("CorrectionOfBasis", CreatedDocument.DocumentPatch);
			EndIf;
			Parameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.ReceiptOfGoodsFromCustodian.Form.DocumentForm", Parameters, Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.GoodsReceiptForStorage") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			If CreatedDocument.Patch Then
				FormParameters.Insert("Patch",  True);
			ElsIf CreatedDocument.ThereIsFix Then
				FormParameters.Insert("CorrectionOfBasis", CreatedDocument.DocumentPatch);
			EndIf;
			Parameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.GoodsReceiptForStorage.Form.DocumentForm", Parameters, Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			OpenForm("Document.ReturnOfGoodsToVendor.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			OpenForm("Document.RequestForReturnOfGoodsFromCustomer.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			
			FormParameters.Insert("DiscrepancyCertificate",    DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",       BasisOfAct);
			If CreatedDocument.ThereIsFix Then
				FormParameters.Insert("CorrectionOfBasis", CreatedDocument.DocumentPatch);
			EndIf;
			OpenForm("Document.RequestForReturnOfGoodsFromCustomer.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.PurchaseAdjustment") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct); 
			
			OpenForm("Document.PurchaseAdjustment.Form.DocumentForm", New Structure("Basis", FormParameters));
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("SaleOfGoodsAndServices")
			And TypeOf(CreatedDocument.SaleOfGoodsAndServices) = Type("DocumentRef.SaleAdjustment") Then
			
			ThisIsReturnToPath = CommonClientServer.StructureProperty(CreatedDocument, "ThisIsReturnToPath", False);
			
			FormParameters = New Structure;
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("SaleOfGoodsAndServices",       BasisOfAct);
			FormParameters.Insert("Operation",         CreatedDocument.BusinessOperation);
			FormParameters.Insert("ThisIsReturnToPath",  ThisIsReturnToPath);
			
			OpenForm("Document.SaleAdjustment.Form.DocumentForm", New Structure("Basis", FormParameters));
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CorrectedDocument")
			And TypeOf(CreatedDocument.CorrectedDocument) = Type("DocumentRef.GoodsShipmentToCustomer") Then
			
			FormParameters = New Structure;
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			FormParameters.Insert("Patch",      CreatedDocument.Patch);
			FormParameters.Insert("AdditionalDelivery",       CreatedDocument.AdditionalDelivery);
			
			FormOpenParameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.GoodsShipmentToCustomer.Form.DocumentForm", FormOpenParameters);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.InventorySurplusRecognition") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			FormParameters.Insert("Warehouse",            CreatedDocument.Warehouse);
			
			OpenForm("Document.InventorySurplusRecognition.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("InventoryTransfer")
			And TypeOf(CreatedDocument.InventoryTransfer) = Type("DocumentRef.InventoryTransfer") Then
			
			FormParameters.Insert("DiscrepancyCertificate",   DiscrepancyCertificate);
			FormParameters.Insert("InventoryTransfer", BasisOfAct);
			FormParameters.Insert("ThisIsOvershooting", ?(CreatedDocument.Property("ThisIsOvershooting"), CreatedDocument.ThisIsOvershooting, False));
			FormParameters.Insert("Patch", ?(CreatedDocument.Property("Patch"), CreatedDocument.Patch, False));
			FormParameters.Insert("CorrectedDocument", ?(CreatedDocument.Property("CorrectedDocument"), CreatedDocument.CorrectedDocument, Undefined));
			
			OpenForm("Document.InventoryTransfer.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
		
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CorrectedDocument")
			And TypeOf(CreatedDocument.CorrectedDocument) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
			
			FormParameters.Insert("DiscrepancyCertificate",   DiscrepancyCertificate);
			FormParameters.Insert("Purchase", BasisOfAct);
			FormParameters.Insert("Patch", ?(CreatedDocument.Property("Patch"), CreatedDocument.Patch, False));
			FormParameters.Insert("CorrectedDocument", ?(CreatedDocument.Property("CorrectedDocument"), CreatedDocument.CorrectedDocument, Undefined));
			
			OpenForm("Document.ReceiptOfGoodsToWarehouse.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.VendorInvoice") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			OpenForm("Document.VendorInvoice.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			FormParameters.Insert("Warehouse",            CreatedDocument.Warehouse);

			OpenForm("Document.ReceiptOfGoodsToWarehouse.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.GoodsReceiptForStorage") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			
			Parameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.GoodsReceiptForStorage.Form.DocumentForm", Parameters, Form);
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.TransferOfGoodsToBailee") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			
			Parameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.TransferOfGoodsToBailee.Form.DocumentForm", Parameters, Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.TransferOfGoodsToBailee") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			If CreatedDocument.Patch Then
				FormParameters.Insert("Patch",  True);
			Else
				FormParameters.Insert("BusinessOperation",    CreatedDocument.BusinessOperation);
				If CreatedDocument.ThereIsFix Then
					FormParameters.Insert("CorrectionOfBasis", CreatedDocument.DocumentPatch);
				EndIf;
			EndIf;
			Parameters = New Structure("Basis", FormParameters);
			
			OpenForm("Document.TransferOfGoodsToBailee.Form.DocumentForm", Parameters, Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.CustomerInvoice") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			OpenForm("Document.CustomerInvoice.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.RecognitionOfStockSurplusShippedToCustomer") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			OpenForm(
				"Document.RecognitionOfStockSurplusShippedToCustomer.Form.DocumentForm",
				New Structure("Basis", FormParameters),
				Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.WriteOffOfShippedGoods") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			FormParameters.Insert("ReduceShipmentByReference",
				CreatedDocument.ReduceShipmentByReference);
			
			OpenForm(
				"Document.WriteOffOfShippedGoods.Form.DocumentForm",
				New Structure("Basis", FormParameters),
				Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("DocumentRef.ARAPAdjustment") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			OpenForm("Document.ARAPAdjustment.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
			
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.WriteOffOfGoodsShortages") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",    BasisOfAct);
			FormParameters.Insert("Warehouse",            CreatedDocument.Warehouse);
			
			OpenForm("Document.WriteOffOfGoodsShortages.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.WriteOffDiscrepanciesBetweenReceiptAndPurchase") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct",	BasisOfAct);
			FormParameters.Insert("OrderDocument",			CreatedDocument.OrderDocument);
			FormParameters.Insert("Warehouse",            CreatedDocument.Warehouse);
			OpenForm("Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
		
		ElsIf TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("DocumentRef.ARAPAdjustment") Then
			
			FormParameters.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			FormParameters.Insert("BasisOfAct", BasisOfAct);
			OpenForm("Document.ARAPAdjustment.Form.DocumentForm", New Structure("Basis", FormParameters), Form);
		EndIf; 
	ElsIf CommandDetails = "Create" Then
		If TypeOf(CreatedDocument) = Type("Structure")
			And CreatedDocument.Property("CreatedDocument")
			And TypeOf(CreatedDocument.CreatedDocument) = Type("CatalogRef.Complaints") Then
			
			FormParameters.Insert("Basis", BasisOfAct);
			FormParameters.Insert("AmountOfShortDelivery", CreatedDocument.AmountOfShortDelivery);

			OpenForm("Catalog.Complaints.Form.ItemForm", New Structure("Basis", FormParameters), Form);
		EndIf;
	EndIf;
	
	DiscrepanciesClientLocalization.ProcessingReportCommandProcessingDocuments(Form, 
		CommandDetails,
		DiscrepancyCertificate,
		BasisOfAct,
		CreatedDocument);
EndProcedure

Function StructureOfParametersOfDocumentSelectionFormForMovements() Export

	Structure = New Structure("Organization, CompanyRecipient, SourceWarehouse, DestinationWarehouse,
		|BusinessOperation, TabularSectionIsNotEmpty, BasisDocuments");

	Return Structure;

EndFunction

Function DownloadHeaderTextFromExternalFiles() Export
	
	Return NStr("vi = 'Đang tải số lượng thực tế của hàng hóa từ một tập tin bên ngoài';
				|ru = 'Загрузка фактического количества товаров из внешнего файла';
				|en = 'Import of actual goods quantity from an external file'; fa = 'Import of actual goods quantity from an external file';
				|it = 'Download dell''effettiva quantità delle merci da un file esterno';
				|pl = 'Pobieranie rzeczywistej ilości towarów z pliku zewnętrznego';
				|tr = 'Harici bir dosyadan gerçek mal miktarının yüklenmesi'");
	
EndFunction

Function AdditionalExplanationTextWhenDownloadingFromExternalFiles() Export
	
	Return NStr("vi = 'Để so sánh với dữ liệu của chứng từ, sẽ sử dụng các cột ""Mặt hàng"", ""Đặc tính"", ""Đóng gói"" và ""Đơn giá"".';
				|ru = 'Для сопоставления с данными документа будут использованы колонки ""Номенклатура"", ""Характеристика"", ""Упаковка"" и ""Цена"".';
				|en = 'To compare with the document data, the ""Product"", ""Variant"", ""Packaging unit"" and ""Price"" columns will be used.'; fa = 'To compare with the document data, the ""Product"", ""Variant"", ""Packaging unit"" and ""Price"" columns will be used.';
				|it = 'Per il confronto con i dati del documento saranno utilizzati le colonne ""Articoli"", ""Caratteristica"", ""Imballaggio"" e ""Prezzo"".';
				|pl = 'Do zestawienia z danymi dokumentu będą używane kolumny ""Nomenklatura"", ""Cecha"", ""Opakowanie"" i ""Cena"".';
				|tr = '""Öğe"", ""Özellikler"", ""Paket"" ve ""Fiyat"" sütunları belge verileriyle karşılaştırma için kullanılacaktır.'");
	
EndFunction

#EndRegion

// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 
Procedure EstablishAvailabilityOfVendorAgreements(Form) Export
	
	If ValueIsFilled(Form.Object.Partner) And Form.UseTermsOfPurchases Then
		NumberOfSupplierAgreements  = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Form.Object.Partner);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Terms", "Visible", NumberOfSupplierAgreements > 0);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Terms", "Visible", False);
	EndIf;
	
EndProcedure

#EndRegion
