
////////////////////////////////////////////////////////////////////////////////
// The "Discrepancies Server" module contains server procedures and functions for 
// the operation of documents to reflect discrepancies after acceptance and shipment.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Changes the document basis of the Act of discrepancies in accordance with the act.
// Before making a change, it checks that changes are required.
//
// Parameters:
//  DiscrepancyCertificate  - DocumentRef.DiscrepancyReportFollowingShipment - the act of discrepancies.
//  Basis         - DocumentRef.CustomerInvoice, DocumentRef.ReturnOfGoodsToVendor, DocumentRef.ReturnOfGoodsFromCustomer -
//                      the basis of the act, which is subject to change.
//
Procedure ChangeDocumentBasisOfActOfDiscrepancies(DiscrepancyCertificate, Basis) Export
	
	CheckResult = DocumentDoesNotCorrespondToAct(DiscrepancyCertificate, Basis, True);
	If CheckResult.DocumentState = "ChangesRequired" Then
		
		If CheckResult.TableOfMutableRows = Undefined
			And CheckResult.TableOfVariableSeries = Undefined Then
			Return
		EndIf;
		
		ChangeBasisOfAct(DiscrepancyCertificate, Basis, 
		                      CheckResult.TableOfMutableRows,
		                      CheckResult.TableOfVariableSeries);
	EndIf;

EndProcedure

// Checks whether a change to the basis of the act is available
//
// Parameters:
//  DiscrepancyCertificate  - DocumentRef.DiscrepancyReportFollowingShipment - the act of discrepancies.
//  Basis         - DocumentRef.CustomerInvoice, DocumentRef.ReturnOfGoodsToVendor - the basis of the act,
//                      which is checked for the possibility of changes.
//  DocumentModification - Boolean - 
//
// Returns:
//   String   - The State of the availability of changes. It can take the following values:
//               "Changes are required", "Changes are fulfilled", "Changes are required", "The basis does not correspond to the act".
//
Function DocumentDoesNotCorrespondToAct(DiscrepancyCertificate, Basis, DocumentModification = False) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("DocumentState", "BaseDocumentDoesNotMatchTheCertificate");
	ReturnStructure.Insert("TableOfMutableRows", Undefined);
	ReturnStructure.Insert("TableOfVariableSeries", Undefined);
	
	QueryTextByHeader = RequestTextForReportHeader(DiscrepancyCertificate);
	If QueryTextByHeader = "" Then
		Return ReturnStructure;
	EndIf;
	
	QueryTextByHeader = QueryTextByHeader + "
	|;
	|
	|//////////////////////////////////////////////////////////////////////
	|";
	
	RequestTextByBaseHeader = RequestTextByBaseHeader(Basis);
	
	If RequestTextByBaseHeader = "" Then
		Return ReturnStructure;
	EndIf;
		
	QueryTextByHeader = QueryTextByHeader + RequestTextByBaseHeader;
	
	RequestByHeader = New Query(QueryTextByHeader);
	RequestByHeader.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	RequestByHeader.SetParameter("Basis", Basis);
	
	RequestResultByHeader = RequestByHeader.ExecuteBatch();
	
	If Not ActCapAndBaseMatch(RequestResultByHeader, DiscrepancyCertificate, Basis) Then
		Return ReturnStructure;
	EndIf;
	
	CheckTabularPartsOfActAndGrounds(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification);
	
	Return ReturnStructure;
	
EndFunction

// A structure that contains matching field names in the act and invoice, and service attributes.
// 
// Returns:
//   Structure:
//   * NameOfInvoiceOrderField - String
//   * NameOfOrderRegisterField - String
//   * NameOfOrderReportField - String
//   * NameOfInvoiceField - String
//   * NamesOfUniquenessFields - String
//   * NameOfFieldToView - String
//   * OrderInHeader - Boolean
//   * ThisIsReturnRequest - Boolean
//
Function DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice() Export
	
	Structure = New Structure();
	// Matching field names
	Structure.Insert("NameOfInvoiceOrderField", "");
	Structure.Insert("NameOfOrderRegisterField", "");
	Structure.Insert("NameOfOrderReportField", "");
	Structure.Insert("NameOfInvoiceField", "");
	
	Structure.Insert("NamesOfUniquenessFields", "RowCode");
	Structure.Insert("NameOfFieldToView", "ToRegister");
	
	// Indication of the absence of the Order field in the tabular part of the Goods invoice
	Structure.Insert("OrderInHeader", False);
	
	Structure.Insert("VerificationIndicator", "Issued_1");
	
	Return Structure;
	
EndFunction

// Procedure-Checking whether the excess can be added to the invoice
//
// Parameters:
//  Act					 - DocumentObject	 - The current act
//  RegisterName			 - String			 - Name of the Order register that corresponds to the invoice type used in the report
//  MetadataDetails	 - See DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice
//  Cancel				 - Boolean
//
Procedure CheckingPossibilityOfMakingSurplusInInvoice(Act, RegisterName, MetadataDetails, Cancel) Export
	
	ActionsWithExcess = New Array();
	// Issue a re-delivered message
	ActionsWithExcess.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
	ActionsWithExcess.Add(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered);
	// Issue the re-delivered and return it
	ActionsWithExcess.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
	ActionsWithExcess.Add(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered);
	
	ArrayOfInvoices = ItIsNecessaryToMakeExcessInInvoice(Act, MetadataDetails.NameOfInvoiceField, ActionsWithExcess);
	
	ModifiedTSGoods = New Array();
	ArrayOfOverheadForChanges = New Array();
	
	// Getting a table of modified PM Goods invoices
	For Each Invoice In ArrayOfInvoices Do
		
		InvoiceChanges = PrepareChangesToVHFInvoice(Act, Invoice, MetadataDetails, ActionsWithExcess);
		If InvoiceChanges.HasChanges Then
			ModifiedTSGoods.Add(InvoiceChanges.InvoiceGoods);
			ArrayOfOverheadForChanges.Add(Invoice);
		EndIf;
	EndDo;
	
	If ModifiedTSGoods.Count() = 0 Then
		Return;
	EndIf;
	
	VTModifiedGoodsWaybills = ModifiedTSGoods[0].CopyColumns();
	For Each VTGoodsWaybill In ModifiedTSGoods Do
		CommonClientServer.SupplementTable(VTGoodsWaybill, VTModifiedGoodsWaybills);
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	BatchProcessingOfTablePartServer.TreatTS(VTModifiedGoodsWaybills, StructureOfActions, Undefined);
	
	InvoiceForFillingServiceData = ArrayOfOverheadForChanges[0];
	TypeOfInvoice = TypeOf(InvoiceForFillingServiceData);
	InvoiceMetadata = Metadata.FindByType(TypeOfInvoice);
	InvoiceName = InvoiceMetadata.Name;
	
	// Getting a table of invoice movements
	RegisterRecordTable = GetNewInvoiceRegisteredRecordsByRegisterOrders(RegisterName, InvoiceName, VTModifiedGoodsWaybills);
	
	LinesWithErrors = PerformControlOfAddingExcessToInvoice(RegisterName,
		MetadataDetails.NameOfOrderRegisterField,
		MetadataDetails.NameOfFieldToView,
		MetadataDetails.NamesOfUniquenessFields,
		RegisterRecordTable,
		ArrayOfOverheadForChanges,
		MetadataDetails.VerificationIndicator);
	
	ReportErrorsWhenAddingExcessToInvoice(Act,
		LinesWithErrors,
		MetadataDetails.NameOfOrderReportField,
		MetadataDetails.NamesOfUniquenessFields,
		Cancel);
	
EndProcedure

// Set the action option in the lines.
// 
// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 	NumberOfModifiedRowsMatching   - Structure -
// 	ActionWithShortageDocument            - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue -
// 	ActionWithSurplusDocument              - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue -
// 	ActionWithShortageGoods               - EnumRef.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue -
// 	ActionWithSurplusGoods                 - EnumRef.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue -
// 	ThirdPartyIsGuilty                 - Boolean -
// 
// Returns:
// 	Number - Number of rows changed
Function SetActionOptionInLines(
	Form,
	NumberOfModifiedRowsMatching,
	ActionWithShortageDocument,
	ActionWithSurplusDocument,
	ActionWithShortageGoods = Undefined,
	ActionWithSurplusGoods = Undefined,
	ThirdPartyIsGuilty = Undefined) Export
	
	NumberOfRowsChanged = 0;
	CachedValues = Undefined;
	
	For Each LineID In Form.Items.Goods.SelectedRows Do
		
		CurrentRow = Form.Object.Goods.FindByID(LineID);
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(CurrentRow, CachedValues, Form.SeriesSpecificationParameters);
		
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
			ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Form.Object, Form.SeriesSpecificationParameters, LineID, CachedValues);
		EndIf;
	EndDo;
	
	Return NumberOfRowsChanged;
	
EndFunction

#EndRegion

#Region Private

#Region ReportsOfDiscrepanciesAfterShipment

// The report of discrepancies list process the grounds parameter.
// 
// Parameters:
//  Form - ClientApplicationForm:
//  * TypeOfBaseDocumentForNonConformanceCertificate - EnumRef.TypesOfBaseDocumentsForDiscrepancyReport -
//  * Title - String - 
//  * List - DynamicList - 
//  * Items - FormItems - 
//  * Parameters - Structure:
//  ** TypeOfBaseDocumentForNonConformanceCertificate - EnumRef.TypesOfBaseDocumentsForDiscrepancyReport - 
//  ** CurrentRow - LineOfATabularSection - 
//  TheseAreActsOfDiscrepancyAfterShipment - Boolean - These are reports of discrepancies after shipment
Procedure ReportOfDiscrepanciesListAndGroundsParameter(Form, TheseAreActsOfDiscrepancyAfterShipment) Export
	
	ListOfAllTypesOfGroundsForActOfDiscrepancies = False;
	
	If Form.Parameters.Property("TypeOfBaseDocumentForNonConformanceCertificate") And ValueIsFilled(Form.Parameters.TypeOfBaseDocumentForNonConformanceCertificate) Then 
		Form.TypeOfBaseDocumentForNonConformanceCertificate = Form.Parameters.TypeOfBaseDocumentForNonConformanceCertificate;
	ElsIf Form.Parameters.Filter.Property("TypeOfBaseDocumentForNonConformanceCertificate") And ValueIsFilled(Form.Parameters.Filter.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Form.TypeOfBaseDocumentForNonConformanceCertificate = Form.Parameters.Filter.TypeOfBaseDocumentForNonConformanceCertificate;
	ElsIf ValueIsFilled(Form.Parameters.CurrentRow) And ValueIsFilled(Form.Parameters.CurrentRow.TypeOfBaseDocumentForNonConformanceCertificate) Then
		Form.TypeOfBaseDocumentForNonConformanceCertificate = Form.Parameters.CurrentRow.TypeOfBaseDocumentForNonConformanceCertificate;
	Else
		ListOfAllTypesOfGroundsForActOfDiscrepancies = True;
	EndIf;
	
	If ListOfAllTypesOfGroundsForActOfDiscrepancies Then
		If TheseAreActsOfDiscrepancyAfterShipment Then
			ArrayOfValidTypes = DiscrepanciesClientServer.TypesOfGroundsForActOfDiscrepanciesAfterShipment();
		Else
			ArrayOfValidTypes = DiscrepanciesClientServer.TypesOfGroundsForActOfDiscrepanciesAfterAcceptance();
		EndIf;
	Else
		ArrayOfValidTypes = New Array;
		ArrayOfValidTypes.Add(Form.TypeOfBaseDocumentForNonConformanceCertificate);
	EndIf;
	
	If ListOfAllTypesOfGroundsForActOfDiscrepancies Then
		
		If TheseAreActsOfDiscrepancyAfterShipment Then
			Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng';
								|ru = 'Акты о расхождениях после отгрузки';
								|en = 'Customer invoice disputes'; fa = 'اختلافات فاکتور مشتری';
								|it = 'Documenti di accettazione con riserva dopo la spedizione';
								|pl = 'Protokołu o odchyleniu po wysyłce';
								|tr = 'Teslimat sonrası tutarsızlık raporu'");
		Else
			Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi chấp nhận';
								|ru = 'Акты о расхождениях после приемки';
								|en = 'Receipt discrepancy reports'; fa = 'گزارش‌های مغایرت دریافت';
								|it = 'Atti di discrepanze dopo l''accettazione';
								|pl = 'Protokoły o odchyleniu po przyjęciu';
								|tr = 'Stok farkları raporları'");
		EndIf;
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate",
			NStr("vi = 'Thay đổi cơ sở';
				|ru = 'Изменение основания';
				|en = 'Edit a base document'; fa = 'Edit a base document';
				|it = 'Edit a base document';
				|pl = 'Edit a base document';
				|tr = 'Ana değişiklik'"));
		CommonClientServer.SetFormItemProperty(Form.Items, "TypeOfBaseDocumentForNonConformanceCertificate",
			"Visible", True);
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice Then
		
		ArrayOfValidTypes.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.EmptyRef());
		Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi bán';
							|ru = 'Акты о расхождениях после реализации';
							|en = 'Sales invoice disputes'; fa = 'Sales invoice disputes';
							|it = 'Atti sulle discrepanze dopo il realizzo';
							|pl = 'Protokoły o odchyleniu po sprzedaży';
							|tr = 'Satış faturası uyuşmazlığı'");
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", NStr("vi = 'Khách hàng';
																						|ru = 'Клиент';
																						|en = 'Client'; fa = 'کلاینت';
																						|it = 'Cliente';
																						|pl = 'Client';
																						|tr = 'Müşteri'"));
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi bán hàng';
																					|ru = 'Изменение реализации';
																					|en = 'Change sales'; fa = 'Change sales';
																					|it = 'Modifica del realizzo';
																					|pl = 'Zmiana realizacji';
																					|tr = 'Faturada değişiklik'"));

	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate =
			Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer Then
		
		ArrayOfValidTypes.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.EmptyRef());
		
		Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và trước khi chuyển quyền sở hữu';
							|ru = 'Акт о расхождениях после отгрузки товаров клиенту и до перехода права собственности';
							|en = 'Sales dispute after goods shipment to customer and before transfer of title to goods'; fa = 'Sales dispute after goods shipment to customer and before transfer of title to goods';
							|it = 'Sales dispute after goods shipment to customer and before transfer of title to goods';
							|pl = 'Sales dispute after goods shipment to customer and before transfer of title to goods';
							|tr = 'Ürünlerin müşteri tarafında satış uyuşmazlığıyla karşılaşması ve mülkiyetin devrinden önce tutarsızlıkların beyanı'");
		
		TMCommonUseClientServer.SetFormItemProperty(Form.Items,
			"Partner", "Title", NStr("vi = 'Khách hàng';
									|ru = 'Клиент';
									|en = 'Client'; fa = 'کلاینت';
									|it = 'Cliente';
									|pl = 'Client';
									|tr = 'Müşteri'"));
		
		CommonClientServer.SetDynamicListParameter(Form.List,
			"StatusUpdate", NStr("vi = 'Thay đổi giao hàng cho khách';
								|ru = 'Изменение отгрузки товаров клиенту';
								|en = 'Change goods shipment to customer'; fa = 'Change goods shipment to customer';
								|it = 'Change goods shipment to customer';
								|pl = 'Change goods shipment to customer';
								|tr = 'Müşterü ürün sevkiyatının değiştirilmesi'"));
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor Then
		
		Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi trả lại nhà cung cấp';
							|ru = 'Акты о расхождениях после возвратов поставщикам';
							|en = 'Discrepancy reports following returns to vendors'; fa = 'Discrepancy reports following returns to vendors';
							|it = 'Atti sulle discrepanze dopo i resi ai fornitori';
							|pl = 'Protokoły o odchyleniu po zwrotach do dostawców';
							|tr = 'Tedarikçi iadeleri sonrası tutarsızlık raporu'");
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", NStr("vi = 'Nhà cung cấp';
																						|ru = 'Поставщик';
																						|en = 'Vendor'; fa = 'تأمین‌کننده';
																						|it = 'Fornitore';
																						|pl = 'Vendor';
																						|tr = 'Tedarikçi'"));
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi trả lại';
																					|ru = 'Изменение возврата';
																					|en = 'Change return'; fa = 'Change return';
																					|it = 'Modifica del reso';
																					|pl = 'Zmiana zwrotu';
																					|tr = 'İadenin değiştirilmesi'"));
		CommonClientServer.SetFormItemProperty(Form.Items,"DiscrepanciesPostingMethod", "Visible", False);
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage Then
		
		Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi vận chuyển hàng hóa từ kho';
							|ru = 'Акты о расхождениях после отгрузки товаров с хранения';
							|en = 'VMI pick-up discrepancy reports'; fa = 'VMI pick-up discrepancy reports';
							|it = 'Atti sulle discrepanze dopo lo scarico delle merci dalla custodia';
							|pl = 'Protokoły o odchyleniu po wysyłce towaru z magazynu';
							|tr = 'Mallar depodan çıktıktan sonra tutarsızlıkların raporlanması'");
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", NStr("vi = 'Nhà cung cấp';
																						|ru = 'Поставщик';
																						|en = 'Vendor'; fa = 'تأمین‌کننده';
																						|it = 'Fornitore';
																						|pl = 'Vendor';
																						|tr = 'Tedarikçi'"));
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi lô hàng';
																					|ru = 'Изменение отгрузки';
																					|en = 'Shipment change'; fa = 'Shipment change';
																					|it = 'Modifica dello scarico';
																					|pl = 'Zmiana wysyłki';
																					|tr = 'Sevkiyatın değiştirilmesi'"));
		CommonClientServer.SetFormItemProperty(Form.Items,"DiscrepanciesPostingMethod", "Visible", False);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Form.TypeOfBaseDocumentForNonConformanceCertificate);
		
		Form.Title = Handler.ReportFormHeader();
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", Handler.HeaderOfActPartner());
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi chuyển';
																					|ru = 'Изменение передачи';
																					|en = 'Change transfers'; fa = 'Change transfers';
																					|it = 'Modifica del trasferimento';
																					|pl = 'Zmiana transferu';
																					|tr = 'Transferin değiştirilmesi'"));
		CommonClientServer.SetFormItemProperty(Form.Items,"DiscrepanciesPostingMethod", "Visible", False);
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent Then
		
		Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao hàng hóa cho người nhận ký gửi';
							|ru = 'Акты о расхождениях после передачи товаров комиссионеру';
							|en = 'Discrepancy reports after goods transfer to consignee'; fa = 'Discrepancy reports after goods transfer to consignee';
							|it = 'Atti sulle discrepanze dopo il trasferimento degli articoli al commissionario';
							|pl = 'Protokoły o odchyleniu po przekazaniu towarów do komisanta';
							|tr = 'Konsinye malların transferinden sonra tutarsızlık raporu'");
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", NStr("vi = 'Người nhận ký gửi';
																						|ru = 'Комиссионер';
																						|en = 'Consignee'; fa = 'امانت‌دار';
																						|it = 'Commissionario';
																						|pl = 'Consignee';
																						|tr = 'Konsinye'"));
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi chuyển';
																					|ru = 'Изменение передачи';
																					|en = 'Change transfers'; fa = 'Change transfers';
																					|it = 'Modifica del trasferimento';
																					|pl = 'Zmiana transferu';
																					|tr = 'Transferin değiştirilmesi'"));
		CommonClientServer.SetFormItemProperty(Form.Items,"DiscrepanciesPostingMethod", "Visible", False);
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		Form.Title = NStr("vi = 'Biên bản chênh lệchsau khi chấp nhận hàng hóa từ kho';
							|ru = 'Акты о расхождениях после приемки товаров с хранения';
							|en = 'Discrepancy reports following goods receipt from storage'; fa = 'Discrepancy reports following goods receipt from storage';
							|it = 'Atti sulle discrepanze dopo l''accettazione delle merci dalla custodia';
							|pl = 'Protokoły o odchyleniu po przyjęciu towarów z magazynu';
							|tr = 'Depolanan stok farkları raporları'");
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", NStr("vi = 'Nhà cung cấp';
																						|ru = 'Поставщик';
																						|en = 'Vendor'; fa = 'تأمین‌کننده';
																						|it = 'Fornitore';
																						|pl = 'Vendor';
																						|tr = 'Tedarikçi'"));
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi chấp nhận';
																					|ru = 'Изменение приемки';
																					|en = 'Receiving change'; fa = 'Receiving change';
																					|it = 'Modifica dell''accettazione';
																					|pl = 'Zmiana przyjęcia';
																					|tr = 'Kabulün değiştirilmesi'"));
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
		
		Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi chấp nhận';
							|ru = 'Акты о расхождениях после приемки';
							|en = 'Receipt discrepancy reports'; fa = 'گزارش‌های مغایرت دریافت';
							|it = 'Atti di discrepanze dopo l''accettazione';
							|pl = 'Protokoły o odchyleniu po przyjęciu';
							|tr = 'Stok farkları raporları'");
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", NStr("vi = 'Nhà cung cấp';
																						|ru = 'Поставщик';
																						|en = 'Vendor'; fa = 'تأمین‌کننده';
																						|it = 'Fornitore';
																						|pl = 'Vendor';
																						|tr = 'Tedarikçi'"));
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi tiếp nhận';
																					|ru = 'Изменение поступления';
																					|en = 'Change receipts'; fa = 'Change receipts';
																					|it = 'Modifica delle entrate';
																					|pl = 'Zmiana wpłaty';
																					|tr = 'Teslim alımın değiştirilmesi'"));
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate =
						Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		
		Form.Title = NStr("vi = 'Biên bản về chênh lệch sau khi tiếp nhận nguyên vật liệu của bên đặt gia công';
							|ru = 'Акты о расхождениях после приемки сырья давальцев';
							|en = 'Discrepancy reports following receipt of raw materials from providers'; fa = 'Discrepancy reports following receipt of raw materials from providers';
							|it = 'Atti di accettazione con riserva dopo la ricezione di materie prime del fornitore';
							|pl = 'Protokoły o odchyleniu po przyjęciu surowców od właścicieli surowców';
							|tr = 'Sağlayıcı hammaddelerinin kabulünden sonra tutarsızlık raporları'");
		
		TMCommonUseClientServer.SetFormItemProperty(
			Form.Items, "Partner", "Title", NStr("vi = 'Bên đặt gia công';
												|ru = 'Давалец';
												|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
												|it = 'Fornitore';
												|pl = 'Material provider';
												|tr = 'Malzeme tedarikçisi'"));
			
		CommonClientServer.SetDynamicListParameter(
			Form.List, "StatusUpdate", NStr("vi = 'Thay đổi chấp nhận';
											|ru = 'Изменение приемки';
											|en = 'Receiving change'; fa = 'Receiving change';
											|it = 'Modifica dell''accettazione';
											|pl = 'Zmiana przyjęcia';
											|tr = 'Kabulün değiştirilmesi'"));
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider Then
		
		Form.Title = TollingSchemeClientServer.SynonymOfDocumentCertificateOfDiscrepanciesTransferToGiver();
		
		TMCommonUseClientServer.SetFormItemProperty(
			Form.Items, "Partner", "Title", NStr("vi = 'Bên đặt gia công';
												|ru = 'Давалец';
												|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
												|it = 'Fornitore';
												|pl = 'Material provider';
												|tr = 'Malzeme tedarikçisi'"));
		
		CommonClientServer.SetDynamicListParameter(
			Form.List, "StatusUpdate", NStr("vi = 'Thay đổi chuyển';
											|ru = 'Изменение передачи';
											|en = 'Change transfers'; fa = 'Change transfers';
											|it = 'Modifica del trasferimento';
											|pl = 'Zmiana transferu';
											|tr = 'Transferin değiştirilmesi'"));
		
		CommonClientServer.SetFormItemProperty(
			Form.Items,"DiscrepanciesPostingMethod", "Visible", False);
		
	ElsIf Form.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		
		Form.Title = TollingSchemeClientServer.SynonymOfDocumentCertificateOfDiscrepanciesReturnOfRawMaterialsToGiver();
		
		TMCommonUseClientServer.SetFormItemProperty(
			Form.Items, "Partner", "Title", NStr("vi = 'Bên đặt gia công';
												|ru = 'Давалец';
												|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
												|it = 'Fornitore';
												|pl = 'Material provider';
												|tr = 'Malzeme tedarikçisi'"));
		
		CommonClientServer.SetDynamicListParameter(
			Form.List, "StatusUpdate", NStr("vi = 'Thay đổi trả lại';
											|ru = 'Изменение возврата';
											|en = 'Change return'; fa = 'Change return';
											|it = 'Modifica del reso';
											|pl = 'Zmiana zwrotu';
											|tr = 'İadenin değiştirilmesi'"));
		
		CommonClientServer.SetFormItemProperty(
			Form.Items,"DiscrepanciesPostingMethod", "Visible", False);
	Else
		
		Form.Title = NStr("vi = 'Biên bản chênh lệch sau khi nhận trả lại từ khách hàng';
							|ru = 'Акты о расхождениях после возвратов от клиентов';
							|en = 'Discrepancy reports following returns from customers'; fa = 'Discrepancy reports following returns from customers';
							|it = 'Atti sulle discrepanze dopo i resi dai clienti';
							|pl = 'Protokoły o odchyleniu po zwrotach od klientów';
							|tr = 'Müşteri iadesi sonrası tutarsızlık raporları'");
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Partner", "Title", NStr("vi = 'Khách hàng';
																						|ru = 'Клиент';
																						|en = 'Client'; fa = 'کلاینت';
																						|it = 'Cliente';
																						|pl = 'Client';
																						|tr = 'Müşteri'"));
		CommonClientServer.SetDynamicListParameter(Form.List, "StatusUpdate", NStr("vi = 'Thay đổi trả lại';
																					|ru = 'Изменение возврата';
																					|en = 'Change return'; fa = 'Change return';
																					|it = 'Modifica del reso';
																					|pl = 'Zmiana zwrotu';
																					|tr = 'İadenin değiştirilmesi'"));
		CommonClientServer.SetFormItemProperty(Form.Items,"DiscrepanciesPostingMethod", "Visible", False);
		
	EndIf;
	
	If TheseAreActsOfDiscrepancyAfterShipment Then
		CommonClientServer.SetDynamicListParameter(
		      Form.List,
		      "StatusAdjustmentAsNew",
		      NStr("vi = 'Thực hiện điều chỉnh (thực hiện giao lại/ nhận lại hàng giao thiếu)';
					|ru = 'Оформление корректировок (реализация перепоставленного/возврат недопоставленного товара)';
					|en = 'Register notes (sales of overdelivered goods/return of underdelivered goods)'; fa = 'ثبت حواله‌ها (فروش کالای مازادتحویل/برگشت کالای کم‌تحویل)';
					|it = 'Esecuzione della correzione (realizzo della merce consegnata in eccesso/restituzione della merce mancante in consegna)';
					|pl = 'Wprowadzanie korekt (realizacja nadprodukcji/zwrotu niedostarczonych towarów)';
					|tr = 'Düzenlemelerin yapılması (fazla tedarik edilen malların satılması/tedarik edilmeyen malların iadesi)'"));
		CommonClientServer.SetDynamicListParameter(
		      Form.List, 
		      "StatusCorrectionAsCorrection", 
		      NStr("vi = 'Lập điều chỉnh (sửa lỗi)';
					|ru = 'Оформление корректировки (исправление)';
					|en = 'Register an adjustment (correction)'; fa = 'Register an adjustment (correction)';
					|it = 'Register an adjustment (correction)';
					|pl = 'Register an adjustment (correction)';
					|tr = 'Düzeltme oluşturma (yama)'"));
	Else
		CommonClientServer.SetDynamicListParameter(
		      Form.List, 
		      "StatusCorrectionAsCorrection", 
		      NStr("vi = 'Lập điều chỉnh (sửa lỗi)';
					|ru = 'Оформление корректировки (исправление)';
					|en = 'Register an adjustment (correction)'; fa = 'Register an adjustment (correction)';
					|it = 'Register an adjustment (correction)';
					|pl = 'Register an adjustment (correction)';
					|tr = 'Düzeltme oluşturma (yama)'"));
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(Form.List,
	                                                                   "TypeOfBaseDocumentForNonConformanceCertificate", 
	                                                                   ArrayOfValidTypes, 
	                                                                   True);

EndProcedure

Procedure FillInDependentDetailsOfGoodsDiscrepanciesAfterShipment(Object) Export
	
	StructureOfActions = DiscrepanciesClientServer.ActionStructureFillInDependentDetailsOfGoodsDiscrepanciesAfterShipment();
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods,StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#Region ReportsOfDiscrepanciesAfterAcceptance

Procedure FillInDependentDetailsOfGoodsDiscrepanciesAfterAcceptance(Object) Export
	
	StructureOfActions = DiscrepanciesClientServer.ActionStructureFillInDependentDetailsOfGoodsDiscrepanciesAfterAcceptance();
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods,StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#Region ActsOnDiscrepanciesAfterTransfers

// Returns a table that contains documents transferred to the base, plus orders and the warehouse for these documents.
//
// Parameters:
//  ArrayOfDocuments	 - Array - 
// 
// Returns:
//   - ValueTable - 
//
Function GenerateTableOfDocumentsForMoving(ArrayOfDocuments) Export
	
	Query = New Query;
	
	Query.Text = Documents.DiscrepancyReportFollowingTransfer.RequestTextDocumentsAndMovingOrder();
	
	Query.SetParameter("ArrayOfBases", ArrayOfDocuments);
	
	QueryResult = Query.Execute();
	
	TableOfFoundationDocuments = New ValueTable();
	TableOfFoundationDocuments.Columns.Add("DocumentBasis",
		New TypeDescription("DocumentRef.InventoryTransfer, DocumentRef.CustomerInvoice, DocumentRef.ReturnOfGoodsToVendor"));
	TableOfFoundationDocuments.Columns.Add("BasisOrders", New TypeDescription("ValueList"));
	TableOfFoundationDocuments.Columns.Add("BasisWarehouses", New TypeDescription("ValueList"));
	
	SamplingBase = QueryResult.Select(QueryResultIteration.ByGroups);
	While SamplingBase.Next() Do
		NewRow = TableOfFoundationDocuments.Add();
		NewRow.DocumentBasis = SamplingBase.DocumentBasis;
		SampleOrders = SamplingBase.Select();
		While SampleOrders.Next() Do
			If SampleOrders.OrderDocument <> Undefined And Not SampleOrders.OrderDocument.IsEmpty() Then
				NewRow.BasisOrders.Add(SampleOrders.OrderDocument);
			EndIf;
			If SampleOrders.Warehouse <> Undefined And Not SampleOrders.Warehouse.IsEmpty() Then
				NewRow.BasisWarehouses.Add(SampleOrders.Warehouse);
			EndIf;
		EndDo;
	EndDo;
	
	Return TableOfFoundationDocuments;
	
EndFunction

// Modifies the item of the form "Documentingreflection".
//  Returns the calculated string for it.
//
// Parameters:
//  Item							 - FormField	 - Element of the form "Documentingreflection"
//  NumberOfBaseDocuments	 - Number		 - 
//  GoodsQuantity				 - Number		 - 
//  BaseDocumentPresentation	 - String		 - Presentation of the first Foundation document.
// 
// Returns:
//   - String - Presentation of the foundation document.
//
Function FormationOfInscriptionDocumentsBaseMovement(Item, NumberOfBaseDocuments, GoodsQuantity, BaseDocumentPresentation = "") Export

	DocumentsBasisSubmission = NStr("vi = 'Chưa chọn';
									|ru = 'Не выбрано';
									|en = 'Not selected'; fa = 'انتخاب نشده';
									|it = 'Non selezionato';
									|pl = 'Nie wybrano';
									|tr = 'Seçilmedi'");
	
	If GoodsQuantity = 0 Then
		DocumentsBasisSubmission = NStr("vi = 'Chưa chọn';
										|ru = 'Не выбрано';
										|en = 'Not selected'; fa = 'انتخاب نشده';
										|it = 'Non selezionato';
										|pl = 'Nie wybrano';
										|tr = 'Seçilmedi'"); 
		Item.Width = 8;
		Item.Hyperlink = False;
	Else
		
		If NumberOfBaseDocuments = 0 Then
			DocumentsBasisSubmission = NStr("vi = 'Chưa chọn';
											|ru = 'Не выбрано';
											|en = 'Not selected'; fa = 'انتخاب نشده';
											|it = 'Non selezionato';
											|pl = 'Nie wybrano';
											|tr = 'Seçilmedi'");
			Item.Width = 8;
			Item.Hyperlink = False;
		ElsIf NumberOfBaseDocuments = 1 Then
			DocumentsBasisSubmission = BaseDocumentPresentation;
			Item.Width = 42;
			Item.Hyperlink = True;
		Else
			DocumentsBasisSubmission = NStr("vi = 'Tổng số lưu chuyển';
											|ru = 'Всего перемещений';
											|en = 'Total transfers'; fa = 'Total transfers';
											|it = 'Totale spostamenti';
											|pl = 'Przemieszczeń ogółem';
											|tr = 'Tüm hareketler'") + ": " + String(NumberOfBaseDocuments);
			Item.Width = 14;
			Item.Hyperlink = True;
		EndIf;
		
	EndIf;
	
	Return DocumentsBasisSubmission;

EndFunction

#EndRegion

#Region GeneralProceduresAndFunctionsOfDivergenceCertificates

// Checks that the document type of the basis of the act is filled in. Raises an exception if not.
//
// Parameters:
//  DocumentReportObject  - DocumentObject.DiscrepancyReportFollowingShipment, DocumentObject.DiscrepancyReportFollowingShipment - the document for which the type check is performed
//
Procedure CheckTypeOfReportSBasisWhenCreatingIt(DocumentReportObject) Export
	
	If Not ValueIsFilled(DocumentReportObject.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Raise NStr("vi = 'Khi tạo chứng từ, chưa phản ánh loại cơ sở của biên bản chênh lệch.';
					|ru = 'При создании документа не определен тип основания акта о расхождениях.';
					|en = 'A type of base documents for the discrepancy report is not specified when creating the document.'; fa = 'A type of base documents for the discrepancy report is not specified when creating the document.';
					|it = 'A type of base documents for the discrepancy report is not specified when creating the document.';
					|pl = 'A type of base documents for the discrepancy report is not specified when creating the document.';
					|tr = 'Belge oluşturulurken tutarsızlık raporunun ana türü tanımlanmadı.'");
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
Procedure ManagingAutoHeaderAfterRecording(Form) Export
	
	If Form.AutoTitle = False Then
		Form.Title = "";
		Form.AutoTitle = True;
	EndIf;
	
EndProcedure

// process the series when splitting the goods line in the discrepancy reports.
// 
// Parameters:
//  Form - ClientApplicationForm - Change shape:
//  	* BasisDocuments - FormDataCollection -
//  	* Object - FormDataStructure:
//  		** TypeOfBaseDocumentForNonConformanceCertificate - EnumRef.TypesOfBaseDocumentsForDiscrepancyReport -
//  		** Goods - FormDataCollection -
//  		** SetOfSeries - FormDataCollection -:
//  			*** Count - Number - Count
//  			*** CountByDocument - Number - quantity per document
//  CallAvailabilityManagement - Boolean - call availability management.
Procedure FillInByBasis(Form, CallAvailabilityManagement = True) Export
	
	If Form.BasisDocuments.Count() = 0 And Form.FillingVariant = "Variant1" Then
		Form.Object.Goods.Clear();
	Else
		
		Query = New Query;
		
		If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			QueryTexts = New Array;
			
			If AccessRight("Read", Metadata.Documents.GoodsShipmentToCustomer) Then
				
				QueryText = "
				|SELECT ALLOWED
				|	MAX(Table.Ref) AS DocumentShipments,
				|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
				|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
				|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
				|	SalesOfGoodsServicesGoods.Products AS Products,
				|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
				|	SalesOfGoodsServicesGoods.Purpose AS Purpose
				|INTO ShipmentDocumentsInAdvance
				|FROM
				|	Document.GoodsShipmentToCustomer.Goods AS Table
				|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
				|		ON Table.Products = SalesOfGoodsServicesGoods.Products
				|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
				|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
				|			AND Table.Ref = SalesOfGoodsServicesGoods.SalesOrder
				|WHERE
				|	Table.Ref.Posted
				|	AND SalesOfGoodsServicesGoods.Ref IN(&BasisDocuments)
				|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
				|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
				|
				|GROUP BY
				|	SalesOfGoodsServicesGoods.SalesOrder,
				|	SalesOfGoodsServicesGoods.Ref,
				|	SalesOfGoodsServicesGoods.RowCode,
				|	SalesOfGoodsServicesGoods.Products,
				|	SalesOfGoodsServicesGoods.Characteristic,
				|	SalesOfGoodsServicesGoods.Purpose
				|
				|UNION ALL
				|
				|SELECT
				|	MAX(Table.Ref) AS DocumentShipments,
				|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
				|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
				|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
				|	SalesOfGoodsServicesGoods.Products AS Products,
				|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
				|	SalesOfGoodsServicesGoods.Purpose AS Purpose
				|FROM
				|	Document.GoodsShipmentToCustomer.Goods AS Table
				|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
				|		ON Table.Products = SalesOfGoodsServicesGoods.Products
				|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
				|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
				|			AND Table.Ref.CorrectedDocument = SalesOfGoodsServicesGoods.SalesOrder
				|WHERE
				|	Table.Ref.Posted
				|	AND SalesOfGoodsServicesGoods.Ref IN(&BasisDocuments)
				|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
				|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
				|
				|GROUP BY
				|	SalesOfGoodsServicesGoods.SalesOrder,
				|	SalesOfGoodsServicesGoods.Ref,
				|	SalesOfGoodsServicesGoods.RowCode,
				|	SalesOfGoodsServicesGoods.Products,
				|	SalesOfGoodsServicesGoods.Characteristic,
				|	SalesOfGoodsServicesGoods.Purpose
				|
				|UNION ALL
				|
				|SELECT
				|	MAX(Table.Ref) AS DocumentShipments,
				|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
				|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
				|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
				|	SalesOfGoodsServicesGoods.Products AS Products,
				|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
				|	SalesOfGoodsServicesGoods.Purpose AS Purpose
				|FROM
				|	Document.GoodsShipmentToCustomer.Goods AS Table
				|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
				|		ON Table.Products = SalesOfGoodsServicesGoods.Products
				|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
				|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
				|			AND Table.SalesOrder = SalesOfGoodsServicesGoods.SalesOrder
				|WHERE
				|	Table.Ref.Posted
				|	AND SalesOfGoodsServicesGoods.Ref IN(&BasisDocuments)
				|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
				|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
				|
				|GROUP BY
				|	SalesOfGoodsServicesGoods.SalesOrder,
				|	SalesOfGoodsServicesGoods.Ref,
				|	SalesOfGoodsServicesGoods.RowCode,
				|	SalesOfGoodsServicesGoods.Products,
				|	SalesOfGoodsServicesGoods.Characteristic,
				|	SalesOfGoodsServicesGoods.Purpose
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	ShipmentDocumentsInAdvance.DocumentShipments AS DocumentShipments,
				|	ShipmentDocumentsInAdvance.SalesOrder AS SalesOrder,
				|	ShipmentDocumentsInAdvance.SaleOfGoodsAndServices AS SaleOfGoodsAndServices,
				|	ShipmentDocumentsInAdvance.RowCode AS RowCode,
				|	ShipmentDocumentsInAdvance.Products AS Products,
				|	ShipmentDocumentsInAdvance.Characteristic AS Characteristic,
				|	ShipmentDocumentsInAdvance.Purpose AS Purpose
				|INTO ShippingDocuments
				|FROM
				|	ShipmentDocumentsInAdvance AS ShipmentDocumentsInAdvance
				|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
				|		ON ShipmentDocumentsInAdvance.DocumentShipments = DocumentsRegistry.ReversedDocument
				|			AND DocumentsRegistry.Posted
				|			AND NOT DocumentsRegistry.AdditionalRecord
				|WHERE
				|	DocumentsRegistry.Ref IS NULL
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT ALLOWED
				|	SalesOfGoodsServicesGoods.LineNumber AS LineNumber,
				|	SalesOfGoodsServicesGoods.Products AS Products,
				|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
				|	CASE
				|		WHEN ShipmentOfItemsByOrder.Ref IS NOT NULL
				|			THEN ShipmentOfItemsByOrder.Series
				|		WHEN ShipmentOfItemsOrder.Ref IS NOT NULL
				|			THEN ShipmentOfItemsOrder.Series
				|		WHEN ShipmentOfItemsOrderCorrection.Ref IS NOT NULL
				|			THEN ShipmentOfItemsOrderCorrection.Series
				|		ELSE
				|			SalesOfGoodsServicesGoods.Series
				|	END AS Series,
				|	SalesOfGoodsServicesGoods.Purpose AS Purpose,
				|	SalesOfGoodsServicesGoods.Purpose AS AssignmentSender,
				|	SalesOfGoodsServicesGoods.Package AS Package,
				|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
				|	SalesOfGoodsServicesGoods.Count AS Count,
				|	SalesOfGoodsServicesGoods.PriceKind AS PriceKind,
				|	CASE
				|		WHEN SalesOfGoodsServicesGoods.NumberOfPackages = 0
				|			THEN SalesOfGoodsServicesGoods.Price
				|		ELSE
				|			CAST(SalesOfGoodsServicesGoods.Sum / SalesOfGoodsServicesGoods.NumberOfPackages AS NUMBER(31,2))
				|	END AS Price,
				|	SalesOfGoodsServicesGoods.Sum AS Sum,
				|	SalesOfGoodsServicesGoods.VATRate AS VATRate,
				|	CASE
				|		WHEN ShipmentOfItemsByOrder.Ref IS NOT NULL
				|			THEN ShipmentOfItemsByOrder.Warehouse
				|		WHEN ShipmentOfItemsOrder.Ref IS NOT NULL
				|			THEN ShipmentOfItemsOrder.Warehouse
				|		WHEN ShipmentOfItemsOrderCorrection.Ref IS NOT NULL
				|			THEN ShipmentOfItemsOrderCorrection.Warehouse
				|		ELSE
				|			SalesOfGoodsServicesGoods.Warehouse
				|	END AS Warehouse,
				|	SalesOfGoodsServicesGoods.Department AS Department,
				|	SalesOfGoodsServicesGoods.VATAmount AS VATAmount,
				|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVAT,
				|	SalesOfGoodsServicesGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
				|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
				|	TRUE AS FilledInBySale,
				|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackagesByDocument,
				|	SalesOfGoodsServicesGoods.Count AS CountByDocument,
				|	SalesOfGoodsServicesGoods.Sum AS SumByDocument,
				|	SalesOfGoodsServicesGoods.VATAmount AS VATAmountByDocument,
				|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVATByDocument,
				|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
				|	SalesOfGoodsServicesGoods.RowCode AS RowCode
				|FROM
				|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
				|	LEFT JOIN ShippingDocuments AS ShippingDocuments
				|		ON SalesOfGoodsServicesGoods.SalesOrder = ShippingDocuments.SalesOrder
				|			AND SalesOfGoodsServicesGoods.Ref = ShippingDocuments.SaleOfGoodsAndServices
				|			AND SalesOfGoodsServicesGoods.RowCode = ShippingDocuments.RowCode
				|			AND SalesOfGoodsServicesGoods.Products = ShippingDocuments.Products
				|			AND SalesOfGoodsServicesGoods.Characteristic = ShippingDocuments.Characteristic
				|			AND SalesOfGoodsServicesGoods.Purpose = ShippingDocuments.Purpose
				|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsByOrder
				|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsByOrder.Ref
				|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsByOrder.Products
				|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsByOrder.Characteristic
				|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsByOrder.RowCode
				|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsByOrder.Purpose
				|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsByOrder.SalesOrder
				|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsOrder
				|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsOrder.Ref
				|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsOrder.Products
				|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsOrder.Characteristic
				|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsOrder.RowCode
				|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsOrder.Purpose
				|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsOrder.Ref
				|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsOrderCorrection
				|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsOrderCorrection.Ref
				|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsOrderCorrection.Products
				|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsOrderCorrection.Characteristic
				|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsOrderCorrection.RowCode
				|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsOrderCorrection.Purpose
				|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsOrderCorrection.Ref.CorrectedDocument
				|WHERE
				|	SalesOfGoodsServicesGoods.Ref IN(&BasisDocuments)
				|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
				|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
				|";
				
				QueryTexts.Add(QueryText);
				
			EndIf;
			
			QueryText = "
			|SELECT
			|	SalesOfGoodsServicesGoods.LineNumber AS LineNumber,
			|	SalesOfGoodsServicesGoods.Products AS Products,
			|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
			|	SalesOfGoodsServicesGoods.Series AS Series,
			|	SalesOfGoodsServicesGoods.Purpose AS Purpose,
			|	SalesOfGoodsServicesGoods.Purpose AS AssignmentSender,
			|	SalesOfGoodsServicesGoods.Package AS Package,
			|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
			|	SalesOfGoodsServicesGoods.Count AS Count,
			|	SalesOfGoodsServicesGoods.PriceKind AS PriceKind,
			|	CASE
			|		WHEN SalesOfGoodsServicesGoods.NumberOfPackages = 0
			|			THEN SalesOfGoodsServicesGoods.Price
			|		ELSE CAST(SalesOfGoodsServicesGoods.Sum / SalesOfGoodsServicesGoods.NumberOfPackages AS NUMBER(31,2))
			|	END AS Price,
			|	SalesOfGoodsServicesGoods.Sum AS Sum,
			|	SalesOfGoodsServicesGoods.VATRate AS VATRate,
			|	SalesOfGoodsServicesGoods.Warehouse AS Warehouse,
			|	SalesOfGoodsServicesGoods.Department AS Department,
			|	SalesOfGoodsServicesGoods.VATAmount AS VATAmount,
			|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVAT,
			|	SalesOfGoodsServicesGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
			|	TRUE AS FilledInBySale,
			|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackagesByDocument,
			|	SalesOfGoodsServicesGoods.Count AS CountByDocument,
			|	SalesOfGoodsServicesGoods.Sum AS SumByDocument,
			|	SalesOfGoodsServicesGoods.VATAmount AS VATAmountByDocument,
			|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVATByDocument,
			|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
			|	SalesOfGoodsServicesGoods.RowCode AS RowCode
			|FROM
			|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
			|WHERE
			|	SalesOfGoodsServicesGoods.Ref IN(&BasisDocuments)
			|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
			|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
			|ORDER BY
			|	SaleOfGoodsAndServices,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	SalesOfGoodsServicesSeries.Series          AS Series,
			|	SalesOfGoodsServicesSeries.Count     AS Count,
			|	SalesOfGoodsServicesSeries.Count     AS CountByDocument,
			|	SalesOfGoodsServicesSeries.Products   AS Products,
			|	SalesOfGoodsServicesSeries.Characteristic AS Characteristic,
			|	SalesOfGoodsServicesSeries.Purpose     AS Purpose,
			|	SalesOfGoodsServicesSeries.Purpose     AS AssignmentSender,
			|	SalesOfGoodsServicesSeries.Warehouse          AS Warehouse,
			|	SalesOfGoodsServicesSeries.Ref         AS SaleOfGoodsAndServices,
			|	TRUE                                     AS FilledInBySale
			|FROM
			|	Document.CustomerInvoice.SetOfSeries AS SalesOfGoodsServicesSeries
			|WHERE
			|	SalesOfGoodsServicesSeries.Ref IN(&BasisDocuments)
			|	AND SalesOfGoodsServicesSeries.Products.ItemsType IN(&ItemsTypes)
			|";
			
			QueryTexts.Add(QueryText);
			
			Query.Text = StrConcat(QueryTexts, Common.UnionAllText());
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
			Query.Text = "SELECT
			|	ShipmentOfItemsToCustomerItems.Products           AS Products,
			|	ShipmentOfItemsToCustomerItems.Characteristic         AS Characteristic,
			|	ShipmentOfItemsToCustomerItems.Series                  AS Series,
			|	ShipmentOfItemsToCustomerItems.Purpose             AS Purpose,
			|	ShipmentOfItemsToCustomerItems.Purpose             AS AssignmentSender,
			|	ShipmentOfItemsToCustomerItems.Package               AS Package,
			|	ShipmentOfItemsToCustomerItems.NumberOfPackages     AS NumberOfPackages,
			|	ShipmentOfItemsToCustomerItems.Count             AS Count,
			|	ShipmentOfItemsToCustomerItems.PriceKind                AS PriceKind,
			|	CASE
			|		WHEN ShipmentOfItemsToCustomerItems.NumberOfPackages = 0
			|			THEN ShipmentOfItemsToCustomerItems.Price
			|		ELSE CAST(ShipmentOfItemsToCustomerItems.Sum / ShipmentOfItemsToCustomerItems.NumberOfPackages AS NUMBER(31, 2))
			|	END                                               AS Price,
			|	ShipmentOfItemsToCustomerItems.Sum                  AS Sum,
			|	VALUE(Catalog.VATRates.EmptyRef)         AS VATRate,
			|	ShipmentOfItemsToCustomerItems.Warehouse                  AS Warehouse,
			|	ShipmentOfItemsToCustomerItems.Ref.Department   AS Department,
			|	0                                                   AS VATAmount,
			|	ShipmentOfItemsToCustomerItems.Sum                  AS AmountIncludingVAT,
			|	ShipmentOfItemsToCustomerItems.BatchesIndicationStatus    AS BatchesIndicationStatus,
			|	ShipmentOfItemsToCustomerItems.Ref                 AS SaleOfGoodsAndServices,
			|	TRUE                                              AS FilledInBySale,
			|	ShipmentOfItemsToCustomerItems.NumberOfPackages     AS NumberOfPackagesByDocument,
			|	ShipmentOfItemsToCustomerItems.Count             AS CountByDocument,
			|	ShipmentOfItemsToCustomerItems.Sum                  AS SumByDocument,
			|	0                                                   AS VATAmountByDocument,
			|	ShipmentOfItemsToCustomerItems.Sum                  AS AmountIncludingVATByDocument,
			|	ShipmentOfItemsToCustomerItems.SalesOrder           AS SalesOrder,
			|	ShipmentOfItemsToCustomerItems.RowCode              AS RowCode
			|FROM
			|	Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomerItems
			|WHERE
			|	ShipmentOfItemsToCustomerItems.Ref IN (&BasisDocuments)
			|	AND ShipmentOfItemsToCustomerItems.Products.ItemsType IN (&ItemsTypes)
			|ORDER BY
			|	SaleOfGoodsAndServices,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	ShipmentOfItemsToCustomerOfSeries.Series           AS Series,
			|	ShipmentOfItemsToCustomerOfSeries.Count      AS Count,
			|	ShipmentOfItemsToCustomerOfSeries.Count      AS CountByDocument,
			|	ShipmentOfItemsToCustomerOfSeries.Products    AS Products,
			|	ShipmentOfItemsToCustomerOfSeries.Characteristic  AS Characteristic,
			|	ShipmentOfItemsToCustomerOfSeries.Purpose      AS Purpose,
			|	ShipmentOfItemsToCustomerOfSeries.Purpose      AS AssignmentSender,
			|	ShipmentOfItemsToCustomerOfSeries.Warehouse           AS Warehouse,
			|	ShipmentOfItemsToCustomerOfSeries.Ref          AS SaleOfGoodsAndServices,
			|	TRUE                                      AS FilledInBySale
			|FROM
			|	Document.GoodsShipmentToCustomer.SetOfSeries AS ShipmentOfItemsToCustomerOfSeries
			|WHERE
			|	ShipmentOfItemsToCustomerOfSeries.Ref IN (&BasisDocuments)
			|	AND ShipmentOfItemsToCustomerOfSeries.Products.ItemsType IN (&ItemsTypes)";

		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
			
			Query.Text = "
			|SELECT
			|	PurchaseOfGoodsServicesGoods.Products           AS Products,
			|	PurchaseOfGoodsServicesGoods.PartnerProducts AS PartnerProducts,
			|	PurchaseOfGoodsServicesGoods.Characteristic         AS Characteristic,
			|	PurchaseOfGoodsServicesGoods.Series                  AS Series,
			|	PurchaseOfGoodsServicesGoods.Purpose             AS Purpose,
			|	PurchaseOfGoodsServicesGoods.Package               AS Package,
			|	PurchaseOfGoodsServicesGoods.NumberOfPackages     AS NumberOfPackages,
			|	PurchaseOfGoodsServicesGoods.Count             AS Count,
			|	PurchaseOfGoodsServicesGoods.VendorPriceKind      AS VendorPriceKind,
			|
			|	CASE
			|		WHEN PurchaseOfGoodsServicesGoods.NumberOfPackages = 0
			|			THEN PurchaseOfGoodsServicesGoods.Price
			|		ELSE  CAST(PurchaseOfGoodsServicesGoods.Sum / PurchaseOfGoodsServicesGoods.NumberOfPackages AS NUMBER(31,2))
			|	END                                             AS Price,
			|
			|	PurchaseOfGoodsServicesGoods.Sum               AS Sum,
			|	PurchaseOfGoodsServicesGoods.VATRate           AS VATRate,
			|	PurchaseOfGoodsServicesGoods.Warehouse               AS Warehouse,
			|	PurchaseOfGoodsServicesGoods.VATAmount            AS VATAmount,
			|	PurchaseOfGoodsServicesGoods.AmountIncludingVAT           AS AmountIncludingVAT,
			|	PurchaseOfGoodsServicesGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	PurchaseOfGoodsServicesGoods.Ref              AS DocumentBasis,
			|	TRUE                                            AS FilledUsingBaseDocument,
			|	PurchaseOfGoodsServicesGoods.NumberOfPackages  AS NumberOfPackagesByDocument,
			|	PurchaseOfGoodsServicesGoods.Count          AS CountByDocument,
			|	PurchaseOfGoodsServicesGoods.Sum               AS SumByDocument,
			|	PurchaseOfGoodsServicesGoods.VATAmount            AS VATAmountByDocument,
			|	PurchaseOfGoodsServicesGoods.AmountIncludingVAT           AS AmountIncludingVATByDocument,
			|	PurchaseOfGoodsServicesGoods.PurchaseOrder     AS PurchaseOrder,
			|	PurchaseOfGoodsServicesGoods.RowCode           AS RowCode,
			|	PurchaseOfGoodsServicesGoods.ToExpenseAs    AS ToExpenseAs,
			|	PurchaseOfGoodsServicesGoods.ExpenseItem      AS ExpenseItem,
			|	PurchaseOfGoodsServicesGoods.DimensionOfExpenses   AS DimensionOfExpenses,
			|	PurchaseOfGoodsServicesGoods.Department       AS Department,
			|	PurchaseOfGoodsServicesGoods.SalesOpportunity              AS SalesOpportunity,
			|	PurchaseOfGoodsServicesGoods.CCDNumber            AS CCDNumber,
			|	PurchaseOfGoodsServicesGoods.Certificate          AS Certificate
			|FROM
			|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
			|WHERE
			|	PurchaseOfGoodsServicesGoods.Ref IN(&BasisDocuments)
			|	AND PurchaseOfGoodsServicesGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
			|		VALUE(Enum.ItemsTypes.ReusablePackage))
			|ORDER BY
			|	DocumentBasis,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	PurchaseOfGoodsServicesSeries.Series          AS Series,
			|	PurchaseOfGoodsServicesSeries.Count     AS Count,
			|	PurchaseOfGoodsServicesSeries.Count     AS CountByDocument,
			|	PurchaseOfGoodsServicesSeries.Products   AS Products,
			|	PurchaseOfGoodsServicesSeries.Characteristic AS Characteristic,
			|	PurchaseOfGoodsServicesSeries.Purpose     AS Purpose,
			|	PurchaseOfGoodsServicesSeries.Warehouse          AS Warehouse,
			|	PurchaseOfGoodsServicesSeries.Ref         AS DocumentBasis,
			|	TRUE                                       AS FilledUsingBaseDocument
			|FROM
			|	Document.VendorInvoice.SetOfSeries AS PurchaseOfGoodsServicesSeries
			|WHERE
			|	PurchaseOfGoodsServicesSeries.Ref IN(&BasisDocuments)
			|	AND PurchaseOfGoodsServicesSeries.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
			|		VALUE(Enum.ItemsTypes.ReusablePackage))
			|ORDER BY
			|	DocumentBasis,
			|	Products,
			|	Characteristic,
			|	Series,
			|	Purpose,
			|	Warehouse
			|";
			
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
			  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
			  						Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
			Then
			
			Query.Text = "
			|SELECT
			|	AcceptanceOfGoodsForStorageGoods.Products             AS Products,
			|	AcceptanceOfGoodsForStorageGoods.PartnerProducts     AS PartnerProducts,
			|	AcceptanceOfGoodsForStorageGoods.Characteristic           AS Characteristic,
			|	AcceptanceOfGoodsForStorageGoods.Package                 AS Package,
			|	AcceptanceOfGoodsForStorageGoods.Purpose               AS Purpose,
			|	AcceptanceOfGoodsForStorageGoods.Series                    AS Series,
			|	AcceptanceOfGoodsForStorageGoods.Ref.VendorPriceKind AS VendorPriceKind,
			|	AcceptanceOfGoodsForStorageGoods.NumberOfPackages       AS NumberOfPackages,
			|	AcceptanceOfGoodsForStorageGoods.Count               AS Count,
			|	CASE
			|		WHEN AcceptanceOfGoodsForStorageGoods.NumberOfPackages = 0
			|			THEN AcceptanceOfGoodsForStorageGoods.Price
			|		ELSE  CAST(AcceptanceOfGoodsForStorageGoods.Sum / AcceptanceOfGoodsForStorageGoods.NumberOfPackages AS NUMBER(31,2))
			|	END                                              AS Price,
			|	AcceptanceOfGoodsForStorageGoods.Sum               AS Sum,
			|	VALUE(Catalog.VATRates.EmptyRef)        AS VATRate,
			|	AcceptanceOfGoodsForStorageGoods.Warehouse               AS Warehouse,
			|	0                                                  AS VATAmount,
			|	0                                                  AS AmountIncludingVAT,
			|	AcceptanceOfGoodsForStorageGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	AcceptanceOfGoodsForStorageGoods.Ref              AS DocumentBasis,
			|	TRUE                                             AS FilledUsingBaseDocument,
			|	AcceptanceOfGoodsForStorageGoods.NumberOfPackages  AS NumberOfPackagesByDocument,
			|	AcceptanceOfGoodsForStorageGoods.Count          AS CountByDocument,
			|	AcceptanceOfGoodsForStorageGoods.Sum               AS SumByDocument,
			|	0                                                  AS VATAmountByDocument,
			|	0                                                  AS AmountIncludingVATByDocument,
			|	AcceptanceOfGoodsForStorageGoods.PurchaseOrder     AS PurchaseOrder,
			|	AcceptanceOfGoodsForStorageGoods.RowCode           AS RowCode,
			|	AcceptanceOfGoodsForStorageGoods.SalesOpportunity              AS SalesOpportunity,
			|	AcceptanceOfGoodsForStorageGoods.CCDNumber            AS CCDNumber
			|FROM
			|	Document.GoodsReceiptForStorage.Goods AS AcceptanceOfGoodsForStorageGoods
			|WHERE
			|	AcceptanceOfGoodsForStorageGoods.Ref IN(&BasisDocuments)
			|ORDER BY
			|	DocumentBasis,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	AcceptanceOfGoodsForStorageOfSeries.Products   AS Products,
			|	AcceptanceOfGoodsForStorageOfSeries.Characteristic AS Characteristic,
			|	AcceptanceOfGoodsForStorageOfSeries.Purpose     AS Purpose,
			|	AcceptanceOfGoodsForStorageOfSeries.Series          AS Series,
			|	AcceptanceOfGoodsForStorageOfSeries.Count     AS Count,
			|	AcceptanceOfGoodsForStorageOfSeries.Count     AS CountByDocument,
			|	AcceptanceOfGoodsForStorageOfSeries.Warehouse          AS Warehouse,
			|	AcceptanceOfGoodsForStorageOfSeries.Ref         AS DocumentBasis,
			|	TRUE                                       AS FilledUsingBaseDocument
			|FROM
			|	Document.GoodsReceiptForStorage.SetOfSeries AS AcceptanceOfGoodsForStorageOfSeries
			|WHERE
			|	AcceptanceOfGoodsForStorageOfSeries.Ref IN(&BasisDocuments)
			|";
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			Query.Text = "
			|SELECT
			|	TransferGoods.Products          AS Products,
			|	TransferGoods.Characteristic        AS Characteristic,
			|	TransferGoods.Package              AS Package,
			|	TransferGoods.Purpose            AS Purpose,
			|	TransferGoods.AssignmentSender AS AssignmentSender,
			|	TransferGoods.Series                 AS Series,
			|	TransferGoods.NumberOfPackages    AS NumberOfPackages,
			|	TransferGoods.Count            AS Count,
			|	TransferGoods.PriceKind               AS PriceKind,
			|	CASE
			|		WHEN TransferGoods.NumberOfPackages = 0
			|			THEN TransferGoods.Price
			|		ELSE CAST(TransferGoods.Sum / TransferGoods.NumberOfPackages AS NUMBER(31, 2))
			|	END                                AS Price,
			|	TransferGoods.Sum                 AS Sum,
			|	0                                    AS VATAmount,
			|	TransferGoods.Sum                 AS AmountIncludingVAT,
			|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
			|	TransferGoods.Warehouse                 AS Warehouse,
			|	TransferGoods.BatchesIndicationStatus   AS BatchesIndicationStatus,
			|	TransferGoods.Ref                AS SaleOfGoodsAndServices,
			|	TRUE                               AS FilledInBySale,
			|	TransferGoods.NumberOfPackages    AS NumberOfPackagesByDocument,
			|	TransferGoods.Count            AS CountByDocument,
			|	TransferGoods.Sum                 AS SumByDocument,
			|	0                                    AS VATAmountByDocument,
			|	TransferGoods.Sum                 AS AmountIncludingVATByDocument,
			|	TransferGoods.SalesOrder          AS SalesOrder,
			|	TransferGoods.RowCode             AS RowCode
			|FROM
			|	Document.TransferOfGoodsToBailee.Goods AS TransferGoods
			|WHERE
			|	TransferGoods.Ref IN(&BasisDocuments)
			|ORDER BY
			|	SaleOfGoodsAndServices,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	TransferSeries.Products          AS Products,
			|	TransferSeries.Characteristic        AS Characteristic,
			|	TransferSeries.Purpose            AS Purpose,
			|	TransferSeries.AssignmentSender AS AssignmentSender,
			|	TransferSeries.Series                 AS Series,
			|	TransferSeries.Count            AS Count,
			|	TransferSeries.Count            AS CountByDocument,
			|	TransferSeries.Warehouse                 AS Warehouse,
			|	TransferSeries.Ref                AS SaleOfGoodsAndServices,
			|	TRUE                              AS FilledInBySale
			|FROM
			|	Document.TransferOfGoodsToBailee.SetOfSeries AS TransferSeries
			|WHERE
			|	TransferSeries.Ref IN(&BasisDocuments)
			|";
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisRefundFromCommissionAgent(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			Query.Text = "
			|SELECT ALLOWED
			|	GoodsTable.Products        AS Products,
			|	GoodsTable.Characteristic      AS Characteristic,
			|	GoodsTable.Package            AS Package,
			|	GoodsTable.Purpose          AS Purpose,
			|	GoodsTable.Series               AS Series,
			|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
			|	GoodsTable.Count          AS Count,
			|	CASE
			|		WHEN GoodsTable.NumberOfPackages = 0
			|			THEN GoodsTable.Price
			|		ELSE CAST(GoodsTable.Sum / GoodsTable.NumberOfPackages AS NUMBER(31, 2))
			|	END                             AS Price,
			|	GoodsTable.Sum               AS Sum,
			|	0                                 AS VATAmount,
			|	GoodsTable.Sum               AS AmountIncludingVAT,
			|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
			|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	GoodsTable.Ref              AS DocumentBasis,
			|	DocumentData.Warehouse             AS Warehouse,
			|	TRUE                            AS FilledUsingBaseDocument,
			|	GoodsTable.NumberOfPackages  AS NumberOfPackagesByDocument,
			|	GoodsTable.Count          AS CountByDocument,
			|	GoodsTable.Sum               AS SumByDocument,
			|	0                                 AS VATAmountByDocument,
			|	GoodsTable.Sum               AS AmountIncludingVATByDocument,
			|	GoodsTable.ReferenceOrder        AS PurchaseOrder,
			|	GoodsTable.CCDNumber            AS CCDNumber,
			|	GoodsTable.RowCode           AS RowCode
			|FROM
			|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
			|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS DocumentData
			|		ON GoodsTable.Ref = DocumentData.Ref
			|WHERE
			|	GoodsTable.Ref IN(&BasisDocuments)
			|ORDER BY
			|	DocumentBasis,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	SeriesTable.Products   AS Products,
			|	SeriesTable.Characteristic AS Characteristic,
			|	SeriesTable.Purpose     AS Purpose,
			|	SeriesTable.Series          AS Series,
			|	SeriesTable.Count     AS Count,
			|	SeriesTable.Count     AS CountByDocument,
			|	DocumentData.Warehouse       AS Warehouse,
			|	SeriesTable.Ref         AS DocumentBasis,
			|	TRUE                      AS FilledUsingBaseDocument,
			|	MAX(GoodsTable.BatchesIndicationStatus) AS BatchesIndicationStatus
			|FROM
			|	Document.ReceiptOfGoodsFromCustodian.SetOfSeries AS SeriesTable
			|		LEFT JOIN Document.ReceiptOfGoodsFromCustodian AS DocumentData
			|		ON SeriesTable.Ref = DocumentData.Ref
			|		
			|		INNER JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
			|		ON SeriesTable.Ref = GoodsTable.Ref
			|			AND SeriesTable.Products = GoodsTable.Products
			|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
			|			AND SeriesTable.Purpose = GoodsTable.Purpose
			|WHERE
			|	SeriesTable.Ref IN(&BasisDocuments)
			|	AND GoodsTable.Ref IN(&BasisDocuments)
			|	AND SeriesTable.Count <> 0
			|
			|GROUP BY
			|	SeriesTable.Products,
			|	SeriesTable.Characteristic,
			|	SeriesTable.Purpose,
			|	SeriesTable.Series,
			|	SeriesTable.Count,
			|	DocumentData.Warehouse,
			|	SeriesTable.Ref
			|
			|HAVING
			|	MAX(GoodsTable.BatchesIndicationStatus) IN(2, 4, 6, 8, 10)";
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
			  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
			  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
			Then
			
			Query.Text = "
			|SELECT ALLOWED
			|	ShipmentOfGoodsFromStorageGoods.Products        AS Products,
			|	ShipmentOfGoodsFromStorageGoods.Characteristic      AS Characteristic,
			|	ShipmentOfGoodsFromStorageGoods.Package            AS Package,
			|	ShipmentOfGoodsFromStorageGoods.Purpose          AS Purpose,
			|	ShipmentOfGoodsFromStorageGoods.Purpose          AS AssignmentSender,
			|	ShipmentOfGoodsFromStorageGoods.Series               AS Series,
			|	ShipmentOfGoodsFromStorageGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	ShipmentOfGoodsFromStorageGoods.NumberOfPackages  AS NumberOfPackages,
			|	ShipmentOfGoodsFromStorageGoods.Count          AS Count,
			|	ShipmentOfGoodsFromStorageGoods.Price                AS Price,
			|	VALUE(Catalog.VATRates.EXCLUDINGVAT)              AS VATRate,
			|	ShipmentOfGoodsFromStorageGoods.Sum               AS Sum,
			|	0                                                  AS VATAmount,
			|	0                                                  AS AmountIncludingVAT,
			|	ShipmentOfGoodsFromStorageGoods.NumberOfPackages  AS NumberOfPackagesByDocument,
			|	ShipmentOfGoodsFromStorageGoods.Count          AS CountByDocument,
			|	ShipmentOfGoodsFromStorageGoods.Sum               AS SumByDocument,
			|	0                                                  AS VATAmountByDocument,
			|	0                                                  AS AmountIncludingVATByDocument,
			|	ShipmentOfGoodsFromStorageGoods.Warehouse               AS Warehouse,
			|	ShipmentOfGoodsFromStorageGoods.Ref              AS SaleOfGoodsAndServices,
			|	TRUE                                             AS FilledInBySale,
			|	ShipmentOfGoodsFromStorageGoods.SalesOrder        AS SalesOrder,
			|	ShipmentOfGoodsFromStorageGoods.RowCode           AS RowCode
			|FROM
			|	Document.GoodsShipmentFromStorage.Goods AS ShipmentOfGoodsFromStorageGoods
			|WHERE
			|	ShipmentOfGoodsFromStorageGoods.Ref IN(&BasisDocuments)
			|ORDER BY
			|	SaleOfGoodsAndServices,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	ShipmentOfGoodsFromSeriesStorage.Products   AS Products,
			|	ShipmentOfGoodsFromSeriesStorage.Characteristic AS Characteristic,
			|	ShipmentOfGoodsFromSeriesStorage.Purpose     AS Purpose,
			|	ShipmentOfGoodsFromSeriesStorage.Purpose     AS AssignmentSender,
			|	ShipmentOfGoodsFromSeriesStorage.Series          AS Series,
			|	ShipmentOfGoodsFromSeriesStorage.Count     AS CountByDocument,
			|	ShipmentOfGoodsFromSeriesStorage.Count     AS Count,
			|	ShipmentOfGoodsFromSeriesStorage.Warehouse          AS Warehouse,
			|	ShipmentOfGoodsFromSeriesStorage.Ref         AS SaleOfGoodsAndServices,
			|	TRUE                                       AS FilledInBySale
			|FROM
			|	Document.GoodsShipmentFromStorage.SetOfSeries AS ShipmentOfGoodsFromSeriesStorage
			|WHERE
			|	ShipmentOfGoodsFromSeriesStorage.Ref IN(&BasisDocuments)";
			
		ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
			
			Query.Text = "
			|SELECT ALLOWED
			|	CASE
			|		WHEN ReturnOfGoodsFromCustomerGoods.Damage
			|			THEN ReturnOfGoodsFromCustomerGoods.ProductsRecordingAsReceived
			|		ELSE ReturnOfGoodsFromCustomerGoods.Products
			|	END AS Products,
			|	CASE
			|		WHEN ReturnOfGoodsFromCustomerGoods.Damage
			|			THEN ReturnOfGoodsFromCustomerGoods.CharacteristicRecordingAsReceived
			|		ELSE ReturnOfGoodsFromCustomerGoods.Characteristic
			|	END AS Characteristic,
			|	ReturnOfGoodsFromCustomerGoods.Series,
			|	ReturnOfGoodsFromCustomerGoods.Purpose AS Purpose,
			|	ReturnOfGoodsFromCustomerGoods.Package AS Package,
			|	ReturnOfGoodsFromCustomerGoods.NumberOfPackages AS NumberOfPackages,
			|	ReturnOfGoodsFromCustomerGoods.Count AS Count,
			|	ReturnOfGoodsFromCustomerGoods.Price AS Price,
			|	ReturnOfGoodsFromCustomerGoods.Sum AS Sum,
			|	ReturnOfGoodsFromCustomerGoods.VATRate AS VATRate,
			|	ReturnOfGoodsFromCustomerGoods.VATAmount AS VATAmount,
			|	ReturnOfGoodsFromCustomerGoods.AmountIncludingVAT AS AmountIncludingVAT,
			|	ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	ReturnOfGoodsFromCustomerGoods.Ref AS DocumentBasis,
			|	TRUE AS FilledUsingBaseDocument,
			|	ReturnOfGoodsFromCustomerGoods.NumberOfPackages AS NumberOfPackagesByDocument,
			|	ReturnOfGoodsFromCustomerGoods.Count AS CountByDocument,
			|	ReturnOfGoodsFromCustomerGoods.Sum AS SumByDocument,
			|	ReturnOfGoodsFromCustomerGoods.VATAmount AS VATAmountByDocument,
			|	ReturnOfGoodsFromCustomerGoods.AmountIncludingVAT AS AmountIncludingVATByDocument,
			|	ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
			|	ReturnOfGoodsFromCustomerGoods.RowCode AS RowCode,
			|	ReturnOfGoodsFromCustomer.RequestForReturnOfGoodsFromCustomer AS PurchaseOrder,
			|	ReturnOfGoodsFromCustomerGoods.CCDNumber AS CCDNumber,
			|	ReturnOfGoodsFromCustomerGoods.Warehouse AS Warehouse
			|FROM
			|	Document.ReturnOfGoodsFromCustomer.Goods AS ReturnOfGoodsFromCustomerGoods
			|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
			|		ON ReturnOfGoodsFromCustomerGoods.Ref = ReturnOfGoodsFromCustomer.Ref
			|WHERE
			|	ReturnOfGoodsFromCustomerGoods.Ref IN(&BasisDocuments)
			|ORDER BY
			|	DocumentBasis,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	SeriesTable.Series AS Series,
			|	SeriesTable.Count AS Count,
			|	SeriesTable.Count AS CountByDocument,
			|	CASE
			|		WHEN GoodsTable.Damage
			|			THEN SeriesTable.ProductsRecordingAsReceived
			|		ELSE SeriesTable.Products
			|	END AS Products,
			|	CASE
			|		WHEN GoodsTable.Damage
			|			THEN SeriesTable.CharacteristicRecordingAsReceived
			|		ELSE SeriesTable.Characteristic
			|	END AS Characteristic,
			|	SeriesTable.Warehouse AS Warehouse,
			|	SeriesTable.Ref AS DocumentBasis,
			|	TRUE AS FilledUsingBaseDocument,
			|	SeriesTable.Purpose AS Purpose,
			|	MAX(GoodsTable.BatchesIndicationStatus) AS BatchesIndicationStatus
			|FROM
			|	Document.ReturnOfGoodsFromCustomer.SetOfSeries AS SeriesTable
			|		INNER JOIN Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
			|		ON SeriesTable.Ref = GoodsTable.Ref
			|			AND SeriesTable.Products = GoodsTable.Products
			|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
			|			AND SeriesTable.ProductsRecordingAsReceived = GoodsTable.ProductsRecordingAsReceived
			|			AND SeriesTable.CharacteristicRecordingAsReceived = GoodsTable.CharacteristicRecordingAsReceived
			|			AND SeriesTable.Purpose = GoodsTable.Purpose
			|WHERE
			|	SeriesTable.Ref IN(&BasisDocuments)
			|	AND GoodsTable.Ref IN(&BasisDocuments)
			|	AND SeriesTable.Count <> 0
			|
			|GROUP BY
			|	SeriesTable.Products,
			|	SeriesTable.Characteristic,
			|	SeriesTable.Purpose,
			|	SeriesTable.Series,
			|	SeriesTable.ProductsRecordingAsReceived,
			|	SeriesTable.CharacteristicRecordingAsReceived,
			|	GoodsTable.Damage,
			|	SeriesTable.Count,
			|	SeriesTable.Warehouse,
			|	SeriesTable.Ref,
			|	SeriesTable.Count
			|
			|HAVING
			|	MAX(GoodsTable.BatchesIndicationStatus) IN (2, 4, 6, 8, 10)";
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			Query.Text = "
			|SELECT ALLOWED
			|	ReturnOfGoodsToSupplier.Products,
			|	ReturnOfGoodsToSupplier.Characteristic,
			|	ReturnOfGoodsToSupplier.Series,
			|	ReturnOfGoodsToSupplier.Purpose,
			|	ReturnOfGoodsToSupplier.Purpose AS AssignmentSender,
			|	ReturnOfGoodsToSupplier.Package,
			|	ReturnOfGoodsToSupplier.NumberOfPackages,
			|	ReturnOfGoodsToSupplier.Count,
			|	ReturnOfGoodsToSupplier.Price AS Price,
			|	ReturnOfGoodsToSupplier.Sum,
			|	ReturnOfGoodsToSupplier.VATRate,
			|	ReturnOfGoodsToSupplier.Ref.Warehouse AS Warehouse,
			|	ReturnOfGoodsToSupplier.VATAmount,
			|	ReturnOfGoodsToSupplier.AmountIncludingVAT,
			|	ReturnOfGoodsToSupplier.BatchesIndicationStatus,
			|	ReturnOfGoodsToSupplier.Ref AS SaleOfGoodsAndServices,
			|	VALUE(Document.SalesOrder.EmptyRef) AS SalesOrder,
			|	TRUE AS FilledInBySale,
			|	ReturnOfGoodsToSupplier.NumberOfPackages AS NumberOfPackagesByDocument,
			|	ReturnOfGoodsToSupplier.Count AS CountByDocument,
			|	ReturnOfGoodsToSupplier.Sum AS SumByDocument,
			|	ReturnOfGoodsToSupplier.VATAmount AS VATAmountByDocument,
			|	ReturnOfGoodsToSupplier.AmountIncludingVAT AS AmountIncludingVATByDocument,
			|	ReturnOfGoodsToSupplier.DocumentInflow
			|FROM
			|	Document.ReturnOfGoodsToVendor.Goods AS ReturnOfGoodsToSupplier
			|WHERE
			|	ReturnOfGoodsToSupplier.Ref IN(&BasisDocuments)
			|ORDER BY
			|	SaleOfGoodsAndServices,
			|	LineNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	ReturnOfGoodsToVendorSetOfSeries.Series          AS Series,
			|	ReturnOfGoodsToVendorSetOfSeries.Count     AS Count,
			|	ReturnOfGoodsToVendorSetOfSeries.Count     AS CountByDocument,
			|	ReturnOfGoodsToVendorSetOfSeries.Products   AS Products,
			|	ReturnOfGoodsToVendorSetOfSeries.Characteristic AS Characteristic,
			|	ReturnOfGoodsToVendorSetOfSeries.Purpose     AS Purpose,
			|	ReturnOfGoodsToVendorSetOfSeries.Purpose     AS AssignmentSender,
			|	ReturnOfGoodsToVendorSetOfSeries.Ref.Warehouse   AS Warehouse,
			|	ReturnOfGoodsToVendorSetOfSeries.Ref         AS SaleOfGoodsAndServices,
			|	TRUE                                       AS FilledInBySale
			|FROM
			|	Document.ReturnOfGoodsToVendor.SetOfSeries AS ReturnOfGoodsToVendorSetOfSeries
			|WHERE
			|	ReturnOfGoodsToVendorSetOfSeries.Ref IN(&BasisDocuments)
			|ORDER BY
			|	SaleOfGoodsAndServices,
			|	Products,
			|	Characteristic,
			|	Series,
			|	Purpose,
			|	AssignmentSender,
			|	Warehouse
			|";
			
		EndIf;
		
		FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer();
		
		Query.SetParameter("BasisDocuments", Form.BasisDocuments.Unload().UnloadColumn("SaleOfGoodsAndServices"));
		Query.SetParameter("ItemsTypes", FilterByProductType);
		QueryResults = Query.ExecuteBatch();
		QueryResultGoods = QueryResults[QueryResults.UBound()-1];
		ResultOfSeriesRequest = QueryResults[QueryResults.UBound()];
		If Form.FillingVariant = "Variant1" Then
			If QueryResultGoods.IsEmpty() Then
				Form.Object.Goods.Clear();
				Form.Object.SetOfSeries.Clear();
			Else
				Form.Object.SetOfSeries.Load(ResultOfSeriesRequest.Unload());
				Form.Object.Goods.Load(QueryResultGoods.Unload());
			EndIf;
		ElsIf Form.FillingVariant = "Variant2" Then
			// To the sub-document from the foundation, we calculate the fact	
			TheStructureOfTheSearch = New Structure("Products,Characteristic,Package");
			DocumentGoods = Form.Object.Goods;
			BaseGoodsTable = QueryResultGoods.Unload();
			If BaseGoodsTable.Columns.Find("SaleOfGoodsAndServices") <> Undefined Then
				FillInImplementation = True;
				FillInBusinessUnit = DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
					Or (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
						And Form.Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
			Else
				FillInImplementation = False;
			EndIf;
			
			CacheOfPackagingDetails = New Map;
			
			For Each RowOfTables In BaseGoodsTable Do
				FillPropertyValues(TheStructureOfTheSearch, RowOfTables);
				FoundDocumentLines = DocumentGoods.FindRows(TheStructureOfTheSearch);
				If FoundDocumentLines.Count() > 0 Then
					For Each RowTS In FoundDocumentLines Do
						RowTS.NumberOfPackagesByDocument = RowOfTables.NumberOfPackagesByDocument;
						RowTS.NumberOfPackages = RowTS.NumberOfPackagesByDocument + RowTS.NumberOfDiscrepancyPackaging;
						
						If ValueIsFilled(RowTS.Package) Then;
							CacheKey = String(RowTS.Products.UUID()) + "_" + String(RowTS.Package.UUID());
							If CacheOfPackagingDetails.Get(CacheKey) = Undefined Then
								PackingDetails = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(RowTS.Package, RowTS.Products);
								CacheOfPackagingDetails.Insert(CacheKey, PackingDetails);
							Else
								PackingDetails = CacheOfPackagingDetails.Get(CacheKey);
							EndIf;
						Else
							PackingDetails = New Structure("ZoomRatio", 1);
						EndIf;
						RowTS.Count = RowTS.NumberOfPackages * PackingDetails.ZoomRatio;
						RowTS.CountByDocument = RowTS.NumberOfPackagesByDocument * PackingDetails.ZoomRatio; 
						
						RowTS.SumByDocument = RowOfTables.SumByDocument;
						RowTS.Sum = RowTS.SumByDocument + RowTS.DiscrepancyAmount;
						
						RowTS.AmountIncludingVATByDocument = RowOfTables.AmountIncludingVATByDocument;
						RowTS.AmountIncludingVAT = RowTS.AmountIncludingVATByDocument + RowTS.TheAmountOfTheSNDSRansmission;
						
						RowTS.VATAmountByDocument = RowOfTables.VATAmountByDocument;
						RowTS.VATAmount = RowTS.VATAmountByDocument + RowTS.PersonalIncomeTaxExpense;
						
						If FillInImplementation Then
							RowTS.SaleOfGoodsAndServices   = RowOfTables.SaleOfGoodsAndServices;
							RowTS.SalesOrder = RowOfTables.SalesOrder;
							RowTS.RowCode    = RowOfTables.RowCode;
							If FillInBusinessUnit Then
								RowTS.Department = RowOfTables.Department;
							EndIf;
						Else
							RowTS.DocumentBasis = RowOfTables.DocumentBasis;
						EndIf;
						RowTS.Warehouse = RowOfTables.Warehouse;
					EndDo;
				Else
					NewRow = DocumentGoods.Add();
					FillPropertyValues(NewRow, RowOfTables);
				EndIf;
			EndDo;
	
			Form.Object.SetOfSeries.Load(ResultOfSeriesRequest.Unload());
		ElsIf Form.FillingVariant = "Variant3" Then
			// To the sub-document from the base, we calculate the discrepancies	
			TheStructureOfTheSearch = New Structure("Products,Characteristic,Package");
			DocumentGoods = Form.Object.Goods;
			BaseGoodsTable = QueryResultGoods.Unload();
			If BaseGoodsTable.Columns.Find("SaleOfGoodsAndServices") <> Undefined Then
				FillInImplementation = True;
				FillInBusinessUnit = DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
					Or (DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
						And Form.Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
			Else
				FillInImplementation = False;
			EndIf;
			
			CacheOfPackagingDetails = New Map;
			
			For Each RowOfTables In BaseGoodsTable Do
				FillPropertyValues(TheStructureOfTheSearch, RowOfTables);
				FoundDocumentLines = DocumentGoods.FindRows(TheStructureOfTheSearch);
				If FoundDocumentLines.Count() > 0 Then
					For Each RowTS In FoundDocumentLines Do
						If ValueIsFilled(RowTS.Package) Then;
							CacheKey = String(RowTS.Products.UUID()) + "_" + String(RowTS.Package.UUID());
							If CacheOfPackagingDetails.Get(CacheKey) = Undefined Then
								PackingDetails = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(RowTS.Package, RowTS.Products);
								CacheOfPackagingDetails.Insert(CacheKey, PackingDetails);
							Else
								PackingDetails = CacheOfPackagingDetails.Get(CacheKey);
							EndIf;
						Else
							PackingDetails = New Structure("ZoomRatio", 1);
						EndIf;
						RowTS.NumberOfPackagesByDocument = RowOfTables.NumberOfPackagesByDocument;
						RowTS.CountByDocument = RowTS.NumberOfPackagesByDocument * PackingDetails.ZoomRatio;
						RowTS.SumByDocument = RowOfTables.SumByDocument;
						RowTS.AmountIncludingVATByDocument = RowOfTables.AmountIncludingVATByDocument;
						RowTS.VATAmountByDocument = RowOfTables.VATAmountByDocument;
						If FillInImplementation Then
							RowTS.SaleOfGoodsAndServices   = RowOfTables.SaleOfGoodsAndServices;
							RowTS.SalesOrder = RowOfTables.SalesOrder;
							RowTS.RowCode    = RowOfTables.RowCode;
							If FillInBusinessUnit Then
								RowTS.Department = RowOfTables.Department;
							EndIf;
						Else
							RowTS.DocumentBasis = RowOfTables.DocumentBasis;
						EndIf;
						RowTS.Warehouse = RowOfTables.Warehouse;
					EndDo;
				Else
					NewRow = DocumentGoods.Add();
					FillPropertyValues(NewRow, RowOfTables);
				EndIf;
			EndDo;
			
			Form.Object.SetOfSeries.Load(ResultOfSeriesRequest.Unload());
		EndIf;
		
	EndIf;
	
	Form.Modified = True;
	FillInServiceDetailsForProductRange(Form.Object);
	FormationOfInscriptionDocumentsBase(Form);
	
	If DiscrepanciesClientServer.ThisIsActOfDiscrepanciesAfterShipment(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterShipment(Form.Object);
	Else
		DiscrepanciesServer.FillInDependentDetailsOfGoodsDiscrepanciesAfterAcceptance(Form.Object);
	EndIf;
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	If CallAvailabilityManagement Then
		DiscrepanciesClientServer.AvailabilityControl(Form);
	EndIf;
	
EndProcedure

// Parameters:
// 	Object - DocumentObject, FormDataStructure - Document data
// 
Procedure FillInServiceDetailsForProductRange(Object) Export
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
	                                       New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
	                                       New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
	                                       New Structure("Products", "SKU"));
	
	If TypeOf(Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
		ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
		
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
EndProcedure

Function GetUploadedProductsFromStorage(GoodsTable, BasisDocuments ,GoodsAddressInStorage) Export

	StructureOfActions = DiscrepanciesClientServer.StructureOfActionsWhenChangingNumberOfPackages();

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);

	Query = New Query;
	Query.Text = "
	|SELECT
	|	DataFromExternalSource.Products,
	|	DataFromExternalSource.Characteristic,
	|	DataFromExternalSource.Package,
	|	DataFromExternalSource.NumberOfPackages,
	|	ISNULL(DataFromExternalSource.Price, 0) AS Price,
	|	DataFromExternalSource.VATRate,
	|	DataFromExternalSource.ItemVariantsAreUsed
	|INTO ExternalSourceData
	|FROM
	|	&DataFromExternalSource AS DataFromExternalSource
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Products,
	|	DocumentData.Characteristic,
	|	DocumentData.Package,
	|	DocumentData.NumberOfPackages,
	|	ISNULL(DocumentData.Price, 0) AS Price,
	|	DocumentData.LineNumber
	|INTO DocumentData
	|FROM
	|	&DocumentData AS DocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalSourceData.Products,
	|	ExternalSourceData.Characteristic,
	|	ExternalSourceData.Package,
	|	ExternalSourceData.NumberOfPackages,
	|	ExternalSourceData.Price,
	|	ISNULL(DocumentData.LineNumber, 0) AS LineNumber,
	|	ExternalSourceData.VATRate,
	|	ExternalSourceData.ItemVariantsAreUsed
	|FROM
	|	ExternalSourceData AS ExternalSourceData
	|		LEFT JOIN DocumentData AS DocumentData
	|		ON ExternalSourceData.Products = DocumentData.Products
	|			AND ExternalSourceData.Characteristic = DocumentData.Characteristic
	|			AND ExternalSourceData.Package = DocumentData.Package
	|			AND ExternalSourceData.Price = DocumentData.Price
	|WHERE
	|	ExternalSourceData.NumberOfPackages <> ISNULL(DocumentData.NumberOfPackages, 0)";
	
	DocumentGoods = GoodsTable.Unload(); // ValueTable
	
	If DocumentGoods.Columns.Find("Price") = Undefined Then
		DocumentGoods.Columns.Add("Price", New TypeDescription("Number"));
	EndIf;

	Query.SetParameter("DataFromExternalSource", ItemsFromStorage);
	Query.SetParameter("DocumentData", DocumentGoods);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return New Array();
	EndIf;
	
	Selection = Result.Select();
	
	RowsToProcess = New Array();
	
	While Selection.Next() Do
	
		If Selection.LineNumber > 0 Then
			
			StringTSGoods = GoodsTable[Selection.LineNumber - 1];
			StringTSGoods.NumberOfPackages = Selection.NumberOfPackages;
			
		Else
			
			StringTSGoods = GoodsTable.Add();
			FillPropertyValues(StringTSGoods, Selection);
			DiscrepanciesClientServer.FillInDocumentBaseInLine(StringTSGoods, BasisDocuments);
		EndIf;
		
		RowsToProcess.Add(StringTSGoods);
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		GoodsTable,
		CachedValues);
		
	Return RowsToProcess;
	
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - contains including:
// 		* Object - DocumentObject, FormDataStructure - 
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
// 	ValueSelected - Structure - selected value
// 	ThisIsActOfDivergenceAfterShipment - Boolean - indicates the document type
// 	FillInVATRateByPriceType - Boolean - indicates whether the VAT rate is filled in based on the price type.
// 	
Procedure ProcessingSelectionOfSelectionOnServer(Form,
										CachedValues,
										ValueSelected,
										ThisIsActOfDivergenceAfterShipment,
										FillInVATRateByPriceType = False) Export
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ListOfProperties = "Products, Characteristic, Package, Price, NumberOfPackages";
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		ListOfProperties = ListOfProperties + ", PriceKind";
		
	ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		
		ListOfProperties = ListOfProperties + ", VendorPriceKind, PartnerProducts";
		
	EndIf;
	
	VATIsNotRecorded = DiscrepanciesClientServer.VATIsNotRecorded(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	If Not VATIsNotRecorded Then
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Form.Object);
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
		If FillInVATRateByPriceType Then
			StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Form.Object));
		EndIf;
	EndIf;
	
	SelfServiceClientServer.AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form.Object);
	
	RowsToProcess = New Array();
	TSGoods = Form.Object.Goods;
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = TSGoods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		SelfServiceClientServer.FillInDocumentBaseInLine(CurrentRow, Form.BasisDocuments, ThisIsActOfDivergenceAfterShipment);
		If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
			Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
			
			DiscrepanciesClientServer.FillInTransactionInLine(CurrentRow, Form.TransactionOrders);
			
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", Form.CacheQualityControl);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TSGoods,
		CachedValues);
			
	FillInServiceDetailsForProductRange(Form.Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Form.Object, Form.SeriesSpecificationParameters);
	DiscrepanciesClientServer.CalculateFormTotals(Form);

EndProcedure

Function ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn() Export

	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.StatusesOfDiscrepancyReport.ForCompletion);
	ArrayOfValidStatuses.Add(Enums.StatusesOfDiscrepancyReport.Processed_);
	
	Return ArrayOfValidStatuses;

EndFunction

// Parameters:
//  CurRow - LineOfATabularSection - contains including:
//   * Action - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue, EnumRef.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt -
//  TypeOfAct		 - Type - Document type.
//  OperationType	 - String - Clarification of the operation performed by documents.
// 
// Returns:
//  Boolean - The act line contains actions that require processing.
//
Function ActLineContainsActionsThatNeedToBeProcessed(CurRow, TypeOfAct, OperationType = "")
	
	If TypeOfAct = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		
		If CurRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait") Then
			Return False;
		EndIf;
		
		If CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow")
					And CurRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off") Then
			
			Return True;
			
		EndIf;
		
		Return False;
		
	ElsIf TypeOfAct = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		
		If CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired")
				Or CurRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery") Then
			
			Return True;
			
		Else
			
			Return False;
			
		EndIf;
		
	ElsIf TypeOfAct = Type("DocumentRef.DiscrepancyReportFollowingReceipt")
		And OperationType = "TwoWayRegistrationOfAdjustments" Then
		
		Return True;
		
	Else
			
		If CurRow.Action <> PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration")
			And CurRow.Action <> PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices") Then
			
			Return True;
			
		Else
			
			Return False;
			
		EndIf;
		
	EndIf;
	
EndFunction

// Checks whether a change to the basis of the act is available
//
// Parameters:
//  Form  - ClientApplicationForm - the form of the document.
//  Goods - TabularSection - table part of the act of discrepancies.
//  DiscrepancyLabel - FormField - elements of the form where you want to display the information label.
//  InscriptionIssueDocuments - FormField - elements of the form where you want to display the information label.
//  TypeOfAct - Type - Document type.
//  OperationType - String - Clarification of the operation performed by documents. Using - See ActLineContainsActionsThatNeedToBeProcessed.
//
Procedure FormInscriptionToReflectDiscrepancies(Form, Goods, DiscrepancyLabel, InscriptionIssueDocuments, TypeOfAct, OperationType = "") Export
	
	NumberOfDiscrepancyLines = 0;
	
	For Each CurRow In Goods Do
		
		If CurRow.NumberOfDiscrepancyPackaging <> 0 And ActLineContainsActionsThatNeedToBeProcessed(CurRow, TypeOfAct, OperationType) Then
			
			NumberOfDiscrepancyLines = NumberOfDiscrepancyLines + 1;
			
		EndIf;
		
	EndDo;
	
	If NumberOfDiscrepancyLines > 0 Then
		
		TextString_ = TMCommonUseClientServer.DeclensionOfWord(
		NumberOfDiscrepancyLines,
		NStr("vi = 'dòng, dòng, dòng, d';
			|ru = 'строке, строках, строках, ж';
			|en = 'line, lines'; fa = 'line, lines';
			|it = 'строке, строках, строках, ж';
			|pl = 'line, lines';
			|tr = 'satır, satırlar, satırlar, j'"));

		TextOfDiscrepancies = NStr("vi = 'Đăng ký chênh lệch theo %NumberOfDiscrepancyLines% Biên bản';
									|ru = 'Оформление расхождений в %NumberOfDiscrepancyLines% акта';
									|en = 'Registration of discrepancies in %NumberOfDiscrepancyLines% of the statement'; fa = 'Registration of discrepancies in %NumberOfDiscrepancyLines% of the statement';
									|it = 'Regolarizzazione delle deviazioni in %NumberOfDiscrepancyLines% dell''atto';
									|pl = 'Sporządzenie odchylenia w %NumberOfDiscrepancyLines% aktach';
									|tr = '%NumberOfDiscrepancyLines% tutarsızlık raporunun oluşturulması'");
		TextOfDiscrepancies = StrReplace(TextOfDiscrepancies, "%NumberOfDiscrepancyLines%", String(NumberOfDiscrepancyLines)  + " " + TextString_);
		
		InscriptionIssueDocuments.Enabled = True;
		
	Else
		
		TextOfDiscrepancies = NStr("vi = 'Trong biên bản chênh lệch không có dòng nào cần tạo lại chứng từ.';
									|ru = 'В акте отсутствуют строки с расхождениями, по которым требуется оформление документов';
									|en = 'There are no lines with discrepancies in the report for which document registration is required'; fa = 'There are no lines with discrepancies in the report for which document registration is required';
									|it = 'Nell''atto sono assenti righe con divergenze, per le quali è richiesta una regolarizzazione dei documenti';
									|pl = 'W akcie są nieobecne wiersze z odchyleniem dla których jest wymagane sporządzenie dokumentów';
									|tr = 'Raporda belgelendirilmesi gereken herhangi bir tutarsızlık satırı bulunmamaktadır'");
		InscriptionIssueDocuments.Enabled = False;
		
	EndIf;
	
	Form.ActLinesContainActionsThatRequireProcessing = (NumberOfDiscrepancyLines > 0);
	
	DiscrepancyLabel.Title = TextOfDiscrepancies;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
Procedure ActOfDiscrepanciesEstablishConditionalAppearanceOfFormOfDocument(Form) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems      = Form.Items;
	
	FormElementsProductsAction                  = FormItems.GoodsAction; // FormField
	FormElementsProductsWarehouse                     = FormItems.GoodsWarehouse; // FormField
	ItemsInProductsAmountForm                     = FormItems.GoodsSum; // FormField
	FormElementsProductsNumberOfDiscrepancy     = FormItems.ProductsQuantityDiscrepancies; // FormField
	FormElementsDocumentsBasePresentation = FormItems.DocumentsBasisSubmission; // FormField
	ItemsOfGoodsFormAmountOfDiscrepancy          = FormItems.GoodsDiscrepancyAmount; // FormField
	ItemsOfProductsVATAmountFormDiscrepancies       = FormItems.GoodsPersonalIncomeTaxExpense; // FormField
	ItemsOfFormGoodsSumWithVATDiscrepancies      = FormItems.GoodsTheAmountOfTheSNDSRansmission; // FormField
		
	// Package
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form);
	
	// The use of the characteristics
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(Form);
	
	// Product Action No discrepancies
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsProductsAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThereAreDiscrepancies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	// Commodity action The document is not agreed
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsProductsAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The type of item is not a container or a product
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = Form;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	// Type of item container or product

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsProductsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Warehouse mark blank

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsProductsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Sum

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsInProductsAmountForm.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Discrepancy quantity

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsProductsNumberOfDiscrepancy.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfDiscrepancyPackaging");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Unavailability of foundation documents

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsDocumentsBasePresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfBaseDocuments");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// Discrepancy amount
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsOfGoodsFormAmountOfDiscrepancy.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DiscrepancyAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Discrepancy amount of VAT

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsOfProductsVATAmountFormDiscrepancies.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PersonalIncomeTaxExpense");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Discrepancy amount with VAT

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsOfFormGoodsSumWithVATDiscrepancies.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheAmountOfTheSNDSRansmission");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
EndProcedure

Procedure FillInDefaultContract(Object, ContractBusinessTransaction) Export
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Object.Contract = SalesServer.GetDefaultContract(Object, Object.BusinessOperation, Object.Currency);

	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Object.Contract = SalesServer.GetDefaultContract(Object,
			PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"), Object.Currency);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Object.Contract = Handler.GetDefaultContract(Object,, False);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Object.Contract = Handler.GetDefaultContract(Object,, False);
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		Object.Contract = SalesServer.GetDefaultContract(Object, ContractBusinessTransaction, Object.Currency);
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		Object.Contract = PurchasesServer.GetDefaultContract(Object, Object.BusinessOperation, AddlParameters);
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		
		Object.Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction);
		
	Else
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		Object.Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - Document
// 	ArrayOfDocuments - Undefined, Array - array of foundation documents
// 
Procedure GenerateTableOfDocumentsOfBases(Form, ArrayOfDocuments = Undefined) Export
	
	TypeOfGNRActOfDivergence = TypeOf(Form.Object.Ref);
	AttributesNames = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(
		TypeOfGNRActOfDivergence = Type("DocumentRef.DiscrepancyReportFollowingShipment"));
	
	Form.BasisDocuments.Clear();
	Form.Items.GoodsDocumentBasis.ChoiceList.Clear();
	
	If ArrayOfDocuments = Undefined Then
		ArrayOfDocuments = Form.Object.Goods.Unload(, AttributesNames.Basis).UnloadColumn(AttributesNames.Basis);
	EndIf;

	If ArrayOfDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		QueryTexts = New Array;
		
		ThereIsRightToReadShipmentOfClientSGoods = AccessRight("Read", Metadata.Documents.GoodsShipmentToCustomer);
		
		If ThereIsRightToReadShipmentOfClientSGoods Then
			
			QueryText = "
			|SELECT ALLOWED
			|	MAX(Table.Ref) AS DocumentShipments,
			|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
			|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
			|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
			|	SalesOfGoodsServicesGoods.Products AS Products,
			|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
			|	SalesOfGoodsServicesGoods.Purpose AS Purpose
			|INTO ShipmentDocumentsInAdvance
			|FROM
			|	Document.GoodsShipmentToCustomer.Goods AS Table
			|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
			|		ON Table.Products = SalesOfGoodsServicesGoods.Products
			|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
			|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
			|			AND Table.Ref = SalesOfGoodsServicesGoods.SalesOrder
			|WHERE
			|	Table.Ref.Posted
			|	AND SalesOfGoodsServicesGoods.Ref IN(&ArrayOfBases)
			|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
			|
			|GROUP BY
			|	SalesOfGoodsServicesGoods.SalesOrder,
			|	SalesOfGoodsServicesGoods.Ref,
			|	SalesOfGoodsServicesGoods.RowCode,
			|	SalesOfGoodsServicesGoods.Products,
			|	SalesOfGoodsServicesGoods.Characteristic,
			|	SalesOfGoodsServicesGoods.Purpose
			|
			|UNION ALL
			|
			|SELECT
			|	MAX(Table.Ref) AS DocumentShipments,
			|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
			|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
			|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
			|	SalesOfGoodsServicesGoods.Products AS Products,
			|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
			|	SalesOfGoodsServicesGoods.Purpose AS Purpose
			|FROM
			|	Document.GoodsShipmentToCustomer.Goods AS Table
			|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
			|		ON Table.Products = SalesOfGoodsServicesGoods.Products
			|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
			|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
			|			AND Table.Ref.CorrectedDocument = SalesOfGoodsServicesGoods.SalesOrder
			|WHERE
			|	Table.Ref.Posted
			|	AND SalesOfGoodsServicesGoods.Ref IN(&ArrayOfBases)
			|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
			|
			|GROUP BY
			|	SalesOfGoodsServicesGoods.SalesOrder,
			|	SalesOfGoodsServicesGoods.Ref,
			|	SalesOfGoodsServicesGoods.RowCode,
			|	SalesOfGoodsServicesGoods.Products,
			|	SalesOfGoodsServicesGoods.Characteristic,
			|	SalesOfGoodsServicesGoods.Purpose
			|
			|UNION ALL
			|
			|SELECT
			|	MAX(Table.Ref) AS DocumentShipments,
			|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
			|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
			|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
			|	SalesOfGoodsServicesGoods.Products AS Products,
			|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
			|	SalesOfGoodsServicesGoods.Purpose AS Purpose
			|FROM
			|	Document.GoodsShipmentToCustomer.Goods AS Table
			|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
			|		ON Table.Products = SalesOfGoodsServicesGoods.Products
			|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
			|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
			|			AND Table.SalesOrder = SalesOfGoodsServicesGoods.SalesOrder
			|WHERE
			|	Table.Ref.Posted
			|	AND SalesOfGoodsServicesGoods.Ref IN(&ArrayOfBases)
			|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
			|
			|GROUP BY
			|	SalesOfGoodsServicesGoods.SalesOrder,
			|	SalesOfGoodsServicesGoods.Ref,
			|	SalesOfGoodsServicesGoods.RowCode,
			|	SalesOfGoodsServicesGoods.Products,
			|	SalesOfGoodsServicesGoods.Characteristic,
			|	SalesOfGoodsServicesGoods.Purpose
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	ShipmentDocumentsInAdvance.DocumentShipments AS DocumentShipments,
			|	ShipmentDocumentsInAdvance.SalesOrder AS SalesOrder,
			|	ShipmentDocumentsInAdvance.SaleOfGoodsAndServices AS SaleOfGoodsAndServices,
			|	ShipmentDocumentsInAdvance.RowCode AS RowCode,
			|	ShipmentDocumentsInAdvance.Products AS Products,
			|	ShipmentDocumentsInAdvance.Characteristic AS Characteristic,
			|	ShipmentDocumentsInAdvance.Purpose AS Purpose
			|INTO ShippingDocuments
			|FROM
			|	ShipmentDocumentsInAdvance AS ShipmentDocumentsInAdvance
			|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|		ON ShipmentDocumentsInAdvance.DocumentShipments = DocumentsRegistry.ReversedDocument
			|			AND DocumentsRegistry.Posted
			|			AND NOT DocumentsRegistry.AdditionalRecord
			|WHERE
			|	DocumentsRegistry.Ref IS NULL
			|";
			
			QueryTexts.Add(QueryText);
			
		EndIf;
		
		QueryTextsTSItems = New Array;
		
		QueryText = "
		|SELECT ALLOWED DISTINCT
		|	CustomerInvoice.Ref AS SaleOfGoodsAndServices,
		|	CustomerInvoice.Date AS Date,
		|	ISNULL(SalesOfGoodsServicesGoods.SalesOrder, UNDEFINED) AS SalesOrder,
		|	ISNULL(SalesOfGoodsServicesGoods.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
		|	CustomerInvoice.ToReturnReusablePackage AS ToReturnReusablePackage,
		|	CustomerInvoice.PackageDepositIsRequired AS PackageDepositIsRequired
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|		LEFT JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
		|		ON (SalesOfGoodsServicesGoods.Ref = CustomerInvoice.Ref)
		|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|		ON CustomerInvoice.LineOfBusiness = LinesOfBusiness.Ref
		|			AND LinesOfBusiness.CostAccounting
		|WHERE
		|	CustomerInvoice.Ref IN(&ArrayOfBases)
		|	AND CustomerInvoice.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|";
		
		QueryTextsTSItems.Add(QueryText);
		
		If ThereIsRightToReadShipmentOfClientSGoods Then
			
			QueryText =
			"SELECT
			|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
			|	SalesOfGoodsServicesGoods.Ref.Date AS Date,
			|	ISNULL(SalesOfGoodsServicesGoods.SalesOrder, UNDEFINED) AS SalesOrder,
			|	CASE
			|		WHEN ShipmentOfItemsByOrder.Ref IS NOT NULL
			|			THEN ShipmentOfItemsByOrder.Warehouse
			|		WHEN ShipmentOfItemsOrder.Ref IS NOT NULL
			|			THEN ShipmentOfItemsOrder.Warehouse
			|		WHEN ShipmentOfItemsOrderCorrection.Ref IS NOT NULL
			|			THEN ShipmentOfItemsOrderCorrection.Warehouse
			|		ELSE
			|			SalesOfGoodsServicesGoods.Warehouse
			|	END AS Warehouse,
			|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
			|	CustomerInvoice.ToReturnReusablePackage AS ToReturnReusablePackage,
			|	CustomerInvoice.PackageDepositIsRequired AS PackageDepositIsRequired
			|FROM
			|	Document.CustomerInvoice AS CustomerInvoice
			|	LEFT JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
			|		ON (SalesOfGoodsServicesGoods.Ref = CustomerInvoice.Ref)
			|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
			|		ON CustomerInvoice.LineOfBusiness = LinesOfBusiness.Ref
			|			AND LinesOfBusiness.CostAccounting
			|	LEFT JOIN ShippingDocuments AS ShippingDocuments
			|		ON SalesOfGoodsServicesGoods.SalesOrder = ShippingDocuments.SalesOrder
			|			AND SalesOfGoodsServicesGoods.Ref = ShippingDocuments.SaleOfGoodsAndServices
			|			AND SalesOfGoodsServicesGoods.RowCode = ShippingDocuments.RowCode
			|			AND SalesOfGoodsServicesGoods.Products = ShippingDocuments.Products
			|			AND SalesOfGoodsServicesGoods.Characteristic = ShippingDocuments.Characteristic
			|			AND SalesOfGoodsServicesGoods.Purpose = ShippingDocuments.Purpose
			|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsByOrder
			|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsByOrder.Ref
			|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsByOrder.Products
			|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsByOrder.Characteristic
			|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsByOrder.RowCode
			|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsByOrder.Purpose
			|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsByOrder.SalesOrder
			|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsOrder
			|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsOrder.Ref
			|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsOrder.Products
			|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsOrder.Characteristic
			|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsOrder.RowCode
			|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsOrder.Purpose
			|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsOrder.Ref
			|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsOrderCorrection
			|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsOrderCorrection.Ref
			|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsOrderCorrection.Products
			|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsOrderCorrection.Characteristic
			|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsOrderCorrection.RowCode
			|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsOrderCorrection.Purpose
			|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsOrderCorrection.Ref.CorrectedDocument
			|WHERE
			|	CustomerInvoice.Ref  IN(&ArrayOfBases)
			|	AND CustomerInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
			|";
			
			QueryTextsTSItems.Add(QueryText);
			
		EndIf;
		
		QueryText = StrConcat(QueryTextsTSItems, Common.UnionAllText());
		
		QueryText = QueryText + "
		|TOTALS BY
		|	SaleOfGoodsAndServices";
		
		QueryTexts.Add(QueryText);
		
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		Query.Text = "
		|SELECT ALLOWED DISTINCT
		|	GoodsShipmentToCustomer.Ref                                                              AS SaleOfGoodsAndServices,
		|	GoodsShipmentToCustomer.Date                                                                AS Date,
		|	ISNULL(ShipmentOfItemsToCustomerItems.SalesOrder, UNDEFINED)                          AS SalesOrder,
		|	ISNULL(ShipmentOfItemsToCustomerItems.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))     AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose
		|FROM
		|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
		|		LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomerItems
		|		ON (ShipmentOfItemsToCustomerItems.Ref = GoodsShipmentToCustomer.Ref)
		|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|		ON GoodsShipmentToCustomer.LineOfBusiness = LinesOfBusiness.Ref
		|			AND LinesOfBusiness.CostAccounting
		|WHERE
		|	GoodsShipmentToCustomer.Ref IN(&ArrayOfBases)
		|TOTALS BY
		|	SaleOfGoodsAndServices";
		
	ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
		
		Query.Text = 
		"SELECT ALLOWED DISTINCT
       |	VendorInvoice.Ref AS SaleOfGoodsAndServices,
       |	VendorInvoice.Date AS Date,
       |	ISNULL(PurchaseOfGoodsServicesGoods.PurchaseOrder, UNDEFINED) AS SalesOrder,
       |	ISNULL(PurchaseOfGoodsServicesGoods.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse,
       |	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
       |	VendorInvoice.ToReturnReusablePackage AS ToReturnReusablePackage,
       |	VendorInvoice.PackageDepositIsRequired AS PackageDepositIsRequired
       |FROM
       |	Document.VendorInvoice AS VendorInvoice
       |		LEFT JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
       |		ON VendorInvoice.Ref = PurchaseOfGoodsServicesGoods.Ref
       |		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
       |		ON VendorInvoice.LineOfBusiness = LinesOfBusiness.Ref
       |			AND (LinesOfBusiness.CostAccounting)
       |WHERE
       |	VendorInvoice.Ref IN(&ArrayOfBases)
       |TOTALS BY
       |	SaleOfGoodsAndServices";
		
	ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
		  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
		  						Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		Then
		
		Query.Text = "
		|SELECT ALLOWED DISTINCT
		|	GoodsReceiptForStorage.Ref                                                            AS SaleOfGoodsAndServices,
		|	GoodsReceiptForStorage.Date                                                              AS Date,
		|	ISNULL(AcceptanceOfGoodsForStorageGoods.PurchaseOrder, UNDEFINED)                     AS SalesOrder,
		|	ISNULL(AcceptanceOfGoodsForStorageGoods.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))   AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose
		|FROM
		|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
		|		LEFT JOIN Document.GoodsReceiptForStorage.Goods AS AcceptanceOfGoodsForStorageGoods
		|		ON (GoodsReceiptForStorage.Ref = AcceptanceOfGoodsForStorageGoods.Ref)
		|
		|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|		ON GoodsReceiptForStorage.LineOfBusiness = LinesOfBusiness.Ref
		|			AND LinesOfBusiness.CostAccounting
		|WHERE
		|	GoodsReceiptForStorage.Ref IN(&ArrayOfBases)
		|TOTALS BY
		|	SaleOfGoodsAndServices";
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisRefundFromCommissionAgent(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Query.Text = "
		|SELECT ALLOWED DISTINCT
		|	ReceiptOfGoodsFromCustodian.Ref AS SaleOfGoodsAndServices,
		|	ReceiptOfGoodsFromCustodian.Date   AS Date,
		|	ISNULL(ReceiptOfGoodsFromCustodianGoods.ReferenceOrder, UNDEFINED) AS SalesOrder,
		|	ReceiptOfGoodsFromCustodian.Warehouse  AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose
		|FROM
		|	Document.ReceiptOfGoodsFromCustodian AS ReceiptOfGoodsFromCustodian
		|	
		|	INNER JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS ReceiptOfGoodsFromCustodianGoods
		|	ON ReceiptOfGoodsFromCustodian.Ref = ReceiptOfGoodsFromCustodianGoods.Ref
		|	
		|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|	ON ReceiptOfGoodsFromCustodian.LineOfBusiness = LinesOfBusiness.Ref
		|	AND LinesOfBusiness.CostAccounting
		|
		|WHERE
		|	ReceiptOfGoodsFromCustodian.Ref IN(&ArrayOfBases)
		|
		|TOTALS BY
		|	SaleOfGoodsAndServices
		|";
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Query.Text = "
		|SELECT ALLOWED DISTINCT
		|	GoodsHandover.Ref AS SaleOfGoodsAndServices,
		|	GoodsHandover.Date   AS Date,
		|	ISNULL(TransferGoods.SalesOrder, UNDEFINED) AS SalesOrder,
		|	ISNULL(TransferGoods.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose
		|FROM
		|	Document.TransferOfGoodsToBailee AS GoodsHandover
		|		LEFT JOIN Document.TransferOfGoodsToBailee.Goods AS TransferGoods
		|		ON TransferGoods.Ref = GoodsHandover.Ref
		|	
		|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|		ON GoodsHandover.LineOfBusiness = LinesOfBusiness.Ref
		|			AND LinesOfBusiness.CostAccounting
		|
		|WHERE
		|	GoodsHandover.Ref IN(&ArrayOfBases)
		|
		|TOTALS BY
		|	SaleOfGoodsAndServices";
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
		Then
		
		Query.Text = "
		|SELECT DISTINCT ALLOWED
		|	GoodsShipmentFromStorage.Ref                                                            AS SaleOfGoodsAndServices,
		|	GoodsShipmentFromStorage.Date                                                              AS Date,
		|	ISNULL(ShipmentOfGoodsFromStorageGoods.SalesOrder, UNDEFINED)                        AS SalesOrder,
		|	ISNULL(ShipmentOfGoodsFromStorageGoods.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))   AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose
		|FROM
		|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
		|		LEFT JOIN Document.GoodsShipmentFromStorage.Goods AS ShipmentOfGoodsFromStorageGoods
		|		ON (ShipmentOfGoodsFromStorageGoods.Ref = GoodsShipmentFromStorage.Ref)
		|
		|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|		ON GoodsShipmentFromStorage.LineOfBusiness = LinesOfBusiness.Ref
		|			AND LinesOfBusiness.CostAccounting
		|WHERE
		|	GoodsShipmentFromStorage.Ref IN (&ArrayOfBases)
		|
		|TOTALS BY
		|	SaleOfGoodsAndServices";
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Query.Text = "
		|SELECT DISTINCT ALLOWED
		|	ReturnOfGoodsToVendor.Ref AS SaleOfGoodsAndServices,
		|	ReturnOfGoodsToVendor.Date AS Date,
		|	UNDEFINED AS SalesOrder,
		|	ReturnOfGoodsToVendor.Warehouse AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose
		|FROM
		|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
		|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|		ON ReturnOfGoodsToVendor.LineOfBusiness = LinesOfBusiness.Ref
		|			AND LinesOfBusiness.CostAccounting
		|WHERE
		|	ReturnOfGoodsToVendor.Ref IN (&ArrayOfBases)
		|TOTALS BY
		|	SaleOfGoodsAndServices";
		
	Else
		Query.Text = "
		|SELECT DISTINCT ALLOWED
		|	ReturnOfGoodsFromCustomer.Ref                                                             AS SaleOfGoodsAndServices,
		|	ReturnOfGoodsFromCustomer.Date                                                               AS Date,
		|	ReturnOfGoodsFromCustomer.RequestForReturnOfGoodsFromCustomer                                    AS SalesOrder,
		|	ReturnOfGoodsFromCustomer.Warehouse                                                              AS Warehouse,
		|	ISNULL(LinesOfBusiness.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose
		|FROM
		|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
		|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|		ON ReturnOfGoodsFromCustomer.LineOfBusiness = LinesOfBusiness.Ref
		|			AND LinesOfBusiness.CostAccounting
		|WHERE
		|	ReturnOfGoodsFromCustomer.Ref IN (&ArrayOfBases)
		|TOTALS BY
		|	SaleOfGoodsAndServices";
	EndIf;
	
	Query.SetParameter("ArrayOfBases", ArrayOfDocuments);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	SampleImplementation = QueryResult.Select(QueryResultIteration.ByGroups);
	While SampleImplementation.Next() Do
		
		NewRow            = Form.BasisDocuments.Add();
		NewRow.SaleOfGoodsAndServices = SampleImplementation.SaleOfGoodsAndServices;
		
		Form.Items.GoodsDocumentBasis.ChoiceList.Add(SampleImplementation.SaleOfGoodsAndServices);
		SampleOrders = SampleImplementation.Select();
		
		While SampleOrders.Next() Do
			
			If ValueIsFilled(SampleOrders.SalesOrder)
				And NewRow.BasisOrders.FindByValue(SampleOrders.SalesOrder) = Undefined Then
				
				NewRow.BasisOrders.Add(SampleOrders.SalesOrder);
				
			EndIf;
			
			If ValueIsFilled(SampleOrders.Warehouse)
				And NewRow.BasisWarehouses.FindByValue(SampleOrders.Warehouse) = Undefined Then
				
				NewRow.BasisWarehouses.Add(SampleOrders.Warehouse);
				
			EndIf;
			
			If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
				Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
									Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
				
				NewRow.BaseDocumentDate = SampleOrders.Date;
				
			EndIf;
			
			If Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice 
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice Then
				
				NewRow.ToReturnReusablePackage = SampleOrders.ToReturnReusablePackage;
				NewRow.PackageDepositIsRequired = SampleOrders.PackageDepositIsRequired;
				
			EndIf;
			
			NewRow.Purpose = SampleOrders.Purpose;
			
		EndDo;
		
	EndDo;
	
	For Each StringFoundationDocuments In Form.BasisDocuments Do
		
		If StringFoundationDocuments.BasisOrders.Count() > 0 Then
			
			Filter           = New Structure(AttributesNames.Basis, StringFoundationDocuments.SaleOfGoodsAndServices);
			FoundRows = Form.Object.Goods.FindRows(Filter);
			
			For Each FoundRow In FoundRows Do
				FoundRow[AttributesNames.BasisByOrders] = True;
			EndDo
			
		EndIf;
		
	EndDo
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
Procedure VATVisibilityManagement(Form) Export
	
	Object = Form.Object;
	
	VisibilityVATTaxation =
		VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Object.VATTaxation)
		And Not DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Object.TypeOfBaseDocumentForNonConformanceCertificate);
	
	VisibilitySumWithVAT =  Not Object.PriceIncludesVAT;
	
	Form.Items.ProductsGroupSumSNDS.Visible = VisibilitySumWithVAT And VisibilityVATTaxation;
	Form.Items.ProductsVATGroup.Visible       = VisibilityVATTaxation;
	Form.Items.GoodsVATRate.Visible       = VisibilityVATTaxation;

EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
Procedure SetContractAvailability(Form) Export

	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		SalesServer.SetContractAvailability(Form.Object, Form.Items.Contract.Enabled,
			Form.Items.Contract.Visible);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Handler.SetContractAvailability(Form, Form.Object);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Handler.SetContractAvailability(Form, Form.Object);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
							PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider")
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		// For documents of responsible storage, the "Contract" field is always available.

	Else
		PurchasesServer.SetContractAvailability(Form.Object, Form.Items.Contract.Enabled,
			Form.Items.Contract.Visible, Form.Object.Contract);
	EndIf;

EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - DocumentObject - Document
Procedure SetValuesOfCachedReportFormDetails(Form) Export
	
	Object = Form.Object;
	
	Form.ToUseTermsOfSales                  = GetFunctionalOption("ToUseTermsOfSales");
	Form.UseCustomerContracts                    = GetFunctionalOption("UseCustomerContracts");
	Form.UseTermsOfPurchases               = GetFunctionalOption("UseTermsOfPurchases");
	Form.UseContractsWithVendors                 = GetFunctionalOption("UseContractsWithVendors");
	Form.UseShipmentWithDeferredTransferOfTitle =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	Form.EditingRights_3                             = AccessRight("Update", Object.Ref.Metadata());
	If DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(
						Object.TypeOfBaseDocumentForNonConformanceCertificate);
		
		Form.ToUseTermsOfSales =
			Form.ToUseTermsOfSales And Handler.CustomerAgreementsAreApplicable();
		
		Form.UseTermsOfPurchases =
			Form.UseTermsOfPurchases And Handler.AgreementsWithSuppliersAreApplicable();
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(
						Object.TypeOfBaseDocumentForNonConformanceCertificate);
		
		Form.ToUseTermsOfSales =
			Form.ToUseTermsOfSales And Handler.CustomerAgreementsAreApplicable();
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		  Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		
		Form.ToUseTermsOfSales    = False;
		Form.UseTermsOfPurchases = False;
	EndIf;
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 	UpdateOfGroundsListIsRequired - Boolean - 
Procedure FormationOfInscriptionDocumentsBase(Form, UpdateOfGroundsListIsRequired = True) Export

	If Form.Object.Goods.Count() = 0 Then
		
		Form.NumberOfBaseDocuments = 0;
		Form.DocumentsBasisSubmission = NStr("vi = 'Chưa chọn';
											|ru = 'Не выбрано';
											|en = 'Not selected'; fa = 'انتخاب نشده';
											|it = 'Non selezionato';
											|pl = 'Nie wybrano';
											|tr = 'Seçilmedi'");
		Form.BasisDocuments.Clear();
		Form.Items.DocumentsBasisSubmission.Width = 8;
		Form.Items.GoodsDocumentBasis.Visible = False;
		Form.Items.DocumentsBasisSubmission.Hyperlink = False;
		
	Else
		
		If UpdateOfGroundsListIsRequired Then
			
			GenerateTableOfDocumentsOfBases(Form);
			
		EndIf;
		
		Form.NumberOfBaseDocuments = Form.BasisDocuments.Count();
		If Form.NumberOfBaseDocuments = 0 Then
			
			Form.DocumentsBasisSubmission = NStr("vi = 'Chưa chọn';
												|ru = 'Не выбрано';
												|en = 'Not selected'; fa = 'انتخاب نشده';
												|it = 'Non selezionato';
												|pl = 'Nie wybrano';
												|tr = 'Seçilmedi'");
			Form.Items.DocumentsBasisSubmission.Width = 8;
			Form.Items.DocumentsBasisSubmission.Hyperlink = False;
			
		ElsIf Form.NumberOfBaseDocuments = 1 Then
			
			Form.DocumentsBasisSubmission = Form.BasisDocuments[0].SaleOfGoodsAndServices;
			Form.Items.DocumentsBasisSubmission.Width = 42;
			Form.Items.DocumentsBasisSubmission.Hyperlink = True;
			
		Else
			
			TextPresentation = NStr("vi = 'Tổng số';
									|ru = 'Всего';
									|en = 'Total'; fa = 'جمع کل';
									|it = 'In totale';
									|pl = 'Łącznie';
									|tr = 'Toplam'");
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				TextPresentation = TextPresentation + " " + NStr("vi = 'thực hiện';
																|ru = 'реализаций';
																|en = 'sales'; fa = 'sales';
																|it = 'dei realizzi';
																|pl = 'realizacji';
																|tr = 'satış'");

			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(
					Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				TextPresentation = TextPresentation + " " + NStr("vi = 'giao hàng';
																|ru = 'отгрузок товаров';
																|en = 'goods shipments'; fa = 'goods shipments';
																|it = 'goods shipments';
																|pl = 'goods shipments';
																|tr = 'ürün sevkiyatları'");
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
						Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
				Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				TextPresentation = TextPresentation + " " + NStr("vi = 'chuyển giao';
																|ru = 'передач';
																|en = 'transfers'; fa = 'transfers';
																|it = 'trasferito';
																|pl = 'transferów';
																|tr = 'Aktarım'");
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
									Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
				
				TextPresentation = TextPresentation + " " + NStr("vi = 'trả lại';
																|ru = 'возвратов';
																|en = 'returns'; fa = 'returns';
																|it = 'dei resi';
																|pl = 'zwrotów';
																|tr = 'iade'");
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				TextPresentation = TextPresentation + " " + NStr("vi = 'xuất kho';
																|ru = 'отгрузок';
																|en = 'shipments'; fa = 'shipments';
																|it = 'degli scarichi';
																|pl = 'wysyłek';
																|tr = 'sevkiyat'");
				
			ElsIf Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
									Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
				Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
				
				TextPresentation = TextPresentation + " " + NStr("vi = 'phát sinh';
																|ru = 'поступлений';
																|en = 'receipts'; fa = 'receipts';
																|it = 'delle entrate';
																|pl = 'wpłat';
																|tr = 'Giriş'");
				
			EndIf;
			
			Form.DocumentsBasisSubmission = TextPresentation + ": " + String(Form.NumberOfBaseDocuments);
			Form.Items.DocumentsBasisSubmission.Width = StrLen(Form.DocumentsBasisSubmission);
			Form.Items.DocumentsBasisSubmission.Hyperlink = True;
			
		EndIf;
		
		Form.Items.GoodsDocumentBasis.Visible = Form.BasisDocuments.Count() > 1;
		
	EndIf;

EndProcedure

Procedure PageManagementSelectAction(Form, Parameters) Export

	If Not Parameters.GroupUpdate Then
		Form.Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	Else
		FormAttributes = Form.GetAttributes();
		For Each FormAttribute In FormAttributes Do
			
			AttributeName = FormAttribute.Name;
			ThisIsAttributeOfAction =
				AttributeName = "ActionSurplus"
				Or AttributeName = "ShortfallAction"
				Or AttributeName = "ActionWithShortageDocument"
				Or AttributeName = "ActionWithSurplusDocument"
				Or AttributeName = "ActionWithShortageGoods"
				Or AttributeName = "ActionWithSurplusGoods";
			
			If ThisIsAttributeOfAction Then
				FormAttribute.StoredData = False;
			EndIf;
			
		EndDo;
		
		Form.Items.Shortages.Visible = Parameters.ThereIsShortages;
		Form.Items.Surpluses.Visible   = Parameters.ThereAreSurpluses;
		
		If Not Parameters.ThereIsShortages Or Not Parameters.ThereAreSurpluses Then
			Form.Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		EndIf;
		
		If Form.FormName = "DataProcessor.ProcessingOfDiscrepancyReports.Form.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue" Then
			Form.ActionWithSurplusDocument = Parameters.ActionWithSurplusDocument;
			Form.ActionWithShortageDocument = Parameters.ActionWithShortageDocument;
			Form.ActionWithSurplusGoods = Parameters.ActionWithSurplusGoods;
			Form.ActionWithShortageGoods = Parameters.ActionWithShortageGoods;
		Else
			Form.ActionSurplus   = Parameters.ActionSurplus;
			Form.ShortfallAction = Parameters.ShortfallAction;
		EndIf;
		
	EndIf;

EndProcedure

Function KeyFieldsDependingOnAction(Action, KeyFields) Export
	
	KeyFieldsWithSeries = KeyFields;
	KeyFieldsWithoutSeries = StrReplace(KeyFields, ", Series", "");
	
	KeyFieldsForSearchingExistingRows = "";
	KeyFieldsForSearchingForNewRows = "";
	KeyFieldsForAssigningNewRows = "";
	
	If Action = "A0" Or Action = "A3" Then
		KeyFieldsForSearchingExistingRows = KeyFieldsWithoutSeries;
		KeyFieldsForSearchingForNewRows = KeyFieldsWithoutSeries;
		KeyFieldsForAssigningNewRows = KeyFieldsWithoutSeries;
	ElsIf Action = "A1" Then
		KeyFieldsForSearchingExistingRows = KeyFieldsWithSeries;
		KeyFieldsForSearchingForNewRows = KeyFieldsWithoutSeries;
		KeyFieldsForAssigningNewRows = KeyFieldsWithoutSeries;
	ElsIf Action = "A2" Then
		KeyFieldsForSearchingExistingRows = KeyFieldsWithSeries;
		KeyFieldsForSearchingForNewRows = KeyFieldsWithSeries;
		KeyFieldsForAssigningNewRows = KeyFieldsWithSeries;
	ElsIf Action = "A4" Then
		KeyFieldsForSearchingExistingRows = KeyFieldsWithSeries;
		KeyFieldsForSearchingForNewRows = KeyFieldsWithoutSeries;
		KeyFieldsForAssigningNewRows = KeyFieldsWithSeries;
	EndIf;
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("KeyFieldsForSearchingExistingRows", KeyFieldsForSearchingExistingRows);
	ReturnStructure.Insert("KeyFieldsForSearchingForNewRows", KeyFieldsForSearchingForNewRows);
	ReturnStructure.Insert("KeyFieldsForAssigningNewRows", KeyFieldsForAssigningNewRows);
	
	Return ReturnStructure;
	
EndFunction

Procedure AssignNewRowsToExistingOnes(TableOfExistingRows, TableOfNewRows, KeyFields) Export
	
	Filter = New Structure(KeyFields);
	For Each String In TableOfNewRows Do
		If String.Count > 0 Then
			FillPropertyValues(Filter, String);
			// Search for existing rows whose analytics completely match
			FoundRows = TableOfExistingRows.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				FoundRow = FoundRows[0];
				FoundRow.Count = FoundRow.Count + String.Count;
				String.Count = 0;
			EndIf;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region ChangingGroundsOfActOfDiscrepancies

Procedure ChangeBasisOfAct(DiscrepancyCertificate, Basis, TableOfMutableRows, TableOfVariableSeries)
	
	Try
		
		LockDataForEdit(Basis);
		
	Except
		
		ErrorText = NStr("vi = 'Không thể khóa %Item% để thay đổi.  %ErrorDescription%';
						|ru = 'Не удалось заблокировать для изменения %Item%. %ErrorDescription%';
						|en = 'Cannot lock for changing %Item%. %ErrorDescription%'; fa = 'Cannot lock for changing %Item%. %ErrorDescription%';
						|it = 'Non è stato possibile bloccare per la modifica %Item%. %ErrorDescription%';
						|pl = 'Nie udało się zablokować dla zmiany %Item%. %ErrorDescription%';
						|tr = '%Item% değişimi engellenemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorText, "%Item%",        Basis);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		
		Raise ErrorText;
		
	EndTry;
	
	DocumentBasis = Basis.GetObject(); // DocumentObject
	
	// Table part " Products"
	ChangeableTSProducts = DocumentBasis.Goods;
	StructureOfActions = StructureOfActionOnTSGroundsAct(DocumentBasis);
	ThereIsSumOfMutualSettlements = Not DocumentBasis.Metadata().TabularSections.Goods.Attributes.Find("AmountARAP") = Undefined;
	
	ThereIsQuantityOfRNPT    = Not DocumentBasis.Metadata().TabularSections.Goods.Attributes.Find("QuantityByGBRN") = Undefined;
	
	If ThereIsQuantityOfRNPT Then
		
		Products = TableOfMutableRows.UnloadColumn("Products");
		Products = CommonClientServer.CollapseArray(Products);
		
		ProductAttributes =
			Common.ObjectsAttributesValues(Products, "UnitOfMeasure, FEACNCode");
		
		HSCodes = New Array;
		For Each KeyValue In ProductAttributes Do
			HSCodes.Add(KeyValue.Value.FEACNCode);
		EndDo;
		HSCodes = CommonClientServer.CollapseArray(HSCodes);
		
		DetailsOfHSCodes =
			Common.ObjectsAttributesValues(HSCodes, "UnitOfMeasure, TracedGoods");
		
	EndIf;
	
	RowsToProcess = New Array;
	AddedRows = New Array;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BusinessTransactionOfCertificate = Common.ObjectAttributeValue(DiscrepancyCertificate, "BusinessOperation");
	
	For Each LineToChangeByAct In TableOfMutableRows Do
		
		SearchParameters = SearchParametersForBaseDocument(Basis, LineToChangeByAct);
		
		FoundRows = ChangeableTSProducts.FindRows(SearchParameters);
		
		If FoundRows.Count() = 0
			And TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
			And Common.ObjectAttributeValue(Basis, "ReturnOfSpoiledGoods") Then
			
			SearchParameters.Delete("Products");
			SearchParameters.Delete("Characteristic");
			
			SearchParameters.Insert("ProductsRecordingAsReceived", LineToChangeByAct.Products);
			SearchParameters.Insert("CharacteristicRecordingAsReceived", LineToChangeByAct.Characteristic);
			
			FoundRows = ChangeableTSProducts.FindRows(SearchParameters);
			
		EndIf;
		
		If FoundRows <> Undefined Then
			
			If FoundRows.Count() = 1 Then
				
				VariableString = FoundRows[0];
				
				NumberOfPackagesBeforeChange_ = VariableString.NumberOfPackages;
				VariableString.NumberOfPackages = LineToChangeByAct.NumberOfPackagesAccordingToAct;
					
				If VariableString.NumberOfPackages = 0 Then
					ChangeableTSProducts.Delete(VariableString);
				Else
					
					If ThereIsSumOfMutualSettlements And VariableString.AmountARAP > 0 Then
						VariableString.AmountARAP = VariableString.AmountARAP / NumberOfPackagesBeforeChange_ * VariableString.NumberOfPackages;
					EndIf;
					
					If ThereIsQuantityOfRNPT And VariableString.QuantityByGBRN > 0 Then
						VariableString.QuantityByGBRN = VariableString.QuantityByGBRN / NumberOfPackagesBeforeChange_ * VariableString.NumberOfPackages;
					EndIf;
					
					RowsToProcess.Add(VariableString);
					
				EndIf;
				
			ElsIf FoundRows.Count() = 0 Then
				
				VariableString = ChangeableTSProducts.Add(); // LineOfATabularSection
				FillPropertyValues(VariableString, LineToChangeByAct);
				
				If BusinessTransactionOfCertificate = Enums.BusinessTransactions.TransferOfTitleToGoods Then
					VariableString.Warehouse = Undefined;
				EndIf;
				VariableString.NumberOfPackages = LineToChangeByAct.NumberOfPackagesAccordingToAct;
				
				// additional search to fill in the lines over the order
				If SearchParameters.Property("SalesOrder")
					And SearchParameters.Property("RowCode")
					And ValueIsFilled(SearchParameters.SalesOrder) Then
					
					TableOfSourceGoods = Common.ObjectAttributesValues(DocumentBasis.Ref, "Goods").Goods.Unload();

					SearchParameters.Delete("SalesOrder");
					SearchParameters.Delete("RowCode");
					
					FoundRowsWithoutTakingIntoAccountOrder = TableOfSourceGoods.FindRows(SearchParameters);
					If FoundRowsWithoutTakingIntoAccountOrder.Count() > 0 Then
						FillPropertyValues(VariableString, FoundRowsWithoutTakingIntoAccountOrder.Get(0), "PriceKind");
					EndIf;
					
				EndIf;

				RowsToProcess.Add(VariableString);
				AddedRows.Add(VariableString);
				
			ElsIf FoundRows.Count() > 1 Then
				
				QuantityToChange = LineToChangeByAct.NumberOfPackagesAccordingToAct - LineToChangeByAct.NumberOfPackagesOnBasisOfAct;
				If QuantityToChange < 0 Then
					
					QuantityToChange = - QuantityToChange;
					For Each VariableString In FoundRows Do
						If QuantityToChange <= 0 Then
							Break;
						EndIf;
						
						If QuantityToChange >= VariableString.NumberOfPackages Then
							QuantityToChange = QuantityToChange -VariableString.NumberOfPackages; 
							ChangeableTSProducts.Delete(VariableString);
						Else
							
							NumberOfPackagesBeforeChange_ = VariableString.NumberOfPackages;
							VariableString.NumberOfPackages = VariableString.NumberOfPackages
								- QuantityToChange;
							
							If ThereIsSumOfMutualSettlements And VariableString.AmountARAP > 0 Then
								VariableString.AmountARAP = VariableString.AmountARAP / NumberOfPackagesBeforeChange_ * VariableString.NumberOfPackages;
							EndIf;
							
							If ThereIsQuantityOfRNPT And VariableString.QuantityByGBRN > 0 Then
								VariableString.QuantityByGBRN = VariableString.QuantityByGBRN / NumberOfPackagesBeforeChange_ * VariableString.NumberOfPackages;
							EndIf;
							
							RowsToProcess.Add(VariableString);
							
							QuantityToChange = 0;
							
						EndIf;
						
					EndDo;
					
				ElsIf QuantityToChange > 0 Then
					
					VariableString = FoundRows[0];
					VariableString.NumberOfPackages = VariableString.NumberOfPackages + QuantityToChange;
					RowsToProcess.Add(VariableString);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ChangeableTSProducts,
		CachedValues);
		
	If ThereIsQuantityOfRNPT Then
			
		For Each VariableString In AddedRows Do
		
			CurrentProducts = ProductAttributes[VariableString.Products];
			CurHSCode = DetailsOfHSCodes[CurrentProducts.FEACNCode];
			
			If ValueIsFilled(CurHSCode)
				And Not CurHSCode.TracedGoods = Undefined
				And CurHSCode.TracedGoods Then
				If Not CurHSCode.UnitOfMeasure = Undefined
					And CurHSCode.UnitOfMeasure =
						CurrentProducts.UnitOfMeasure Then
					VariableString.QuantityByGBRN = VariableString.Count;
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
	
	// Tabular part of the "Series"
	VariableTSSeries = DocumentBasis.SetOfSeries;

	For Each LineToChangeByAct In TableOfVariableSeries Do
		
		SearchParameters = SearchParametersForTSDocumentSeries(Basis, LineToChangeByAct);
		
		FoundRows = VariableTSSeries.FindRows(SearchParameters);
		
		If FoundRows <> Undefined Then
			
			If FoundRows.Count() = 1 Then
				
				VariableString = FoundRows[0];
				VariableString.Count = LineToChangeByAct.QuantityByAct;
				
				If VariableString.Count = 0 Then
					VariableTSSeries.Delete(VariableString);
				EndIf;
				
			ElsIf FoundRows.Count() = 0 Then
				
				VariableString = VariableTSSeries.Add();
				FillPropertyValues(VariableString, LineToChangeByAct);
				VariableString.Count = LineToChangeByAct.QuantityByAct;
				
			ElsIf FoundRows.Count() > 1 Then
				
				QuantityToChange = LineToChangeByAct.QuantityByAct - LineToChangeByAct.QuantityBasedOnAct;
				If QuantityToChange < 0 Then
					
					QuantityToChange = - QuantityToChange;
					For Each VariableString In FoundRows Do
						If QuantityToChange <= 0 Then
							Break;
						EndIf;
						
						If QuantityToChange >= VariableString.Count Then
							QuantityToChange = QuantityToChange - VariableString.Count; 
							VariableTSSeries.Delete(VariableString);
						Else
							VariableString.Count = VariableString.Count - QuantityToChange;
							QuantityToChange = 0;
						EndIf;
						
					EndDo;
					
				ElsIf QuantityToChange > 0 Then
					
					VariableString = FoundRows[0];
					VariableString.Count = VariableString.Count + QuantityToChange;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ProcessHeaderOfDocumentBasisOfActWhenChanging(DocumentBasis);
	
	SeriesSpecificationParameters = Common.ObjectManagerByRef(DocumentBasis.Ref).SeriesSpecificationParameters(DocumentBasis);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentBasis, SeriesSpecificationParameters);
	
	If DocumentBasis.Goods.Count() = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sau khi thay đổi, sẽ không có sản phẩm nào trong chứng từ %1. chứng từ sẽ không được tạo lại.';
				|ru = 'После изменения в документе %1 будут отсутствовать товары. Документ переоформлен не будет.';
				|en = 'After changing the document %1, there will be no goods available. The document will not be reregistered.'; fa = 'After changing the document %1, there will be no goods available. The document will not be reregistered.';
				|it = 'Dopo la modifica nel documento %1 mancheranno le merci. Il documento non verrà emesso nuovamente.';
				|pl = 'Po zmianie w dokumencie %1 nie będzie towarów. dokument nie zostanie zatwierdzony ponownie.';
				|tr = 'Değişiklikten sonra %1 belgesinde herhangi bir mal olmayacaktır. Belge yeniden düzenlenmeyecektir.'"), 
			DocumentBasis.Ref);
		Common.MessageToUser(ErrorText);
		Return;
	EndIf;
	
	Try
		DocumentBasis.CheckFilling();
		DocumentBasis.AdditionalProperties.Insert("ChangeBasedOnActOfDiscrepancies", True);
		DocumentBasis.Write(DocumentWriteMode.Posting);
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(ErrorText);
	EndTry;

EndProcedure

Procedure ProcessHeaderOfDocumentBasisOfActWhenChanging(Basis)

	If TypeOf(Basis) = Type("DocumentObject.CustomerInvoice") Then
		
		SalesInExcessOfOrder = False;
		If Basis.OrderSales Then
			For Each TSRow In Basis.Goods Do
				If TSRow.RowCode = 0 Then
					SalesInExcessOfOrder = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If Basis.OrderSales Then
			CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
			CalculationParameters.FillInImplementationByOrder = True;
			DiscountsMarkupsFillingServer.Calculate(Basis, CalculationParameters);
		EndIf;
		If SalesInExcessOfOrder Or Not Basis.OrderSales Then
			
			ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
			ParametersStructure1.ApplyToObject				 = True;
			ParametersStructure1.OnlyPreliminaryCalculation		 = False;
			ParametersStructure1.RestoreManagedDiscounts	 = True;
			ParametersStructure1.SalesInExcessOfOrder		 = SalesInExcessOfOrder And Basis.OrderSales;
			
			DiscountsMarkupsFillingServer.Calculate(Basis, ParametersStructure1);
			
		EndIf;
		
	ElsIf TypeOf(Basis) = Type("DocumentObject.ReturnOfGoodsToVendor")
		Or TypeOf(Basis) = Type("DocumentObject.GoodsShipmentFromStorage")
		Or TypeOf(Basis) = Type("DocumentObject.TransferOfGoodsToBailee")
		Or TypeOf(Basis) = Type("DocumentObject.ReceiptOfGoodsFromCustodian")
		Or TypeOf(Basis) = Type("DocumentObject.ReturnOfGoodsFromCustomer") Then
		
		SumByDocument = Basis.GetDocumentAmount();
		
		RecalculatePaymentDecryptionAmounts = False;
		RecalculatePaymentDecryptionAmounts = TypeOf(Basis) = Type("DocumentObject.GoodsShipmentFromStorage")
							Or TypeOf(Basis) = Type("DocumentObject.TransferOfGoodsToBailee")
							Or TypeOf(Basis) = Type("DocumentObject.ReceiptOfGoodsFromCustodian");
		
		If Not RecalculatePaymentDecryptionAmounts Then
			FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Basis, SumByDocument);
		EndIf;
		
	EndIf;

EndProcedure

Function SearchParametersForBaseDocument(Basis, LineToChangeByAct)
	
	SearchParameters = New Structure;
	
	BusinessOperation = Common.ObjectAttributeValue(Basis, "BusinessOperation");
	If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice")
		And BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then

		SearchParameters.Insert("Products",        LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",      LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",            LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",          LineToChangeByAct.Purpose);
		SearchParameters.Insert("SalesOrder",        LineToChangeByAct.SalesOrder);
		SearchParameters.Insert("RowCode",           LineToChangeByAct.RowCode);

	ElsIf TypeOf(Basis) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer")
		Or TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee") Then
		
		SearchParameters.Insert("Products",        LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",      LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",            LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",          LineToChangeByAct.Purpose);
		SearchParameters.Insert("SalesOrder",        LineToChangeByAct.SalesOrder);
		SearchParameters.Insert("RowCode",           LineToChangeByAct.RowCode);
		SearchParameters.Insert("Warehouse",               LineToChangeByAct.Warehouse);
		If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice") Then
			SearchParameters.Insert("Series",           LineToChangeByAct.Series);
		ElsIf (TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee")
				Or TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer"))
			And LineToChangeByAct.BatchesIndicationStatus <> 0 Then
			
			SearchParameters.Insert("Series",           LineToChangeByAct.Series);
			
		EndIf;
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage")
		Then
		
		SearchParameters.Insert("Products",           LineToChangeByAct.Products);
		SearchParameters.Insert("PartnerProducts", LineToChangeByAct.PartnerProducts);
		SearchParameters.Insert("Characteristic",         LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",               LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",             LineToChangeByAct.Purpose);
		SearchParameters.Insert("PurchaseOrder",        LineToChangeByAct.PurchaseOrder);
		SearchParameters.Insert("RowCode",              LineToChangeByAct.RowCode);
		SearchParameters.Insert("Series",                  LineToChangeByAct.Series);
		SearchParameters.Insert("CCDNumber",               LineToChangeByAct.CCDNumber);
		SearchParameters.Insert("Warehouse",                  LineToChangeByAct.Warehouse);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		
		SearchParameters.Insert("Products",           LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",         LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",               LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",             LineToChangeByAct.Purpose);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		
		SearchParameters.Insert("Products",        LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",      LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",            LineToChangeByAct.Package);
		SearchParameters.Insert("DocumentInflow", LineToChangeByAct.DocumentInflow);
		SearchParameters.Insert("Purpose",          LineToChangeByAct.Purpose);
		SearchParameters.Insert("Series",               LineToChangeByAct.Series);
		SearchParameters.Insert("Price",                LineToChangeByAct.Price);
		SearchParameters.Insert("Warehouse",               LineToChangeByAct.Warehouse);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentFromStorage") Then
		
		SearchParameters.Insert("Products",        LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",      LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",            LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",          LineToChangeByAct.Purpose);
		SearchParameters.Insert("SalesOrder",        LineToChangeByAct.SalesOrder);
		SearchParameters.Insert("RowCode",           LineToChangeByAct.RowCode);
		SearchParameters.Insert("Series",               LineToChangeByAct.Series);
		SearchParameters.Insert("DocumentInflow", LineToChangeByAct.DocumentInflow);
		SearchParameters.Insert("Warehouse",               LineToChangeByAct.Warehouse);
		SearchParameters.Insert("Price",                LineToChangeByAct.Price);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		
		SearchParameters.Insert("Products",        LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",      LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",            LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",          LineToChangeByAct.Purpose);
		SearchParameters.Insert("ReferenceOrder",        LineToChangeByAct.PurchaseOrder);
		SearchParameters.Insert("RowCode",           LineToChangeByAct.RowCode);
		SearchParameters.Insert("Series",               LineToChangeByAct.Series);
		SearchParameters.Insert("Price",                LineToChangeByAct.Price);
		SearchParameters.Insert("CCDNumber",            LineToChangeByAct.CCDNumber);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.InventoryTransfer") Then
		
		SearchParameters.Insert("Products",         LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",       LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",             LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",           LineToChangeByAct.Purpose);
		SearchParameters.Insert("AssignmentSender",LineToChangeByAct.AssignmentSender);
		SearchParameters.Insert("TransferOrder",   LineToChangeByAct.TransferOrder);
		SearchParameters.Insert("RowCode",            LineToChangeByAct.RowCode);
		SearchParameters.Insert("Series",                LineToChangeByAct.Series);
		SearchParameters.Insert("BatchesIndicationStatus",  LineToChangeByAct.BatchesIndicationStatus);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		SearchParameters.Insert("Products",         LineToChangeByAct.Products);
		SearchParameters.Insert("Characteristic",       LineToChangeByAct.Characteristic);
		SearchParameters.Insert("Package",             LineToChangeByAct.Package);
		SearchParameters.Insert("Purpose",           LineToChangeByAct.Purpose);
		SearchParameters.Insert("Series",                LineToChangeByAct.Series);
		SearchParameters.Insert("RowCode",            LineToChangeByAct.RowCode);
		SearchParameters.Insert("DocumentSalesOfGoodsAndServices",   LineToChangeByAct.DocumentSalesOfGoodsAndServices);
		SearchParameters.Insert("Price",                 LineToChangeByAct.Price);
		SearchParameters.Insert("CCDNumber",             LineToChangeByAct.CCDNumber);
		SearchParameters.Insert("Warehouse",                LineToChangeByAct.Warehouse);
		
	EndIf;
	
	Return SearchParameters;
	
EndFunction

Function SearchParametersForTSDocumentSeries(Basis, LineToChangeByAct)
	
	SearchParameters = New Structure;
	
	SearchParameters.Insert("Products",   LineToChangeByAct.Products);
	SearchParameters.Insert("Characteristic", LineToChangeByAct.Characteristic);
	SearchParameters.Insert("Series",          LineToChangeByAct.Series);
	
	If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer")
		Or TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage")
		Or TypeOf(Basis) = Type("DocumentRef.GoodsShipmentFromStorage")
		Or TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee")
		Or TypeOf(Basis) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
		Or TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		
		SearchParameters.Insert("Warehouse",      LineToChangeByAct.Warehouse);
		SearchParameters.Insert("Purpose", LineToChangeByAct.Purpose);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.InventoryTransfer") Then
		
		SearchParameters.Insert("AssignmentSender", LineToChangeByAct.AssignmentSender);
		SearchParameters.Insert("Purpose",            LineToChangeByAct.Purpose);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		
		SearchParameters.Insert("Purpose", LineToChangeByAct.Purpose);
		
	EndIf;
	
	Return SearchParameters;
	
EndFunction

Function StructureOfActionOnTSGroundsAct(DocumentBasis) Export

	Basis = DocumentBasis.Ref;
	StructureOfActions = New Structure;
	
	If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice") Then
		
		ComplementTSActionFrameworkForImplementation(StructureOfActions, DocumentBasis);

	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		ToSupplementStructureOfActionsForTSItemsShipmentOfItemsToCustomer(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.VendorInvoice") Then
		
		ComplementTSActionFrameworkForNewArrivals(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		
		ComplementTSActionStructureUponArrivalAtWarehouse(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
		
		ToSupplementStructureOfActionsOnTSAndAcceptanceOfGoodsForStorage(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee") Then
		
		ToSupplementStructureOfActionsOnTSGoodsTransferOfGoodsToCustodian(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		
		SupplementTSActionStructureForReturnToSupplier(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		SupplementActionStructureForTSGoodsRefundFromCustomer(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.InventoryTransfer") Then
		
		ComplementTSActionFramework(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentFromStorage") Then
		
		ToSupplementStructureOfActionsForTSGoodsShipmentToCustodian(StructureOfActions, DocumentBasis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		
		SupplementTSActionStructureGoodsComingFromCustodian(StructureOfActions, DocumentBasis);
		
	EndIf;
	
	Return StructureOfActions;

EndFunction 

Procedure ComplementTSActionFrameworkForImplementation(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	
EndProcedure

Procedure ToSupplementStructureOfActionsForTSItemsShipmentOfItemsToCustomer(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

Procedure SupplementTSActionStructureForReturnToSupplier(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

Procedure ToSupplementStructureOfActionsForTSGoodsShipmentToCustodian(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure 

Procedure SupplementActionStructureForTSGoodsRefundFromCustomer(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
EndProcedure

Procedure ComplementTSActionFramework(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
EndProcedure

Procedure ComplementTSActionStructureUponArrivalAtWarehouse(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
EndProcedure

Procedure ComplementTSActionFrameworkForNewArrivals(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
EndProcedure

Procedure ToSupplementStructureOfActionsOnTSAndAcceptanceOfGoodsForStorage(StructureOfActions, Object)
	
	ParametersForRecalculatingNumberOfUnits = Undefined;
	BusinessOperation = Common.ObjectAttributeValue(Object.Ref, "BusinessOperation");
	
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		ParametersForRecalculatingNumberOfUnits = ProductionClientServer.ParametersForRecalculatingNumberOfUnits();
	EndIf;
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

Procedure ToSupplementStructureOfActionsOnTSGoodsTransferOfGoodsToCustodian(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

Procedure SupplementTSActionStructureGoodsComingFromCustodian(StructureOfActions, Object)
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

#EndRegion

#Region VerificationOfComplianceWithActOnDiscrepanciesAndGrounds

// Parameters:
// 	RequestResultByHeader - Array of QueryResult - 
// 	DiscrepancyCertificate - DocumentRef.DiscrepancyReportFollowingShipment - 
// 	Basis - DocumentRef.CustomerInvoice, DocumentRef.ReturnOfGoodsToVendor - 
// Returns:
// 	Boolean - 
Function  ActCapAndBaseMatch(RequestResultByHeader, DiscrepancyCertificate, Basis) 
	
	ActSelection       = RequestResultByHeader[0].Select();
	If Not ActSelection.Next() Then
		Return False;
	EndIf;
	
	SampleBase = RequestResultByHeader[1].Select();
	If Not SampleBase.Next() Then
		Return False;
	EndIf;
	
	If Not ActSelection.Posted Or Not SampleBase.Posted Then
		Return False;
	EndIf;
	
	If ActSelection.Status = Enums.StatusesOfDiscrepancyReport.NotApproved
		Or ActSelection.Status = Enums.StatusesOfDiscrepancyReport.Approved Then
		Return False;
	EndIf;
	
	If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment")
		Or TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		
		If TypeOf(Basis) <> Type("DocumentRef.ReceiptOfGoodsToWarehouse")
			And ActSelection.DiscrepanciesPostingMethod <> Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments
			And ActSelection.DiscrepanciesPostingMethod <> Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments Then
			Return False;
		EndIf;
		
		If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice") Then
			
			If Not DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(ActSelection.TypeOfBaseDocumentForNonConformanceCertificate) Then
				Return False;
			EndIf;
		
		ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer") Then
			
			If Not DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(
				ActSelection.TypeOfBaseDocumentForNonConformanceCertificate) Then
				Return False;
			EndIf;
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
			
			If ActSelection.TypeOfBaseDocumentForNonConformanceCertificate <> Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor Then
				Return False;
			EndIf;
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentFromStorage") Then
			
			If Not DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(ActSelection.TypeOfBaseDocumentForNonConformanceCertificate)
			   And ActSelection.TypeOfBaseDocumentForNonConformanceCertificate <> Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
			   And ActSelection.TypeOfBaseDocumentForNonConformanceCertificate <> Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
			Then
				Return False;
			EndIf;
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee") Then
			
			If Common.ObjectAttributeValue(Basis, "BusinessOperation") = Enums.BusinessTransactions.TransferToCommissionAgent Then
				If Not DiscrepanciesClientServer.TypeOfBasisTransferToCommission(ActSelection.TypeOfBaseDocumentForNonConformanceCertificate) Then
					Return False;
				EndIf;
			Else
				If Not DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(ActSelection.TypeOfBaseDocumentForNonConformanceCertificate) Then
					Return False;
				EndIf;
			EndIf;
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
			
			If Common.ObjectAttributeValue(Basis, "BusinessOperation") = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
				If Not DiscrepanciesClientServer.TypeOfBasisRefundFromCommissionAgent(ActSelection.TypeOfBaseDocumentForNonConformanceCertificate) Then
					Return False;
				EndIf;
			Else
				If Not DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(ActSelection.TypeOfBaseDocumentForNonConformanceCertificate) Then
					Return False;
				EndIf;
			EndIf;
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
			
			TypesOfGroundsForAcceptanceCertificate = New Array;
			TypesOfGroundsForAcceptanceCertificate.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage);
			TypesOfGroundsForAcceptanceCertificate.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider);
			If TypesOfGroundsForAcceptanceCertificate.Find(ActSelection.TypeOfBaseDocumentForNonConformanceCertificate) = Undefined Then
				Return False;
			EndIf;
			
		ElsIf TypeOf(Basis) =  Type("DocumentRef.VendorInvoice") Then
			
			If ActSelection.TypeOfBaseDocumentForNonConformanceCertificate <>  Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
				Return False;
			EndIf;
			
		ElsIf TypeOf(Basis) =  Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
			
			// No additional checks are required.
			
		ElsIf TypeOf(Basis) =  Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
			
			If ActSelection.TypeOfBaseDocumentForNonConformanceCertificate <>  Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
				Return False;
			EndIf;
			
		Else
		
			Return False;
		
		EndIf;
		
		PairsOfSeparatePurchases = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
		EconomicOperationsAreEqual = (ActSelection.BusinessOperation = SampleBase.BusinessOperation)
			Or (PairsOfSeparatePurchases[ActSelection.BusinessOperation] = SampleBase.BusinessOperation);
		
		If ActSelection.Organization              <> SampleBase.Organization
			Or ActSelection.Partner                <> SampleBase.Partner 
			Or ActSelection.Counterparty             <> SampleBase.Counterparty
			Or ((ValueIsFilled(ActSelection.Terms) Or ValueIsFilled(SampleBase.Terms)) And ActSelection.Terms <> SampleBase.Terms)
			Or ActSelection.Contract                <> SampleBase.Contract
			Or Not EconomicOperationsAreEqual
			Or (ActSelection.PriceIncludesVAT       <> SampleBase.PriceIncludesVAT
				And SampleBase.PriceIncludesVAT <> Undefined)
			Or ActSelection.VATTaxation    <> SampleBase.VATTaxation Then
			
			Return False;
			
		EndIf;
		
		Return True;
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		
		 If ActSelection.Organization             <> SampleBase.Organization
			Or ActSelection.CompanyRecipient <> SampleBase.CompanyRecipient 
			Or ActSelection.SourceWarehouse      <> SampleBase.SourceWarehouse
			Or ActSelection.DestinationWarehouse       <> SampleBase.DestinationWarehouse
			Or ActSelection.BusinessOperation <> SampleBase.BusinessOperation Then
			
			Return False;
			
		EndIf;
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure CheckTabularPartsOfActAndGrounds(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)
	
	Query = New Query;
	
	If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		
		If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice") Then
			
			Query.Text = RequestTextTabularPartsOfReportOnDiscrepanciesAfterShipmentAndSale(DiscrepancyCertificate, Basis, ReturnStructure);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer") Then
			
			Query.Text = QueryTextTabularPartsOfDiscrepancyReportAfterShipmentAndShipmentOfItems(
				DiscrepancyCertificate, Basis, ReturnStructure);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
			
			Query.Text = RequestTextTabularPartsOfDiscrepancyReportAfterShipmentAndReturnToSupplier(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentFromStorage") Then
			
			Query.Text = RequestTextTabularPartsOfReportOnDiscrepanciesAfterShipmentAndShipmentFromStorage(DiscrepancyCertificate,
				Basis, ReturnStructure, DocumentModification);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee") Then
			
			Query.Text = RequestTextTabularPartsOfDiscrepancyReportAfterShipmentAndTransferToCustodian(DiscrepancyCertificate,
				Basis, ReturnStructure, DocumentModification);
			
		EndIf;
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		
		If TypeOf(Basis) = Type("DocumentRef.VendorInvoice") Then
			
			Query.Text = RequestTextTabularPartsOfReportOnDiscrepanciesAfterAcceptance(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
			
			Query.Text = RequestTextTabularPartsOfDiscrepancyReportAfterReceipt(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
			
			Query.Text = RequestTextTabularPartsOfReportOnDiscrepanciesAfterAcceptanceAndAcceptanceOfGoodsForStorage(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
			
			Query.Text = RequestTextTabularPartsOfDiscrepancyReportAfterAcceptanceAndReceiptOfGoodsFromCustodian(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification);
			
		ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
			
			Query.Text = RequestTextTabularPartsOfDiscrepancyReportAfterAcceptanceAndReturnFromClient(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification);
			
		EndIf;
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		
		Query.Text = RequestTextTabularPartsOfReportOnDiscrepanciesAfterShipmentAndMovement(DiscrepancyCertificate, Basis, ReturnStructure);
		
	EndIf;
	
	If IsBlankString(Query.Text) Then
		Return;
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"StateGoods.Package",
		"StateGoods.Products"));
	Query.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	Query.SetParameter("Basis", Basis);

	QueryResult = Query.ExecuteBatch();
	
	ActionSelection = QueryResult[6].Select();
	DocumentState = "NoModificationsAreRequired";
	
	While ActionSelection.Next() Do 
		If ActionSelection.LineState = "BaseDocumentDoesNotMatchTheCertificate" Then
			DocumentState = ActionSelection.LineState;
			Break;
		EndIf;
		If ActionSelection.LineState = "ChangesRequired" 
			And DocumentState <> "ChangesRequired" Then
			DocumentState = ActionSelection.LineState;
		EndIf;
		If ActionSelection.LineState = "ChangesAreMade" 
			And DocumentState = "NoModificationsAreRequired" Then
			DocumentState = ActionSelection.LineState;
		EndIf;
	EndDo;
	
	ReturnStructure.DocumentState = DocumentState;
	
	If DocumentState = "ChangesRequired" Then
		
		TableOfMutableRows = QueryResult[7].Unload();
		If DocumentModification Then
			Cancel = False;
			
			If TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
				PurchasesServer.CheckCorrectnessOfReturnedProducts(DiscrepancyCertificate, Cancel, TableOfMutableRows);
			ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
				SalesServer.CheckCorrectnessOfReturnedProducts(DiscrepancyCertificate, "", Cancel, TableOfMutableRows);
			EndIf;
			
			If Cancel Then
				Return
			EndIf;
		EndIf;
		
		ReturnStructure.TableOfMutableRows = TableOfMutableRows;
		ReturnStructure.TableOfVariableSeries = QueryResult[8].Unload();
	EndIf;
	
EndProcedure

Function RequestTextByBaseHeader(Basis)
	
	If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice") Then
		
		Return RequestTextForSalesOfGoodsAndServicesHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		Return QueryTextForHeaderShipmentOfItemsToCustomer(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.VendorInvoice") Then
		
		Return RequestTextForPurchaseOfGoodsAndServicesHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		
		Return TextOfRequestForGoodsArrivingAtWarehouseHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
		
		Return RequestTextForAcceptanceOfGoodsForStorageHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentFromStorage") Then
		
		Return RequestTextForShippingGoodsFromStorageHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee") Then
		
		Return RequestTextForTransferOfGoodsToCustodianHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		
		Return RequestTextForReceiptOfGoodsFromCustodianHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		
		Return RequestTextForRefundToSupplierHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		Return RequestTextForReturnOfGoodsFromClientHeader(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.InventoryTransfer") Then
		
		Return RequestTextForMovingItemsHeader(Basis);
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

Function QueryTextForHeaderShipmentOfItemsToCustomer(Basis)
	
	Return "
	|SELECT ALLOWED
	|	GoodsShipmentToCustomer.Organization           AS Organization,
	|	GoodsShipmentToCustomer.Partner               AS Partner,
	|	GoodsShipmentToCustomer.Counterparty            AS Counterparty,
	|	GoodsShipmentToCustomer.Terms            AS Terms,
	|	GoodsShipmentToCustomer.Currency                AS Currency,
	|	GoodsShipmentToCustomer.BusinessOperation AS BusinessOperation,
	|	GoodsShipmentToCustomer.Contract               AS Contract,
	|	TRUE                                       AS PriceIncludesVAT,
	|	GoodsShipmentToCustomer.VATTaxation    AS VATTaxation,
	|	GoodsShipmentToCustomer.Posted              AS Posted
	|FROM
	|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
	|WHERE
	|	GoodsShipmentToCustomer.Ref = &Basis";
	
EndFunction

Function RequestTextForSalesOfGoodsAndServicesHeader(Basis)
	
	Return "
	|SELECT ALLOWED
	|	CustomerInvoice.Organization,
	|	CustomerInvoice.Partner,
	|	CustomerInvoice.Counterparty,
	|	CustomerInvoice.Terms,
	|	CustomerInvoice.Currency,
	|	CustomerInvoice.BusinessOperation,
	|	CustomerInvoice.Contract,
	|	CustomerInvoice.PriceIncludesVAT,
	|	CASE
	|		WHEN CustomerInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE CustomerInvoice.VATTaxation
	|	END AS VATTaxation,
	|	CustomerInvoice.Posted
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Ref = &Basis";
	
EndFunction 

Function RequestTextForRefundToSupplierHeader(Basis)

	Return "
	|SELECT ALLOWED
	|	ReturnOfGoodsToVendor.Organization,
	|	ReturnOfGoodsToVendor.Partner,
	|	ReturnOfGoodsToVendor.Counterparty,
	|	ReturnOfGoodsToVendor.Terms,
	|	ReturnOfGoodsToVendor.Currency,
	|	ReturnOfGoodsToVendor.BusinessOperation,
	|	ReturnOfGoodsToVendor.Contract,
	|	ReturnOfGoodsToVendor.PriceIncludesVAT,
	|	ReturnOfGoodsToVendor.VATTaxation,
	|	ReturnOfGoodsToVendor.Posted
	|FROM
	|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
	|WHERE
	|	ReturnOfGoodsToVendor.Ref = &Basis";


EndFunction

Function RequestTextForPurchaseOfGoodsAndServicesHeader(Basis)

	Return "
	|SELECT ALLOWED
	|	VendorInvoice.Organization,
	|	VendorInvoice.Partner,
	|	VendorInvoice.Counterparty,
	|	VendorInvoice.Terms,
	|	VendorInvoice.Currency,
	|	VendorInvoice.BusinessOperation,
	|	VendorInvoice.Contract,
	|	VendorInvoice.PriceIncludesVAT,
	|	VendorInvoice.VATTaxation,
	|	VendorInvoice.Posted
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref = &Basis";

EndFunction 

Function TextOfRequestForGoodsArrivingAtWarehouseHeader(Basis)

	Return "
	|SELECT ALLOWED
	|	ReceiptOfGoodsToWarehouse.Organization,
	|	ReceiptOfGoodsToWarehouse.Partner,
	|	ReceiptOfGoodsToWarehouse.Counterparty,
	|	ReceiptOfGoodsToWarehouse.Terms,
	|	ReceiptOfGoodsToWarehouse.Currency,
	|	ReceiptOfGoodsToWarehouse.BusinessOperation,
	|	ReceiptOfGoodsToWarehouse.Contract,
	|	ReceiptOfGoodsToWarehouse.PriceIncludesVAT,
	|	ReceiptOfGoodsToWarehouse.VATTaxation,
	|	ReceiptOfGoodsToWarehouse.Posted
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS ReceiptOfGoodsToWarehouse
	|WHERE
	|	ReceiptOfGoodsToWarehouse.Ref = &Basis";

EndFunction

Function RequestTextForMovingItemsHeader(DiscrepancyCertificate)

	Return "
	|SELECT ALLOWED
	|	InventoryTransfer.Organization,
	|	InventoryTransfer.CompanyRecipient,
	|	InventoryTransfer.SourceWarehouse,
	|	InventoryTransfer.DestinationWarehouse,
	|	InventoryTransfer.BusinessOperation,
	|	InventoryTransfer.Posted
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|WHERE
	|	InventoryTransfer.Ref = &Basis";

EndFunction

Function RequestTextForReportHeader(DiscrepancyCertificate)
	
	If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		
		Return RequestTextForHeaderOfDiscrepancyReportAfterShipment(DiscrepancyCertificate);
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		
		Return RequestTextForHeaderOfDiscrepancyReportAfterMove(DiscrepancyCertificate);
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		
		Return RequestTextForHeaderOfDiscrepancyReportAfterAcceptance(DiscrepancyCertificate);
		
	Else
		
		Return "";
		
	EndIf;

EndFunction

Function RequestTextForHeaderOfDiscrepancyReportAfterAcceptance(DiscrepancyCertificate)

	Return "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Organization,
	|	DiscrepancyReportFollowingReceipt.Partner,
	|	DiscrepancyReportFollowingReceipt.Counterparty,
	|	DiscrepancyReportFollowingReceipt.Terms,
	|	DiscrepancyReportFollowingReceipt.Contract,
	|	DiscrepancyReportFollowingReceipt.Currency,
	|	DiscrepancyReportFollowingReceipt.BusinessOperation,
	|	DiscrepancyReportFollowingReceipt.PriceIncludesVAT,
	|	CASE
	|		WHEN DiscrepancyReportFollowingReceipt.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|				VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale),
	|				VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|				VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5),
	|				VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|			OR DiscrepancyReportFollowingReceipt.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE DiscrepancyReportFollowingReceipt.VATTaxation
	|	END AS VATTaxation,
	|	DiscrepancyReportFollowingReceipt.Status,
	|	DiscrepancyReportFollowingReceipt.TypeOfBaseDocumentForNonConformanceCertificate,
	|	DiscrepancyReportFollowingReceipt.DiscrepanciesPostingMethod,
	|	DiscrepancyReportFollowingReceipt.Posted
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate";
	
EndFunction

Function RequestTextForReturnOfGoodsFromClientHeader(Basis)
	
	Return "
	|SELECT ALLOWED
	|	ReturnOfGoodsFromCustomer.Organization,
	|	ReturnOfGoodsFromCustomer.Partner,
	|	ReturnOfGoodsFromCustomer.Counterparty,
	|	ReturnOfGoodsFromCustomer.Terms,
	|	ReturnOfGoodsFromCustomer.Currency,
	|	ReturnOfGoodsFromCustomer.BusinessOperation,
	|	ReturnOfGoodsFromCustomer.Contract,
	|	ReturnOfGoodsFromCustomer.PriceIncludesVAT,
	|	CASE
	|		WHEN ReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE ReturnOfGoodsFromCustomer.VATTaxation
	|	END AS VATTaxation,
	|	ReturnOfGoodsFromCustomer.Posted
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref = &Basis";
	
EndFunction

Function RequestTextForHeaderOfDiscrepancyReportAfterShipment(DiscrepancyCertificate)

	Return "
	|SELECT
	|	DiscrepancyReportFollowingShipment.Organization,
	|	DiscrepancyReportFollowingShipment.Partner,
	|	DiscrepancyReportFollowingShipment.Counterparty,
	|	DiscrepancyReportFollowingShipment.Terms,
	|	DiscrepancyReportFollowingShipment.Contract,
	|	DiscrepancyReportFollowingShipment.Currency,
	|	DiscrepancyReportFollowingShipment.BusinessOperation,
	|	DiscrepancyReportFollowingShipment.PriceIncludesVAT,
	|	CASE
	|		WHEN DiscrepancyReportFollowingShipment.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale),
	|				VALUE(Enum.BusinessTransactions.DeliveryForPrincipal),
	|				VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale),
	|				VALUE(Enum.BusinessTransactions.DeliveryForPrincipal),
	|				VALUE(Enum.BusinessTransactions.TransferToToller2_5),
	|				VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
	|			OR DiscrepancyReportFollowingShipment.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5))
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE DiscrepancyReportFollowingShipment.VATTaxation
	|	END AS VATTaxation,
	|	DiscrepancyReportFollowingShipment.Status,
	|	DiscrepancyReportFollowingShipment.TypeOfBaseDocumentForNonConformanceCertificate,
	|	DiscrepancyReportFollowingShipment.DiscrepanciesPostingMethod,
	|	DiscrepancyReportFollowingShipment.Posted
	|FROM
	|	Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|WHERE
	|	DiscrepancyReportFollowingShipment.Ref = &DiscrepancyCertificate";

EndFunction

Function RequestTextForHeaderOfDiscrepancyReportAfterMove(DiscrepancyCertificate)

	Return "
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingTransfer.Organization,
	|	DiscrepancyReportFollowingTransfer.CompanyRecipient,
	|	DiscrepancyReportFollowingTransfer.SourceWarehouse,
	|	DiscrepancyReportFollowingTransfer.DestinationWarehouse,
	|	DiscrepancyReportFollowingTransfer.BusinessOperation,
	|	DiscrepancyReportFollowingTransfer.Status,
	|	DiscrepancyReportFollowingTransfer.Posted
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer AS DiscrepancyReportFollowingTransfer
	|WHERE
	|	DiscrepancyReportFollowingTransfer.Ref = &DiscrepancyCertificate";

EndFunction

Function RequestTextTabularPartsOfDiscrepancyReportAfterShipmentAndReturnToSupplier(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)
	
	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse,
	|	ISNULL(CAST(CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow AS Document.VendorInvoice),
	|		VALUE(Document.VendorInvoice.EmptyRef)) AS DocumentInflow,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate AS VATRate,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|		END) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancyDuringShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
    |	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|	ISNULL(CAST(CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow AS Document.VendorInvoice),
	|		VALUE(Document.VendorInvoice.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse AS Warehouse,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose AS Purpose,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingShipmentSetOfSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN DiscrepancyReportFollowingShipmentSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument
	|		END) AS Count,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED 
	|	ReturnOfGoodsToSupplier.Products,
	|	ReturnOfGoodsToSupplier.Characteristic,
	|	ReturnOfGoodsToSupplier.Purpose,
	|	ReturnOfGoodsToSupplier.Package,
	|	ReturnOfGoodsToSupplier.Series,
	|	ReturnOfGoodsToSupplier.Price,
	|	ReturnOfGoodsToSupplier.VATRate,
	|	ReturnOfGoodsToSupplier.DocumentInflow,
	|	SUM(ReturnOfGoodsToSupplier.NumberOfPackages) AS NumberOfPackages,
	|	ReturnOfGoodsToSupplier.Warehouse
	|INTO ReturnOfGoodsToVendor
	|FROM
	|	Document.ReturnOfGoodsToVendor.Goods AS ReturnOfGoodsToSupplier
	|WHERE
	|	ReturnOfGoodsToSupplier.Ref = &Basis
	|
	|GROUP BY
	|	ReturnOfGoodsToSupplier.Package,
	|	ReturnOfGoodsToSupplier.Products,
	|	ReturnOfGoodsToSupplier.Series,
	|	ReturnOfGoodsToSupplier.DocumentInflow,
	|	ReturnOfGoodsToSupplier.Purpose,
	|	ReturnOfGoodsToSupplier.Characteristic,
	|	ReturnOfGoodsToSupplier.Price,
	|	ReturnOfGoodsToSupplier.VATRate,
	|	ReturnOfGoodsToSupplier.Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ReturnOfGoodsToVendorSetOfSeries.Products,
	|	ReturnOfGoodsToVendorSetOfSeries.Characteristic,
	|	ReturnOfGoodsToVendorSetOfSeries.Purpose,
	|	ReturnOfGoodsToVendorSetOfSeries.Series,
	|	ReturnOfGoodsToVendorSetOfSeries.Warehouse,
	|	SUM(ReturnOfGoodsToVendorSetOfSeries.Count) AS Count
	|INTO ReturnToSeriesSupplier
	|FROM
	|	Document.ReturnOfGoodsToVendor.SetOfSeries AS ReturnOfGoodsToVendorSetOfSeries
	|WHERE
	|	ReturnOfGoodsToVendorSetOfSeries.Ref = &Basis
	|
	|GROUP BY
	|	ReturnOfGoodsToVendorSetOfSeries.Products,
	|	ReturnOfGoodsToVendorSetOfSeries.Series,
	|	ReturnOfGoodsToVendorSetOfSeries.Warehouse,
	|	ReturnOfGoodsToVendorSetOfSeries.Purpose,
	|	ReturnOfGoodsToVendorSetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.DocumentInflow,
	|	NestedQuery.Series,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Price,
	|	NestedQuery.VATRate,
	|	NestedQuery.NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose AS Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow AS DocumentInflow,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Price AS Price,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate AS VATRate,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages) AS NumberOfPackagesAccordingToAct,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(ReturnOfGoodsToSupplier.NumberOfPackages, 0)) AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			LEFT JOIN ReturnOfGoodsToVendor AS ReturnOfGoodsToSupplier
	|			ON CertificateOfDiscrepanciesAfterShipmentOfGoods.Products = ReturnOfGoodsToSupplier.Products
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic = ReturnOfGoodsToSupplier.Characteristic
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose = ReturnOfGoodsToSupplier.Purpose
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Package = ReturnOfGoodsToSupplier.Package
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow = ReturnOfGoodsToSupplier.DocumentInflow
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Series = ReturnOfGoodsToSupplier.Series
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Price = ReturnOfGoodsToSupplier.Price
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate = ReturnOfGoodsToSupplier.VATRate
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse = ReturnOfGoodsToSupplier.Warehouse
	|	
	|	GROUP BY
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReturnOfGoodsToSupplier.Products,
	|		ReturnOfGoodsToSupplier.Characteristic,
	|		ReturnOfGoodsToSupplier.Purpose,
	|		ReturnOfGoodsToSupplier.Package,
	|		ReturnOfGoodsToSupplier.DocumentInflow,
	|		ReturnOfGoodsToSupplier.Series,
	|		ReturnOfGoodsToSupplier.Warehouse,
	|		ReturnOfGoodsToSupplier.Price,
	|		ReturnOfGoodsToSupplier.VATRate,
	|		SUM(0),
	|		SUM(0),
	|		SUM(ReturnOfGoodsToSupplier.NumberOfPackages)
	|	FROM
	|		ReturnOfGoodsToVendor AS ReturnOfGoodsToSupplier
	|			LEFT JOIN ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			ON ReturnOfGoodsToSupplier.Products = CertificateOfDiscrepanciesAfterShipmentOfGoods.Products
	|				AND ReturnOfGoodsToSupplier.Characteristic = CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic
	|				AND ReturnOfGoodsToSupplier.Purpose = CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose
	|				AND ReturnOfGoodsToSupplier.Package = CertificateOfDiscrepanciesAfterShipmentOfGoods.Package
	|				AND ReturnOfGoodsToSupplier.DocumentInflow = CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow
	|				AND ReturnOfGoodsToSupplier.Series = CertificateOfDiscrepanciesAfterShipmentOfGoods.Series
	|				AND ReturnOfGoodsToSupplier.Price = CertificateOfDiscrepanciesAfterShipmentOfGoods.Price
	|				AND ReturnOfGoodsToSupplier.VATRate = CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate
	|				AND ReturnOfGoodsToSupplier.Warehouse = CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|	WHERE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		ReturnOfGoodsToSupplier.Package,
	|		ReturnOfGoodsToSupplier.Products,
	|		ReturnOfGoodsToSupplier.Series,
	|		ReturnOfGoodsToSupplier.DocumentInflow,
	|		ReturnOfGoodsToSupplier.Purpose,
	|		ReturnOfGoodsToSupplier.Characteristic,
	|		ReturnOfGoodsToSupplier.Price,
	|		ReturnOfGoodsToSupplier.Warehouse,
	|		ReturnOfGoodsToSupplier.VATRate) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.Warehouse,
	|	NestedQuery.QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose AS Purpose,
	|		ActOfDivergenceSeries.Series AS Series,
	|		ActOfDivergenceSeries.Warehouse AS Warehouse,
	|		SUM(ActOfDivergenceSeries.Count) AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument) AS QuantityBasedOnAct,
	|		SUM(ISNULL(ReturnToSeriesSupplier.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN ReturnToSeriesSupplier AS ReturnToSeriesSupplier
	|			ON ActOfDivergenceSeries.Products = ReturnToSeriesSupplier.Products
	|				AND ActOfDivergenceSeries.Characteristic = ReturnToSeriesSupplier.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = ReturnToSeriesSupplier.Purpose
	|				AND ActOfDivergenceSeries.Series = ReturnToSeriesSupplier.Series
	|				AND ActOfDivergenceSeries.Warehouse = ReturnToSeriesSupplier.Warehouse
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReturnToSeriesSupplier.Products,
	|		ReturnToSeriesSupplier.Characteristic,
	|		ReturnToSeriesSupplier.Purpose,
	|		ReturnToSeriesSupplier.Series,
	|		ReturnToSeriesSupplier.Warehouse,
	|		SUM(0),
	|		SUM(0),
	|		SUM(ReturnToSeriesSupplier.Count)
	|	FROM
	|		ReturnToSeriesSupplier AS ReturnToSeriesSupplier
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON ReturnToSeriesSupplier.Products = ActOfDivergenceSeries.Products
	|				AND ReturnToSeriesSupplier.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND ReturnToSeriesSupplier.Purpose = ActOfDivergenceSeries.Purpose
	|				AND ReturnToSeriesSupplier.Series = ActOfDivergenceSeries.Series
	|				AND ReturnToSeriesSupplier.Warehouse = ActOfDivergenceSeries.Warehouse
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		ReturnToSeriesSupplier.Products,
	|		ReturnToSeriesSupplier.Series,
	|		ReturnToSeriesSupplier.Warehouse,
	|		ReturnToSeriesSupplier.Purpose,
	|		ReturnToSeriesSupplier.Characteristic) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	StateGoods.LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StateGoods.Products,
	|	StateGoods.Characteristic,
	|	StateGoods.Purpose,
	|	StateGoods.Package AS Package,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	StateGoods.DocumentInflow,
	|	StateGoods.Series,
	|	StateGoods.Warehouse,
	|	StateGoods.Price,
	|	StateGoods.VATRate,
	|	StateGoods.NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StateOfSeriesGoods.Products,
	|	StateOfSeriesGoods.Characteristic,
	|	StateOfSeriesGoods.Purpose,
	|	StateOfSeriesGoods.Series,
	|	StateOfSeriesGoods.Warehouse,
	|	StateOfSeriesGoods.QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""";
	
EndFunction

Function RequestTextTabularPartsOfReportOnDiscrepanciesAfterShipmentAndMovement(DiscrepancyCertificate, Basis, ReturnStructure)

	Return "
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingTransferGoods.Products AS Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender AS AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Package AS Package,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument AS OrderDocument,
	|	DiscrepancyReportFollowingTransferGoods.RowCode AS RowCode,
	|	DiscrepancyReportFollowingTransferGoods.Series AS Series,
	|	DiscrepancyReportFollowingTransferGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingTransferGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN DiscrepancyReportFollowingTransferGoods.NumberOfPackages
	|			ELSE DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument
	|		END) AS NumberOfPackages,
	|	SUM(DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDivergenceAfterRelocation
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingTransferGoods.DocumentBasis = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingTransferGoods.Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Products,
	|	DiscrepancyReportFollowingTransferGoods.Purpose,
	|	DiscrepancyReportFollowingTransferGoods.Package,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument,
	|	DiscrepancyReportFollowingTransferGoods.Series,
	|	DiscrepancyReportFollowingTransferGoods.RowCode,
	|	DiscrepancyReportFollowingTransferGoods.BatchesIndicationStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender AS AssignmentSender,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingTransferSetOfSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN DiscrepancyReportFollowingTransferSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument
	|		END) AS Count,
	|	SUM(DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.SetOfSeries AS DiscrepancyReportFollowingTransferSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingTransferSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingTransferSetOfSeries.DocumentBasis = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MovementOfGoodsGoods.Products,
	|	MovementOfGoodsGoods.Characteristic,
	|	MovementOfGoodsGoods.Purpose,
	|	MovementOfGoodsGoods.Package,
	|	MovementOfGoodsGoods.AssignmentSender,
	|	MovementOfGoodsGoods.Series,
	|	MovementOfGoodsGoods.BatchesIndicationStatus,
	|	MovementOfGoodsGoods.TransferOrder AS OrderDocument,
	|	MovementOfGoodsGoods.RowCode AS RowCode,
	|	SUM(MovementOfGoodsGoods.NumberOfPackages) AS NumberOfPackages
	|INTO InventoryTransfer
	|FROM
	|	Document.InventoryTransfer.Goods AS MovementOfGoodsGoods
	|WHERE
	|	MovementOfGoodsGoods.Ref = &Basis
	|
	|GROUP BY
	|	MovementOfGoodsGoods.Package,
	|	MovementOfGoodsGoods.Products,
	|	MovementOfGoodsGoods.Series,
	|	MovementOfGoodsGoods.AssignmentSender,
	|	MovementOfGoodsGoods.Purpose,
	|	MovementOfGoodsGoods.Characteristic,
	|	MovementOfGoodsGoods.BatchesIndicationStatus,
	|	MovementOfGoodsGoods.TransferOrder,
	|	MovementOfGoodsGoods.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InventoryTransferSetOfSeries.Products,
	|	InventoryTransferSetOfSeries.Characteristic,
	|	InventoryTransferSetOfSeries.Purpose,
	|	InventoryTransferSetOfSeries.AssignmentSender,
	|	InventoryTransferSetOfSeries.Series,
	|	SUM(InventoryTransferSetOfSeries.Count) AS Count
	|INTO MovingSeries
	|FROM
	|	Document.InventoryTransfer.SetOfSeries AS InventoryTransferSetOfSeries
	|WHERE
	|	InventoryTransferSetOfSeries.Ref = &Basis
	|
	|GROUP BY
	|	InventoryTransferSetOfSeries.Products,
	|	InventoryTransferSetOfSeries.Series,
	|	InventoryTransferSetOfSeries.AssignmentSender,
	|	InventoryTransferSetOfSeries.Purpose,
	|	InventoryTransferSetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.AssignmentSender,
	|	NestedQuery.Series,
	|	NestedQuery.BatchesIndicationStatus,
	|	NestedQuery.RowCode,
	|	NestedQuery.OrderDocument,
	|	NestedQuery.NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceAfterMovingGoods.Products AS Products,
	|		ActOfDivergenceAfterMovingGoods.Characteristic AS Characteristic,
	|		ActOfDivergenceAfterMovingGoods.Purpose AS Purpose,
	|		ActOfDivergenceAfterMovingGoods.Package AS Package,
	|		ActOfDivergenceAfterMovingGoods.AssignmentSender AS AssignmentSender,
	|		ActOfDivergenceAfterMovingGoods.Series AS Series,
	|		ActOfDivergenceAfterMovingGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		ActOfDivergenceAfterMovingGoods.RowCode AS RowCode,
	|		ActOfDivergenceAfterMovingGoods.OrderDocument AS OrderDocument,
	|		SUM(ActOfDivergenceAfterMovingGoods.NumberOfPackages) AS NumberOfPackagesAccordingToAct,
	|		SUM(ActOfDivergenceAfterMovingGoods.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(MovementOfGoodsGoods.NumberOfPackages, 0)) AS NumberOfPackagesBase
	|	FROM
	|		ActOfDivergenceAfterRelocation AS ActOfDivergenceAfterMovingGoods
	|			LEFT JOIN InventoryTransfer AS MovementOfGoodsGoods
	|			ON ActOfDivergenceAfterMovingGoods.Products = MovementOfGoodsGoods.Products
	|				AND ActOfDivergenceAfterMovingGoods.Characteristic = MovementOfGoodsGoods.Characteristic
	|				AND ActOfDivergenceAfterMovingGoods.Purpose = MovementOfGoodsGoods.Purpose
	|				AND ActOfDivergenceAfterMovingGoods.Package = MovementOfGoodsGoods.Package
	|				AND ActOfDivergenceAfterMovingGoods.AssignmentSender = MovementOfGoodsGoods.AssignmentSender
	|				AND ActOfDivergenceAfterMovingGoods.BatchesIndicationStatus = MovementOfGoodsGoods.BatchesIndicationStatus
	|				AND ActOfDivergenceAfterMovingGoods.Series = MovementOfGoodsGoods.Series
	|				AND ActOfDivergenceAfterMovingGoods.RowCode = MovementOfGoodsGoods.RowCode
	|				AND ActOfDivergenceAfterMovingGoods.OrderDocument = MovementOfGoodsGoods.OrderDocument
	|	
	|	GROUP BY
	|		ActOfDivergenceAfterMovingGoods.Purpose,
	|		ActOfDivergenceAfterMovingGoods.Characteristic,
	|		ActOfDivergenceAfterMovingGoods.Series,
	|		ActOfDivergenceAfterMovingGoods.Package,
	|		ActOfDivergenceAfterMovingGoods.Products,
	|		ActOfDivergenceAfterMovingGoods.AssignmentSender,
	|		ActOfDivergenceAfterMovingGoods.BatchesIndicationStatus,
	|		ActOfDivergenceAfterMovingGoods.RowCode,
	|		ActOfDivergenceAfterMovingGoods.OrderDocument
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MovementOfGoodsGoods.Products,
	|		MovementOfGoodsGoods.Characteristic,
	|		MovementOfGoodsGoods.Purpose,
	|		MovementOfGoodsGoods.Package,
	|		MovementOfGoodsGoods.AssignmentSender,
	|		MovementOfGoodsGoods.Series,
	|		MovementOfGoodsGoods.BatchesIndicationStatus,
	|		MovementOfGoodsGoods.RowCode,
	|		MovementOfGoodsGoods.OrderDocument,
	|		SUM(0),
	|		SUM(0),
	|		SUM(MovementOfGoodsGoods.NumberOfPackages)
	|	FROM
	|		InventoryTransfer AS MovementOfGoodsGoods
	|			LEFT JOIN ActOfDivergenceAfterRelocation AS ActOfDivergenceAfterMovingGoods
	|			ON MovementOfGoodsGoods.Products = ActOfDivergenceAfterMovingGoods.Products
	|				AND MovementOfGoodsGoods.Characteristic = ActOfDivergenceAfterMovingGoods.Characteristic
	|				AND MovementOfGoodsGoods.Purpose = ActOfDivergenceAfterMovingGoods.Purpose
	|				AND MovementOfGoodsGoods.Package = ActOfDivergenceAfterMovingGoods.Package
	|				AND MovementOfGoodsGoods.AssignmentSender = ActOfDivergenceAfterMovingGoods.AssignmentSender
	|				AND MovementOfGoodsGoods.Series = ActOfDivergenceAfterMovingGoods.Series
	|				AND MovementOfGoodsGoods.BatchesIndicationStatus = ActOfDivergenceAfterMovingGoods.BatchesIndicationStatus
	|				AND MovementOfGoodsGoods.RowCode = ActOfDivergenceAfterMovingGoods.RowCode
	|				AND MovementOfGoodsGoods.OrderDocument = ActOfDivergenceAfterMovingGoods.OrderDocument
	|	WHERE
	|		ActOfDivergenceAfterMovingGoods.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		MovementOfGoodsGoods.Package,
	|		MovementOfGoodsGoods.Products,
	|		MovementOfGoodsGoods.Series,
	|		MovementOfGoodsGoods.Purpose,
	|		MovementOfGoodsGoods.AssignmentSender,
	|		MovementOfGoodsGoods.Characteristic,
	|		MovementOfGoodsGoods.BatchesIndicationStatus,
	|		MovementOfGoodsGoods.RowCode,
	|		MovementOfGoodsGoods.OrderDocument) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.AssignmentSender,
	|	NestedQuery.Series,
	|	NestedQuery.QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose AS Purpose,
	|		ActOfDivergenceSeries.AssignmentSender AS AssignmentSender,
	|		ActOfDivergenceSeries.Series AS Series,
	|		SUM(ActOfDivergenceSeries.Count) AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument) AS QuantityBasedOnAct,
	|		SUM(ISNULL(MovingSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN MovingSeries AS MovingSeries
	|			ON ActOfDivergenceSeries.Products = MovingSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = MovingSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = MovingSeries.Purpose
	|				AND ActOfDivergenceSeries.AssignmentSender = MovingSeries.AssignmentSender
	|				AND ActOfDivergenceSeries.Series = MovingSeries.Series
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.AssignmentSender,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MovingSeries.Products,
	|		MovingSeries.Characteristic,
	|		MovingSeries.Purpose,
	|		MovingSeries.AssignmentSender,
	|		MovingSeries.Series,
	|		SUM(0),
	|		SUM(0),
	|		SUM(MovingSeries.Count)
	|	FROM
	|		MovingSeries AS MovingSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON MovingSeries.Products = ActOfDivergenceSeries.Products
	|				AND MovingSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND MovingSeries.Purpose = ActOfDivergenceSeries.Purpose
	|				AND MovingSeries.AssignmentSender = ActOfDivergenceSeries.AssignmentSender
	|				AND MovingSeries.Series = ActOfDivergenceSeries.Series
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		MovingSeries.Products,
	|		MovingSeries.Series,
	|		MovingSeries.AssignmentSender,
	|		MovingSeries.Purpose,
	|		MovingSeries.Characteristic) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	StateGoods.LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StateGoods.Products,
	|	StateGoods.Characteristic,
	|	StateGoods.Purpose,
	|	StateGoods.Package,
	|	StateGoods.AssignmentSender,
	|	StateGoods.BatchesIndicationStatus,
	|	StateGoods.Series,
	|	StateGoods.RowCode,
	|	StateGoods.OrderDocument AS TransferOrder,
	|	StateGoods.NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StateOfSeriesGoods.Products,
	|	StateOfSeriesGoods.Characteristic,
	|	StateOfSeriesGoods.Purpose,
	|	StateOfSeriesGoods.AssignmentSender,
	|	StateOfSeriesGoods.Series,
	|	StateOfSeriesGoods.QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""";
	
EndFunction

Function RequestTextTabularPartsOfReportOnDiscrepanciesAfterShipmentAndSale(DiscrepancyCertificate, Basis, ReturnStructure)

	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref.BusinessOperation AS BusinessOperation,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder AS SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode AS RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|	CASE 
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef) 
	|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		ELSE CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate 
	|	END AS VATRate,
	|	MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.Price) AS Price,
	|	MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.PriceKind) AS PriceKind,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|						)
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment IN (
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit)
	|						)
	|				THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|		END) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancyDuringShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref.BusinessOperation,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse AS Warehouse,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingShipmentSetOfSeries.Action IN (
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|						)
	|				AND DiscrepancyReportFollowingShipmentSetOfSeries.DiscrepancyTreatment IN (
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_),
	|						VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit)
	|						)
	|				THEN DiscrepancyReportFollowingShipmentSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument
	|		END) AS Count,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &Basis
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED
	|	SalesOfGoodsServicesGoods.Ref.BusinessOperation,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose,
	|	SalesOfGoodsServicesGoods.Package,
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Warehouse,
	|	SalesOfGoodsServicesGoods.Series,
	|	CASE
	|		WHEN SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|				AND SalesOfGoodsServicesGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		ELSE SalesOfGoodsServicesGoods.VATRate
	|	END AS VATRate,
	|	SUM(SalesOfGoodsServicesGoods.NumberOfPackages) AS NumberOfPackages
	|INTO CustomerInvoice
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|WHERE
	|	SalesOfGoodsServicesGoods.Ref = &Basis
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.Ref.BusinessOperation,
	|	SalesOfGoodsServicesGoods.Package,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Series,
	|	SalesOfGoodsServicesGoods.Warehouse,
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.Purpose,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Ref.BusinessOperation,
	|	SalesOfGoodsServicesGoods.VATRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED
	|	SalesOfGoodsServicesSeries.Products,
	|	SalesOfGoodsServicesSeries.Characteristic,
	|	SalesOfGoodsServicesSeries.Purpose,
	|	SalesOfGoodsServicesSeries.Warehouse,
	|	SalesOfGoodsServicesSeries.Series,
	|	SUM(SalesOfGoodsServicesSeries.Count) AS Count
	|INTO SalesOfGoodsServicesSeries
	|FROM
	|	Document.CustomerInvoice.SetOfSeries AS SalesOfGoodsServicesSeries
	|WHERE
	|	SalesOfGoodsServicesSeries.Ref = &Basis
	|	AND SalesOfGoodsServicesSeries.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	SalesOfGoodsServicesSeries.Products,
	|	SalesOfGoodsServicesSeries.Series,
	|	SalesOfGoodsServicesSeries.Warehouse,
	|	SalesOfGoodsServicesSeries.Purpose,
	|	SalesOfGoodsServicesSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.SalesOrder,
	|	NestedQuery.RowCode,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Series,
	|	NestedQuery.VATRate,
	|	NestedQuery.Price,
	|	NestedQuery.PriceKind,
	|	NestedQuery.VATRate,
	|	NestedQuery.NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose AS Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder AS SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode AS RowCode,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate AS VATRate,
	|		MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.Price) AS Price,
	|		MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.PriceKind) AS PriceKind,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages) AS NumberOfPackagesAccordingToAct,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(SalesOfGoodsServicesGoods.NumberOfPackages, 0)) AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			LEFT JOIN CustomerInvoice AS SalesOfGoodsServicesGoods
	|			ON CertificateOfDiscrepanciesAfterShipmentOfGoods.Products = SalesOfGoodsServicesGoods.Products
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic = SalesOfGoodsServicesGoods.Characteristic
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose = SalesOfGoodsServicesGoods.Purpose
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Package = SalesOfGoodsServicesGoods.Package
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = SalesOfGoodsServicesGoods.SalesOrder
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = SalesOfGoodsServicesGoods.RowCode
	|				AND (CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse = SalesOfGoodsServicesGoods.Warehouse
	|					OR CertificateOfDiscrepanciesAfterShipmentOfGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|				AND (CertificateOfDiscrepanciesAfterShipmentOfGoods.Series = SalesOfGoodsServicesGoods.Series
	|					OR CertificateOfDiscrepanciesAfterShipmentOfGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate = SalesOfGoodsServicesGoods.VATRate
	|	
	|	GROUP BY
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesOfGoodsServicesGoods.Products,
	|		SalesOfGoodsServicesGoods.Characteristic,
	|		SalesOfGoodsServicesGoods.Purpose,
	|		SalesOfGoodsServicesGoods.Package,
	|		SalesOfGoodsServicesGoods.SalesOrder,
	|		SalesOfGoodsServicesGoods.RowCode,
	|		SalesOfGoodsServicesGoods.Warehouse,
	|		SalesOfGoodsServicesGoods.Series,
	|		SalesOfGoodsServicesGoods.VATRate,
	|		0,
	|		MAX(VALUE(Catalog.TypesOfPrices.EmptyRef)),
	|		SUM(0),
	|		SUM(0),
	|		SUM(SalesOfGoodsServicesGoods.NumberOfPackages)
	|	FROM
	|		CustomerInvoice AS SalesOfGoodsServicesGoods
	|			LEFT JOIN ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			ON SalesOfGoodsServicesGoods.Products = CertificateOfDiscrepanciesAfterShipmentOfGoods.Products
	|				AND SalesOfGoodsServicesGoods.Characteristic = CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic
	|				AND SalesOfGoodsServicesGoods.Purpose = CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose
	|				AND SalesOfGoodsServicesGoods.Package = CertificateOfDiscrepanciesAfterShipmentOfGoods.Package
	|				AND SalesOfGoodsServicesGoods.SalesOrder = CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder
	|				AND SalesOfGoodsServicesGoods.RowCode = CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|				AND (SalesOfGoodsServicesGoods.Warehouse = CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|					OR SalesOfGoodsServicesGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|				AND (SalesOfGoodsServicesGoods.Series = CertificateOfDiscrepanciesAfterShipmentOfGoods.Series
	|					OR SalesOfGoodsServicesGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|				AND SalesOfGoodsServicesGoods.VATRate = CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate
	|	WHERE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		SalesOfGoodsServicesGoods.Package,
	|		SalesOfGoodsServicesGoods.Products,
	|		SalesOfGoodsServicesGoods.Series,
	|		SalesOfGoodsServicesGoods.Warehouse,
	|		SalesOfGoodsServicesGoods.SalesOrder,
	|		SalesOfGoodsServicesGoods.Purpose,
	|		SalesOfGoodsServicesGoods.Characteristic,
	|		SalesOfGoodsServicesGoods.RowCode,
	|		SalesOfGoodsServicesGoods.VATRate) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Series,
	|	NestedQuery.QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose AS Purpose,
	|		ActOfDivergenceSeries.Warehouse AS Warehouse,
	|		ActOfDivergenceSeries.Series AS Series,
	|		SUM(ActOfDivergenceSeries.Count) AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument) AS QuantityBasedOnAct,
	|		SUM(ISNULL(SalesOfGoodsServicesSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN SalesOfGoodsServicesSeries AS SalesOfGoodsServicesSeries
	|			ON ActOfDivergenceSeries.Products = SalesOfGoodsServicesSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = SalesOfGoodsServicesSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = SalesOfGoodsServicesSeries.Purpose
	|				AND ActOfDivergenceSeries.Warehouse = SalesOfGoodsServicesSeries.Warehouse
	|				AND ActOfDivergenceSeries.Series = SalesOfGoodsServicesSeries.Series
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesOfGoodsServicesSeries.Products,
	|		SalesOfGoodsServicesSeries.Characteristic,
	|		SalesOfGoodsServicesSeries.Purpose,
	|		SalesOfGoodsServicesSeries.Warehouse,
	|		SalesOfGoodsServicesSeries.Series,
	|		SUM(0),
	|		SUM(0),
	|		SUM(SalesOfGoodsServicesSeries.Count)
	|	FROM
	|		SalesOfGoodsServicesSeries AS SalesOfGoodsServicesSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON SalesOfGoodsServicesSeries.Products = ActOfDivergenceSeries.Products
	|				AND SalesOfGoodsServicesSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND SalesOfGoodsServicesSeries.Purpose = ActOfDivergenceSeries.Purpose
	|				AND SalesOfGoodsServicesSeries.Warehouse = ActOfDivergenceSeries.Warehouse
	|				AND SalesOfGoodsServicesSeries.Series = ActOfDivergenceSeries.Series
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		SalesOfGoodsServicesSeries.Products,
	|		SalesOfGoodsServicesSeries.Series,
	|		SalesOfGoodsServicesSeries.Warehouse,
	|		SalesOfGoodsServicesSeries.Purpose,
	|		SalesOfGoodsServicesSeries.Characteristic) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT DISTINCT
	|	StateGoods.LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|SELECT
	|	StateGoods.Products,
	|	StateGoods.Characteristic,
	|	StateGoods.Purpose,
	|	StateGoods.Package,
	|	StateGoods.SalesOrder,
	|	StateGoods.RowCode,
	|	StateGoods.Warehouse,
	|	StateGoods.Series,
	|	StateGoods.VATRate,
	|	StateGoods.Price,
	|	StateGoods.PriceKind,
	|	StateGoods.NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////8
	|SELECT
	|	StateOfSeriesGoods.Products,
	|	StateOfSeriesGoods.Characteristic,
	|	StateOfSeriesGoods.Purpose,
	|	StateOfSeriesGoods.Warehouse,
	|	StateOfSeriesGoods.Series,
	|	StateOfSeriesGoods.QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""";
	
EndFunction

Function QueryTextTabularPartsOfDiscrepancyReportAfterShipmentAndShipmentOfItems(DiscrepancyCertificate, Basis, ReturnStructure)

	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products        AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic      AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose          AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package            AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder        AS SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode           AS RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse               AS Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series               AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.Price)      AS Price,
	|	MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.PriceKind)   AS PriceKind,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|						)
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount)
	|				THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|	END)                                                  AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancyDuringShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &Basis
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer)
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series          AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products   AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose     AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse          AS Warehouse,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingShipmentSetOfSeries.Action IN (
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|						)
	|				AND DiscrepancyReportFollowingShipmentSetOfSeries.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount)
	|				THEN DiscrepancyReportFollowingShipmentSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument
	|		END)                                        AS Count,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	ShipmentOfItemsToCustomerItems.Ref.ShipmentByOrders     AS ShipmentByOrders,
	|	ShipmentOfItemsToCustomerItems.Products                 AS Products,
	|	ShipmentOfItemsToCustomerItems.Characteristic               AS Characteristic,
	|	ShipmentOfItemsToCustomerItems.Purpose                   AS Purpose,
	|	ShipmentOfItemsToCustomerItems.Package                     AS Package,
	|	ShipmentOfItemsToCustomerItems.SalesOrder                 AS SalesOrder,
	|	ShipmentOfItemsToCustomerItems.RowCode                    AS RowCode,
	|	ShipmentOfItemsToCustomerItems.Warehouse                        AS Warehouse,
	|	CASE
	|		WHEN ShipmentOfItemsToCustomerItems.BatchesIndicationStatusInWarehouses = 0
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE
	|			ShipmentOfItemsToCustomerItems.Series
	|	END                                                     AS Series,
	|	ShipmentOfItemsToCustomerItems.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatus,
	|	SUM(ShipmentOfItemsToCustomerItems.NumberOfPackages)    AS NumberOfPackages
	|INTO GoodsShipmentToCustomer
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomerItems
	|WHERE
	|	ShipmentOfItemsToCustomerItems.Ref = &Basis
	|
	|GROUP BY
	|	ShipmentOfItemsToCustomerItems.Ref.ShipmentByOrders,
	|	ShipmentOfItemsToCustomerItems.Products,
	|	ShipmentOfItemsToCustomerItems.Characteristic,
	|	ShipmentOfItemsToCustomerItems.Purpose,
	|	ShipmentOfItemsToCustomerItems.Package,
	|	ShipmentOfItemsToCustomerItems.SalesOrder,
	|	ShipmentOfItemsToCustomerItems.RowCode,
	|	ShipmentOfItemsToCustomerItems.Warehouse,
	|	CASE
	|		WHEN ShipmentOfItemsToCustomerItems.BatchesIndicationStatusInWarehouses = 0
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE
	|			ShipmentOfItemsToCustomerItems.Series
	|	END,
	|	ShipmentOfItemsToCustomerItems.BatchesIndicationStatusInWarehouses
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT ALLOWED
	|	ShipmentOfItemsToCustomerOfSeries.Products      AS Products,
	|	ShipmentOfItemsToCustomerOfSeries.Characteristic    AS Characteristic,
	|	ShipmentOfItemsToCustomerOfSeries.Purpose        AS Purpose,
	|	ShipmentOfItemsToCustomerOfSeries.Warehouse             AS Warehouse,
	|	ShipmentOfItemsToCustomerOfSeries.Series             AS Series,
	|	SUM(ShipmentOfItemsToCustomerOfSeries.Count) AS Count
	|INTO ShipmentOfItemsToCustomerOfSeries
	|FROM
	|	Document.GoodsShipmentToCustomer.SetOfSeries AS ShipmentOfItemsToCustomerOfSeries
	|WHERE
	|	ShipmentOfItemsToCustomerOfSeries.Ref = &Basis
	|
	|GROUP BY
	|	ShipmentOfItemsToCustomerOfSeries.Products,
	|	ShipmentOfItemsToCustomerOfSeries.Characteristic,
	|	ShipmentOfItemsToCustomerOfSeries.Purpose,
	|	ShipmentOfItemsToCustomerOfSeries.Warehouse,
	|	ShipmentOfItemsToCustomerOfSeries.Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT DISTINCT
	|	NestedQuery.Products                     AS Products,
	|	NestedQuery.Characteristic                   AS Characteristic,
	|	NestedQuery.Purpose                       AS Purpose,
	|	NestedQuery.Package                         AS Package,
	|	NestedQuery.SalesOrder                     AS SalesOrder,
	|	NestedQuery.RowCode                        AS RowCode,
	|	NestedQuery.Warehouse                            AS Warehouse,
	|	NestedQuery.Series                            AS Series,
	|	NestedQuery.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|	NestedQuery.Price                             AS Price,
	|	NestedQuery.PriceKind                          AS PriceKind,
	|	NestedQuery.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase      AS NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                            AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products                         AS Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic                       AS Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose                           AS Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package                             AS Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder                         AS SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode                            AS RowCode,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse                                AS Warehouse,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series                                AS Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus                  AS BatchesIndicationStatus,
	|		MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.Price)                       AS Price,
	|		MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.PriceKind)                    AS PriceKind,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages)            AS NumberOfPackagesAccordingToAct,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(ShipmentOfItemsToCustomerItems.NumberOfPackages, 0))      AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			LEFT JOIN GoodsShipmentToCustomer AS ShipmentOfItemsToCustomerItems
	|			ON CertificateOfDiscrepanciesAfterShipmentOfGoods.Products = ShipmentOfItemsToCustomerItems.Products
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic = ShipmentOfItemsToCustomerItems.Characteristic
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose = ShipmentOfItemsToCustomerItems.Purpose
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Package = ShipmentOfItemsToCustomerItems.Package
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = ShipmentOfItemsToCustomerItems.SalesOrder
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse = ShipmentOfItemsToCustomerItems.Warehouse
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Series = ShipmentOfItemsToCustomerItems.Series
	|				AND (ShipmentOfItemsToCustomerItems.RowCode = CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|					OR NOT ShipmentOfItemsToCustomerItems.ShipmentByOrders
	|						AND CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = 0
	|						AND ShipmentOfItemsToCustomerItems.RowCode > 0)
	|	
	|	GROUP BY
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShipmentOfItemsToCustomerItems.Products              AS Products,
	|		ShipmentOfItemsToCustomerItems.Characteristic            AS Characteristic,
	|		ShipmentOfItemsToCustomerItems.Purpose                AS Purpose,
	|		ShipmentOfItemsToCustomerItems.Package                  AS Package,
	|		ShipmentOfItemsToCustomerItems.SalesOrder              AS SalesOrder,
	|		ShipmentOfItemsToCustomerItems.RowCode                 AS RowCode,
	|		ShipmentOfItemsToCustomerItems.Warehouse                     AS Warehouse,
	|		ShipmentOfItemsToCustomerItems.Series                     AS Series,
	|		ShipmentOfItemsToCustomerItems.BatchesIndicationStatus       AS BatchesIndicationStatus,
	|		0                                                      AS Price,
	|		MAX(VALUE(Catalog.TypesOfPrices.EmptyRef))    AS PriceKind,
	|		SUM(0)                                               AS NumberOfPackagesAccordingToAct,
	|		SUM(0)                                               AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ShipmentOfItemsToCustomerItems.NumberOfPackages) AS NumberOfPackagesBase
	|	FROM
	|		GoodsShipmentToCustomer AS ShipmentOfItemsToCustomerItems
	|			LEFT JOIN ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			ON ShipmentOfItemsToCustomerItems.Products = CertificateOfDiscrepanciesAfterShipmentOfGoods.Products
	|				AND ShipmentOfItemsToCustomerItems.Characteristic = CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic
	|				AND ShipmentOfItemsToCustomerItems.Purpose = CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose
	|				AND ShipmentOfItemsToCustomerItems.Package = CertificateOfDiscrepanciesAfterShipmentOfGoods.Package
	|				AND ShipmentOfItemsToCustomerItems.SalesOrder = CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder
	|				AND ShipmentOfItemsToCustomerItems.Warehouse = CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|				AND ShipmentOfItemsToCustomerItems.Series = CertificateOfDiscrepanciesAfterShipmentOfGoods.Series
	|				AND (ShipmentOfItemsToCustomerItems.RowCode = CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|					OR NOT ShipmentOfItemsToCustomerItems.ShipmentByOrders
	|						AND CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = 0
	|						AND ShipmentOfItemsToCustomerItems.RowCode > 0)
	|	WHERE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		ShipmentOfItemsToCustomerItems.Package,
	|		ShipmentOfItemsToCustomerItems.Products,
	|		ShipmentOfItemsToCustomerItems.Series,
	|		ShipmentOfItemsToCustomerItems.BatchesIndicationStatus,
	|		ShipmentOfItemsToCustomerItems.Warehouse,
	|		ShipmentOfItemsToCustomerItems.SalesOrder,
	|		ShipmentOfItemsToCustomerItems.Purpose,
	|		ShipmentOfItemsToCustomerItems.Characteristic,
	|		ShipmentOfItemsToCustomerItems.RowCode) AS NestedQuery
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	NestedQuery.Products             AS Products,
	|	NestedQuery.Characteristic           AS Characteristic,
	|	NestedQuery.Purpose               AS Purpose,
	|	NestedQuery.Warehouse                    AS Warehouse,
	|	NestedQuery.Series                    AS Series,
	|	NestedQuery.QuantityByAct         AS QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_      AS QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                    AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products                         AS Products,
	|		ActOfDivergenceSeries.Characteristic                       AS Characteristic,
	|		ActOfDivergenceSeries.Purpose                           AS Purpose,
	|		ActOfDivergenceSeries.Warehouse                                AS Warehouse,
	|		ActOfDivergenceSeries.Series                                AS Series,
	|		SUM(ActOfDivergenceSeries.Count)                    AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument)         AS QuantityBasedOnAct,
	|		SUM(ISNULL(ShipmentOfItemsToCustomerOfSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN ShipmentOfItemsToCustomerOfSeries AS ShipmentOfItemsToCustomerOfSeries
	|			ON ActOfDivergenceSeries.Products = ShipmentOfItemsToCustomerOfSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = ShipmentOfItemsToCustomerOfSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = ShipmentOfItemsToCustomerOfSeries.Purpose
	|				AND ActOfDivergenceSeries.Warehouse = ShipmentOfItemsToCustomerOfSeries.Warehouse
	|				AND ActOfDivergenceSeries.Series = ShipmentOfItemsToCustomerOfSeries.Series
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShipmentOfItemsToCustomerOfSeries.Products      AS Products,
	|		ShipmentOfItemsToCustomerOfSeries.Characteristic    AS Characteristic,
	|		ShipmentOfItemsToCustomerOfSeries.Purpose        AS Purpose,
	|		ShipmentOfItemsToCustomerOfSeries.Warehouse             AS Warehouse,
	|		ShipmentOfItemsToCustomerOfSeries.Series             AS Series,
	|		SUM(0)                                      AS QuantityByAct,
	|		SUM(0)                                      AS QuantityBasedOnAct,
	|		SUM(ShipmentOfItemsToCustomerOfSeries.Count) AS QuantityBase_
	|	FROM
	|		ShipmentOfItemsToCustomerOfSeries AS ShipmentOfItemsToCustomerOfSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON ShipmentOfItemsToCustomerOfSeries.Products = ActOfDivergenceSeries.Products
	|				AND ShipmentOfItemsToCustomerOfSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND ShipmentOfItemsToCustomerOfSeries.Purpose = ActOfDivergenceSeries.Purpose
	|				AND ShipmentOfItemsToCustomerOfSeries.Warehouse = ActOfDivergenceSeries.Warehouse
	|				AND ShipmentOfItemsToCustomerOfSeries.Series = ActOfDivergenceSeries.Series
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		ShipmentOfItemsToCustomerOfSeries.Products,
	|		ShipmentOfItemsToCustomerOfSeries.Series,
	|		ShipmentOfItemsToCustomerOfSeries.Warehouse,
	|		ShipmentOfItemsToCustomerOfSeries.Purpose,
	|		ShipmentOfItemsToCustomerOfSeries.Characteristic) AS NestedQuery
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT DISTINCT
	|	StateGoods.LineState AS LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT
	|	StateOfSeriesGoods.LineState AS LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	StateGoods.Products                     AS Products,
	|	StateGoods.Characteristic                   AS Characteristic,
	|	StateGoods.Purpose                       AS Purpose,
	|	StateGoods.Package                         AS Package,
	|	StateGoods.SalesOrder                     AS SalesOrder,
	|	StateGoods.RowCode                        AS RowCode,
	|	StateGoods.Warehouse                            AS Warehouse,
	|	StateGoods.Series                            AS Series,
	|	StateGoods.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|	StateGoods.Price                             AS Price,
	|	StateGoods.PriceKind                          AS PriceKind,
	|	StateGoods.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase      AS NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	StateOfSeriesGoods.Products             AS Products,
	|	StateOfSeriesGoods.Characteristic           AS Characteristic,
	|	StateOfSeriesGoods.Purpose               AS Purpose,
	|	StateOfSeriesGoods.Warehouse                    AS Warehouse,
	|	StateOfSeriesGoods.Series                    AS Series,
	|	StateOfSeriesGoods.QuantityByAct         AS QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_      AS QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""";
	
EndFunction

Function RequestTextTabularPartsOfDiscrepancyReportAfterAcceptanceAndReturnFromClient(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)
	
	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package AS Package,
	|	CASE
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|	END AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode AS RowCode,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber AS CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate AS VATRate,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price) AS Price,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument
	|		END) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancies
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package,
	|	CASE
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|	END,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentSalesOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse AS Warehouse,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingReceiptSetOfSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN DiscrepancyReportFollowingReceiptSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument
	|		END) AS Count,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|
	|SELECT ALLOWED 
	|	CASE 
	|		WHEN ReturnOfGoodsFromCustomerGoods.Damage THEN  ReturnOfGoodsFromCustomerGoods.ProductsRecordingAsReceived
	|		ELSE ReturnOfGoodsFromCustomerGoods.Products 
	|	END AS Products,
	|	CASE 
	|		WHEN ReturnOfGoodsFromCustomerGoods.Damage THEN  ReturnOfGoodsFromCustomerGoods.CharacteristicRecordingAsReceived
	|		ELSE ReturnOfGoodsFromCustomerGoods.Characteristic 
	|	END AS Characteristic,
	|	ReturnOfGoodsFromCustomerGoods.Purpose,
	|	ReturnOfGoodsFromCustomerGoods.Package,
	|	ReturnOfGoodsFromCustomerGoods.Series,
	|	ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus,
	|	ReturnOfGoodsFromCustomerGoods.RowCode,
	|	ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices,
	|	ReturnOfGoodsFromCustomerGoods.CCDNumber,
	|	ReturnOfGoodsFromCustomerGoods.Warehouse,
	|	ReturnOfGoodsFromCustomerGoods.VATRate,
	|	SUM(ReturnOfGoodsFromCustomerGoods.NumberOfPackages) AS NumberOfPackages
	|INTO ReturnOfGoodsFromCustomerGoods
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS ReturnOfGoodsFromCustomerGoods
	|WHERE
	|	ReturnOfGoodsFromCustomerGoods.Ref = &Basis
	|
	|GROUP BY
	|	CASE 
	|		WHEN ReturnOfGoodsFromCustomerGoods.Damage THEN  ReturnOfGoodsFromCustomerGoods.ProductsRecordingAsReceived
	|		ELSE ReturnOfGoodsFromCustomerGoods.Products 
	|	END,
	|	CASE 
	|		WHEN ReturnOfGoodsFromCustomerGoods.Damage THEN  ReturnOfGoodsFromCustomerGoods.CharacteristicRecordingAsReceived
	|		ELSE ReturnOfGoodsFromCustomerGoods.Characteristic 
	|	END,
	|	ReturnOfGoodsFromCustomerGoods.Purpose,
	|	ReturnOfGoodsFromCustomerGoods.Products,
	|	ReturnOfGoodsFromCustomerGoods.Package,
	|	ReturnOfGoodsFromCustomerGoods.Series,
	|	ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus,
	|	ReturnOfGoodsFromCustomerGoods.RowCode,
	|	ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices,
	|	ReturnOfGoodsFromCustomerGoods.CCDNumber,
	|	ReturnOfGoodsFromCustomerGoods.Warehouse,
	|	ReturnOfGoodsFromCustomerGoods.VATRate
	|;
	|////////////////////////////////////////////////////////////////////////////////3
	|
	|SELECT ALLOWED
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.Warehouse,
	|	SUM(NestedQuery.Count) AS Count
	|INTO ReturnOfGoodsFromCustomerSeries
	|FROM 
	|	(SELECT
	|		CASE 
	|			WHEN GoodsTable.Damage THEN  SeriesTable.ProductsRecordingAsReceived
	|			ELSE SeriesTable.Products 
	|		END                                        AS Products,
	|		CASE 
	|			WHEN GoodsTable.Damage THEN  SeriesTable.CharacteristicRecordingAsReceived
	|			ELSE SeriesTable.Characteristic 
	|		END                                        AS Characteristic,
	|		SeriesTable.Purpose                      AS Purpose,
	|		SeriesTable.Series                           AS Series,
	|		SeriesTable.Warehouse                           AS Warehouse,
	|		SeriesTable.Count                      AS Count,
	|		MAX(GoodsTable.BatchesIndicationStatus)  AS BatchesIndicationStatus
	|	FROM
	|		Document.ReturnOfGoodsFromCustomer.SetOfSeries AS SeriesTable
	|			INNER JOIN Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
	|			ON SeriesTable.Ref = GoodsTable.Ref
	|				AND SeriesTable.Products                = GoodsTable.Products
	|				AND SeriesTable.Characteristic              = GoodsTable.Characteristic
	|				AND SeriesTable.ProductsRecordingAsReceived   = GoodsTable.ProductsRecordingAsReceived
	|				AND SeriesTable.CharacteristicRecordingAsReceived = GoodsTable.CharacteristicRecordingAsReceived
	|				AND SeriesTable.Purpose                  = GoodsTable.Purpose
	|				AND SeriesTable.Warehouse                       = GoodsTable.Warehouse
	|	WHERE
	|		SeriesTable.Ref = &Basis
	|		AND GoodsTable.Ref = &Basis
	|		AND SeriesTable.Count <> 0
	|
	|	GROUP BY
	|		SeriesTable.Products,
	|		SeriesTable.Series,
	|		SeriesTable.Warehouse,
	|		GoodsTable.Damage,
	|		SeriesTable.Count,
	|		SeriesTable.Characteristic,
	|		SeriesTable.Purpose,
	|		SeriesTable.ProductsRecordingAsReceived,
	|		SeriesTable.CharacteristicRecordingAsReceived
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN  (2, 4, 6, 8, 10)) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	NestedQuery.BatchesIndicationStatus,
	|	NestedQuery.RowCode,
	|	NestedQuery.DocumentSalesOfGoodsAndServices,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.Price,
	|	NestedQuery.Warehouse,
	|	NestedQuery.VATRate,
	|	NestedQuery.NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		ActOfDiscrepancies.Products AS Products,
	|		ActOfDiscrepancies.Characteristic AS Characteristic,
	|		ActOfDiscrepancies.Purpose AS Purpose,
	|		ActOfDiscrepancies.Package AS Package,
	|		ActOfDiscrepancies.Series AS Series,
	|		ActOfDiscrepancies.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		ActOfDiscrepancies.RowCode AS RowCode,
	|		ActOfDiscrepancies.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		ActOfDiscrepancies.CCDNumber AS CCDNumber,
	|		ActOfDiscrepancies.Warehouse AS Warehouse,
	|		ActOfDiscrepancies.VATRate AS VATRate,
	|		MAX(ActOfDiscrepancies.Price) AS Price,
	|		SUM(ActOfDiscrepancies.NumberOfPackages) AS NumberOfPackagesAccordingToAct,
	|		SUM(ActOfDiscrepancies.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(ReturnOfGoodsFromCustomerGoods.NumberOfPackages, 0)) AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancies AS ActOfDiscrepancies
	|			LEFT JOIN ReturnOfGoodsFromCustomerGoods AS ReturnOfGoodsFromCustomerGoods
	|			ON ActOfDiscrepancies.Products = ReturnOfGoodsFromCustomerGoods.Products
	|				AND ActOfDiscrepancies.Characteristic = ReturnOfGoodsFromCustomerGoods.Characteristic
	|				AND ActOfDiscrepancies.Purpose = ReturnOfGoodsFromCustomerGoods.Purpose
	|				AND ActOfDiscrepancies.Package = ReturnOfGoodsFromCustomerGoods.Package
	|				AND ActOfDiscrepancies.Series = ReturnOfGoodsFromCustomerGoods.Series
	|				AND ActOfDiscrepancies.BatchesIndicationStatus = ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus
	|				AND ActOfDiscrepancies.RowCode = ReturnOfGoodsFromCustomerGoods.RowCode
	|				AND ActOfDiscrepancies.DocumentSalesOfGoodsAndServices = ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices
	|				AND ActOfDiscrepancies.CCDNumber = ReturnOfGoodsFromCustomerGoods.CCDNumber
	|				AND ActOfDiscrepancies.Warehouse = ReturnOfGoodsFromCustomerGoods.Warehouse
	|				AND ActOfDiscrepancies.VATRate = ReturnOfGoodsFromCustomerGoods.VATRate
	|	
	|	GROUP BY
	|		ActOfDiscrepancies.Characteristic,
	|		ActOfDiscrepancies.Purpose,
	|		ActOfDiscrepancies.Series,
	|		ActOfDiscrepancies.BatchesIndicationStatus,
	|		ActOfDiscrepancies.Package,
	|		ActOfDiscrepancies.Products,
	|		ActOfDiscrepancies.RowCode,
	|		ActOfDiscrepancies.DocumentSalesOfGoodsAndServices,
	|		ActOfDiscrepancies.CCDNumber,
	|		ActOfDiscrepancies.Warehouse,
	|		ActOfDiscrepancies.VATRate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReturnOfGoodsFromCustomerGoods.Products,
	|		ReturnOfGoodsFromCustomerGoods.Characteristic,
	|		ReturnOfGoodsFromCustomerGoods.Purpose,
	|		ReturnOfGoodsFromCustomerGoods.Package,
	|		ReturnOfGoodsFromCustomerGoods.Series,
	|		ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus,
	|		ReturnOfGoodsFromCustomerGoods.RowCode,
	|		ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices,
	|		ReturnOfGoodsFromCustomerGoods.CCDNumber,
	|		ReturnOfGoodsFromCustomerGoods.Warehouse,
	|		ReturnOfGoodsFromCustomerGoods.VATRate,
	|		MAX(0) AS Price,
	|		SUM(0),
	|		SUM(0),
	|		SUM(ReturnOfGoodsFromCustomerGoods.NumberOfPackages)
	|	FROM
	|		ReturnOfGoodsFromCustomerGoods AS ReturnOfGoodsFromCustomerGoods
	|			LEFT JOIN ActOfDiscrepancies AS ActOfDiscrepancies
	|			ON ReturnOfGoodsFromCustomerGoods.Products = ActOfDiscrepancies.Products
	|				AND ReturnOfGoodsFromCustomerGoods.Characteristic = ActOfDiscrepancies.Characteristic
	|				AND ReturnOfGoodsFromCustomerGoods.Purpose = ActOfDiscrepancies.Purpose
	|				AND ReturnOfGoodsFromCustomerGoods.Package = ActOfDiscrepancies.Package
	|				AND ReturnOfGoodsFromCustomerGoods.Series = ActOfDiscrepancies.Series
	|				AND ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus = ActOfDiscrepancies.BatchesIndicationStatus
	|				AND ReturnOfGoodsFromCustomerGoods.RowCode = ActOfDiscrepancies.RowCode
	|				AND ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices = ActOfDiscrepancies.DocumentSalesOfGoodsAndServices
	|				AND ReturnOfGoodsFromCustomerGoods.CCDNumber = ActOfDiscrepancies.CCDNumber
	|				AND ReturnOfGoodsFromCustomerGoods.Warehouse = ActOfDiscrepancies.Warehouse
	|				AND ReturnOfGoodsFromCustomerGoods.VATRate = ActOfDiscrepancies.VATRate
	|	WHERE
	|		ActOfDiscrepancies.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		ReturnOfGoodsFromCustomerGoods.Package,
	|		ReturnOfGoodsFromCustomerGoods.Products,
	|		ReturnOfGoodsFromCustomerGoods.Series,
	|		ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus,
	|		ReturnOfGoodsFromCustomerGoods.Characteristic,
	|		ReturnOfGoodsFromCustomerGoods.Purpose,
	|		ReturnOfGoodsFromCustomerGoods.RowCode,
	|		ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices,
	|		ReturnOfGoodsFromCustomerGoods.CCDNumber,
	|		ReturnOfGoodsFromCustomerGoods.Warehouse,
	|		ReturnOfGoodsFromCustomerGoods.VATRate) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.Warehouse,
	|	NestedQuery.QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose AS Purpose,
	|		ActOfDivergenceSeries.Series AS Series,
	|		ActOfDivergenceSeries.Warehouse AS Warehouse,
	|		SUM(ActOfDivergenceSeries.Count) AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument) AS QuantityBasedOnAct,
	|		SUM(ISNULL(ReturnOfGoodsFromCustomerSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN ReturnOfGoodsFromCustomerSeries AS ReturnOfGoodsFromCustomerSeries
	|			ON ActOfDivergenceSeries.Products  = ReturnOfGoodsFromCustomerSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = ReturnOfGoodsFromCustomerSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = ReturnOfGoodsFromCustomerSeries.Purpose
	|				AND ActOfDivergenceSeries.Series = ReturnOfGoodsFromCustomerSeries.Series
	|				AND ActOfDivergenceSeries.Warehouse = ReturnOfGoodsFromCustomerSeries.Warehouse
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReturnOfGoodsFromCustomerSeries.Products,
	|		ReturnOfGoodsFromCustomerSeries.Characteristic,
	|		ReturnOfGoodsFromCustomerSeries.Purpose,
	|		ReturnOfGoodsFromCustomerSeries.Series,
	|		ReturnOfGoodsFromCustomerSeries.Warehouse,
	|		SUM(0),
	|		SUM(0),
	|		SUM(ReturnOfGoodsFromCustomerSeries.Count)
	|	FROM
	|		ReturnOfGoodsFromCustomerSeries AS ReturnOfGoodsFromCustomerSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON ReturnOfGoodsFromCustomerSeries.Products = ActOfDivergenceSeries.Products
	|				AND ReturnOfGoodsFromCustomerSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND ReturnOfGoodsFromCustomerSeries.Purpose = ActOfDivergenceSeries.Purpose
	|				AND ReturnOfGoodsFromCustomerSeries.Series = ActOfDivergenceSeries.Series
	|				AND ReturnOfGoodsFromCustomerSeries.Warehouse = ActOfDivergenceSeries.Warehouse
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		ReturnOfGoodsFromCustomerSeries.Products,
	|		ReturnOfGoodsFromCustomerSeries.Series,
	|		ReturnOfGoodsFromCustomerSeries.Warehouse,
	|		ReturnOfGoodsFromCustomerSeries.Purpose,
	|		ReturnOfGoodsFromCustomerSeries.Characteristic) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|
	|SELECT DISTINCT
	|	StateGoods.LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|	
	|SELECT
	|	StateGoods.Products,
	|	StateGoods.Characteristic,
	|	StateGoods.Purpose,
	|	StateGoods.Package AS Package,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	StateGoods.Series,
	|	StateGoods.BatchesIndicationStatus,
	|	StateGoods.Price,
	|	StateGoods.Warehouse,
	|	StateGoods.RowCode,
	|	StateGoods.DocumentSalesOfGoodsAndServices,
	|	StateGoods.CCDNumber,
	|	StateGoods.VATRate,
	|	StateGoods.NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////8
	|SELECT
	|	StateOfSeriesGoods.Products,
	|	StateOfSeriesGoods.Characteristic,
	|	StateOfSeriesGoods.Purpose,
	|	StateOfSeriesGoods.Series,
	|	StateOfSeriesGoods.Warehouse,
	|	StateOfSeriesGoods.QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""
	|";
	
EndFunction

Function RequestTextTabularPartsOfReportOnDiscrepanciesAfterAcceptance(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)

	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts AS PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package AS Package,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|	END AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber AS CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode AS RowCode,
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder = UNDEFINED
	|			THEN VALUE(Document.PurchaseOrder.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder
	|	END AS PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate AS VATRate,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VendorPriceKind) AS VendorPriceKind,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price) AS Price,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ToExpenseAs) AS ToExpenseAs,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ExpenseItem) AS ExpenseItem,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DimensionOfExpenses) AS DimensionOfExpenses,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Department) AS Department,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SalesOpportunity) AS SalesOpportunity,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Certificate) AS Certificate,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument
	|		END) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancies
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|	INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentData
	|		ON CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = DocumentData.Ref
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series 
	|	END,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse AS Warehouse,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingReceiptSetOfSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN DiscrepancyReportFollowingReceiptSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument
	|		END) AS Count,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|
	|SELECT ALLOWED 
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.Purpose,
	|	PurchaseOfGoodsServicesGoods.Package,
	|	PurchaseOfGoodsServicesGoods.Series,
	|	PurchaseOfGoodsServicesGoods.CCDNumber,
	|	PurchaseOfGoodsServicesGoods.RowCode,
	|	PurchaseOfGoodsServicesGoods.PurchaseOrder,
	|	PurchaseOfGoodsServicesGoods.Warehouse,
	|	PurchaseOfGoodsServicesGoods.VATRate,
	|	SUM(PurchaseOfGoodsServicesGoods.NumberOfPackages) AS NumberOfPackages
	|INTO PurchaseOfGoodsServicesGoods
	|FROM
	|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|WHERE
	|	PurchaseOfGoodsServicesGoods.Ref = &Basis
	|	AND PurchaseOfGoodsServicesGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	PurchaseOfGoodsServicesGoods.Package,
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.Series,
	|	PurchaseOfGoodsServicesGoods.CCDNumber,
	|	PurchaseOfGoodsServicesGoods.Purpose,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.RowCode,
	|	PurchaseOfGoodsServicesGoods.PurchaseOrder,
	|	PurchaseOfGoodsServicesGoods.Warehouse,
	|	PurchaseOfGoodsServicesGoods.VATRate
	|;
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED
	|	PurchaseOfGoodsServicesSeries.Products,
	|	PurchaseOfGoodsServicesSeries.Characteristic,
	|	PurchaseOfGoodsServicesSeries.Purpose,
	|	PurchaseOfGoodsServicesSeries.Warehouse,
	|	PurchaseOfGoodsServicesSeries.Series,
	|	SUM(PurchaseOfGoodsServicesSeries.Count) AS Count
	|INTO PurchaseOfGoodsServicesSeries
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS PurchaseOfGoodsServicesSeries
	|WHERE
	|	PurchaseOfGoodsServicesSeries.Ref = &Basis
	|	AND PurchaseOfGoodsServicesSeries.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	PurchaseOfGoodsServicesSeries.Products,
	|	PurchaseOfGoodsServicesSeries.Series,
	|	PurchaseOfGoodsServicesSeries.Purpose,
	|	PurchaseOfGoodsServicesSeries.Warehouse,
	|	PurchaseOfGoodsServicesSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.PartnerProducts,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	NestedQuery.RowCode,
	|	NestedQuery.PurchaseOrder,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Price,
	|	NestedQuery.VendorPriceKind,
	|	NestedQuery.ToExpenseAs,
	|	NestedQuery.ExpenseItem,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.Department,
	|	NestedQuery.SalesOpportunity,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.Certificate,
	|	NestedQuery.VATRate,
	|	NestedQuery.NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		ActOfDiscrepancies.Products AS Products,
	|		ActOfDiscrepancies.PartnerProducts AS PartnerProducts,
	|		ActOfDiscrepancies.Characteristic AS Characteristic,
	|		ActOfDiscrepancies.Purpose AS Purpose,
	|		ActOfDiscrepancies.Package AS Package,
	|		ActOfDiscrepancies.Series AS Series,
	|		ActOfDiscrepancies.CCDNumber AS CCDNumber,
	|		ActOfDiscrepancies.RowCode AS RowCode,
	|		ActOfDiscrepancies.PurchaseOrder AS PurchaseOrder,
	|		ActOfDiscrepancies.Warehouse AS Warehouse,
	|		ActOfDiscrepancies.VATRate AS VATRate,
	|		MAX(ActOfDiscrepancies.Price) AS Price,
	|		MAX(ActOfDiscrepancies.VendorPriceKind) AS VendorPriceKind,
	|		MAX(ActOfDiscrepancies.ToExpenseAs) AS ToExpenseAs,
	|		MAX(ActOfDiscrepancies.ExpenseItem) AS ExpenseItem,
	|		MAX(ActOfDiscrepancies.DimensionOfExpenses) AS DimensionOfExpenses,
	|		MAX(ActOfDiscrepancies.Department) AS Department,
	|		MAX(ActOfDiscrepancies.SalesOpportunity) AS SalesOpportunity,
	|		MAX(ActOfDiscrepancies.Certificate) AS Certificate,
	|		SUM(ActOfDiscrepancies.NumberOfPackages) AS NumberOfPackagesAccordingToAct,
	|		SUM(ActOfDiscrepancies.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(PurchaseOfGoodsServicesGoods.NumberOfPackages, 0)) AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancies AS ActOfDiscrepancies
	|			LEFT JOIN PurchaseOfGoodsServicesGoods AS PurchaseOfGoodsServicesGoods
	|			ON ActOfDiscrepancies.Products = PurchaseOfGoodsServicesGoods.Products
	|				AND ActOfDiscrepancies.Characteristic = PurchaseOfGoodsServicesGoods.Characteristic
	|				AND ActOfDiscrepancies.Purpose = PurchaseOfGoodsServicesGoods.Purpose
	|				AND ActOfDiscrepancies.Package = PurchaseOfGoodsServicesGoods.Package
	|				AND ActOfDiscrepancies.Series = PurchaseOfGoodsServicesGoods.Series
	|				AND ActOfDiscrepancies.RowCode = PurchaseOfGoodsServicesGoods.RowCode
	|				AND ActOfDiscrepancies.PurchaseOrder = PurchaseOfGoodsServicesGoods.PurchaseOrder
	|				AND ActOfDiscrepancies.Warehouse = PurchaseOfGoodsServicesGoods.Warehouse
	|				AND ActOfDiscrepancies.VATRate = PurchaseOfGoodsServicesGoods.VATRate
	|				AND ActOfDiscrepancies.CCDNumber = PurchaseOfGoodsServicesGoods.CCDNumber
	|	
	|	GROUP BY
	|		ActOfDiscrepancies.Purpose,
	|		ActOfDiscrepancies.Characteristic,
	|		ActOfDiscrepancies.Series,
	|		ActOfDiscrepancies.CCDNumber,
	|		ActOfDiscrepancies.Package,
	|		ActOfDiscrepancies.Products,
	|		ActOfDiscrepancies.PartnerProducts,
	|		ActOfDiscrepancies.RowCode,
	|		ActOfDiscrepancies.PurchaseOrder,
	|		ActOfDiscrepancies.Warehouse,
	|		ActOfDiscrepancies.VATRate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseOfGoodsServicesGoods.Products,
	|		PurchaseOfGoodsServicesGoods.PartnerProducts,
	|		PurchaseOfGoodsServicesGoods.Characteristic,
	|		PurchaseOfGoodsServicesGoods.Purpose,
	|		PurchaseOfGoodsServicesGoods.Package,
	|		PurchaseOfGoodsServicesGoods.Series,
	|		PurchaseOfGoodsServicesGoods.CCDNumber, 
	|		PurchaseOfGoodsServicesGoods.RowCode,
	|		PurchaseOfGoodsServicesGoods.PurchaseOrder,
	|		PurchaseOfGoodsServicesGoods.Warehouse,
	|		PurchaseOfGoodsServicesGoods.VATRate,
	|		MAX(VALUE(Catalog.VendorPriceTypes.EmptyRef)),
	|		MAX(0),
	|		MAX(FALSE), //ToExpenseAs
	|		MAX(VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)), //ExpenseItem
	|		MAX(UNDEFINED), //DimensionOfExpenses
	|		MAX(VALUE(Catalog.BusinessStructure.EmptyRef)), //Department
	|		MAX(VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)), //SalesOpportunity
	|		MAX(""""), //Certificate
	|		SUM(0),
	|		SUM(0),
	|		SUM(PurchaseOfGoodsServicesGoods.NumberOfPackages)
	|	FROM
	|		PurchaseOfGoodsServicesGoods AS PurchaseOfGoodsServicesGoods
	|			LEFT JOIN ActOfDiscrepancies AS ActOfDiscrepancies
	|			ON PurchaseOfGoodsServicesGoods.Products = ActOfDiscrepancies.Products
	|				AND PurchaseOfGoodsServicesGoods.Characteristic = ActOfDiscrepancies.Characteristic
	|				AND PurchaseOfGoodsServicesGoods.Purpose = ActOfDiscrepancies.Purpose
	|				AND PurchaseOfGoodsServicesGoods.Package = ActOfDiscrepancies.Package
	|				AND PurchaseOfGoodsServicesGoods.Series = ActOfDiscrepancies.Series
	|				AND PurchaseOfGoodsServicesGoods.RowCode = ActOfDiscrepancies.RowCode
	|				AND PurchaseOfGoodsServicesGoods.PurchaseOrder = ActOfDiscrepancies.PurchaseOrder
	|				AND PurchaseOfGoodsServicesGoods.Warehouse = ActOfDiscrepancies.Warehouse
	|				AND PurchaseOfGoodsServicesGoods.VATRate = ActOfDiscrepancies.VATRate
	|				AND PurchaseOfGoodsServicesGoods.CCDNumber = ActOfDiscrepancies.CCDNumber
	|	WHERE
	|		ActOfDiscrepancies.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		PurchaseOfGoodsServicesGoods.Package,
	|		PurchaseOfGoodsServicesGoods.Products,
	|		PurchaseOfGoodsServicesGoods.PartnerProducts,
	|		PurchaseOfGoodsServicesGoods.Series,
	|		PurchaseOfGoodsServicesGoods.CCDNumber,
	|		PurchaseOfGoodsServicesGoods.Purpose,
	|		PurchaseOfGoodsServicesGoods.Characteristic,
	|		PurchaseOfGoodsServicesGoods.RowCode,
	|		PurchaseOfGoodsServicesGoods.PurchaseOrder,
	|		PurchaseOfGoodsServicesGoods.Warehouse,
	|		PurchaseOfGoodsServicesGoods.VATRate) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Series,
	|	NestedQuery.QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose AS Purpose,
	|		ActOfDivergenceSeries.Warehouse AS Warehouse,
	|		ActOfDivergenceSeries.Series AS Series,
	|		SUM(ActOfDivergenceSeries.Count) AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument) AS QuantityBasedOnAct,
	|		SUM(ISNULL(PurchaseOfGoodsServicesSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN PurchaseOfGoodsServicesSeries AS PurchaseOfGoodsServicesSeries
	|			ON ActOfDivergenceSeries.Products = PurchaseOfGoodsServicesSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = PurchaseOfGoodsServicesSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = PurchaseOfGoodsServicesSeries.Purpose
	|				AND ActOfDivergenceSeries.Warehouse = PurchaseOfGoodsServicesSeries.Warehouse
	|				AND ActOfDivergenceSeries.Series = PurchaseOfGoodsServicesSeries.Series
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseOfGoodsServicesSeries.Products,
	|		PurchaseOfGoodsServicesSeries.Characteristic,
	|		PurchaseOfGoodsServicesSeries.Purpose,
	|		PurchaseOfGoodsServicesSeries.Warehouse,
	|		PurchaseOfGoodsServicesSeries.Series,
	|		SUM(0),
	|		SUM(0),
	|		SUM(PurchaseOfGoodsServicesSeries.Count)
	|	FROM
	|		PurchaseOfGoodsServicesSeries AS PurchaseOfGoodsServicesSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON PurchaseOfGoodsServicesSeries.Products = ActOfDivergenceSeries.Products
	|				AND PurchaseOfGoodsServicesSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND PurchaseOfGoodsServicesSeries.Purpose = ActOfDivergenceSeries.Purpose
	|				AND PurchaseOfGoodsServicesSeries.Warehouse = ActOfDivergenceSeries.Warehouse
	|				AND PurchaseOfGoodsServicesSeries.Series = ActOfDivergenceSeries.Series
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		PurchaseOfGoodsServicesSeries.Products,
	|		PurchaseOfGoodsServicesSeries.Series,
	|		PurchaseOfGoodsServicesSeries.Purpose,
	|		PurchaseOfGoodsServicesSeries.Warehouse,
	|		PurchaseOfGoodsServicesSeries.Characteristic) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT DISTINCT
	|	StateGoods.LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|	
	|SELECT
	|	StateGoods.Products,
	|	StateGoods.PartnerProducts,
	|	StateGoods.Characteristic,
	|	StateGoods.Purpose,
	|	StateGoods.Package AS Package,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	StateGoods.Series,
	|	StateGoods.Warehouse,
	|	StateGoods.Price,
	|	StateGoods.VendorPriceKind,
	|	StateGoods.RowCode,
	|	StateGoods.PurchaseOrder,
	|	StateGoods.VATRate,
	|	StateGoods.ToExpenseAs,
	|	StateGoods.ExpenseItem,
	|	StateGoods.DimensionOfExpenses,
	|	StateGoods.Department,
	|	StateGoods.SalesOpportunity,
	|	StateGoods.CCDNumber,
	|	StateGoods.Certificate,
	|	StateGoods.NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StateOfSeriesGoods.Products,
	|	StateOfSeriesGoods.Characteristic,
	|	StateOfSeriesGoods.Purpose,
	|	StateOfSeriesGoods.Series,
	|	StateOfSeriesGoods.Warehouse,
	|	StateOfSeriesGoods.QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""
	|";
	
EndFunction

Function RequestTextTabularPartsOfDiscrepancyReportAfterReceipt(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)
	
	// It is required to add or decrease the quantity in the Receipt. To bring the quantity in the Receipt to the level of the PTiU,
	// since in the considered options of actions the PTiU remains unchanged.
	
	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts AS PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber AS CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate AS VATRate,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price) AS Price,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancies
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef)
	|	)
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse
	|
	|HAVING
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages) <> SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse AS Warehouse,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.Count) AS Count,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Action IN (
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef)
	|	)
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic
	|
	|HAVING
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.Count) <> SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|
	|SELECT ALLOWED 
	|	ReceiptOfGoodsInWarehouseGoods.Products,
	|	ReceiptOfGoodsInWarehouseGoods.PartnerProducts,
	|	ReceiptOfGoodsInWarehouseGoods.Characteristic,
	|	ReceiptOfGoodsInWarehouseGoods.Purpose,
	|	ReceiptOfGoodsInWarehouseGoods.Package,
	|	ReceiptOfGoodsInWarehouseGoods.Series,
	|	ReceiptOfGoodsInWarehouseGoods.CCDNumber,
	|	ReceiptOfGoodsInWarehouseGoods.Ref.Warehouse,
	|	ReceiptOfGoodsInWarehouseGoods.VATRate,
	|	SUM(ReceiptOfGoodsInWarehouseGoods.NumberOfPackages) AS NumberOfPackages
	|INTO ReceiptOfGoodsInWarehouseGoods
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS ReceiptOfGoodsInWarehouseGoods
	|		INNER JOIN ActOfDiscrepancies AS FilteringByItem
	|		ON ReceiptOfGoodsInWarehouseGoods.Products = FilteringByItem.Products
	|			AND ReceiptOfGoodsInWarehouseGoods.Characteristic = FilteringByItem.Characteristic
	|			AND ReceiptOfGoodsInWarehouseGoods.Purpose = FilteringByItem.Purpose
	|WHERE
	|	ReceiptOfGoodsInWarehouseGoods.Ref = &Basis
	|
	|GROUP BY
	|	ReceiptOfGoodsInWarehouseGoods.Package,
	|	ReceiptOfGoodsInWarehouseGoods.Products,
	|	ReceiptOfGoodsInWarehouseGoods.PartnerProducts,
	|	ReceiptOfGoodsInWarehouseGoods.Series,
	|	ReceiptOfGoodsInWarehouseGoods.CCDNumber,
	|	ReceiptOfGoodsInWarehouseGoods.Purpose,
	|	ReceiptOfGoodsInWarehouseGoods.Characteristic,
	|	ReceiptOfGoodsInWarehouseGoods.Ref.Warehouse,
	|	ReceiptOfGoodsInWarehouseGoods.VATRate
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED
	|	ReceiptOfGoodsInWarehouseOfSeries.Products,
	|	ReceiptOfGoodsInWarehouseOfSeries.Characteristic,
	|	ReceiptOfGoodsInWarehouseOfSeries.Purpose,
	|	ReceiptOfGoodsInWarehouseOfSeries.Ref.Warehouse,
	|	ReceiptOfGoodsInWarehouseOfSeries.Series,
	|	SUM(ReceiptOfGoodsInWarehouseOfSeries.Count) AS Count
	|INTO ReceiptOfGoodsInWarehouseOfSeries
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.SetOfSeries AS ReceiptOfGoodsInWarehouseOfSeries
	|		INNER JOIN ActOfDiscrepancies AS FilteringByItem
	|		ON ReceiptOfGoodsInWarehouseOfSeries.Products = FilteringByItem.Products
	|			AND ReceiptOfGoodsInWarehouseOfSeries.Characteristic = FilteringByItem.Characteristic
	|			AND ReceiptOfGoodsInWarehouseOfSeries.Purpose = FilteringByItem.Purpose
	|WHERE
	|	ReceiptOfGoodsInWarehouseOfSeries.Ref = &Basis
	|
	|GROUP BY
	|	ReceiptOfGoodsInWarehouseOfSeries.Products,
	|	ReceiptOfGoodsInWarehouseOfSeries.Series,
	|	ReceiptOfGoodsInWarehouseOfSeries.Purpose,
	|	ReceiptOfGoodsInWarehouseOfSeries.Ref.Warehouse,
	|	ReceiptOfGoodsInWarehouseOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|
	|SELECT DISTINCT
	|	NestedQuery.Products AS Products,
	|	NestedQuery.PartnerProducts AS PartnerProducts,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Package AS Package,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.Warehouse AS Warehouse,
	|	NestedQuery.Price AS Price,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	NestedQuery.VATRate AS VATRate,
	// Substitution of the quantity in the Quantity of Packages field for the act to bring the Receipt document
	// to the quantity of the PTIU document.
	|	NestedQuery.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase AS NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesAccordingToAct
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesOnBasisOfAct
	|			THEN ""ChangesAreMade""
	// A simplified scheme without the status of "Basis does not correspond to the act" because the act does not cache the amount
	// of receipt in the same way as it caches the amount from the PTiU.
	|		ELSE
	|			""ChangesRequired""
	|	END AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		ActOfDiscrepancies.Products AS Products,
	|		ActOfDiscrepancies.PartnerProducts AS PartnerProducts,
	|		ActOfDiscrepancies.Characteristic AS Characteristic,
	|		ActOfDiscrepancies.Purpose AS Purpose,
	|		ActOfDiscrepancies.Package AS Package,
	|		ActOfDiscrepancies.Series AS Series,
	|		ActOfDiscrepancies.CCDNumber AS CCDNumber,
	|		ActOfDiscrepancies.Warehouse AS Warehouse,
	|		ActOfDiscrepancies.VATRate AS VATRate,
	|		MAX(ActOfDiscrepancies.Price) AS Price,
	|		SUM(ActOfDiscrepancies.NumberOfPackages) AS NumberOfPackagesAccordingToAct,
	|		SUM(ActOfDiscrepancies.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(PurchaseOfGoodsServicesGoods.NumberOfPackages, 0)) AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancies AS ActOfDiscrepancies
	|			LEFT JOIN ReceiptOfGoodsInWarehouseGoods AS PurchaseOfGoodsServicesGoods
	|			ON ActOfDiscrepancies.Products = PurchaseOfGoodsServicesGoods.Products
	|				AND ActOfDiscrepancies.Characteristic = PurchaseOfGoodsServicesGoods.Characteristic
	|				AND ActOfDiscrepancies.Purpose = PurchaseOfGoodsServicesGoods.Purpose
	|				AND ActOfDiscrepancies.Package = PurchaseOfGoodsServicesGoods.Package
	|				AND ActOfDiscrepancies.Series = PurchaseOfGoodsServicesGoods.Series
	|				AND ActOfDiscrepancies.Warehouse = PurchaseOfGoodsServicesGoods.Warehouse
	|				AND ActOfDiscrepancies.CCDNumber = PurchaseOfGoodsServicesGoods.CCDNumber
	|	
	|	GROUP BY
	|		ActOfDiscrepancies.Purpose,
	|		ActOfDiscrepancies.Characteristic,
	|		ActOfDiscrepancies.Series,
	|		ActOfDiscrepancies.CCDNumber,
	|		ActOfDiscrepancies.Package,
	|		ActOfDiscrepancies.Products,
	|		ActOfDiscrepancies.PartnerProducts,
	|		ActOfDiscrepancies.Warehouse,
	|		ActOfDiscrepancies.VATRate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseOfGoodsServicesGoods.Products,
	|		PurchaseOfGoodsServicesGoods.PartnerProducts,
	|		PurchaseOfGoodsServicesGoods.Characteristic,
	|		PurchaseOfGoodsServicesGoods.Purpose,
	|		PurchaseOfGoodsServicesGoods.Package,
	|		PurchaseOfGoodsServicesGoods.Series,
	|		PurchaseOfGoodsServicesGoods.CCDNumber,
	|		PurchaseOfGoodsServicesGoods.Warehouse,
	|		PurchaseOfGoodsServicesGoods.VATRate,
	|		MAX(VALUE(Catalog.VendorPriceTypes.EmptyRef)),
	|		SUM(0),
	|		SUM(0),
	|		SUM(PurchaseOfGoodsServicesGoods.NumberOfPackages)
	|	FROM
	|		ReceiptOfGoodsInWarehouseGoods AS PurchaseOfGoodsServicesGoods
	|			LEFT JOIN ActOfDiscrepancies AS ActOfDiscrepancies
	|			ON PurchaseOfGoodsServicesGoods.Products = ActOfDiscrepancies.Products
	|				AND PurchaseOfGoodsServicesGoods.Characteristic = ActOfDiscrepancies.Characteristic
	|				AND PurchaseOfGoodsServicesGoods.Purpose = ActOfDiscrepancies.Purpose
	|				AND PurchaseOfGoodsServicesGoods.Package = ActOfDiscrepancies.Package
	|				AND PurchaseOfGoodsServicesGoods.Series = ActOfDiscrepancies.Series
	|				AND PurchaseOfGoodsServicesGoods.Warehouse = ActOfDiscrepancies.Warehouse
	|				AND PurchaseOfGoodsServicesGoods.CCDNumber = ActOfDiscrepancies.CCDNumber
	|	WHERE
	|		ActOfDiscrepancies.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		PurchaseOfGoodsServicesGoods.Package,
	|		PurchaseOfGoodsServicesGoods.Products,
	|		PurchaseOfGoodsServicesGoods.PartnerProducts,
	|		PurchaseOfGoodsServicesGoods.Series,
	|		PurchaseOfGoodsServicesGoods.CCDNumber,
	|		PurchaseOfGoodsServicesGoods.Purpose,
	|		PurchaseOfGoodsServicesGoods.Characteristic,
	|		PurchaseOfGoodsServicesGoods.Warehouse,
	|		PurchaseOfGoodsServicesGoods.VATRate) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|
	|SELECT DISTINCT
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Warehouse AS Warehouse,
	|	NestedQuery.Series AS Series,
	// Substitution of the quantity in the Quantity of Packages field for the act to bring the Receipt document
	// to the quantity of the PTIU document.
	|	NestedQuery.QuantityBasedOnAct AS QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_ AS QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityByAct
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBasedOnAct
	|			THEN ""ChangesAreMade""
	|		ELSE
	|			""ChangesRequired""
	|	END AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose AS Purpose,
	|		ActOfDivergenceSeries.Warehouse AS Warehouse,
	|		ActOfDivergenceSeries.Series AS Series,
	|		SUM(ActOfDivergenceSeries.Count) AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument) AS QuantityBasedOnAct,
	|		SUM(ISNULL(PurchaseOfGoodsServicesSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN ReceiptOfGoodsInWarehouseOfSeries AS PurchaseOfGoodsServicesSeries
	|			ON ActOfDivergenceSeries.Products = PurchaseOfGoodsServicesSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = PurchaseOfGoodsServicesSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = PurchaseOfGoodsServicesSeries.Purpose
	|				AND ActOfDivergenceSeries.Warehouse = PurchaseOfGoodsServicesSeries.Warehouse
	|				AND ActOfDivergenceSeries.Series = PurchaseOfGoodsServicesSeries.Series
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseOfGoodsServicesSeries.Products,
	|		PurchaseOfGoodsServicesSeries.Characteristic,
	|		PurchaseOfGoodsServicesSeries.Purpose,
	|		PurchaseOfGoodsServicesSeries.Warehouse,
	|		PurchaseOfGoodsServicesSeries.Series,
	|		SUM(0),
	|		SUM(0),
	|		SUM(PurchaseOfGoodsServicesSeries.Count)
	|	FROM
	|		ReceiptOfGoodsInWarehouseOfSeries AS PurchaseOfGoodsServicesSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON PurchaseOfGoodsServicesSeries.Products = ActOfDivergenceSeries.Products
	|				AND PurchaseOfGoodsServicesSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND PurchaseOfGoodsServicesSeries.Purpose = ActOfDivergenceSeries.Purpose
	|				AND PurchaseOfGoodsServicesSeries.Warehouse = ActOfDivergenceSeries.Warehouse
	|				AND PurchaseOfGoodsServicesSeries.Series = ActOfDivergenceSeries.Series
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		PurchaseOfGoodsServicesSeries.Products,
	|		PurchaseOfGoodsServicesSeries.Series,
	|		PurchaseOfGoodsServicesSeries.Purpose,
	|		PurchaseOfGoodsServicesSeries.Warehouse,
	|		PurchaseOfGoodsServicesSeries.Characteristic) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT DISTINCT
	|	StateGoods.LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|	
	|SELECT
	|	StateGoods.Products,
	|	StateGoods.PartnerProducts,
	|	StateGoods.Characteristic,
	|	StateGoods.Purpose,
	|	StateGoods.Package AS Package,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	StateGoods.Series,
	|	StateGoods.Warehouse,
	|	StateGoods.Price,
	|	StateGoods.VATRate,
	|	StateGoods.CCDNumber,
	|	StateGoods.NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StateOfSeriesGoods.Products,
	|	StateOfSeriesGoods.Characteristic,
	|	StateOfSeriesGoods.Purpose,
	|	StateOfSeriesGoods.Series,
	|	StateOfSeriesGoods.Warehouse,
	|	StateOfSeriesGoods.QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""
	|";
	
EndFunction

Function RequestTextForShippingGoodsFromStorageHeader(Basis)
	
	Return "
	|SELECT ALLOWED
	|	GoodsShipmentFromStorage.Partner                           AS Partner,
	|	GoodsShipmentFromStorage.Counterparty                        AS Counterparty,
	|	GoodsShipmentFromStorage.Terms                        AS Terms,
	|	GoodsShipmentFromStorage.Contract                           AS Contract,
	|	GoodsShipmentFromStorage.Organization                       AS Organization,
	|	GoodsShipmentFromStorage.BusinessOperation             AS BusinessOperation,
	|	GoodsShipmentFromStorage.Currency                            AS Currency,
	|	FALSE                                                       AS PriceIncludesVAT,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	GoodsShipmentFromStorage.Posted                          AS Posted
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|WHERE
	|	GoodsShipmentFromStorage.Ref = &Basis";
	
EndFunction

Function RequestTextForTransferOfGoodsToCustodianHeader(Basis)
	
	Return "
	|SELECT ALLOWED
	|	GoodsHandover.Partner               AS Partner,
	|	GoodsHandover.Counterparty            AS Counterparty,
	|	GoodsHandover.Terms            AS Terms,
	|	GoodsHandover.Contract               AS Contract,
	|	GoodsHandover.Organization           AS Organization,
	|	GoodsHandover.BusinessOperation AS BusinessOperation,
	|	GoodsHandover.Currency                AS Currency,
	|	FALSE                                  AS PriceIncludesVAT,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	GoodsHandover.Posted              AS Posted
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|WHERE
	|	GoodsHandover.Ref = &Basis";
	
EndFunction

Function RequestTextForReceiptOfGoodsFromCustodianHeader(Basis)
	
	Return "
	|SELECT ALLOWED
	|	ReceiptFromTheCustodian.Partner                                       AS Partner,
	|	ReceiptFromTheCustodian.Counterparty                                    AS Counterparty,
	|	ReceiptFromTheCustodian.Terms                                    AS Terms,
	|	ReceiptFromTheCustodian.Contract                                       AS Contract,
	|	ReceiptFromTheCustodian.Organization                                   AS Organization,
	|	ReceiptFromTheCustodian.BusinessOperation                         AS BusinessOperation,
	|	ReceiptFromTheCustodian.Currency                                        AS Currency,
	|	FALSE                                                                 AS PriceIncludesVAT,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)           AS VATTaxation,
	|	ReceiptFromTheCustodian.Posted                                      AS Posted
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|WHERE
	|	ReceiptFromTheCustodian.Ref = &Basis";
	
EndFunction

Function RequestTextForAcceptanceOfGoodsForStorageHeader(Basis)
	
	Return "
	|SELECT ALLOWED
	|	GoodsReceiptForStorage.Organization                                 AS Organization,
	|	GoodsReceiptForStorage.Partner                                     AS Partner,
	|	GoodsReceiptForStorage.Counterparty                                  AS Counterparty,
	|	GoodsReceiptForStorage.Terms                                  AS Terms,
	|	GoodsReceiptForStorage.Currency                                      AS Currency,
	|	GoodsReceiptForStorage.BusinessOperation                       AS BusinessOperation,
	|	GoodsReceiptForStorage.Contract                                     AS Contract,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)           AS VATTaxation,
	|	UNDEFINED                                                         AS PriceIncludesVAT,
	|	GoodsReceiptForStorage.Posted                                    AS Posted
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|WHERE
	|	GoodsReceiptForStorage.Ref = &Basis";
	
EndFunction

Function RequestTextTabularPartsOfReportOnDiscrepanciesAfterShipmentAndShipmentFromStorage(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)
	
	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products                         AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic                       AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package                             AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose                           AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder                         AS SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode                            AS RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series                                AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow                  AS DocumentInflow,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price                                 AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse                                AS Warehouse,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|		END)                                                               AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancyDuringShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products                 AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic               AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose                   AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series                        AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse                        AS Warehouse,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingShipmentSetOfSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN DiscrepancyReportFollowingShipmentSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument
	|		END)                                                      AS Count,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS CountByDocument
	|
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED 
	|	ShipmentOfGoodsFromStorageGoods.Products              AS Products,
	|	ShipmentOfGoodsFromStorageGoods.Characteristic            AS Characteristic,
	|	ShipmentOfGoodsFromStorageGoods.Package                  AS Package,
	|	ShipmentOfGoodsFromStorageGoods.Purpose                AS Purpose,
	|	ShipmentOfGoodsFromStorageGoods.SalesOrder              AS SalesOrder,
	|	ShipmentOfGoodsFromStorageGoods.RowCode                 AS RowCode,
	|	ShipmentOfGoodsFromStorageGoods.Series                     AS Series,
	|	ShipmentOfGoodsFromStorageGoods.DocumentInflow       AS DocumentInflow,
	|	SUM(ShipmentOfGoodsFromStorageGoods.NumberOfPackages) AS NumberOfPackages,
	|	ShipmentOfGoodsFromStorageGoods.Price                      AS Price,
	|	ShipmentOfGoodsFromStorageGoods.Warehouse                     AS Warehouse
	|
	|INTO GoodsShipmentFromStorage
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS ShipmentOfGoodsFromStorageGoods
	|WHERE
	|	ShipmentOfGoodsFromStorageGoods.Ref = &Basis
	|
	|GROUP BY
	|	ShipmentOfGoodsFromStorageGoods.Products,
	|	ShipmentOfGoodsFromStorageGoods.Characteristic,
	|	ShipmentOfGoodsFromStorageGoods.Package,
	|	ShipmentOfGoodsFromStorageGoods.Purpose,
	|	ShipmentOfGoodsFromStorageGoods.SalesOrder,
	|	ShipmentOfGoodsFromStorageGoods.RowCode,
	|	ShipmentOfGoodsFromStorageGoods.Series,
	|	ShipmentOfGoodsFromStorageGoods.DocumentInflow,
	|	ShipmentOfGoodsFromStorageGoods.Price,
	|	ShipmentOfGoodsFromStorageGoods.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package,
	|	Purpose,
	|	SalesOrder,
	|	RowCode,
	|	Series,
	|	DocumentInflow,
	|	Price,
	|	Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED
	|	ShipmentOfGoodsFromSeriesStorage.Products      AS Products,
	|	ShipmentOfGoodsFromSeriesStorage.Characteristic    AS Characteristic,
	|	ShipmentOfGoodsFromSeriesStorage.Purpose        AS Purpose,
	|	ShipmentOfGoodsFromSeriesStorage.Series             AS Series,
	|	ShipmentOfGoodsFromSeriesStorage.Warehouse             AS Warehouse,
	|	SUM(ShipmentOfGoodsFromSeriesStorage.Count) AS Count
	|
	|INTO ShipmentOfGoodsFromSeriesStorage
	|FROM
	|	Document.GoodsShipmentFromStorage.SetOfSeries AS ShipmentOfGoodsFromSeriesStorage
	|WHERE
	|	ShipmentOfGoodsFromSeriesStorage.Ref = &Basis
	|
	|GROUP BY
	|	ShipmentOfGoodsFromSeriesStorage.Products,
	|	ShipmentOfGoodsFromSeriesStorage.Characteristic,
	|	ShipmentOfGoodsFromSeriesStorage.Purpose,
	|	ShipmentOfGoodsFromSeriesStorage.Series,
	|	ShipmentOfGoodsFromSeriesStorage.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT DISTINCT
	|	NestedQuery.Products                     AS Products,
	|	NestedQuery.Characteristic                   AS Characteristic,
	|	NestedQuery.Package                         AS Package,
	|	NestedQuery.Purpose                       AS Purpose,
	|	NestedQuery.SalesOrder                     AS SalesOrder,
	|	NestedQuery.RowCode                        AS RowCode,
	|	NestedQuery.Series                            AS Series,
	|	NestedQuery.DocumentInflow              AS DocumentInflow,
	|	NestedQuery.Price                             AS Price,
	|	NestedQuery.Warehouse                            AS Warehouse,
	|	NestedQuery.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase      AS NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                            AS LineState
	|
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products                         AS Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic                       AS Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package                             AS Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose                           AS Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder                         AS SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode                            AS RowCode,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series                                AS Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow                  AS DocumentInflow,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Price                                 AS Price,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse                                AS Warehouse,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages)            AS NumberOfPackagesAccordingToAct,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(ShipmentOfGoodsFromStorageGoods.NumberOfPackages, 0))    AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			LEFT JOIN GoodsShipmentFromStorage AS ShipmentOfGoodsFromStorageGoods
	|			ON CertificateOfDiscrepanciesAfterShipmentOfGoods.Products = ShipmentOfGoodsFromStorageGoods.Products
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic = ShipmentOfGoodsFromStorageGoods.Characteristic
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose = ShipmentOfGoodsFromStorageGoods.Purpose
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = ShipmentOfGoodsFromStorageGoods.SalesOrder
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = ShipmentOfGoodsFromStorageGoods.RowCode
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Package = ShipmentOfGoodsFromStorageGoods.Package
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Series = ShipmentOfGoodsFromStorageGoods.Series
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow = ShipmentOfGoodsFromStorageGoods.DocumentInflow
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Price = ShipmentOfGoodsFromStorageGoods.Price
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse     = ShipmentOfGoodsFromStorageGoods.Warehouse
	|	
	|	GROUP BY
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShipmentOfGoodsFromStorageGoods.Products,
	|		ShipmentOfGoodsFromStorageGoods.Characteristic,
	|		ShipmentOfGoodsFromStorageGoods.Package,
	|		ShipmentOfGoodsFromStorageGoods.Purpose,
	|		ShipmentOfGoodsFromStorageGoods.SalesOrder,
	|		ShipmentOfGoodsFromStorageGoods.RowCode,
	|		ShipmentOfGoodsFromStorageGoods.Series,
	|		ShipmentOfGoodsFromStorageGoods.DocumentInflow,
	|		ShipmentOfGoodsFromStorageGoods.Price,
	|		ShipmentOfGoodsFromStorageGoods.Warehouse,
	|		SUM(0),
	|		SUM(0),
	|		SUM(ShipmentOfGoodsFromStorageGoods.NumberOfPackages)
	|	FROM
	|		GoodsShipmentFromStorage AS ShipmentOfGoodsFromStorageGoods
	|			LEFT JOIN ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			ON ShipmentOfGoodsFromStorageGoods.Products = CertificateOfDiscrepanciesAfterShipmentOfGoods.Products
	|				AND ShipmentOfGoodsFromStorageGoods.Characteristic = CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic
	|				AND ShipmentOfGoodsFromStorageGoods.Purpose = CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose
	|				AND ShipmentOfGoodsFromStorageGoods.SalesOrder = CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder
	|				AND ShipmentOfGoodsFromStorageGoods.RowCode = CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|				AND ShipmentOfGoodsFromStorageGoods.Package = CertificateOfDiscrepanciesAfterShipmentOfGoods.Package
	|				AND ShipmentOfGoodsFromStorageGoods.Series = CertificateOfDiscrepanciesAfterShipmentOfGoods.Series
	|				AND ShipmentOfGoodsFromStorageGoods.DocumentInflow = CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow
	|				AND ShipmentOfGoodsFromStorageGoods.Price = CertificateOfDiscrepanciesAfterShipmentOfGoods.Price
	|				AND ShipmentOfGoodsFromStorageGoods.Warehouse = CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|	WHERE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		ShipmentOfGoodsFromStorageGoods.Products,
	|		ShipmentOfGoodsFromStorageGoods.Characteristic,
	|		ShipmentOfGoodsFromStorageGoods.Package,
	|		ShipmentOfGoodsFromStorageGoods.Purpose,
	|		ShipmentOfGoodsFromStorageGoods.SalesOrder,
	|		ShipmentOfGoodsFromStorageGoods.RowCode,
	|		ShipmentOfGoodsFromStorageGoods.Series,
	|		ShipmentOfGoodsFromStorageGoods.DocumentInflow,
	|		ShipmentOfGoodsFromStorageGoods.Price,
	|		ShipmentOfGoodsFromStorageGoods.Warehouse) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT DISTINCT
	|	NestedQuery.Products             AS Products,
	|	NestedQuery.Characteristic           AS Characteristic,
	|	NestedQuery.Purpose               AS Purpose,
	|	NestedQuery.Series                    AS Series,
	|	NestedQuery.Warehouse                    AS Warehouse,
	|	NestedQuery.QuantityByAct         AS QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_      AS QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                    AS LineState
	|
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products                           AS Products,
	|		ActOfDivergenceSeries.Characteristic                         AS Characteristic,
	|		ActOfDivergenceSeries.Purpose                             AS Purpose,
	|		ActOfDivergenceSeries.Series                                  AS Series,
	|		ActOfDivergenceSeries.Warehouse                                  AS Warehouse,
	|		SUM(ActOfDivergenceSeries.Count)                      AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument)           AS QuantityBasedOnAct,
	|		SUM(ISNULL(ShipmentOfGoodsFromSeriesStorage.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN ShipmentOfGoodsFromSeriesStorage AS ShipmentOfGoodsFromSeriesStorage
	|			ON ActOfDivergenceSeries.Products = ShipmentOfGoodsFromSeriesStorage.Products
	|				AND ActOfDivergenceSeries.Characteristic = ShipmentOfGoodsFromSeriesStorage.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = ShipmentOfGoodsFromSeriesStorage.Purpose
	|				AND ActOfDivergenceSeries.Series = ShipmentOfGoodsFromSeriesStorage.Series
	|				AND ActOfDivergenceSeries.Warehouse = ShipmentOfGoodsFromSeriesStorage.Warehouse
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Products,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShipmentOfGoodsFromSeriesStorage.Products,
	|		ShipmentOfGoodsFromSeriesStorage.Characteristic,
	|		ShipmentOfGoodsFromSeriesStorage.Purpose,
	|		ShipmentOfGoodsFromSeriesStorage.Series,
	|		ShipmentOfGoodsFromSeriesStorage.Warehouse,
	|		SUM(0),
	|		SUM(0),
	|		SUM(ShipmentOfGoodsFromSeriesStorage.Count)
	|	FROM
	|		ShipmentOfGoodsFromSeriesStorage AS ShipmentOfGoodsFromSeriesStorage
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON ShipmentOfGoodsFromSeriesStorage.Products = ActOfDivergenceSeries.Products
	|				AND ShipmentOfGoodsFromSeriesStorage.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND ShipmentOfGoodsFromSeriesStorage.Purpose = ActOfDivergenceSeries.Purpose
	|				AND ShipmentOfGoodsFromSeriesStorage.Series = ActOfDivergenceSeries.Series
	|				AND ShipmentOfGoodsFromSeriesStorage.Warehouse = ActOfDivergenceSeries.Warehouse
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		ShipmentOfGoodsFromSeriesStorage.Products,
	|		ShipmentOfGoodsFromSeriesStorage.Characteristic,
	|		ShipmentOfGoodsFromSeriesStorage.Purpose,
	|		ShipmentOfGoodsFromSeriesStorage.Series,
	|		ShipmentOfGoodsFromSeriesStorage.Warehouse) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT DISTINCT
	|	StateGoods.LineState AS LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION ALL
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|SELECT
	|	StateGoods.Products                     AS Products,
	|	StateGoods.Characteristic                   AS Characteristic,
	|	StateGoods.Package                         AS Package,
	|	StateGoods.Purpose                       AS Purpose,
	|	StateGoods.SalesOrder                     AS SalesOrder,
	|	StateGoods.RowCode                        AS RowCode,
	|	StateGoods.Series                            AS Series,
	|	StateGoods.DocumentInflow              AS DocumentInflow,
	|	ISNULL(&QueryTextPackagingFactor, 1)    AS PackagingFactor,
	|	StateGoods.Price                             AS Price,
	|	StateGoods.Warehouse                            AS Warehouse,
	|	StateGoods.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase      AS NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////8
	|SELECT
	|	StateOfSeriesGoods.Products             AS Products,
	|	StateOfSeriesGoods.Characteristic           AS Characteristic,
	|	StateOfSeriesGoods.Purpose               AS Purpose,
	|	StateOfSeriesGoods.Series                    AS Series,
	|	StateOfSeriesGoods.Warehouse                    AS Warehouse,
	|	StateOfSeriesGoods.QuantityByAct         AS QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_      AS QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""";
	
EndFunction

Function RequestTextTabularPartsOfDiscrepancyReportAfterShipmentAndTransferToCustodian(DiscrepancyCertificate,
																				Basis,
																				ReturnStructure,
																				DocumentModification)
	
	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products      AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic    AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package          AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose        AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series             AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.PriceKind) AS PriceKind,
	|	MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.Price)    AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse             AS Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder      AS SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode         AS RowCode,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|					VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|					VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|					VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|		END)                                                               AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|INTO ActOfDiscrepancyDuringShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package,
	|	Purpose,
	|	Series,
	|	SalesOrder,
	|	RowCode,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products   AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose     AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series          AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse          AS Warehouse,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingShipmentSetOfSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired), VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|				THEN DiscrepancyReportFollowingShipmentSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument
	|		END)                                                      AS Count,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	GoodsHandover.Products   AS Products,
	|	GoodsHandover.Characteristic AS Characteristic,
	|	GoodsHandover.Package       AS Package,
	|	GoodsHandover.Purpose     AS Purpose,
	|	CASE
	|		WHEN GoodsHandover.BatchesIndicationStatusInWarehouses = 0
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsHandover.Series
	|	END                          AS Series,
	|	GoodsHandover.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatus,
	|	SUM(GoodsHandover.NumberOfPackages) AS NumberOfPackages,
	|	GoodsHandover.SalesOrder   AS SalesOrder,
	|	GoodsHandover.RowCode      AS RowCode,
	|	GoodsHandover.Warehouse          AS Warehouse
	|INTO TransferOfGoodsToBailee
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsHandover
	|WHERE
	|	GoodsHandover.Ref = &Basis
	|
	|GROUP BY
	|	GoodsHandover.Products,
	|	GoodsHandover.Characteristic,
	|	GoodsHandover.Package,
	|	GoodsHandover.Purpose,
	|	CASE
	|		WHEN GoodsHandover.BatchesIndicationStatusInWarehouses = 0
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsHandover.Series
	|	END,
	|	GoodsHandover.BatchesIndicationStatusInWarehouses,
	|	GoodsHandover.SalesOrder,
	|	GoodsHandover.RowCode,
	|	GoodsHandover.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package,
	|	Purpose,
	|	Series,
	|	SalesOrder,
	|	RowCode,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT ALLOWED
	|	TransferOfGoodsSeries.Products      AS Products,
	|	TransferOfGoodsSeries.Characteristic    AS Characteristic,
	|	TransferOfGoodsSeries.Purpose        AS Purpose,
	|	TransferOfGoodsSeries.Series             AS Series,
	|	TransferOfGoodsSeries.Warehouse             AS Warehouse,
	|	SUM(TransferOfGoodsSeries.Count) AS Count
	|INTO TransferOfGoodsToSeriesKeeper
	|FROM
	|	Document.TransferOfGoodsToBailee.SetOfSeries AS TransferOfGoodsSeries
	|WHERE
	|	TransferOfGoodsSeries.Ref = &Basis
	|
	|GROUP BY
	|	TransferOfGoodsSeries.Products,
	|	TransferOfGoodsSeries.Characteristic,
	|	TransferOfGoodsSeries.Purpose,
	|	TransferOfGoodsSeries.Series,
	|	TransferOfGoodsSeries.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT DISTINCT
	|	NestedQuery.Products   AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Package       AS Package,
	|	NestedQuery.Purpose     AS Purpose,
	|	NestedQuery.Series          AS Series,
	|	NestedQuery.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	NestedQuery.PriceKind        AS PriceKind,
	|	NestedQuery.Price           AS Price,
	|	NestedQuery.SalesOrder   AS SalesOrder,
	|	NestedQuery.RowCode      AS RowCode,
	|	NestedQuery.Warehouse          AS Warehouse,
	|	NestedQuery.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase      AS NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                            AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products   AS Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package       AS Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose     AS Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series          AS Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.PriceKind) AS PriceKind,
	|		MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.Price) AS Price,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse          AS Warehouse,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder   AS SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode      AS RowCode,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages)            AS NumberOfPackagesAccordingToAct,
	|		SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(GoodsHandover.NumberOfPackages, 0))                   AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			LEFT JOIN TransferOfGoodsToBailee AS GoodsHandover
	|			ON CertificateOfDiscrepanciesAfterShipmentOfGoods.Products = GoodsHandover.Products
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic = GoodsHandover.Characteristic
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose = GoodsHandover.Purpose
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Package = GoodsHandover.Package
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Series = GoodsHandover.Series
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = GoodsHandover.SalesOrder
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = GoodsHandover.RowCode
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse     = GoodsHandover.Warehouse
	|	
	|	GROUP BY
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsHandover.Products   AS Products,
	|		GoodsHandover.Characteristic AS Characteristic,
	|		GoodsHandover.Package       AS Package,
	|		GoodsHandover.Purpose     AS Purpose,
	|		GoodsHandover.Series          AS Series,
	|		GoodsHandover.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		MAX(VALUE(Catalog.TypesOfPrices.EmptyRef)) AS PriceKind,
	|		0                              AS Price,
	|		GoodsHandover.Warehouse          AS Warehouse,
	|		GoodsHandover.SalesOrder   AS SalesOrder,
	|		GoodsHandover.RowCode      AS RowCode,
	|		SUM(0)                                  AS NumberOfPackagesAccordingToAct,
	|		SUM(0)                                  AS NumberOfPackagesOnBasisOfAct,
	|		SUM(GoodsHandover.NumberOfPackages) AS NumberOfPackagesBase
	|	FROM
	|		TransferOfGoodsToBailee AS GoodsHandover
	|			LEFT JOIN ActOfDiscrepancyDuringShipment AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|			ON CertificateOfDiscrepanciesAfterShipmentOfGoods.Products = GoodsHandover.Products
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic = GoodsHandover.Characteristic
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose = GoodsHandover.Purpose
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Package = GoodsHandover.Package
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Series = GoodsHandover.Series
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = GoodsHandover.SalesOrder
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = GoodsHandover.RowCode
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse     = GoodsHandover.Warehouse
	|	WHERE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument IS NULL
	|	
	|	GROUP BY
	|		GoodsHandover.Products,
	|		GoodsHandover.Characteristic,
	|		GoodsHandover.Package,
	|		GoodsHandover.Purpose,
	|		GoodsHandover.Series,
	|		GoodsHandover.BatchesIndicationStatus,
	|		GoodsHandover.SalesOrder,
	|		GoodsHandover.RowCode,
	|		GoodsHandover.Warehouse) AS NestedQuery
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	NestedQuery.Products             AS Products,
	|	NestedQuery.Characteristic           AS Characteristic,
	|	NestedQuery.Purpose               AS Purpose,
	|	NestedQuery.Series                    AS Series,
	|	NestedQuery.Warehouse                    AS Warehouse,
	|	NestedQuery.QuantityByAct         AS QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_      AS QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                    AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products   AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose     AS Purpose,
	|		ActOfDivergenceSeries.Series          AS Series,
	|		ActOfDivergenceSeries.Warehouse          AS Warehouse,
	|		SUM(ActOfDivergenceSeries.Count)             AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument)  AS QuantityBasedOnAct,
	|		SUM(ISNULL(TransferOfGoodsSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN TransferOfGoodsToSeriesKeeper AS TransferOfGoodsSeries
	|			ON ActOfDivergenceSeries.Products = TransferOfGoodsSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = TransferOfGoodsSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = TransferOfGoodsSeries.Purpose
	|				AND ActOfDivergenceSeries.Series = TransferOfGoodsSeries.Series
	|				AND ActOfDivergenceSeries.Warehouse = TransferOfGoodsSeries.Warehouse
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Products,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TransferOfGoodsSeries.Products   AS Products,
	|		TransferOfGoodsSeries.Characteristic AS Characteristic,
	|		TransferOfGoodsSeries.Purpose     AS Purpose,
	|		TransferOfGoodsSeries.Series          AS Series,
	|		TransferOfGoodsSeries.Warehouse          AS Warehouse,
	|		SUM(0)                               AS QuantityByAct,
	|		SUM(0)                               AS QuantityBasedOnAct,
	|		SUM(TransferOfGoodsSeries.Count) AS QuantityBase_
	|	FROM
	|		TransferOfGoodsToSeriesKeeper AS TransferOfGoodsSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON TransferOfGoodsSeries.Products = ActOfDivergenceSeries.Products
	|				AND TransferOfGoodsSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND TransferOfGoodsSeries.Purpose = ActOfDivergenceSeries.Purpose
	|				AND TransferOfGoodsSeries.Series = ActOfDivergenceSeries.Series
	|				AND TransferOfGoodsSeries.Warehouse = ActOfDivergenceSeries.Warehouse
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL
	|	
	|	GROUP BY
	|		TransferOfGoodsSeries.Products,
	|		TransferOfGoodsSeries.Characteristic,
	|		TransferOfGoodsSeries.Purpose,
	|		TransferOfGoodsSeries.Series,
	|		TransferOfGoodsSeries.Warehouse) AS NestedQuery
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT DISTINCT
	|	StateGoods.LineState AS LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT DISTINCT
	|	StateOfSeriesGoods.LineState AS LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	StateGoods.Products   AS Products,
	|	StateGoods.Characteristic AS Characteristic,
	|	StateGoods.Package       AS Package,
	|	StateGoods.Purpose     AS Purpose,
	|	StateGoods.Series          AS Series,
	|	StateGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	StateGoods.Price           AS Price,
	|	StateGoods.SalesOrder   AS SalesOrder,
	|	StateGoods.RowCode      AS RowCode,
	|	StateGoods.Warehouse          AS Warehouse,
	|	StateGoods.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase      AS NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Package,
	|	Purpose,
	|	Series,
	|	PackagingFactor,
	|	Price,
	|	SalesOrder,
	|	RowCode,
	|	Warehouse,
	|	NumberOfPackagesAccordingToAct,
	|	NumberOfPackagesOnBasisOfAct,
	|	NumberOfPackagesBase
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	StateOfSeriesGoods.Products   AS Products,
	|	StateOfSeriesGoods.Characteristic AS Characteristic,
	|	StateOfSeriesGoods.Purpose     AS Purpose,
	|	StateOfSeriesGoods.Series          AS Series,
	|	StateOfSeriesGoods.Warehouse          AS Warehouse,
	|	StateOfSeriesGoods.QuantityByAct         AS QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_      AS QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse,
	|	QuantityByAct,
	|	QuantityBasedOnAct,
	|	QuantityBase_";
	
EndFunction

Function RequestTextTabularPartsOfReportOnDiscrepanciesAfterAcceptanceAndAcceptanceOfGoodsForStorage(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)

	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products                         AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts                 AS PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic                       AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose                           AS Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package                             AS Package,
	|	CASE
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|	END AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber                             AS CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode                            AS RowCode,
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder = VALUE(Document.PurchaseOrder.EmptyRef)
	|			OR CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			OR CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder = UNDEFINED
	|			THEN UNDEFINED
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder = UNDEFINED
	|			THEN VALUE(Document.PurchaseOrder.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder
	|	END                                                                   AS PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse                                AS Warehouse,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VendorPriceKind)          AS VendorPriceKind,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price)                       AS Price,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SalesOpportunity)                     AS SalesOpportunity,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument
	|		END) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument
	|
	|INTO ActOfDiscrepancies
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|	INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentData
	|		ON CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = DocumentData.Ref
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package,
	|	CASE
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|	END,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode
	|
	|INDEX BY
	|	Products,
	|	PartnerProducts,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series,
	|	RowCode,
	|	PurchaseOrder,
	|	Warehouse,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series          AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products   AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose     AS Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse          AS Warehouse,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingReceiptSetOfSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN DiscrepancyReportFollowingReceiptSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument
	|		END) AS Count,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument) AS CountByDocument
	|
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|
	|SELECT ALLOWED 
	|	AcceptanceOfGoodsForStorageGoods.Products AS Products,
	|	AcceptanceOfGoodsForStorageGoods.PartnerProducts    AS PartnerProducts,
	|	AcceptanceOfGoodsForStorageGoods.Characteristic            AS Characteristic,
	|	AcceptanceOfGoodsForStorageGoods.Purpose                AS Purpose,
	|	AcceptanceOfGoodsForStorageGoods.Package                  AS Package,
	|	AcceptanceOfGoodsForStorageGoods.Series                     AS Series,
	|	AcceptanceOfGoodsForStorageGoods.CCDNumber                  AS CCDNumber,
	|	AcceptanceOfGoodsForStorageGoods.RowCode                 AS RowCode,
	|	AcceptanceOfGoodsForStorageGoods.PurchaseOrder           AS PurchaseOrder,
	|	AcceptanceOfGoodsForStorageGoods.Warehouse                     AS Warehouse,
	|	SUM(AcceptanceOfGoodsForStorageGoods.NumberOfPackages) AS NumberOfPackages
	|
	|INTO AcceptanceOfGoodsForStorageGoods
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS AcceptanceOfGoodsForStorageGoods
	|WHERE
	|	AcceptanceOfGoodsForStorageGoods.Ref = &Basis
	|
	|GROUP BY
	|	AcceptanceOfGoodsForStorageGoods.Package,
	|	AcceptanceOfGoodsForStorageGoods.Products,
	|	AcceptanceOfGoodsForStorageGoods.PartnerProducts,
	|	AcceptanceOfGoodsForStorageGoods.Series,
	|	AcceptanceOfGoodsForStorageGoods.CCDNumber,
	|	AcceptanceOfGoodsForStorageGoods.Purpose,
	|	AcceptanceOfGoodsForStorageGoods.Characteristic,
	|	AcceptanceOfGoodsForStorageGoods.RowCode,
	|	AcceptanceOfGoodsForStorageGoods.PurchaseOrder,
	|	AcceptanceOfGoodsForStorageGoods.Warehouse
	|
	|INDEX BY
	|	Products,
	|	PartnerProducts,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series,
	|	RowCode,
	|	PurchaseOrder,
	|	Warehouse,
	|	CCDNumber
	|;
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED
	|	AcceptanceOfGoodsForStorageOfSeries.Products      AS Products,
	|	AcceptanceOfGoodsForStorageOfSeries.Characteristic    AS Characteristic,
	|	AcceptanceOfGoodsForStorageOfSeries.Purpose        AS Purpose,
	|	AcceptanceOfGoodsForStorageOfSeries.Warehouse             AS Warehouse,
	|	AcceptanceOfGoodsForStorageOfSeries.Series             AS Series,
	|	SUM(AcceptanceOfGoodsForStorageOfSeries.Count) AS Count
	|
	|INTO AcceptanceOfGoodsForStorageOfSeries
	|FROM
	|	Document.GoodsReceiptForStorage.SetOfSeries AS AcceptanceOfGoodsForStorageOfSeries
	|WHERE
	|	AcceptanceOfGoodsForStorageOfSeries.Ref = &Basis
	|
	|GROUP BY
	|	AcceptanceOfGoodsForStorageOfSeries.Products,
	|	AcceptanceOfGoodsForStorageOfSeries.Series,
	|	AcceptanceOfGoodsForStorageOfSeries.Purpose,
	|	AcceptanceOfGoodsForStorageOfSeries.Warehouse,
	|	AcceptanceOfGoodsForStorageOfSeries.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|
	|SELECT DISTINCT
	|	NestedQuery.Products                     AS Products,
	|	NestedQuery.PartnerProducts           AS PartnerProducts,
	|	NestedQuery.Characteristic                   AS Characteristic,
	|	NestedQuery.Purpose                       AS Purpose,
	|	NestedQuery.Package                         AS Package,
	|	NestedQuery.Series                            AS Series,
	|	NestedQuery.RowCode                        AS RowCode,
	|	NestedQuery.PurchaseOrder                  AS PurchaseOrder,
	|	NestedQuery.Warehouse                            AS Warehouse,
	|	NestedQuery.Price                             AS Price,
	|	NestedQuery.VendorPriceKind                AS VendorPriceKind,
	|	NestedQuery.SalesOpportunity                           AS SalesOpportunity,
	|	NestedQuery.CCDNumber                         AS CCDNumber,
	|	NestedQuery.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase      AS NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                            AS LineState
	|
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		ActOfDiscrepancies.Products                                   AS Products,
	|		ActOfDiscrepancies.PartnerProducts                         AS PartnerProducts,
	|		ActOfDiscrepancies.Characteristic                                 AS Characteristic,
	|		ActOfDiscrepancies.Purpose                                     AS Purpose,
	|		ActOfDiscrepancies.Package                                       AS Package,
	|		ActOfDiscrepancies.Series                                          AS Series,
	|		ActOfDiscrepancies.CCDNumber                                       AS CCDNumber,
	|		ActOfDiscrepancies.RowCode                                      AS RowCode,
	|		ActOfDiscrepancies.PurchaseOrder                                AS PurchaseOrder,
	|		ActOfDiscrepancies.Warehouse                                          AS Warehouse,
	|		MAX(ActOfDiscrepancies.Price)                                 AS Price,
	|		MAX(ActOfDiscrepancies.VendorPriceKind)                    AS VendorPriceKind,
	|		MAX(ActOfDiscrepancies.SalesOpportunity)                               AS SalesOpportunity,
	|		SUM(ActOfDiscrepancies.NumberOfPackages)                      AS NumberOfPackagesAccordingToAct,
	|		SUM(ActOfDiscrepancies.NumberOfPackagesByDocument)           AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(AcceptanceOfGoodsForStorageGoods.NumberOfPackages, 0)) AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancies AS ActOfDiscrepancies
	|			LEFT JOIN AcceptanceOfGoodsForStorageGoods AS AcceptanceOfGoodsForStorageGoods
	|			ON ActOfDiscrepancies.Products              = AcceptanceOfGoodsForStorageGoods.Products
	|				AND ActOfDiscrepancies.Characteristic         = AcceptanceOfGoodsForStorageGoods.Characteristic
	|				AND ActOfDiscrepancies.Purpose             = AcceptanceOfGoodsForStorageGoods.Purpose
	|				AND ActOfDiscrepancies.Package               = AcceptanceOfGoodsForStorageGoods.Package
	|				AND ActOfDiscrepancies.Series                  = AcceptanceOfGoodsForStorageGoods.Series
	|				AND ActOfDiscrepancies.RowCode              = AcceptanceOfGoodsForStorageGoods.RowCode
	|				AND ActOfDiscrepancies.PurchaseOrder        = AcceptanceOfGoodsForStorageGoods.PurchaseOrder
	|				AND ActOfDiscrepancies.Warehouse                  = AcceptanceOfGoodsForStorageGoods.Warehouse
	|				AND ActOfDiscrepancies.CCDNumber               = AcceptanceOfGoodsForStorageGoods.CCDNumber
	|	
	|	GROUP BY
	|		ActOfDiscrepancies.Purpose,
	|		ActOfDiscrepancies.Characteristic,
	|		ActOfDiscrepancies.Series,
	|		ActOfDiscrepancies.CCDNumber,
	|		ActOfDiscrepancies.Package,
	|		ActOfDiscrepancies.Products,
	|		ActOfDiscrepancies.PartnerProducts,
	|		ActOfDiscrepancies.RowCode,
	|		ActOfDiscrepancies.PurchaseOrder,
	|		ActOfDiscrepancies.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AcceptanceOfGoodsForStorageGoods.Products,
	|		AcceptanceOfGoodsForStorageGoods.PartnerProducts,
	|		AcceptanceOfGoodsForStorageGoods.Characteristic,
	|		AcceptanceOfGoodsForStorageGoods.Purpose,
	|		AcceptanceOfGoodsForStorageGoods.Package,
	|		AcceptanceOfGoodsForStorageGoods.Series,
	|		AcceptanceOfGoodsForStorageGoods.CCDNumber,
	|		AcceptanceOfGoodsForStorageGoods.RowCode,
	|		AcceptanceOfGoodsForStorageGoods.PurchaseOrder,
	|		AcceptanceOfGoodsForStorageGoods.Warehouse,
	|		MAX(0),
	|		MAX(VALUE(Catalog.VendorPriceTypes.EmptyRef)),
	|		MAX(VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)),
	|		SUM(0),
	|		SUM(0),
	|		SUM(AcceptanceOfGoodsForStorageGoods.NumberOfPackages)
	|	FROM
	|		AcceptanceOfGoodsForStorageGoods AS AcceptanceOfGoodsForStorageGoods
	|			LEFT JOIN ActOfDiscrepancies AS ActOfDiscrepancies
	|			ON AcceptanceOfGoodsForStorageGoods.Products              = ActOfDiscrepancies.Products
	|				AND AcceptanceOfGoodsForStorageGoods.Characteristic         = ActOfDiscrepancies.Characteristic
	|				AND AcceptanceOfGoodsForStorageGoods.Purpose             = ActOfDiscrepancies.Purpose
	|				AND AcceptanceOfGoodsForStorageGoods.Package               = ActOfDiscrepancies.Package
	|				AND AcceptanceOfGoodsForStorageGoods.Series                  = ActOfDiscrepancies.Series
	|				AND AcceptanceOfGoodsForStorageGoods.RowCode              = ActOfDiscrepancies.RowCode
	|				AND AcceptanceOfGoodsForStorageGoods.PurchaseOrder        = ActOfDiscrepancies.PurchaseOrder
	|				AND AcceptanceOfGoodsForStorageGoods.Warehouse                  = ActOfDiscrepancies.Warehouse
	|				AND AcceptanceOfGoodsForStorageGoods.CCDNumber               = ActOfDiscrepancies.CCDNumber
	|	WHERE
	|		ActOfDiscrepancies.NumberOfPackagesByDocument IS NULL 
	|	
	|	GROUP BY
	|		AcceptanceOfGoodsForStorageGoods.Package,
	|		AcceptanceOfGoodsForStorageGoods.Products,
	|		AcceptanceOfGoodsForStorageGoods.PartnerProducts,
	|		AcceptanceOfGoodsForStorageGoods.Series,
	|		AcceptanceOfGoodsForStorageGoods.CCDNumber,
	|		AcceptanceOfGoodsForStorageGoods.Purpose,
	|		AcceptanceOfGoodsForStorageGoods.Characteristic,
	|		AcceptanceOfGoodsForStorageGoods.RowCode,
	|		AcceptanceOfGoodsForStorageGoods.PurchaseOrder,
	|		AcceptanceOfGoodsForStorageGoods.Warehouse) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|
	|SELECT DISTINCT
	|	NestedQuery.Products             AS Products,
	|	NestedQuery.Characteristic           AS Characteristic,
	|	NestedQuery.Purpose               AS Purpose,
	|	NestedQuery.Warehouse                    AS Warehouse,
	|	NestedQuery.Series                    AS Series,
	|	NestedQuery.QuantityByAct         AS QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_      AS QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                                    AS LineState
	|
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Products                           AS Products,
	|		ActOfDivergenceSeries.Characteristic                         AS Characteristic,
	|		ActOfDivergenceSeries.Purpose                             AS Purpose,
	|		ActOfDivergenceSeries.Warehouse                                  AS Warehouse,
	|		ActOfDivergenceSeries.Series                                  AS Series,
	|		SUM(ActOfDivergenceSeries.Count)                      AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument)           AS QuantityBasedOnAct,
	|		SUM(ISNULL(AcceptanceOfGoodsForStorageOfSeries.Count, 0)) AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN AcceptanceOfGoodsForStorageOfSeries AS AcceptanceOfGoodsForStorageOfSeries
	|			ON ActOfDivergenceSeries.Products      = AcceptanceOfGoodsForStorageOfSeries.Products
	|				AND ActOfDivergenceSeries.Characteristic = AcceptanceOfGoodsForStorageOfSeries.Characteristic
	|				AND ActOfDivergenceSeries.Purpose     = AcceptanceOfGoodsForStorageOfSeries.Purpose
	|				AND ActOfDivergenceSeries.Warehouse          = AcceptanceOfGoodsForStorageOfSeries.Warehouse
	|				AND ActOfDivergenceSeries.Series          = AcceptanceOfGoodsForStorageOfSeries.Series
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Purpose,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Warehouse,
	|		ActOfDivergenceSeries.Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AcceptanceOfGoodsForStorageOfSeries.Products,
	|		AcceptanceOfGoodsForStorageOfSeries.Characteristic,
	|		AcceptanceOfGoodsForStorageOfSeries.Purpose,
	|		AcceptanceOfGoodsForStorageOfSeries.Warehouse,
	|		AcceptanceOfGoodsForStorageOfSeries.Series,
	|		SUM(0),
	|		SUM(0),
	|		SUM(AcceptanceOfGoodsForStorageOfSeries.Count)
	|	FROM
	|		AcceptanceOfGoodsForStorageOfSeries AS AcceptanceOfGoodsForStorageOfSeries
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON AcceptanceOfGoodsForStorageOfSeries.Products      = ActOfDivergenceSeries.Products
	|				AND AcceptanceOfGoodsForStorageOfSeries.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND AcceptanceOfGoodsForStorageOfSeries.Purpose     = ActOfDivergenceSeries.Purpose
	|				AND AcceptanceOfGoodsForStorageOfSeries.Warehouse          = ActOfDivergenceSeries.Warehouse
	|				AND AcceptanceOfGoodsForStorageOfSeries.Series          = ActOfDivergenceSeries.Series
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL 
	|	
	|	GROUP BY
	|		AcceptanceOfGoodsForStorageOfSeries.Products,
	|		AcceptanceOfGoodsForStorageOfSeries.Series,
	|		AcceptanceOfGoodsForStorageOfSeries.Purpose,
	|		AcceptanceOfGoodsForStorageOfSeries.Warehouse,
	|		AcceptanceOfGoodsForStorageOfSeries.Characteristic) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT DISTINCT
	|	StateGoods.LineState AS LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION ALL
	|
	|SELECT
	|	StateOfSeriesGoods.LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|	
	|SELECT
	|	StateGoods.Products                     AS Products,
	|	StateGoods.PartnerProducts           AS PartnerProducts,
	|	StateGoods.Characteristic                   AS Characteristic,
	|	StateGoods.Purpose                       AS Purpose,
	|	StateGoods.Package                         AS Package,
	|	ISNULL(&QueryTextPackagingFactor, 1)    AS PackagingFactor,
	|	StateGoods.Series                            AS Series,
	|	StateGoods.Warehouse                            AS Warehouse,
	|	StateGoods.Price                             AS Price,
	|	StateGoods.VendorPriceKind                AS VendorPriceKind,
	|	StateGoods.RowCode                        AS RowCode,
	|	StateGoods.PurchaseOrder                  AS PurchaseOrder,
	|	StateGoods.SalesOpportunity                           AS SalesOpportunity,
	|	StateGoods.CCDNumber                         AS CCDNumber,
	|	StateGoods.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase      AS NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StateOfSeriesGoods.Products             AS Products,
	|	StateOfSeriesGoods.Characteristic           AS Characteristic,
	|	StateOfSeriesGoods.Purpose               AS Purpose,
	|	StateOfSeriesGoods.Series                    AS Series,
	|	StateOfSeriesGoods.Warehouse                    AS Warehouse,
	|	StateOfSeriesGoods.QuantityByAct         AS QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_      AS QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""
	|";
	
EndFunction

Function RequestTextTabularPartsOfDiscrepancyReportAfterAcceptanceAndReceiptOfGoodsFromCustodian(DiscrepancyCertificate, Basis, ReturnStructure, DocumentModification)
	
	Return "
	|SELECT ALLOWED
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products        AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic      AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose          AS Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package            AS Package,
	|	CASE
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|	END AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN(VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
	|																VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
	|																VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
	|																VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages
	|			ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument
	|		END)                                                              AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) AS NumberOfPackagesByDocument,
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price)      AS Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder     AS PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode           AS RowCode,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentSalesOfGoodsAndServices  AS DocumentSalesOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber            AS CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse               AS Warehouse
	|INTO ActOfDiscrepancies
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package,
	|	CASE
	|		WHEN NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient IN (13,14)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series
	|	END,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatusRecipient,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentSalesOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series,
	|	PurchaseOrder,
	|	RowCode,
	|	DocumentSalesOfGoodsAndServices,
	|	CCDNumber,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series          AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products   AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose     AS Purpose,
	|	SUM(CASE
	|			WHEN DiscrepancyReportFollowingReceiptSetOfSeries.Action IN(VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
	|																VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
	|																VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
	|																VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|				THEN DiscrepancyReportFollowingReceiptSetOfSeries.Count
	|			ELSE DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument
	|		END)                                                     AS Count,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument) AS CountByDocument
	|INTO ActOfDivergenceSeries
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &Basis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose
	|
	|INDEX BY
	|	Series,
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.ReferenceOrder        AS PurchaseOrder,
	|	GoodsTable.RowCode           AS RowCode,
	|	DocumentData.Warehouse             AS Warehouse,
	|	GoodsTable.CCDNumber            AS CCDNumber,
	|	SUM(GoodsTable.NumberOfPackages) AS NumberOfPackages
	|INTO GoodsTable
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|		LEFT JOIN Document.ReceiptOfGoodsFromCustodian AS DocumentData
	|		ON GoodsTable.Ref = DocumentData.Ref
	|WHERE
	|	GoodsTable.Ref = &Basis
	|	AND DocumentData.Ref = &Basis
	|
	|GROUP BY
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END,
	|	GoodsTable.Purpose,
	|	GoodsTable.Package,
	|	GoodsTable.Series,
	|	GoodsTable.BatchesIndicationStatus,
	|	GoodsTable.ReferenceOrder,
	|	GoodsTable.RowCode,
	|	DocumentData.Warehouse,
	|	GoodsTable.CCDNumber
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series,
	|	PurchaseOrder,
	|	RowCode,
	|	Warehouse,
	|	CCDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT ALLOWED
	|	NestedQuery.Products   AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose     AS Purpose,
	|	NestedQuery.Series          AS Series,
	|	SUM(NestedQuery.Count) AS Count
	|INTO SeriesTable
	|FROM 
	|	(SELECT
	|		SeriesTable.Series          AS Series,
	|		SeriesTable.Products   AS Products,
	|		SeriesTable.Characteristic AS Characteristic,
	|		SeriesTable.Purpose     AS Purpose,
	|		SeriesTable.Count     AS Count,
	|		MAX(GoodsTable.BatchesIndicationStatus) AS BatchesIndicationStatus
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.SetOfSeries AS SeriesTable
	|			INNER JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|			ON SeriesTable.Ref = GoodsTable.Ref
	|				AND SeriesTable.Products   = GoodsTable.Products
	|				AND SeriesTable.Characteristic = GoodsTable.Characteristic
	|				AND SeriesTable.Purpose     = GoodsTable.Purpose
	|	WHERE
	|		SeriesTable.Ref = &Basis
	|		AND GoodsTable.Ref = &Basis
	|		AND SeriesTable.Count <> 0
	|
	|	GROUP BY
	|		SeriesTable.Series,
	|		SeriesTable.Products,
	|		SeriesTable.Count,
	|		SeriesTable.Characteristic,
	|		SeriesTable.Purpose
	|	
	|	HAVING
	|		MAX(GoodsTable.BatchesIndicationStatus) IN(2, 4, 6, 8, 10)
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose
	|
	|INDEX BY
	|	Series,
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT DISTINCT
	|	NestedQuery.Products        AS Products,
	|	NestedQuery.Characteristic      AS Characteristic,
	|	NestedQuery.Purpose          AS Purpose,
	|	NestedQuery.Package            AS Package,
	|	NestedQuery.Series               AS Series,
	|	NestedQuery.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	NestedQuery.PurchaseOrder     AS PurchaseOrder,
	|	NestedQuery.RowCode           AS RowCode,
	|	NestedQuery.Price                AS Price,
	|	NestedQuery.CCDNumber            AS CCDNumber,
	|	NestedQuery.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	NestedQuery.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	NestedQuery.NumberOfPackagesBase      AS NumberOfPackagesBase,
	|	CASE
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.NumberOfPackagesAccordingToAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesOnBasisOfAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.NumberOfPackagesOnBasisOfAct = NestedQuery.NumberOfPackagesBase
	|				AND NestedQuery.NumberOfPackagesAccordingToAct <> NestedQuery.NumberOfPackagesBase
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END                               AS LineState
	|INTO StateGoods
	|FROM
	|	(SELECT
	|		ActOfDiscrepancies.Products        AS Products,
	|		ActOfDiscrepancies.Characteristic      AS Characteristic,
	|		ActOfDiscrepancies.Purpose          AS Purpose,
	|		ActOfDiscrepancies.Package            AS Package,
	|		ActOfDiscrepancies.Series               AS Series,
	|		ActOfDiscrepancies.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		MAX(ActOfDiscrepancies.Price)      AS Price,
	|		ActOfDiscrepancies.PurchaseOrder     AS PurchaseOrder,
	|		ActOfDiscrepancies.RowCode           AS RowCode,
	|		ActOfDiscrepancies.Warehouse               AS Warehouse,
	|		ActOfDiscrepancies.CCDNumber            AS CCDNumber,
	|		SUM(ActOfDiscrepancies.NumberOfPackages)            AS NumberOfPackagesAccordingToAct,
	|		SUM(ActOfDiscrepancies.NumberOfPackagesByDocument) AS NumberOfPackagesOnBasisOfAct,
	|		SUM(ISNULL(GoodsTable.NumberOfPackages, 0))        AS NumberOfPackagesBase
	|	FROM
	|		ActOfDiscrepancies AS ActOfDiscrepancies
	|			LEFT JOIN GoodsTable AS GoodsTable
	|			ON ActOfDiscrepancies.Products = GoodsTable.Products
	|				AND ActOfDiscrepancies.Characteristic = GoodsTable.Characteristic
	|				AND ActOfDiscrepancies.Purpose = GoodsTable.Purpose
	|				AND ActOfDiscrepancies.Package = GoodsTable.Package
	|				AND ActOfDiscrepancies.Series = GoodsTable.Series
	|				AND ActOfDiscrepancies.BatchesIndicationStatus = GoodsTable.BatchesIndicationStatus
	|				AND ActOfDiscrepancies.PurchaseOrder = GoodsTable.PurchaseOrder
	|				AND ActOfDiscrepancies.RowCode = GoodsTable.RowCode
	|				AND ActOfDiscrepancies.Warehouse = GoodsTable.Warehouse
	|				AND ActOfDiscrepancies.CCDNumber = GoodsTable.CCDNumber
	|	
	|	GROUP BY
	|		ActOfDiscrepancies.Products,
	|		ActOfDiscrepancies.Characteristic,
	|		ActOfDiscrepancies.Purpose,
	|		ActOfDiscrepancies.Package,
	|		ActOfDiscrepancies.Series,
	|		ActOfDiscrepancies.BatchesIndicationStatus,
	|		ActOfDiscrepancies.PurchaseOrder,
	|		ActOfDiscrepancies.RowCode,
	|		ActOfDiscrepancies.DocumentSalesOfGoodsAndServices,
	|		ActOfDiscrepancies.Warehouse,
	|		ActOfDiscrepancies.CCDNumber
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products        AS Products,
	|		GoodsTable.Characteristic      AS Characteristic,
	|		GoodsTable.Purpose          AS Purpose,
	|		GoodsTable.Package            AS Package,
	|		GoodsTable.Series               AS Series,
	|		GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		MAX(0)                       AS Price,
	|		GoodsTable.PurchaseOrder     AS PurchaseOrder,
	|		GoodsTable.RowCode           AS RowCode,
	|		GoodsTable.Warehouse               AS Warehouse,
	|		GoodsTable.CCDNumber            AS CCDNumber,
	|		SUM(0)                          AS NumberOfPackagesAccordingToAct,
	|		SUM(0)                          AS NumberOfPackagesOnBasisOfAct,
	|		SUM(GoodsTable.NumberOfPackages) AS NumberOfPackagesBase
	|	FROM
	|		GoodsTable AS GoodsTable
	|			LEFT JOIN ActOfDiscrepancies AS ActOfDiscrepancies
	|			ON GoodsTable.Products = ActOfDiscrepancies.Products
	|				AND GoodsTable.Characteristic = ActOfDiscrepancies.Characteristic
	|				AND GoodsTable.Purpose = ActOfDiscrepancies.Purpose
	|				AND GoodsTable.Package = ActOfDiscrepancies.Package
	|				AND GoodsTable.Series = ActOfDiscrepancies.Series
	|				AND GoodsTable.BatchesIndicationStatus = ActOfDiscrepancies.BatchesIndicationStatus
	|				AND GoodsTable.PurchaseOrder = ActOfDiscrepancies.PurchaseOrder
	|				AND GoodsTable.RowCode = ActOfDiscrepancies.RowCode
	|				AND GoodsTable.Warehouse = ActOfDiscrepancies.Warehouse
	|				AND GoodsTable.CCDNumber = ActOfDiscrepancies.CCDNumber
	|	WHERE
	|		ActOfDiscrepancies.NumberOfPackagesByDocument IS NULL
	|	
	|	GROUP BY
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Purpose,
	|		GoodsTable.Package,
	|		GoodsTable.Series,
	|		GoodsTable.BatchesIndicationStatus,
	|		GoodsTable.PurchaseOrder,
	|		GoodsTable.RowCode,
	|		GoodsTable.Warehouse,
	|		GoodsTable.CCDNumber
	|	) AS NestedQuery
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.QuantityByAct,
	|	NestedQuery.QuantityBasedOnAct,
	|	NestedQuery.QuantityBase_,
	|	CASE
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|			THEN ""NoModificationsAreRequired""
	|		WHEN NestedQuery.QuantityByAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityBasedOnAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesAreMade""
	|		WHEN NestedQuery.QuantityBasedOnAct = NestedQuery.QuantityBase_
	|				AND NestedQuery.QuantityByAct <> NestedQuery.QuantityBase_
	|			THEN ""ChangesRequired""
	|		ELSE ""BaseDocumentDoesNotMatchTheCertificate""
	|	END AS LineState
	|INTO StateOfSeriesGoods
	|FROM
	|	(SELECT
	|		ActOfDivergenceSeries.Series          AS Series,
	|		ActOfDivergenceSeries.Products   AS Products,
	|		ActOfDivergenceSeries.Characteristic AS Characteristic,
	|		ActOfDivergenceSeries.Purpose     AS Purpose,
	|		SUM(ActOfDivergenceSeries.Count)            AS QuantityByAct,
	|		SUM(ActOfDivergenceSeries.CountByDocument) AS QuantityBasedOnAct,
	|		SUM(ISNULL(SeriesTable.Count, 0))        AS QuantityBase_
	|	FROM
	|		ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			LEFT JOIN SeriesTable AS SeriesTable
	|			ON ActOfDivergenceSeries.Series = SeriesTable.Series
	|				AND ActOfDivergenceSeries.Products = SeriesTable.Products
	|				AND ActOfDivergenceSeries.Characteristic = SeriesTable.Characteristic
	|				AND ActOfDivergenceSeries.Purpose = SeriesTable.Purpose
	|	
	|	GROUP BY
	|		ActOfDivergenceSeries.Series,
	|		ActOfDivergenceSeries.Products,
	|		ActOfDivergenceSeries.Characteristic,
	|		ActOfDivergenceSeries.Purpose
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SeriesTable.Series          AS Series,
	|		SeriesTable.Products   AS Products,
	|		SeriesTable.Characteristic AS Characteristic,
	|		SeriesTable.Purpose     AS Purpose,
	|		SUM(0)                    AS QuantityByAct,
	|		SUM(0)                    AS QuantityBasedOnAct,
	|		SUM(SeriesTable.Count) AS QuantityBase_
	|	FROM
	|		SeriesTable AS SeriesTable
	|			LEFT JOIN ActOfDivergenceSeries AS ActOfDivergenceSeries
	|			ON SeriesTable.Series = ActOfDivergenceSeries.Series
	|				AND SeriesTable.Products = ActOfDivergenceSeries.Products
	|				AND SeriesTable.Characteristic = ActOfDivergenceSeries.Characteristic
	|				AND SeriesTable.Purpose = ActOfDivergenceSeries.Purpose
	|	WHERE
	|		ActOfDivergenceSeries.CountByDocument IS NULL
	|	
	|	GROUP BY
	|		SeriesTable.Series,
	|		SeriesTable.Products,
	|		SeriesTable.Purpose,
	|		SeriesTable.Characteristic
	|	) AS NestedQuery
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT DISTINCT
	|	StateGoods.LineState AS LineState
	|FROM
	|	StateGoods AS StateGoods
	|
	|UNION
	|
	|SELECT DISTINCT
	|	StateOfSeriesGoods.LineState AS LineState
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|	
	|SELECT
	|	StateGoods.Products        AS Products,
	|	StateGoods.Characteristic      AS Characteristic,
	|	StateGoods.Purpose          AS Purpose,
	|	StateGoods.Package            AS Package,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	StateGoods.Series               AS Series,
	|	StateGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	StateGoods.Price                AS Price,
	|	StateGoods.CCDNumber            AS CCDNumber,
	|	StateGoods.PurchaseOrder     AS PurchaseOrder,
	|	StateGoods.RowCode           AS RowCode,
	|	StateGoods.NumberOfPackagesAccordingToAct         AS NumberOfPackagesAccordingToAct,
	|	StateGoods.NumberOfPackagesOnBasisOfAct AS NumberOfPackagesOnBasisOfAct,
	|	StateGoods.NumberOfPackagesBase      AS NumberOfPackagesBase
	|FROM
	|	StateGoods AS StateGoods
	|WHERE
	|	StateGoods.LineState = ""ChangesRequired""
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	StateOfSeriesGoods.Products   AS Products,
	|	StateOfSeriesGoods.Characteristic AS Characteristic,
	|	StateOfSeriesGoods.Purpose     AS Purpose,
	|	StateOfSeriesGoods.Series          AS Series,
	|	StateOfSeriesGoods.QuantityByAct         AS QuantityByAct,
	|	StateOfSeriesGoods.QuantityBasedOnAct AS QuantityBasedOnAct,
	|	StateOfSeriesGoods.QuantityBase_      AS QuantityBase_
	|FROM
	|	StateOfSeriesGoods AS StateOfSeriesGoods
	|WHERE
	|	StateOfSeriesGoods.LineState = ""ChangesRequired""
	|";
	
EndFunction

#EndRegion

#Region SetOfSeries

// Process the indication of the series.
// 
// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* Object - FormDataStructure:
// 			** Ref - DocumentRef -
// 			** SetOfSeries - FormDataCollection -
// 			** Goods - FormDataCollection -:
// 				*** Action - EnumRef.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue
// 							 - EnumRef.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt
// 		* Items - FormAllItems - Contents including:
// 			** Goods - FormTable - Product table on the form
// 	ParametersOfSeriesIndicationForm - See ProductsServer.ParametersOfSeriesIndicationForm
// 	StructureOfActions - Structure - structure of actions
Procedure ProcessSeriesIndication_(Form, ParametersOfSeriesIndicationForm, StructureOfActions) Export
	
	AttributesNames = DiscrepanciesClientServer.NamesOfDetailsDependingOnTypeOfAct(TypeOf(Form.Object.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment"));
	
	SeriesSpecificationParameters = Form.SeriesSpecificationParameters;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ThisIsActAfterShipment = (SeriesSpecificationParameters.FullObjectName = "Document.DiscrepancyReportFollowingShipment");
	
	CurrentRow = Form.Object.Goods.FindByID(Form.Items.Goods.CurrentRow); // DocumentTabularSectionRow.DiscrepancyReportFollowingShipment.Goods, DocumentTabularSectionRow.DiscrepancyReportFollowingReceipt.Goods
	InitialAction = CurrentRow.Action;
	If ThisIsActAfterShipment Then
		InitialActionWithProduct = CurrentRow.DiscrepancyTreatment;
	EndIf;
	
	ProductsServer.ProcessSeriesIndication_(Form.Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm, StructureOfActions, CachedValues);
	
	If Not ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(ParametersOfSeriesIndicationForm.BatchesIndicationStatus, SeriesSpecificationParameters) Then
		Return;
	EndIf;
	
	// After processing, the action may be reset, you need to reset it for all rows
	If ThisIsActAfterShipment Then
		
		EmptyAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef();
		EmptyGoodsAction = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.EmptyRef();
		
	ElsIf SeriesSpecificationParameters.FullObjectName = "Document.DiscrepancyReportFollowingTransfer" Then
		EmptyAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef();
	Else
		EmptyAction = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef();
	EndIf;
	ResetAction = (CurrentRow.Action = EmptyAction);

	If StructureOfActions.Property("RecalculateNumberOfUnits") Then
		StructureOfActions.Delete("RecalculateNumberOfUnits");
	EndIf;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	LinkFieldText = "";
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		LinkFieldText = LinkFieldText + "," + ArrRow;
	EndDo;
	TheStructureOfTheSearch = New Structure("Products,Characteristic"+LinkFieldText);
	
	// We will distribute the surplus over the duplicates of the product lines so that the entire surplus does not fall into one line.
	FillPropertyValues(TheStructureOfTheSearch,CurrentRow);
	FoundProductLines = Form.Object.Goods.FindRows(TheStructureOfTheSearch); // Array of DocumentTabularSectionRow.DiscrepancyReportFollowingShipment.Goods, 
	If FoundProductLines.Count() > 1 And CurrentRow[AttributesNames.FilledUsingBaseDocument] = True Then
		QuantityToDistribution = 0;
		RowsToProcess = New Array;
		For Each Page1 In FoundProductLines Do
			If Page1.Count > Page1.CountByDocument Then
				QuantityToDistribution = Page1.Count - Page1.CountByDocument;
				Page1.Count = Page1.CountByDocument;
				RowsToProcess.Add(Page1);
				ResetAction = (Page1.Action = EmptyAction);
			EndIf;
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Form.Object.Goods,
			CachedValues);
		
		If QuantityToDistribution > 0 Then
			RowsToProcess = New Array;
			For Each Page1 In FoundProductLines Do
				If Page1.Count < Page1.CountByDocument Then
					Page1.Count = Min(Page1.CountByDocument, QuantityToDistribution);
					RowsToProcess.Add(Page1);
					ResetAction = (Page1.Action = EmptyAction);
					QuantityToDistribution = QuantityToDistribution - Page1.Count;
					If QuantityToDistribution = 0 Then
						Break;
					EndIf;
				EndIf;
			EndDo;
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				StructureOfActions,
				Form.Object.Goods,
				CachedValues);
			
		EndIf;
		If QuantityToDistribution > 0 Then
			CurrentRow.Count = CurrentRow.Count + QuantityToDistribution;
			BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
			ResetAction = (CurrentRow.Action = EmptyAction);
		EndIf;
	EndIf;
	
	// In case of simultaneous occurrence of shortage and surplus on the lines of the series from the base document,
	// we will allocate the surpluses into separate lines of the series and goods.
	TheStructureOfTheSearch.Action = InitialAction;
	If ThisIsActAfterShipment Then
		TheStructureOfTheSearch.DiscrepancyTreatment = InitialActionWithProduct;
	EndIf;
	FoundSeriesRows_ = Form.Object.SetOfSeries.FindRows(TheStructureOfTheSearch);
	MissingLines = New Array;
	LinesWithExcess = New Array;
	DeleteRows_ = New Array;
	For Each Page1 In FoundSeriesRows_ Do
		Delta = Page1.Count - Page1.CountByDocument;
		If Delta > 0 Then
			LinesWithExcess.Add(Page1);
		ElsIf Delta < 0 Then
			MissingLines.Add(Page1);
		EndIf;
		If Page1.Count = 0
			And Page1.CountByDocument = 0 Then
			DeleteRows_.Add(Page1);
		EndIf;
	EndDo;
	For Each Page1 In DeleteRows_ Do
		Form.Object.SetOfSeries.Delete(Page1);
	EndDo;
	
	If LinesWithExcess.Count() > 0 And MissingLines.Count() > 0 Then
		
		TotalSurplus = 0;
		For Each Page1 In LinesWithExcess Do
			NewRowSeries = Form.Object.SetOfSeries.Add(); // DocumentTabularSectionRow.DiscrepancyReportFollowingShipment.SetOfSeries, DocumentTabularSectionRow.DiscrepancyReportFollowingReceipt.SetOfSeries
			FillPropertyValues(NewRowSeries, Page1);
			NewRowSeries[AttributesNames.FilledUsingBaseDocument] = False;
			NewRowSeries.CountByDocument = 0;
			Delta = Page1.Count - Page1.CountByDocument;
			NewRowSeries.Count = Delta;
			NewRowSeries.Action = EmptyAction;
			If ThisIsActAfterShipment Then
				NewRowSeries.DiscrepancyTreatment = EmptyGoodsAction;
			EndIf;
			Page1.Count = Page1.CountByDocument;
			TotalSurplus = TotalSurplus + Delta;
		EndDo;
		
		NewLineProducts = Form.Object.Goods.Insert(CurrentRow.LineNumber);
		FillPropertyValues(NewLineProducts, CurrentRow,,"RowCode");
		
		InitializationStructure = New Structure;
		InitializationStructure.Insert("CountByDocument", 0);
		InitializationStructure.Insert("NumberOfPackagesByDocument", 0);
		InitializationStructure.Insert("SumByDocument", 0);
		InitializationStructure.Insert("VATAmountByDocument", 0);
		InitializationStructure.Insert("AmountIncludingVATByDocument", 0);
		InitializationStructure.Insert(AttributesNames.FilledUsingBaseDocument, False);
		InitializationStructure.Insert("Action", EmptyAction);
		InitializationStructure.Insert("DiscrepancyTreatment", EmptyGoodsAction);
		
		FillPropertyValues(NewLineProducts, InitializationStructure);
		NewLineProducts.Count = TotalSurplus;
		
		CurrentRow.Count = CurrentRow.Count - TotalSurplus;
		
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		ResetAction = (CurrentRow.Action = EmptyAction);
		BatchProcessingOfTablePartServer.ProcessTSString(NewLineProducts, StructureOfActions, CachedValues);
	EndIf;
	
	If Not InitialAction = EmptyAction
		And ResetAction Then
		FoundProductLines = Form.Object.Goods.FindRows(TheStructureOfTheSearch); // Array of DocumentTabularSectionRow.DiscrepancyReportFollowingShipment.Goods, 
		For Each Page1 In FoundProductLines Do
			Page1.Action = EmptyAction;
			If ThisIsActAfterShipment Then
				Page1.DiscrepancyTreatment = EmptyGoodsAction;
			EndIf;
		EndDo;
		FoundSeriesRows_ = Form.Object.SetOfSeries.FindRows(TheStructureOfTheSearch);  // Array of DocumentTabularSectionRow.DiscrepancyReportFollowingShipment.Goods, 
		For Each Page1 In FoundSeriesRows_ Do
			Page1.Action = EmptyAction;
			If ThisIsActAfterShipment Then
				Page1.DiscrepancyTreatment = EmptyGoodsAction;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
// 	SpecialOptionForSpecifyingSeries - Boolean, String - False if the series are specified in a separate PM,
//			"Seriivsegdavtchtovary" - if the object does not have a special PM for specifying the series,
//			"seriipriplanirovaniyotgruzkiyavtchtovary" - if the series can be specified in different PM,
//				while the series with the accounting policy "when planning shipment" are specified in PM Goods. 
Procedure SetConditionalAppearanceOfSeries(Form, SpecialOptionForSpecifyingSeries) Export
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(Form, SpecialOptionForSpecifyingSeries);
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(Form, False);
	
	// You cannot edit the number of products
	// if the series for such a product are specified in a separate PM.
	// The quantity will be edited in the series selection form.
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormFieldNumberOfPackages = Form.Items.GoodsNumberOfPackages; // FormField
	ItemField.Field = New DataCompositionField(FormFieldNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.BatchesIndicationStatus");
	ItemFilter.ComparisonType    = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue  = 0;
	
	If SpecialOptionForSpecifyingSeries = "SeriesWhenPlanningShipmentWHGoodsAreIndicated" Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.BatchesIndicationStatus");
		ItemFilter.ComparisonType    = DataCompositionComparisonType.Less;
		ItemFilter.RightValue  = 9;
	Else
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue   = New DataCompositionField("Object.Goods.BatchesIndicationStatus");
		ItemFilter.ComparisonType    = DataCompositionComparisonType.Less;
		ItemFilter.RightValue  = 13;
	EndIf;
		
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#EndRegion

#Region CCDNumbers

// Fills in the result of the selection of CCD numbers in the tabular part of the object.
//
// Parameters:
//	Form - ClientApplicationForm - the form in which the selection is carried out.
//	RowID -  Number - ID of the row for which the values are being selected.
//	CalculationResult1 - Structure - a collection containing the following information:
//					* ThisIsRNPTOfKit - Boolean - indicates that the RPT number of the kit has been selected.
//					* MainNumberOfCCD - CatalogRef.CCDNumbers - the main CCD number received during the selection process.
//					* ResidualNumberOfCCD - CatalogRef.CCDNumbers - the main RNPT number of the kit received
//																		during selection.
//	CCDNumbersFilledIn - Boolean - indicates that the table part has been filled in.
//	CCDNumber - CatalogRef.CCDNumbers, Undefined - the CCD number, which is indicated in the tabular part of the object.
//
Procedure ProcessIndicationOfCCDNumber(Form, RowID, CalculationResult1, CCDNumbersFilledIn, CCDNumber) Export
	
	SelectionData_1	= GetFromTempStorage(CalculationResult1.AddressInTempStorage);
	CCDNumber		= ?(SelectionData_1.ResidualNumberOfCCD <> Undefined,
						CCDNumber,
						SelectionData_1.MainNumberOfCCD);
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		SelfServiceClientServer.AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions,
																								Form.Object);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(Form,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
	DiscrepanciesClientServer.CalculateFormTotals(Form);
	
EndProcedure

#EndRegion

#Region Surplus

Function ItIsNecessaryToMakeExcessInInvoice(Act, NameOfInvoiceField, ActionsWithExcess)
	
	ArrayOfInvoices = New Array();
	
	// Search for surpluses not allocated to separate lines and receive invoices of these lines
	For Each String In Act.Goods Do
		If String.RowCode > 0 
			And String.Count > String.CountByDocument 
			And ActionsWithExcess.Find(String.Action) <> Undefined Then
			
			Invoice = String[NameOfInvoiceField];
			
			If ArrayOfInvoices.Find(Invoice) = Undefined Then
				ArrayOfInvoices.Add(Invoice);
			EndIf;
			
		EndIf;
	EndDo;
	
	Return ArrayOfInvoices;
	
EndFunction

Function PrepareChangesToVHFInvoice(Act, Invoice, MetadataDetails, ActionsWithExcess)
	
	ArrayOfInvoiceTypes = New Array();
	ArrayOfInvoiceTypes.Add(TypeOf(Invoice));
	
	ProductsOfAct = Act.Goods.Unload();
	
	InvoiceGoods = Invoice.Goods.Unload(); // ValueTable
	InvoiceGoods.Columns.Add("Ref", New TypeDescription(ArrayOfInvoiceTypes));
	InvoiceGoods.FillValues(Invoice, "Ref");
	
	If MetadataDetails.OrderInHeader Then
		
		OrderDocument = Common.ObjectAttributeValue(Invoice, MetadataDetails.NameOfInvoiceOrderField);
		
		ArrayOfOrderTypes = New Array();
		ArrayOfOrderTypes.Add(TypeOf(OrderDocument));
		
		InvoiceGoods.Columns.Add(MetadataDetails.NameOfInvoiceOrderField, New TypeDescription(ArrayOfOrderTypes));
		InvoiceGoods.FillValues(OrderDocument, MetadataDetails.NameOfInvoiceOrderField);
		
	EndIf;
	
	QueryText =
	"SELECT
	|	Table.RowCode,
	|	Table.NameOfOrderReportField AS OrderDocument,
	|	Table.NameOfInvoiceField AS Invoice,
	|	Table.NumberOfPackages AS NumberOfActs
	|INTO TTGoodsFromActUncollapsed
	|FROM
	|	&ProductsOfAct AS Table
	|WHERE
	|	Table.RowCode > 0
	|	AND Table.Action IN(&ActionsWithExcess)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.RowCode,
	|	Table.OrderDocument,
	|	Table.Invoice,
	|	SUM(Table.NumberOfActs) AS NumberOfActs
	|INTO TTProductsAct
	|FROM
	|	TTGoodsFromActUncollapsed AS Table
	|
	|GROUP BY
	|	Table.Invoice,
	|	Table.RowCode,
	|	Table.OrderDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.RowCode,
	|	Table.NameOfInvoiceOrderField AS OrderDocument,
	|	Table.Ref AS Invoice,
	|	Table.NumberOfPackages AS NumberOfInvoice
	|INTO TTGoodsWaybillUnrolled
	|FROM
	|	&InvoiceGoods AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.RowCode,
	|	Table.OrderDocument,
	|	Table.Invoice,
	|	SUM(Table.NumberOfInvoice) AS NumberOfInvoice
	|INTO TTGoodsWaybill
	|FROM
	|	TTGoodsWaybillUnrolled AS Table
	|
	|GROUP BY
	|	Table.OrderDocument,
	|	Table.Invoice,
	|	Table.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProductsAct.RowCode,
	|	TTProductsAct.OrderDocument AS NameOfInvoiceOrderField,
	|	TTProductsAct.Invoice,
	|	TTProductsAct.NumberOfActs,
	|	TTGoodsWaybill.NumberOfInvoice AS NumberOfPackages
	|FROM
	|	TTProductsAct AS TTProductsAct
	|		INNER JOIN TTGoodsWaybill AS TTGoodsWaybill
	|		ON TTProductsAct.RowCode = TTGoodsWaybill.RowCode
	|			AND TTProductsAct.OrderDocument = TTGoodsWaybill.OrderDocument
	|			AND TTProductsAct.Invoice = TTGoodsWaybill.Invoice
	|WHERE
	|	TTProductsAct.NumberOfActs <> TTGoodsWaybill.NumberOfInvoice";
	
	QueryText = StrReplace(QueryText, "NameOfInvoiceOrderField", MetadataDetails.NameOfInvoiceOrderField);
	QueryText = StrReplace(QueryText, "NameOfOrderReportField", MetadataDetails.NameOfOrderReportField);
	QueryText = StrReplace(QueryText, "NameOfInvoiceField", MetadataDetails.NameOfInvoiceField);

	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("ActionsWithExcess", ActionsWithExcess);
	Query.SetParameter("ProductsOfAct", ProductsOfAct);
	Query.SetParameter("InvoiceGoods", InvoiceGoods);
	
	Result = Query.Execute().Unload();
	
	If Result.Count() > 0 Then
		HasChanges = True;
	Else
		HasChanges = False;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("RowCode, NumberOfPackages, " + MetadataDetails.NameOfInvoiceOrderField);
	
	// Making changes to the invoice table
	For Each String In Result Do
		FillPropertyValues(TheStructureOfTheSearch, String);
		FoundRows = InvoiceGoods.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			FoundRow = FoundRows[0];
			FoundRow.NumberOfPackages = String.NumberOfActs;
		EndIf;
	EndDo;
	
	ReturnStructure = New Structure("HasChanges, InvoiceGoods", HasChanges, InvoiceGoods);
	
	Return ReturnStructure;
	
EndFunction

Function GetNewInvoiceRegisteredRecordsByRegisterOrders(RegisterName, InvoiceName, ModifiedTSGoodsWaybills)
	
	QueryTextTTGoods = TemporaryTableFromValueTable(ModifiedTSGoodsWaybills, "Table");
	
	StructureOfAdaptedInquiryMechanism = Documents[InvoiceName].AdaptedCaseSensitiveQueryText(RegisterName);
	QueryTextMovementsByRegister = StrReplace(StructureOfAdaptedInquiryMechanism.QueryText, "Document." + InvoiceName + ".Goods", "TTTable");
	
	QueryText = QueryTextTTGoods + QueryTextMovementsByRegister;
	
	Query = New Query();
	Query.SetParameter("Table", ModifiedTSGoodsWaybills);
	
	For Each KeyValue In StructureOfAdaptedInquiryMechanism.ParameterValues Do
		Query.SetParameter(KeyValue.Key, KeyValue.Value);
	EndDo;
	
	Query.Text = QueryText;
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Function PerformControlOfAddingExcessToInvoice(RegisterName,
	FieldNameOrder,
	NameOfFieldToView,
	NamesOfUniquenessFields,
	RegisterRecordTable,
	ArrayOfInvoices,
	VerificationIndicator = "Issued_1")
	
	Orders = RegisterRecordTable.UnloadColumn(FieldNameOrder);
	Orders = CommonClientServer.CollapseArray(Orders);
	
	Query = New Query();
	Query.SetParameter("Recorders", ArrayOfInvoices);
	Query.SetParameter("TableOfNewRegisteredRecords", RegisterRecordTable);
	Query.SetParameter("Orders", Orders);
	
	If RegisterName = "ShipmentAndReturnReferences" Then
		
		Query.Text =
		"SELECT
		|	DataTable.ReferenceOrder,
		|	&UniquenessField,
		|	DataTable.IndicatorIssuedQuantity AS Count
		|INTO TTBillOfLading
		|FROM
		|	#OrdersForShipmentRegisteredRecordsExpanded AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataTable.ReferenceOrder,
		|	&UniquenessField,
		|	DataTable.Count AS Count
		|INTO TTNewInvoiceRegisteredRecords
		|FROM
		|	&TableOfNewRegisteredRecords AS DataTable
		|WHERE
		|	DataTable.Factor = &Factor
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataTable.ReferenceOrder AS ReferenceOrder,
		|	&UniquenessField,
		|	(DataTable.IndicatorForRegistrationQuantityTurnover -
		|		DataTable.IndicatorIssuedQuantityTurnover) AS ToRegisterBalance
		|INTO TTNewRegisterBalancesOrders
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS DataTable
		|WHERE
		|	(DataTable.IndicatorForRegistrationQuantityTurnover -
		|		DataTable.IndicatorIssuedQuantityTurnover) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	DataTable.ReferenceOrder,
		|	&UniquenessField,
		|	DataTable.Count
		|FROM
		|	TTBillOfLading AS DataTable
		|
		|UNION ALL
		|
		|SELECT
		|	DataTable.ReferenceOrder,
		|	&UniquenessField,
		|	-DataTable.Count
		|FROM
		|	TTNewInvoiceRegisteredRecords AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataTable.ReferenceOrder AS OrderDocument,
		|	&UniquenessField,
		|	SUM(DataTable.ToRegisterBalance) AS Count
		|FROM
		|	TTNewRegisterBalancesOrders AS DataTable
		|
		|GROUP BY
		|	DataTable.ReferenceOrder,
		|	&UniquenessField
		|
		|HAVING
		|	SUM(DataTable.ToRegisterBalance) < 0";
		
		If VerificationIndicator = "RegisteredOnReturns" Then

			IndicatorForRegistration = "ToRegisterForReturns";
			IndicatorIsIssued = "RegisteredOnReturns";
		
		ElsIf VerificationIndicator = "Shipped" Then
		
			IndicatorForRegistration = "ToShip";
			IndicatorIsIssued = "Shipped";

		Else
		
			IndicatorForRegistration = "ToRegister";
			IndicatorIsIssued = "Issued_1";

		EndIf;
		
		Query.Text = StrReplace(Query.Text, "IndicatorForRegistration", IndicatorForRegistration);
		Query.Text = StrReplace(Query.Text, "IndicatorIsIssued", IndicatorIsIssued);
		
		Query.Text = StrReplace(Query.Text,
			"&Factor",
			StrTemplate("VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.%1)", IndicatorIsIssued));
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"Recorder IN (&Recorders)
			|		AND Active
			|		AND NOT ReversingEntry";
		TableFormationParameters.Indicators = IndicatorIsIssued;
		TableFormationParameters.Resources = "Count";
		TableFormationParameters.PhysicalTable = True;
		
		OrdersForShipmentRegisteredRecordsExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#OrdersForShipmentRegisteredRecordsExpanded",
			OrdersForShipmentRegisteredRecordsExpanded);
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&Orders)";
		TableFormationParameters.Indicators = IndicatorForRegistration + ", " + IndicatorIsIssued;
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
	Else
		
		Query.Text = 
		"SELECT
		|	&FieldNameOrder,
		|	&UniquenessField,
		|	&NameOfFieldToView
		|INTO TTBillOfLading
		|FROM
		|	#RegisterName AS DataTable
		|WHERE
		|	DataTable.Recorder IN(&Recorders)
		|	AND DataTable.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&FieldNameOrder,
		|	&UniquenessField,
		|	&NameOfFieldToView
		|INTO TTNewInvoiceRegisteredRecords
		|FROM
		|	&TableOfNewRegisteredRecords AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&FieldNameOrder,
		|	&UniquenessField,
		|	&NameOfFieldToViewBalance
		|INTO TTNewRegisterBalancesOrders
		|FROM
		|	#RegisterNameBalance AS DataTable
		|
		|UNION ALL
		|
		|SELECT
		|	&FieldNameOrder,
		|	&UniquenessField,
		|	&NameOfFieldToView
		|FROM
		|	TTBillOfLading AS DataTable
		|
		|UNION ALL
		|
		|SELECT
		|	&FieldNameOrder,
		|	&UniquenessField,
		|	-&NameOfFieldToView
		|FROM
		|	TTNewInvoiceRegisteredRecords AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&FieldNameOrder AS OrderDocument,
		|	&UniquenessField,
		|	SUM(&NameOfFieldToViewBalance) AS Count
		|FROM
		|	TTNewRegisterBalancesOrders AS DataTable
		|
		|GROUP BY
		|	&FieldNameOrder,
		|	&UniquenessField
		|
		|HAVING
		|	SUM(&NameOfFieldToViewBalance) < 0";
		
		TableName = StrTemplate("AccumulationRegister.%1", RegisterName);
		TableNameBalance = StrTemplate("%1.Balance(, &FieldNameOrder IN (&Orders))", TableName);
		
		Query.Text = StrReplace(Query.Text, "#RegisterNameBalance", TableNameBalance);
		Query.Text = StrReplace(Query.Text, "#RegisterName", TableName);
		Query.Text = StrReplace(Query.Text, "&FieldNameOrder", FieldNameOrder);
		Query.Text = StrReplace(Query.Text, "&NameOfFieldToView", NameOfFieldToView);
		
	EndIf;
	
	UniquenessFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
		NamesOfUniquenessFields,
		",",
		True,
		True);
	
	SubstringOfUniquenessFields = "";
	
	For Iteration = 0 To UniquenessFields.Count() - 1 Do
		
		UniquenessField = UniquenessFields[Iteration];
		SubstringOfUniquenessFields = SubstringOfUniquenessFields + "DataTable." + UniquenessField;
		
		If Iteration < UniquenessFields.Count() - 1 Then
			SubstringOfUniquenessFields = SubstringOfUniquenessFields + ",";
		EndIf;
		
		SubstringOfUniquenessFields = SubstringOfUniquenessFields + Chars.LF;
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&UniquenessField", SubstringOfUniquenessFields);
	
	Return Query.Execute().Unload();
	
EndFunction

// Parameters:
// 	Act - DocumentObject - contains including:
// 		* Goods - TabularSection, ValueTable - Table with products, contains, among other things:
// 			** LineNumber  - Number - Line number
// 			** Products - CatalogRef.Products - Products
// 			** Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
// 
Procedure ReportErrorsWhenAddingExcessToInvoice(Act, LinesWithErrors, FieldNameOrder, NamesOfUniquenessFields, Cancel)
	
	UniquenessFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(NamesOfUniquenessFields, ",", True, True);
	
	For Each String In LinesWithErrors Do
		
		// The line number is unknown in advance, because requests work with the invoice and the register, but not the act.
		FilterParameters = New Structure();
		FilterParameters.Insert(FieldNameOrder, String.OrderDocument);
		
		For Each UniquenessField In UniquenessFields Do
			FilterParameters.Insert(UniquenessField, String[UniquenessField]);
		EndDo;
		
		FoundRows = Act.Goods.FindRows(FilterParameters); // Array of LineOfATabularSection
		
		If FoundRows.Count() > 0 Then
			For Each InvoiceLine In FoundRows Do // LineOfATabularSection
				// There may be a second line in the invoice using the same line code to indicate a separate CCD number.
				If InvoiceLine.Count > InvoiceLine.CountByDocument Then
					Break;
				EndIf;
			EndDo;
		Else
			Continue;
		EndIf;
		
		UnitOfMeasure = Common.ObjectAttributeValue(InvoiceLine.Products, "UnitOfMeasure");
		
		MessageTemplate = NStr("vi = 'Mặt hàng %ProductsCharacteristic% 
		|Theo dòng %LineNumber% đã lập nhiều hơn số lượng đã chỉ ra trong lệnh là %Count% %Unit%. Nên tách dòng để phần dư được chuyển vào ""Phần trên đơn hàng""';
		|ru = 'Номенклатура %ProductsCharacteristic% 
		|По строке %LineNumber% оформлено больше, чем указано в распоряжении на оформление, на %Count% %Unit%. Рекомендуется разбить строку, чтобы излишек был внесен ""Сверх заказа""';
		|en = 'Item %ProductsCharacteristic%
		|Registered product quantity exceeds the quantity specified in reference for registration in line %LineNumber% by %Count% %Unit%. Split the line to register surplus ""Exceeding the order""'; fa = 'Item %ProductsCharacteristic%
		|Registered product quantity exceeds the quantity specified in reference for registration in line %LineNumber% by %Count% %Unit%. Split the line to register surplus ""Exceeding the order""';
		|it = 'Articolo %ProductsCharacteristic% 
		|Sulla riga %LineNumber% regolarizzato più di quanto indicato nell''ordine di regolarizzazione, per %Count% %Unit%. È consigliato suddividere la riga in modo che l''eccedenza venga immessa ""Sopra l''ordine""';
		|pl = 'Pozycja %ProductsCharacteristic% 
		|W wierszu %LineNumber% sporządzono więcej niż podano w zleceniu na sporządzenie, na %Count%%Unit%. Zaleca się podzielić wiersze, aby nadwyżka została wpisana ""Ponad zamówienie""';
		|tr = '%ProductsCharacteristic% Öğesi
		| %LineNumber% satırında, düzenlenecek sipariş sayısından %Count%%Unit% kadar daha fazladır. Fazlalığın ""Sipariş fazlası"" olarak girilmesi için satırın bölünmesi tavsiye edilir.'");
		
		ErrorText = StrReplace(MessageTemplate, "%ProductsCharacteristic%",
						ProductsClientServer.ProductPresentation(InvoiceLine.Products,
																			InvoiceLine.Characteristic,
																			,
																			InvoiceLine.Series));
		ErrorText = StrReplace(ErrorText, "%LineNumber%", InvoiceLine.LineNumber);
		ErrorText = StrReplace(ErrorText, "%Count%", String(-String.Count));
		ErrorText = StrReplace(ErrorText, "%Unit%",    String(UnitOfMeasure));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			Act,
			CommonClientServer.PathToTabularSection("Goods", InvoiceLine.LineNumber, "NumberOfPackages"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Table - ValueTable - Table template
// 	TableName - String - Table name in the query text
// Returns:
// 	String - The text of the generated request
Function TemporaryTableFromValueTable(Table, TableName)
	
	Template_Field   = "T.Field AS Field";
	TextAllFields = "";
	Separator  = "";
	For Each Column In Table.Columns Do
		TextAllFields = TextAllFields + Separator + StrReplace(Template_Field, "Field", Column.Name);
		Separator = "," + Chars.LF + Chars.Tab;
	EndDo;
	
	Text =
	"SELECT
	|	T.Field AS Field
	|INTO TTTable
	|FROM
	|	&Table AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Text = StrReplace(Text, "T.Field AS Field", TextAllFields);
	Text = StrReplace(Text, "Table", TableName);
	
	Return Text;

EndFunction

#EndRegion

#Region AvailableWaysOfWorkingOff

// Parameters:
// 	Form - ClientApplicationForm - Change shape
Procedure DetermineAvailableWaysToWorkOutActDependingOnStateOfEDIDocument(Form) Export
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		AddAllPossibleWaysToWorkOutImplementationReport(Form);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		AddAllPossibleWaysToWorkOutActOfAcquisition(Form);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		AddAllPossibleWaysToWorkOutTransferReport(Form);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
			Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		Or Form.Object.TypeOfBaseDocumentForNonConformanceCertificate =
			Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
		Then
		
		AddAllPossibleWaysToWorkOutShipmentReport(Form);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisGoodsReceiptForStorage(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Form.Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		AddAllPossibleWaysToWorkOutActOfAcceptanceAndReceipt(Form);
		
	EndIf;
	
	DiscrepanciesServerLocalization.DetermineAvailableWaysToWorkOutActDependingOnStateOfEDIDocument(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Change shape
Procedure AddAllPossibleWaysToWorkOutActOfAcquisition(Form) Export
	
	AddWaysToWorkOutPurchaseReport(Form);
	AddWaysToWorkOutActOfAcquisitionAdjustment(Form);
		
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList - 
Procedure AddWaysToWorkOutPurchaseReport(Form) Export
	
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments);
	Form.AvailableWaysOfProcessingTheCertificate.Add(Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList - 
Procedure AddWaysToWorkOutActOfAcquisitionAdjustment(Form) Export
	
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries);
	If Form.UseDebitNotes Then
		Form.AvailableWaysOfProcessingTheCertificate.Add(Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries);		
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList - 
Procedure AddAllPossibleWaysToWorkOutImplementationReport(Form) Export
	
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments);
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties);
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments);
			
	Form.AvailableWaysOfProcessingTheCertificate.Add(Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments);
	AddWaysToWorkOutImplementationAdjustments(Form);
		
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList - 
Procedure AddWaysToWorkOutImplementationAdjustments(Form) Export
	
	If Form.UseCreditNotes
			And Form.Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Then
			
		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
		
		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties);
		
		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments);
	
	ElsIf Form.UseCreditNotes
			And Form.Object.BusinessOperation =
				Enums.BusinessTransactions.TransferOfTitleToGoods
		Then

		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
		
		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties);
	
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
Procedure AddAllPossibleWaysToWorkOutTransferReport(Form) Export
	
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(
		Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments);
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(
		Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
	
	Form.AvailableWaysOfProcessingTheCertificate.Add(
		Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments);
	AddWaysToWorkOutTransferAdjustments(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
Procedure AddWaysToWorkOutTransferAdjustments(Form) Export
	
	If Form.UseDocumentCorrection Then
		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
Procedure AddAllPossibleWaysToWorkOutShipmentReport(Form) Export
	
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(
		Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments);
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(
		Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
	
	Form.AvailableWaysOfProcessingTheCertificate.Add(
		Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments);
	AddWaysToWorkOutShipmentAdjustments(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList of EnumRef.MethodsOfRecordingDiscrepanciesCustomerReceivingNote - 
Procedure AddWaysToWorkOutShipmentAdjustments(Form) Export
	
	If Form.UseDocumentCorrection Then
		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList of EnumRef.MethodsOfRecordingDiscrepancyReportsFollowingReceipt - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList of EnumRef.MethodsOfRecordingDiscrepancyReportsFollowingReceipt - 
Procedure AddAllPossibleWaysToWorkOutActOfAcceptanceAndReceipt(Form) Export
	
	AddWaysToWorkOutActOfAcceptanceAndReceiptFix(Form);
	AddWaysToWorkOutActOfAcceptanceAndReceiptCorrection(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList of EnumRef.MethodsOfRecordingDiscrepancyReportsFollowingReceipt - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList of EnumRef.MethodsOfRecordingDiscrepancyReportsFollowingReceipt - 
Procedure AddWaysToWorkOutActOfAcceptanceAndReceiptFix(Form) Export
	
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(
		Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments);
	Form.AvailableWaysOfProcessingTheCertificate.Add(
		Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - Changeable form, contains, among other things:
// 		* AvailableWaysOfProcessingTheCertificateByTheEDIState - ValueList of EnumRef.MethodsOfRecordingDiscrepancyReportsFollowingReceipt - 
// 		* AvailableWaysOfProcessingTheCertificate               - ValueList of EnumRef.MethodsOfRecordingDiscrepancyReportsFollowingReceipt - 
Procedure AddWaysToWorkOutActOfAcceptanceAndReceiptCorrection(Form) Export
	
	Form.AvailableWaysOfProcessingTheCertificateByTheEDIState.Add(
		Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries);
	If Form.UseDocumentCorrection Then
		Form.AvailableWaysOfProcessingTheCertificate.Add(
			Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
