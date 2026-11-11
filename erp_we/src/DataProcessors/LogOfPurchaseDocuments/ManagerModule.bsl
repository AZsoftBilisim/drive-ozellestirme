#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

// Defines the composition of documents and business operations that are available for display in the workplace.
//
// Parameters:
//  FilterBusinessTransactions		 - ValueList - list of values of the enum type Link.Economic operations
//  FilterDocumentTypes				 - ValueList - list of values of the reference Link type.IDs of metadata objectsreferences
//  PurposeUseKey		 - String - key of the workplace for which the function is called.
// 
// Returns:
//   See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Function InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions,
		FilterDocumentTypes, PurposeUseKey) Export
		
	BusinessTransactionsAndDocuments = BusinessTransactionsAndDocuments();
		
	If PurposeUseKey = "PurchaseDocumentsAll" Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments,
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
		
	UseNonConformanceCertificatesFollowingGoodsReceiptForStorage = False;
	UseNonConformanceCertificatesFollowingShipmentByGoodsShipmentsFromStorage = False;
	UseNonConformanceCertificatesFollowingGoodsReceiptForStorage = GetFunctionalOption(
		"UseNonConformanceCertificatesFollowingAcceptance");
	UseNonConformanceCertificatesFollowingShipmentByGoodsShipmentsFromStorage = GetFunctionalOption(
		"UseReportsOfDiscrepanciesAfterShipment");
	UseManagementCompany = GetFunctionalOption(
		"UseManagementCompany");
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance") Then
		LinesToDelete = TableOfValuesAvailable.FindRows(New Structure("FullDocumentName",
			Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName()));
		For Each RowToDelete In LinesToDelete Do
			If RowToDelete.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
				TableOfValuesAvailable.Delete(RowToDelete);
			EndIf;
		EndDo;
	EndIf;
	
	If Not UseNonConformanceCertificatesFollowingGoodsReceiptForStorage Then
		LinesToDelete = TableOfValuesAvailable.FindRows(New Structure("FullDocumentName, BusinessOperation",
																	Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName(),
																	Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale));
		For Each RowToDelete In LinesToDelete Do
			TableOfValuesAvailable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		LinesToDelete = TableOfValuesAvailable.FindRows(New Structure("FullDocumentName",
			Metadata.Documents.DiscrepancyReportFollowingShipment.FullName()));
		For Each RowToDelete In LinesToDelete Do
			If RowToDelete.BusinessOperation <> Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale Then
				TableOfValuesAvailable.Delete(RowToDelete);
			EndIf;
		EndDo;
	EndIf;
	
	If Not UseNonConformanceCertificatesFollowingShipmentByGoodsShipmentsFromStorage Then
		LinesToDelete = TableOfValuesAvailable.FindRows(New Structure("FullDocumentName, BusinessOperation",
																	Metadata.Documents.DiscrepancyReportFollowingShipment.FullName(),
																	Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale));
		For Each RowToDelete In LinesToDelete Do
			TableOfValuesAvailable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not UseManagementCompany Then
		LinesToDelete = TableOfValuesAvailable.FindRows(New Structure("FullDocumentName, BusinessOperation",
																	Metadata.Documents.VendorInvoice.FullName(),
																	Enums.BusinessTransactions.PurchaseFromVendorLocal));
		For Each RowToDelete In LinesToDelete Do
			TableOfValuesAvailable.Delete(RowToDelete);
		EndDo;
	EndIf;
		
	Return TableOfValuesAvailable;
	
EndFunction

Function BusinessTransactionsAndDocuments()
	
	BusinessTransactionsAndDocuments = TMCommonUse.NewTableBusinessOperationsAndDocuments();
	
	// VendorInvoice
	
	LinePurchaseOfGoodsServices = BusinessTransactionsAndDocuments.Add();
	String = LinePurchaseOfGoodsServices;
	String.PurposeUseKey 	= "Invoices";
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromSupplier;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.VendorInvoice");
	String.FullDocumentName			= "Document.VendorInvoice";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (hóa đơn giao hàng)';
								|ru = 'Документы закупки (накладные по приемке)';
								|en = 'Procurement documents (delivery invoices)'; fa = 'Procurement documents (delivery invoices)';
								|it = 'Documenti d''acquisto (le bolle di accettazione)';
								|pl = 'Dokumenty zakupu (faktury po odbiorze)';
								|tr = 'Satın alma belgeleri (kabule göre irsaliye)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfPurchaseDocuments";
	
	LinePurchasingThroughAccountablePerson = BusinessTransactionsAndDocuments.Add();
	LinePurchasingThroughAccountablePerson.BusinessOperation                 = Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	LinePurchasingThroughAccountablePerson.AddButtonCreate                 = True;
	LinePurchasingThroughAccountablePerson.DocumentType                          = Type("DocumentRef.VendorInvoice");
	LinePurchasingThroughAccountablePerson.FullDocumentName                    = "Document.VendorInvoice";
	LinePurchasingThroughAccountablePerson.PurposeUseKey           = "PurchaseViaAdvanceHolder";
	LinePurchasingThroughAccountablePerson.WorkplaceTitle                = NStr("vi = 'Chứng từ mua hàng thông qua một người có trách nhiệm';
																				|ru = 'Документы закупки через подотчетное лицо';
																				|en = 'Document purchases via the advance holder'; fa = 'Document purchases via the advance holder';
																				|it = 'Documenti d''acquisto tramite il titolare di anticipo';
																				|pl = 'Dokumenty zakupu przez osobę odpowiedzialną';
																				|tr = 'Sorumlu bir kişi aracılığıyla satın alma belgeleri'");
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.ConsignmentProcurement;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorLocal;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseByImport;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEU;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LinePurchaseOfGoodsServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportGoodsInTransit;
	
	// DiscrepancyReportFollowingShipment
	
	LineReportOfDiscrepanciesAfterShipment = BusinessTransactionsAndDocuments.Add();
	String = LineReportOfDiscrepanciesAfterShipment;
	String.BusinessOperation 		= Enums.BusinessTransactions.ReturnOfGoodsToVendor;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.DiscrepancyReportFollowingShipment");
	String.FullDocumentName			= "Document.DiscrepancyReportFollowingShipment";
	String.StatusesAreUsed          = True;
	String.PurposeUseKey 	= "DiscrepancyReportFollowingShipment";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (chênh lệch)';
								|ru = 'Документы закупки (расхождения)';
								|en = 'Purchase documents (discrepancies)'; fa = 'Purchase documents (discrepancies)';
								|it = 'Documenti d''acquisto (divergenze)';
								|pl = 'Dokumenty zakupu (odchylenie)';
								|tr = 'Satın alma belgeleri (tutarsızlık)'");
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation 		= Enums.BusinessTransactions.ReturnOfGoodsToConsignor;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation 		= Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale;
	
	// DiscrepancyReportFollowingReceipt
	
	LineReportOfDiscrepanciesAfterAcceptance = BusinessTransactionsAndDocuments.Add();
	String = LineReportOfDiscrepanciesAfterAcceptance;
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromSupplier;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.DiscrepancyReportFollowingReceipt");
	String.FullDocumentName			= "Document.DiscrepancyReportFollowingReceipt";
	String.StatusesAreUsed          = True;
	String.PurposeUseKey 	= "DiscrepancyReportFollowingReceipt";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (chênh lệch)';
								|ru = 'Документы закупки (расхождения)';
								|en = 'Purchase documents (discrepancies)'; fa = 'Purchase documents (discrepancies)';
								|it = 'Documenti d''acquisto (divergenze)';
								|pl = 'Dokumenty zakupu (odchylenie)';
								|tr = 'Satın alma belgeleri (tutarsızlık)'");
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.ConsignmentProcurement;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseByImport;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEU;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterAcceptance);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	
	// IncomeAdjustments
	
	AcquisitionAdjustmentLine = BusinessTransactionsAndDocuments.Add();
	String = AcquisitionAdjustmentLine;
	String.PurposeUseKey 	= "IncomeAdjustments";
	String.BusinessOperation 		= Enums.BusinessTransactions.ErrorCorrection;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.PurchaseAdjustment");
	String.FullDocumentName			= "Document.PurchaseAdjustment";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (Điều chỉnh)';
								|ru = 'Документы закупки (корректировки)';
								|en = 'Purchase documents (adjusting entries)'; fa = 'Purchase documents (adjusting entries)';
								|it = 'Documenti d''acquisto (rettifiche)';
								|pl = 'Dokumenty zakupu (zapisy korygujące)';
								|tr = 'Satın alma belgeleri (düzeltme)'");
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation		= Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated;

	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation		= Enums.BusinessTransactions.PurchaseFromSupplier;
	String.AddButtonCreate		= False;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit;
	String.AddButtonCreate		= False;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
	String.AddButtonCreate		= False;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEU;
	String.AddButtonCreate		= False;

	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit;
	String.AddButtonCreate		= False;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,AcquisitionAdjustmentLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	String.AddButtonCreate		= False;
	
	// WriteOffDiscrepanciesBetweenReceiptAndPurchase
	
	LineWriteOffOfDiscrepanciesReceiptPurchase = BusinessTransactionsAndDocuments.Add();
	String = LineWriteOffOfDiscrepanciesReceiptPurchase;
	String.PurposeUseKey 	= "WriteOffDiscrepanciesBetweenReceiptAndPurchase";
	String.BusinessOperation 		= Enums.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.WriteOffDiscrepanciesBetweenReceiptAndPurchase");
	String.FullDocumentName			= "Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (Điều chỉnh)';
								|ru = 'Документы закупки (корректировки)';
								|en = 'Purchase documents (adjusting entries)'; fa = 'Purchase documents (adjusting entries)';
								|it = 'Documenti d''acquisto (rettifiche)';
								|pl = 'Dokumenty zakupu (zapisy korygujące)';
								|tr = 'Satın alma belgeleri (düzeltme)'");
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		String = BusinessTransactionsAndDocuments.Add();
		FillPropertyValues(String,AcquisitionAdjustmentLine);
		String.BusinessOperation 		= Enums.BusinessTransactions.AdjustBeforeEnteringBalance;
	EndIf;
	
	// VendorInvoiceServicesAndAssets
	
	LineReceiptOfServices = BusinessTransactionsAndDocuments.Add();
	String = LineReceiptOfServices;
	String.PurposeUseKey 	= "ProceedsFromOtherAssets";
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromSupplier;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.VendorInvoiceServicesAndAssets");
	String.FullDocumentName			= "Document.VendorInvoiceServicesAndAssets";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (hóa đơn)';
								|ru = 'Документы закупки (накладные)';
								|en = 'Purchase documents (invoices)'; fa = 'Purchase documents (invoices)';
								|it = 'Documenti d''acquisto (bolle)';
								|pl = 'Dokumenty zakupu (faktury)';
								|tr = 'Satın alma belgeleri (irsaliye)'");
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReceiptOfServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	
	// ReturnOfGoodsToVendor
	
	ReturnOfGoodsToSupplierLine = BusinessTransactionsAndDocuments.Add();
	
	String                                       = ReturnOfGoodsToSupplierLine;
	String.PurposeUseKey           = "ReturnOfGoodsToVendor";
	String.BusinessOperation                 = Enums.BusinessTransactions.ReturnOfGoodsToVendor;
	String.AddButtonCreate                 = True;
	String.DocumentType                          = Type("DocumentRef.ReturnOfGoodsToVendor");
	String.FullDocumentName                    = "Document.ReturnOfGoodsToVendor";
	String.WorkplaceTitle                = NStr("vi = 'Chứng từ mua hàng (Trả lại cho nhà cung cấp)';
												|ru = 'Документы закупки (возвраты поставщикам)';
												|en = 'Purchase documents (returns to vendors)'; fa = 'Purchase documents (returns to vendors)';
												|it = 'Documenti d''acquisto (resi ai fornitori)';
												|pl = 'Dokumenty zakupu (zwroty dostawcom)';
												|tr = 'Satın alma belgeleri (Tedarikçilere iadeler)'");
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String, ReturnOfGoodsToSupplierLine);
	String.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor;
	
	#Region AcceptanceOfGoodsForStorage
	
	// GoodsReceiptForStorage
	String = BusinessTransactionsAndDocuments.Add();
	String.PurposeUseKey 	= "GoodsReceiptForStorage";
	String.BusinessOperation 		= Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.GoodsReceiptForStorage");
	String.FullDocumentName			= "Document.GoodsReceiptForStorage";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (chấp nhận lưu trữ)';
								|ru = 'Документы закупки (приемка на хранение)';
								|en = 'Purchase documents (receiving for storage)'; fa = 'Purchase documents (receiving for storage)';
								|it = 'Documenti d''acquisto (accettazione in deposito)';
								|pl = 'Dokumenty zakupu (przyjęcie na przechowanie)';
								|tr = 'Satın alma belgeleri (depoya kabul)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfPurchaseDocuments";
	
	// GoodsShipmentFromStorage
	String = BusinessTransactionsAndDocuments.Add();
	String.PurposeUseKey = "GoodsShipmentFromStorage";
	String.BusinessOperation       = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale;
	String.AddButtonCreate       = True;
	String.DocumentType                = Type("DocumentRef.GoodsShipmentFromStorage");
	String.FullDocumentName          = "Document.GoodsShipmentFromStorage";
	String.WorkplaceTitle      = NStr("vi = 'Chứng từ mua hàng (vận chuyển từ kho)';
										|ru = 'Документы закупки (отгрузки с хранения)';
										|en = 'Purchase documents (VMI pick-up requests from vendors)'; fa = 'Purchase documents (VMI pick-up requests from vendors)';
										|it = 'Documenti d''acquisto (spedizioni dal deposito)';
										|pl = 'Dokumenty zakupu (wysyłki z przechowania)';
										|tr = 'Satın alma belgeleri (depodan transfer)'");
	
	// RedemptionOfGoodsFromStorage
	String = BusinessTransactionsAndDocuments.Add();
	String.PurposeUseKey           = "RedemptionOfGoodsFromStorage";
	String.BusinessOperation                 = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage;
	String.AddButtonCreate                 = True;
	String.DocumentType                          = Type("DocumentRef.RedemptionOfGoodsFromStorage");
	String.FullDocumentName                    = "Document.RedemptionOfGoodsFromStorage";
	String.WorkplaceTitle                = NStr("vi = 'Chứng từ mua hàng (mua hàng hóa)';
												|ru = 'Документы закупки (выкупы товаров)';
												|en = 'Procurement documents (goods purchases)'; fa = 'Procurement documents (goods purchases)';
												|it = 'Documenti d''acquisto (riscatti delle merci)';
												|pl = 'Dokumenty zakupu (wykup towarów)';
												|tr = 'Satın alma belgeleri (malların alınması)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.RedemptionOfGoodsFromStorage";
	
	// ReportOnVMIAdjustment
	String = BusinessTransactionsAndDocuments.Add();
	String.PurposeUseKey           = "ReportOnVMIAdjustment";
	String.BusinessOperation                 = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses;
	String.AddButtonCreate                 = True;
	String.DocumentType                          = Type("DocumentRef.ReportOnVMIAdjustment");
	String.FullDocumentName                    = "Document.ReportOnVMIAdjustment";
	String.WorkplaceTitle                = NStr("vi = 'Chứng từ mua hàng (ghi giảm khỏi lưu trữ)';
												|ru = 'Документы закупки (списания с хранения)';
												|en = 'Procurement documents (VMI adjustments)'; fa = 'Procurement documents (VMI adjustments)';
												|it = 'Documenti d''acquisto (storni dal deposito)';
												|pl = 'Dokumenty zakupu (rozchody z przechowania)';
												|tr = 'Satın alma belgeleri (Depodan gider yazma)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.ReportOnVMIAdjustment";
	
	WriteOffLine = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(WriteOffLine, String);
	WriteOffLine.BusinessOperation = Enums.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor;
	
	#EndRegion
	
	// UninvoicedReceipt
	
	LineReceiptOfGoods = BusinessTransactionsAndDocuments.Add();
	String = LineReceiptOfGoods;
	String.PurposeUseKey 	= "Invoices";
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.ReceiptOfGoodsToWarehouse");
	String.FullDocumentName			= "Document.ReceiptOfGoodsToWarehouse";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (hóa đơn giao hàng)';
								|ru = 'Документы закупки (накладные по приемке)';
								|en = 'Procurement documents (delivery invoices)'; fa = 'Procurement documents (delivery invoices)';
								|it = 'Documenti d''acquisto (le bolle di accettazione)';
								|pl = 'Dokumenty zakupu (faktury po odbiorze)';
								|tr = 'Satın alma belgeleri (kabule göre irsaliye)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfPurchaseDocuments";
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReceiptOfGoods);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReceiptOfGoods);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReceiptOfGoods);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineReceiptOfGoods);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery;
	NonCurrentAssets.CompleteDescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments);
	LineCustomsDeclarationImport = BusinessTransactionsAndDocuments.Add();
	String = LineCustomsDeclarationImport;
	String.PurposeUseKey 	= "CCDsImport";
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseByImport;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.CCDImport");
	String.FullDocumentName			= "Document.CCDImport";
	String.StatusesAreUsed          = True;
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (TKHQ)';
								|ru = 'Документы закупки (ГТД)';
								|en = 'Purchase documents (CCD)'; fa = 'Purchase documents (CCD)';
								|it = 'Documenti di acquisto (DDT)';
								|pl = 'Dokumenty zakupu (ŁDC)';
								|tr = 'Satın alma belgeleri (GB)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.CCDImport";
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineCustomsDeclarationImport);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineCustomsDeclarationImport);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineCustomsDeclarationImport);
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
	
	// ReceiptOfServicesToBusinessUnit
	
	String = BusinessTransactionsAndDocuments.Add();
	String.PurposeUseKey 	= "Invoices";
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.ReceiptOfServicesToBusinessUnit");
	String.FullDocumentName			= "Document.ReceiptOfServicesToBusinessUnit";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (hóa đơn giao hàng)';
								|ru = 'Документы закупки (накладные по приемке)';
								|en = 'Procurement documents (delivery invoices)'; fa = 'Procurement documents (delivery invoices)';
								|it = 'Documenti d''acquisto (le bolle di accettazione)';
								|pl = 'Dokumenty zakupu (faktury po odbiorze)';
								|tr = 'Satın alma belgeleri (kabule göre irsaliye)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfPurchaseDocuments";
	
	VATAccountingERP.DescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments);
	
	Return BusinessTransactionsAndDocuments;
	
EndFunction

// The default form assignment key.
// 
// Returns:
//  String - ID of the default "Purchase Document Log" processing forms.
Function DefaultFormAssignmentKey() Export
	
	Return "PurchaseDocumentsAll";
	
EndFunction

#EndRegion

#Region Private

// Parameters:
// 	Commands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
Procedure OnDefineCommandsAttachedToObject(Commands) Export
	
	ArrayOfReportCommands = Commands.FindRows(New Structure("Kind", "Reports"));
	ArrayOfPrintCommands = Commands.FindRows(New Structure("Kind", "Print"));
	
	DocumentExecutionStateManager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
	ManagerStateOfSettlementsWithSuppliers = Metadata.Reports.StateOfVendorAccountsPayable.FullName();
	ManagerCardOfSettlementsWithSuppliers = Metadata.Reports.VendorARAPOpenItems.FullName();
	ManagerPaymentCardForAcceptedReturnContainers = Metadata.Reports.ARAPAccountingStatementByReturnablePackagingReceived.FullName();
	ManagerDeviationsFromTermsOfPurchase = Metadata.Reports.VariancesFromPurchaseConditions.FullName();
	ManagerSupplierPriceAnalysis = Metadata.Reports.PriceAnalysis.FullName();
	
	For Each CurTeam In ArrayOfReportCommands Do
		If CurTeam.Manager = DocumentExecutionStateManager Then
			CurTeam.Order = 1;
			CurTeam.VisibilityInForms = "DocumentsList, FormCreatedDocuments";
		EndIf;
		If CurTeam.Manager = ManagerStateOfSettlementsWithSuppliers Then
			CurTeam.Importance = "Ordinary";
			CurTeam.Order = 1;
		EndIf;
		If CurTeam.Manager = ManagerCardOfSettlementsWithSuppliers Then
			CurTeam.Importance = "Ordinary";
			CurTeam.Order = 2;
		EndIf;
		If CurTeam.Manager = ManagerPaymentCardForAcceptedReturnContainers Then
			CurTeam.Importance = "Ordinary";
			CurTeam.Order = 3;
		EndIf;
		If CurTeam.Manager = ManagerDeviationsFromTermsOfPurchase Then
			CurTeam.Importance = "SeeAlso";
			CurTeam.Order = 1;
		EndIf;
		If CurTeam.Manager = ManagerSupplierPriceAnalysis Then
			CurTeam.Importance = "SeeAlso";
			CurTeam.Order = 2;
		EndIf;
	EndDo;
	
	LogOfPurchaseDocumentsLocalization.OnDefineCommandsAttachedToObject(Commands);
	
	For Each CurTeam In ArrayOfPrintCommands Do
		CurTeam.VisibilityInForms = "DocumentsList";
	EndDo;
	
EndProcedure

Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export

	Result = New Structure("ToRegister, SeeAlsoInProgress");

	Result.ToRegister = TMCommonUse.CreateHyperlinkToDesign(Parameters[0], Parameters[1]);
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.IssuedLetterOfAuthority");
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.PurchaseOrder");
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption");
	
	LogOfPurchaseDocumentsLocalization.WhenDefiningSourcesForRegistration(ArrayCalculationManagersSeeAlsoInWork);
	
	Result.SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, Parameters[1]);

	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#Region CreatingHyperlinkInPurchaseLog 

Function QueryTextOrdersToBeRegistered(Organization = Undefined, Warehouse = Undefined, ReferencesArrray = Undefined)
	
	QueryText = 
	"SELECT TOP 1 ALLOWED
	|	PurchaseOrders.PurchaseOrder AS Ref
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder REFS Document.PurchaseOrder AND &FilterCriterion) AS PurchaseOrders
	|WHERE
	|	PurchaseOrders.ToRegisterBalance > 0";
	
	FilterCriterion = "TRUE";
	If ValueIsFilled(Organization) Then
		FilterCriterion = FilterCriterion + "
		|AND PurchaseOrder.Organization = &Organization";
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		FilterCriterion = FilterCriterion + "
		|AND PurchaseOrder.Warehouse = &Warehouse";
	EndIf;
	
	If ValueIsFilled(ReferencesArrray) Then
		FilterCriterion = FilterCriterion + "
		|AND PurchaseOrder.Ref IN (&ReferencesArrray)";
	EndIf;
	
	QueryText = StrReplace(QueryText,"&FilterCriterion", FilterCriterion);
	Return QueryText
	
EndFunction

Function QueryTextReceiptRefs(Organization = Undefined, Warehouse = Undefined, ReferencesArrray = Undefined)
	
	QueryText = 
	"SELECT DISTINCT TOP 1 ALLOWED
	|	TableOfOrders.DocumentInflow AS Ref,
	|	MAX(TableOfOrders.Warehouse) AS Warehouse,
	|	MAX(TableOfOrders.Products) AS Products,
	|	MAX(TableOfOrders.Characteristic) AS Characteristic,
	|	MAX(TableOfOrders.Purpose) AS Purpose,
	|	MAX(TableOfOrders.Series) AS Series,
	|	MAX(TableOfOrders.Sender) AS Sender
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			(DocumentInflow REFS Document.PurchaseOrder
	|				OR DocumentInflow REFS Document.VendorInvoice
	|				OR DocumentInflow REFS Document.GoodsReceiptForStorage
	|				OR DocumentInflow REFS Catalog.CounterpartyContracts
	|				OR DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors)
	|				AND &FilterCriterion) AS TableOfOrders
	|WHERE
	|	TableOfOrders.ToRegisterGoodsReceiptsBalance <> 0
	|	AND &FilterCriterion
	|
	|GROUP BY
	|	TableOfOrders.DocumentInflow";
	
	FilterCriterion = "TRUE";
	If ValueIsFilled(Organization) Then
		FilterCriterion = FilterCriterion + "
		|AND DocumentInflow.Organization = &Organization";
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		FilterCriterion = FilterCriterion + "
		|AND DocumentInflow.Warehouse = &Warehouse";
	EndIf;
	
	If ValueIsFilled(ReferencesArrray) Then
		FilterCriterion = FilterCriterion + "
		|AND DocumentInflow.Ref IN (&ReferencesArrray)";
	EndIf;
	
	QueryText = StrReplace(QueryText,"&FilterCriterion", FilterCriterion);
	
	Return QueryText
	
EndFunction

Function ThereAreOrdersForRegistration(Organization = Undefined, Warehouse = Undefined) Export
	
	If Not (AccessRight("Read", Metadata.Documents.PurchaseOrder)
		And AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive)) Then
		Return False;
	EndIf;
	
	QueryText = QueryTextOrdersToBeRegistered(Organization, Warehouse);

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function ThereAreOrdersForAcceptance(Organization = Undefined, Warehouse = Undefined) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
		Return False;
	EndIf;
	
	QueryText = QueryTextReceiptRefs(Organization, Warehouse);

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Not Query.Execute().IsEmpty();
		
EndFunction

Function CreateHyperlinkToDesign(Parameters) Export
	
	Organization = Parameters.Organization;
	Warehouse = Parameters.Warehouse;
	
	ShowOrders = GetFunctionalOption("UsePurchaseOrders")
		And AccessRight("Read", Metadata.Documents.PurchaseOrder)
		And AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
	
	ShowAcceptanceOrders = WarehousesServer.ThereIsOrderForReceiptWarehouse(Warehouse,CurrentSessionDate())
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
		
	ShowOrdersForReceipts = (GetFunctionalOption("UseUninvoicedDeliveries")
		Or GetFunctionalOption("UseGoodsInTransitFromVendors"))
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
		
	HyperlinkForOrders = Undefined;
	AcceptanceHyperlink = Undefined;
	HyperlinkForReceipts = Undefined;
	
	TextHyperlinkForReceipts = NStr("vi = 'Tiếp nhận';
									|ru = 'Поступления';
									|en = 'Receipts'; fa = 'دریافت‌ها';
									|it = 'Поступления';
									|pl = 'Wpływy';
									|tr = 'Teslim alım/makbuz'");
	HyperlinkTextForOrders = NStr("vi = 'Mua lại';
									|ru = 'Приобретения';
									|en = 'Purchases'; fa = 'خریدها';
									|it = 'Acquisizioni';
									|pl = 'Zakupy';
									|tr = 'Satın alma'");
	TextOfAcceptanceHyperlink = NStr("vi = 'Kiểm soát đơn hàng';
									|ru = 'Контроль ордеров';
									|en = 'Goods receipt control'; fa = 'کنترل دریافت کالا';
									|it = 'Verifica dei mandati';
									|pl = 'Kontrola asygnat';
									|tr = 'Giriş fişi kontrolü'");
	
	ColorUnfilled = StyleColors.EmptyTableField;
	FilledColor = StyleColors.HyperlinkColor;
	
	RowsArray = New Array;
	
	If ShowOrders Then
		ThereAreOrders = ThereAreOrdersForRegistration(Organization, Warehouse);
		HyperlinkForOrders = New FormattedString(HyperlinkTextForOrders,,
			?(ThereAreOrders,FilledColor,ColorUnfilled),
			,
			"PageOfTheOrderForRegistration");
		RowsArray.Add(HyperlinkForOrders);
	EndIf;
	
	If ShowOrdersForReceipts Then
		ThereAreOrders_ = ThereAreOrdersForAdmission(Organization, Warehouse);
		HyperlinkForReceipts = New FormattedString(TextHyperlinkForReceipts,,
			?(ThereAreOrders_,FilledColor,ColorUnfilled),
			,
			"ReceiptOrderPage");
			
		If RowsArray.Count() > 0 Then
			RowsArray.Add("; ");
		EndIf;
		RowsArray.Add(HyperlinkForReceipts)
	EndIf;
	
	If ShowAcceptanceOrders Then
		ThereAreOrders_ = ThereAreOrdersForAcceptance(Organization, Warehouse);
		AcceptanceHyperlink = New FormattedString(TextOfAcceptanceHyperlink,,
			?(ThereAreOrders_,FilledColor,ColorUnfilled),
			,
			"PageReceivingReferences");
			
		If RowsArray.Count() > 0 Then
			RowsArray.Add("; ");
		EndIf;
		RowsArray.Add(AcceptanceHyperlink);
	EndIf;
	
	If RowsArray.Count() > 0 Then
		Return New FormattedString(RowsArray);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function QueryTextReceiptOrders(Organization = Undefined, Warehouse = Undefined, ReferencesArrray = Undefined)
	
	QueryText = 
	"SELECT DISTINCT TOP 1 ALLOWED
	|	TableOfOrders.DocumentInflow AS Ref,
	|	MAX(TableOfOrders.Warehouse) AS Warehouse,
	|	MAX(TableOfOrders.Products) AS Products,
	|	MAX(TableOfOrders.Characteristic) AS Characteristic,
	|	MAX(TableOfOrders.Purpose) AS Purpose,
	|	MAX(TableOfOrders.Series) AS Series,
	|	MAX(TableOfOrders.Sender) AS Sender
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			(DocumentInflow REFS Document.PurchaseOrder
	|				OR DocumentInflow REFS Document.VendorInvoice
	|				OR DocumentInflow REFS Document.GoodsReceiptForStorage
	|				OR DocumentInflow REFS Catalog.CounterpartyContracts
	|				OR DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors)
	|				AND BusinessOperation IN (&ListOfBusinessTransactions)
	|				AND &FilterCriterion) AS TableOfOrders
	|WHERE
	|	(TableOfOrders.ToRegisterReceiptsByInvoicesBalance <> 0
	|	OR TableOfOrders.ToRegisterReceiptsByReferenceBalance <> 0)
	|	AND &FilterCriterion
	|
	|GROUP BY
	|	TableOfOrders.DocumentInflow";
	
	FilterCriterion = "TRUE";
	If ValueIsFilled(Organization) Then
		FilterCriterion = FilterCriterion + "
		|AND DocumentInflow.Organization = &Organization";
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		FilterCriterion = FilterCriterion + "
		|AND DocumentInflow.Warehouse = &Warehouse";
	EndIf;
	
	If ValueIsFilled(ReferencesArrray) Then
		FilterCriterion = FilterCriterion + "
		|AND DocumentInflow.Ref IN (&ReferencesArrray)";
	EndIf;
	
	QueryText = StrReplace(QueryText,"&FilterCriterion", FilterCriterion);
	
	Return QueryText
	
EndFunction

Function ThereAreOrdersForAdmission(Organization = Undefined, Warehouse = Undefined) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
		Return False;
	EndIf;
	
	QueryText = QueryTextReceiptOrders(Organization, Warehouse);

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("ListOfBusinessTransactions", PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections());
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	BusinessTransactionsAndDocuments = BusinessTransactionsAndDocuments();
	FoundRows = BusinessTransactionsAndDocuments.FindRows(
		New Structure("PurposeUseKey", Parameters.PurposeUseKey));
	
	If FoundRows.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	//All lines with the same key must have the same workplace header 
	StringByUseDestinationKey = FoundRows[0];
	
	Return New FormattedString(StringByUseDestinationKey.WorkplaceTitle, , , ,
				"DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList");
	
EndFunction


#EndRegion

#EndRegion

#EndIf
