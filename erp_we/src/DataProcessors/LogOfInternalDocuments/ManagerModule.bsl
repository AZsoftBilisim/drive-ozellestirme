
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function DescriptionOfOperationsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes) Export
	
	#Region AssemblyFromComponents
	
	ProductAssemblyLine = VTBusinessTransactionsAndDocumentTypes.Add();
	String = ProductAssemblyLine;
	String.BusinessOperation		= Enums.BusinessTransactions.AssemblyFromComponents;
	String.PurposeUseKey	= "AssemblyDisassemblyOfGoods_";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (đóng bộ hàng hóa)';
										|ru = 'Внутренние документы (сборки товаров)';
										|en = 'Internal documents (product kitting)'; fa = 'Internal documents (product kitting)';
										|it = 'Documenti interni (montaggio delle merci)';
										|pl = 'Dokumenty na rozchód materiałów  (składanki towarów)';
										|tr = 'Dahili belgeler (ürün montajı)'");
	String.DocumentType					= Type("DocumentRef.AssemblyFromComponents");
	String.FullDocumentName			= Metadata.Documents.AssemblyFromComponents.FullName();
	String.StatusesAreUsed			= GetFunctionalOption("UseGoodsAssemblyStatuses");
	String.AddButtonCreate		= True;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfInternalDocuments";
	String.KeyHeaderFields			= Documents.AssemblyFromComponents.KeyFieldsOfHeader();
	String.TitleOfTheReissueForm	= NStr("vi = 'Lập lại chứng từ đóng bộ hàng hóa theo lệnh đã chọn';
											|ru = 'Переоформление сборки товаров по выбранным распоряжениям';
											|en = 'Reregister product kitting according to the selected references'; fa = 'Reregister product kitting according to the selected references';
											|it = 'La formalizzazione sostitutiva di montaggio delle merci per disposizioni selezionate';
											|pl = 'Ponowne przygotowanie zbioru wierszy pozycji dla wybranych zamówień';
											|tr = 'Seçilen emirlere göre ürün montajının yeniden düzenlenmesi'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, ProductAssemblyLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.DisassemblyIntoComponents;
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (tách bộ hàng hóa)';
										|ru = 'Внутренние документы (разборки товаров)';
										|en = 'Internal documents (reverse kitting of goods)'; fa = 'Internal documents (reverse kitting of goods)';
										|it = 'Documenti interni (smontaggio delle merci)';
										|pl = 'Dokumenty na rozchód materiałów  (rozbiórki towarów)';
										|tr = 'Dahili belgeler (ürün demontajı)'");
	String.TitleOfTheReissueForm	= NStr("vi = 'Gia hạn việc tháo gỡ hàng hóa theo đơn đặt hàng đã chọn';
											|ru = 'Переоформление разборки товаров по выбранным распоряжениям';
											|en = 'Reregister reverse kitting of goods  for the selected references'; fa = 'Reregister reverse kitting of goods  for the selected references';
											|it = 'La formalizzazione sostitutiva di smontaggio delle merci per disposizioni selezionate';
											|pl = 'Ponowne przygotowanie rozbierania wierszy towarów dla wybranych zamówień';
											|tr = 'Seçilen emirlere göre ürün demontajının yeniden düzenlenmesi'");
	
	#EndRegion
	
	#Region InventoryConsumption
	
	LineInternalConsumption = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineInternalConsumption;
	String.BusinessOperation		= Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	String.PurposeUseKey	= "DomesticConsumption";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (tiêu dùng nội bộ)';
										|ru = 'Внутренние документы (внутренние потребления)';
										|en = 'Inventory consumption — Non-operational activities'; fa = 'مصرف موجودی — فعالیت‌های غیرعملیاتی';
										|it = 'Documenti interni (consumo interno)';
										|pl = 'Dokumenty wewnętrzne (wewnętrzne zużycie towarów)';
										|tr = 'Dahili belgeler (stok tüketimi)'");
	String.DocumentType					= Type("DocumentRef.InventoryConsumption");
	String.FullDocumentName			= Metadata.Documents.InventoryConsumption.FullName();
	String.StatusesAreUsed			= GetFunctionalOption("UseInventoryConsumptionStatuses");
	String.AddButtonCreate		= True;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfInternalDocuments";
	String.KeyHeaderFields			= Documents.InventoryConsumption.KeyFieldsOfHeader();
	String.TitleOfTheReissueForm	= NStr("vi = 'Lập lại chứng từ ghi giảm hàng hóa theo lệnh đã chọn';
											|ru = 'Переоформление списания товаров по выбранным распоряжениям';
											|en = 'Reregister goods write-off of the selected references'; fa = 'Reregister goods write-off of the selected references';
											|it = 'La formalizzazione sostitutiva di storno delle merci per disposizioni selezionate';
											|pl = 'Ponowne przygotowanie rozchodów towarów dla wybranych zamówień';
											|tr = 'Seçilen emirlere göre ürün gider yazmanın yeniden düzenlenmesi'");
	
	#EndRegion
	
	#Region InventoryTransfer
	
	MovingGoodsLine = VTBusinessTransactionsAndDocumentTypes.Add();
	String = MovingGoodsLine;
	String.BusinessOperation		= Enums.BusinessTransactions.InventoryTransfer;
	String.PurposeUseKey	= "MovementOfGoods_1";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (vận chuyển hàng hóa)';
										|ru = 'Внутренние документы (перемещения товаров)';
										|en = 'Internal documents (inventory transfers)'; fa = 'Internal documents (inventory transfers)';
										|it = 'Documenti interni (movimentazioni delle merci)';
										|pl = 'Dokumenty na rozchód materiałów  (przemieszczenia towarów)';
										|tr = 'Dahili belgeler (mal transferi)'");
	String.DocumentType					= Type("DocumentRef.InventoryTransfer");
	String.FullDocumentName			= Metadata.Documents.InventoryTransfer.FullName();
	String.StatusesAreUsed			= GetFunctionalOption("UseGoodsTransferStatuses");
	String.AddButtonCreate		= True;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfInternalDocuments";
	String.KeyHeaderFields			= Documents.InventoryTransfer.KeyFieldsOfHeader();
	String.TitleOfTheReissueForm	= NStr("vi = 'Đăng ký lại vận chuyển hàng hóa theo đơn đặt hàng đã chọn';
											|ru = 'Переоформление перемещения товаров по выбранным распоряжениям';
											|en = 'Reregister inventory transfer for the selected references'; fa = 'Reregister inventory transfer for the selected references';
											|it = 'La formalizzazione sostitutiva di movimentazione delle merci per disposizioni selezionate';
											|pl = 'Ponowne przygotowanie przemieszczenia towarów dla wybranych zamówień';
											|tr = 'Seçilen emirlere göre mal transferinin yeniden düzenlenmesi'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, MovingGoodsLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices;
	String.TitleOfTheReissueForm	= NStr("vi = 'Lập lại chứng từ điều chuyển hàng hóa giữa các chi nhánh theo lệnh được chọn';
											|ru = 'Переоформление перемещения товаров между филиалами по выбранным распоряжениям';
											|en = 'Reregister inventory transfer between branch offices for the selected references'; fa = 'Reregister inventory transfer between branch offices for the selected references';
											|it = 'La formalizzazione sostitutiva di movimentazione delle merci tra le filiali per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie przemieszczania towarów między oddziałami firmy wg wybranych zamówień';
											|tr = 'Seçilen emirlere göre şubeler arası mal transferinin yeniden düzenlenmesi'");
	
	#EndRegion
	
	#Region DiscrepancyReportFollowingTransfer
	
	LineReportOfDiscrepanciesAfterRelocation = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineReportOfDiscrepanciesAfterRelocation;
	String.BusinessOperation		= Enums.BusinessTransactions.InventoryTransfer;
	String.PurposeUseKey	= "DiscrepancyReportsFollowingTransfer";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (Biên bản chênh lệch sau khi điều chuyển)';
										|ru = 'Внутренние документы (акты о расхождениях после перемещения)';
										|en = 'Internal documents (stock transfer discrepancy reports)'; fa = 'Internal documents (stock transfer discrepancy reports)';
										|it = 'Documenti interni (atti di divergenze dopo le movimentazioni)';
										|pl = 'Dokumenty na rozchód materiałów  (Protokoły o odchyleniu po przemieszczeniu)';
										|tr = 'Dahili belgeler (transfer sonrası tutarsızlıklar raporu)'");
	String.DocumentType					= Type("DocumentRef.DiscrepancyReportFollowingTransfer");
	String.FullDocumentName			= Metadata.Documents.DiscrepancyReportFollowingTransfer.FullName();
	String.StatusesAreUsed			= True;
	String.AddButtonCreate		= True;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, LineReportOfDiscrepanciesAfterRelocation);
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices;
	
	#EndRegion
	
	#Region OtherGoodsRecordingAsReceived
	
	OtherProductRegistrationLine = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OtherProductRegistrationLine;
	String.BusinessOperation		= Enums.BusinessTransactions.ReceiptFromProduction;
	String.PurposeUseKey	= "OtherGoodsRecordingAsReceived";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (ghi tăng hàng hóa khác)';
										|ru = 'Внутренние документы (прочие оприходования товаров)';
										|en = 'Internal documents (other recording of goods as received)'; fa = 'Internal documents (other recording of goods as received)';
										|it = 'Documenti interni (altre registrazioni merci)';
										|pl = 'Dokumenty na rozchód materiałów (pozostałe przeniesienia towarów)';
										|tr = 'Dahili belgeler (diğer mal girişi)'");
	String.DocumentType					= Type("DocumentRef.OtherGoodsRecordingAsReceived");
	String.FullDocumentName			= Metadata.Documents.OtherGoodsRecordingAsReceived.FullName();
	String.StatusesAreUsed			= False;
	String.AddButtonCreate		= True;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfInternalDocuments";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, OtherProductRegistrationLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.InventoryConsumptionReverseTransaction;
	String.HyperlinkCalculationManagerForRegistration = "";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, OtherProductRegistrationLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities;
	String.HyperlinkCalculationManagerForRegistration = "";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, OtherProductRegistrationLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsReceiptByExpencesAssets;
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, OtherProductRegistrationLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.RegistrationAtFADisposal;
	String.HyperlinkCalculationManagerForRegistration = "";
	#EndRegion
	
	#Region WarehouseActs
	
	// Registration of surplus goods.
	WarehouseReportsLine = VTBusinessTransactionsAndDocumentTypes.Add();
	String = WarehouseReportsLine;
	String.BusinessOperation		= Enums.BusinessTransactions.GoodsRecordingAsReceived;
	String.PurposeUseKey	= "";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (Biên bản kho)';
										|ru = 'Внутренние документы (складские акты)';
										|en = 'Internal documents (inventory adjustments)'; fa = 'Internal documents (inventory adjustments)';
										|it = 'Documenti interni (atti di magazzino)';
										|pl = 'Dokumenty na rozchód materiałów  (magazynowe akty)';
										|tr = 'Dahili belgeler (stok düzeltmeleri)'");
	String.DocumentType					= Type("DocumentRef.InventorySurplusRecognition");
	String.FullDocumentName			= Metadata.Documents.InventorySurplusRecognition.FullName();
	String.StatusesAreUsed			= False;
	String.AddButtonCreate		= True;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.WarehouseGoodsIssueReceipt";
	
	// Re-sorting of goods.
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, WarehouseReportsLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsMisgrading;
	String.DocumentType					= Type("DocumentRef.GoodsMisgrading");
	String.FullDocumentName			= Metadata.Documents.GoodsMisgrading.FullName();
	
	// Damage to goods.
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, WarehouseReportsLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsDamage;
	String.DocumentType					= Type("DocumentRef.GoodsDamage");
	String.FullDocumentName			= Metadata.Documents.GoodsDamage.FullName();
	
	// Write-off of shortages of goods.
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, WarehouseReportsLine);
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsConsumption;
	String.DocumentType					= Type("DocumentRef.WriteOffOfGoodsShortages");
	String.FullDocumentName			= Metadata.Documents.WriteOffOfGoodsShortages.FullName();
	
	#EndRegion
	
	
	#Region MovementOfProductsAndMaterials
	
	AvailableDocumentOperations = Documents.MovementOfProductsAndMaterials.TransactionList();
	
	DefaultProperties = New Structure(
		"PurposeUseKey,WorkplaceTitle,DocumentType,FullDocumentName,StatusesAreUsed,
		|AddButtonCreate,KeyHeaderFields, TitleOfTheReissueForm,HyperlinkCalculationManagerForRegistration");
	
	DefaultProperties.PurposeUseKey  = "";
	DefaultProperties.WorkplaceTitle       = NStr("vi = 'Chứng từ nội bộ (biến động sản phẩm và nguyên vật liệu)';
													|ru = 'Внутренние документы (движения продукции и материалов)';
													|en = 'Internal documents (transfer of products and materials)'; fa = 'Internal documents (transfer of products and materials)';
													|it = 'Documenti interni (movimentazioni dei prodotti e materiali)';
													|pl = 'Dokumenty wewnętrzne (przepływy produkcji i materiałów)';
													|tr = 'Dahili belgeler (ürün ve malzeme hareketi)'");
	DefaultProperties.DocumentType                 = Type("DocumentRef.MovementOfProductsAndMaterials");
	DefaultProperties.FullDocumentName           = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
	DefaultProperties.StatusesAreUsed          = GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements");
	DefaultProperties.AddButtonCreate        = True;
	DefaultProperties.KeyHeaderFields            = Documents.MovementOfProductsAndMaterials.KeyFieldsOfHeader();
	DefaultProperties.TitleOfTheReissueForm = "";
	DefaultProperties.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfInternalDocuments";
	
	CurrentOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = "";
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = "";
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.HyperlinkCalculationManagerForRegistration = "";
		String.TitleOfTheReissueForm = "";
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.HyperlinkCalculationManagerForRegistration = "";
		String.TitleOfTheReissueForm = "";
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.MaterialTransferToProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Lập lại chứng từ chuyển giao vào sản xuất theo đơn đặt hàng đã chọn';
											|ru = 'Переоформление передачи в производство по выбранным распоряжениям';
											|en = 'Reregister transfer to production for the selected references'; fa = 'Reregister transfer to production for the selected references';
											|it = 'La formalizzazione sostitutiva di consegna in produzione per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie przekazania do produkcji według wybranych zamówień';
											|tr = 'Seçilen emirlere göre üretim gönderiminin yeniden düzenlenmesi'");
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Lập lại chứng từ hoàn trả từ sản xuất theo các lệnh đã chọn';
											|ru = 'Переоформление возврата из производства по выбранным распоряжениям';
											|en = 'Reregister return from production by selected references'; fa = 'Reregister return from production by selected references';
											|it = 'La formalizzazione sostitutiva del reso dalla produzione per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie zwrotu z produkcji według wybranych zamówień';
											|tr = 'Seçilen emirlere göre üretimden iadenin yeniden düzenlenmesi'");
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Lập chứng từ chuyển giao từ sản xuất theo lệnh đã chọn';
											|ru = 'Переоформление передачи из производства по выбранным распоряжениям';
											|en = 'Reregister transfer from production for the selected references'; fa = 'Reregister transfer from production for the selected references';
											|it = 'La formalizzazione sostitutiva di consegna dalla produzione per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie przekazania z produkcji według wybranych zamówień';
											|tr = 'Seçilen emirlere göre üretimden aktarımın yeniden düzenlenmesi'");
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Lập lại chứng từ chuyển giao đến kho theo các lệnh đã chọn';
											|ru = 'Переоформление передачи в кладовую по выбранным распоряжениям';
											|en = 'Reregister transfer to storeroom for the selected references'; fa = 'Reregister transfer to storeroom for the selected references';
											|it = 'La formalizzazione sostitutiva di consegna al deposito per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie przekazania do komórki według wybranych zamówień';
											|tr = 'Seçilen emirlere göre ambara aktarımın yeniden düzenlenmesi'");
		
	EndIf;
	
	#EndRegion
	
	#Region InventoryConsumption
	
	If Not GetFunctionalOption("BaseVersion") Then

		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= Enums.BusinessTransactions.TransferToOperation;
		String.PurposeUseKey	= "InternalInventoryConsumption";
		String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (tiêu dùng hàng hóa nội bộ)';
											|ru = 'Внутренние документы (внутренние потребления товаров)';
											|en = 'Inventory documents (inventory consumption)'; fa = 'Inventory documents (inventory consumption)';
											|it = 'Documenti interni (propri fabbisogni delle merci)';
											|pl = 'Dokumenty wewnętrzne (wewnętrzne zużycie towarów)';
											|tr = 'Dahili belgeler (Stok tüketimi - Operasyonel olmayan faaliyetler)'");
		String.DocumentType					= Type("DocumentRef.InventoryConsumption");
		String.FullDocumentName			= Metadata.Documents.InventoryConsumption.FullName();
		String.StatusesAreUsed			= GetFunctionalOption("UseInventoryConsumptionStatuses");
		String.AddButtonCreate		= True;
		String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfInternalDocuments";
		String.KeyHeaderFields			= Documents.InventoryConsumption.KeyFieldsOfHeader();
		String.TitleOfTheReissueForm	= NStr("vi = 'Tạo lại chứng từ chuyển giao vào sử dụng theo lệnh đã chọn';
												|ru = 'Переоформление передачи в эксплуатацию по выбранным распоряжениям';
												|en = 'Reregister commissioning under the selected references'; fa = 'Reregister commissioning under the selected references';
												|it = 'Riformalizzazione del trasferimento in lavorazione in base alle disposizioni selezionate';
												|pl = 'Ponowne utworzenie przekazania do eksploatacji według wybranych zamówień';
												|tr = 'Seçilen emirlere göre kullanıma aktarımın yeniden düzenlenmesi'");

	EndIf;
	
	#EndRegion
	
	#Region OtherGoodsRecordingAsReceived
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation		= Enums.BusinessTransactions.PutOutOfOperation;
	String.PurposeUseKey	= "OtherGoodsRecordingAsReceived";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ nội bộ (ghi tăng hàng hóa khác)';
										|ru = 'Внутренние документы (прочие оприходования товаров)';
										|en = 'Internal documents (other recording of goods as received)'; fa = 'Internal documents (other recording of goods as received)';
										|it = 'Documenti interni (altre registrazioni merci)';
										|pl = 'Dokumenty na rozchód materiałów (pozostałe przeniesienia towarów)';
										|tr = 'Dahili belgeler (diğer mal girişi)'");
	String.DocumentType					= Type("DocumentRef.OtherGoodsRecordingAsReceived");
	String.FullDocumentName			= Metadata.Documents.OtherGoodsRecordingAsReceived.FullName();
	String.StatusesAreUsed			= False;
	String.AddButtonCreate		= True;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfInternalDocuments";
	
	#EndRegion
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

Function CreateHyperlinkToDesign(Parameters) Export
	
	HyperlinkText = NStr("vi = 'Hóa đơn';
						|ru = 'Накладные';
						|en = 'Invoices'; fa = 'فاکتورها';
						|it = 'Lettere di vettura';
						|pl = 'Listy przewozowe';
						|tr = 'İrsaliye'");
	FormNameWorkplace = "DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration";
	
	If ThereAreDocumentsForRegistration(Parameters) Then
		Return New FormattedString(HyperlinkText,,,, FormNameWorkplace);
	Else
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,, FormNameWorkplace);
	EndIf;
	
EndFunction

Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export
	
	ToRegister = TMCommonUse.CreateHyperlinkToDesign(Parameters[0], Parameters[1]);
	PutToTempStorage(ToRegister, StorageAddress);
	
EndProcedure

Function ThereAreDocumentsForRegistration(Parameters) Export
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Parameters.Organization,, Parameters.Warehouse, 
		Parameters.FilterBusinessTransactions, Parameters.Manager);
	
	States1 = InvoicesServer.StatesByBusinessTransactions(Parameters.FilterBusinessTransactions.UnloadValues());
	TablesNames = InvoicesServer.NamesOfTemporaryTablesByState();
	If Not ValueIsFilled(States1) Then
		Return False;
	EndIf;
	
	Package = New Array;
	Selection = New Array;
	Text = "SELECT
		|	ToRegister
		|FROM &TableName";
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value, True));
		Selection.Add(StrReplace(Text, "&TableName", TablesNames[KZ.Key]));
	EndDo;
	
	Package.Add(StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()));
	
	If ValueIsFilled(Parameters.Organization) Then
		CompaniesList = Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Parameters.Organization);
		CompaniesList.Add(Parameters.Organization);
	Else
		CompaniesList = New Array;
	EndIf;
	
	Query = New Query(StrConcat(Package, Common.QueryBatchSeparator()));
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization",       CompaniesList);
	Query.SetParameter("Warehouse",             Parameters.Warehouse);
	Query.SetParameter("Manager",          Parameters.Manager);
	Query.SetParameter("BusinessTransaction",       Parameters.FilterBusinessTransactions.UnloadValues());
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function NumberOfLinesForLayout(BsnsTransactions) Export
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(,,, BsnsTransactions);
	
	Package = New Array;
	Selection = New Array;
	States1 = InvoicesServer.StatesByBusinessTransactions(BsnsTransactions);
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value));
		
		If KZ.Key = "StatesOfSpendingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfSpendingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfSpendingOrders.Warehouse AS Warehouse,
			|	StatesOfSpendingOrders.Warehouse AS Sender,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.InventoryConsumptionOrder)
			|			OR VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.RMOrder)
			|			THEN UNDEFINED
			|		ELSE StatesOfSpendingOrders.Recipient
			|	END AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.RMOrder)
			|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction
			|FROM
			|	TTStateOfSpendingOrders AS StatesOfSpendingOrders");
		ElsIf KZ.Key = "StatesOfIncomingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfIncomingOrders.Warehouse AS Warehouse,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.OtherGoodsRecordingAsReceived)
			|			THEN UNDEFINED
			|		ELSE StatesOfIncomingOrders.Sender
			|	END AS Sender,
			|	StatesOfIncomingOrders.Warehouse AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN StatesOfIncomingOrders.BusinessTransaction
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
			|WHERE
			|	NOT VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.TransferOrder)
			|	AND NOT VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.InventoryTransfer)
			|
			|UNION ALL
			|
			|SELECT
			|	StatesOfIncomingOrders.ReferenceOrder,
			|	StatesOfIncomingOrders.Sender,
			|	StatesOfIncomingOrders.Sender,
			|	StatesOfIncomingOrders.Warehouse,
			|	NULL
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
			|WHERE
			|	(VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.TransferOrder)
			|			OR VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.InventoryTransfer))
			|	AND &ActsOfDivergenceAfterMovingAreUsed");
		ElsIf KZ.Key = "MovementStates" Then
			Selection.Add(
			"SELECT
			|	MovementStates.ReferenceOrder AS ReferenceOrder,
			|	DocTransferOrder.SourceWarehouse AS Warehouse,
			|	DocTransferOrder.SourceWarehouse AS Sender,
			|	DocTransferOrder.DestinationWarehouse AS Recipient,
			|	NULL AS BusinessTransaction
			|FROM
			|	TTMovementStates AS MovementStates
			|		LEFT JOIN Document.TransferOrder AS DocTransferOrder
			|		ON MovementStates.ReferenceOrder = DocTransferOrder.Ref");
		ElsIf KZ.Key = "AssemblyStates" Then
			Selection.Add(
			"SELECT
			|	AssemblyStates.ReferenceOrder AS ReferenceOrder,
			|	DocByAssemblyDisassemblyOrder.Warehouse AS Warehouse,
			|	DocByAssemblyDisassemblyOrder.Warehouse AS Sender,
			|	DocByAssemblyDisassemblyOrder.Warehouse AS Recipient,
			|	NULL AS BusinessTransaction
			|FROM
			|	TTStatesOfAssemblies AS AssemblyStates
			|		LEFT JOIN Document.ByAssemblyDisassemblyOrder AS DocByAssemblyDisassemblyOrder
			|		ON AssemblyStates.ReferenceOrder = DocByAssemblyDisassemblyOrder.Ref");
		ElsIf KZ.Key = "StatesOfDomesticConsumption" Then
			Selection.Add(
			"SELECT
			|	StatesOfDomesticConsumption.ReferenceOrder AS ReferenceOrder,
			|	StatesOfDomesticConsumption.Warehouse AS Warehouse,
			|	StatesOfDomesticConsumption.Warehouse AS Sender,
			|	UNDEFINED AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfDomesticConsumption.ReferenceOrder) = TYPE(Document.RMOrder)
			|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction
			|FROM
			|	TTStateOfInternalConsumption AS StatesOfDomesticConsumption");
		ElsIf KZ.Key = "StatesOfTransfersToProduction" Then
			Selection.Add(
			"SELECT
			|	StatesOfTransfersToProduction.ReferenceOrder AS ReferenceOrder,
			|	StatesOfTransfersToProduction.Warehouse AS Warehouse,
			|	StatesOfTransfersToProduction.Warehouse AS Sender,
			|	StatesOfTransfersToProduction.Recipient AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfTransfersToProduction.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction
			|FROM
			|	TTStatesOfTransfersToProduction AS StatesOfTransfersToProduction");
		ElsIf KZ.Key = "StatesOfTransfersFromProduction" Then
			Selection.Add(
			"SELECT
			|	StatesOfTransfersFromProduction.ReferenceOrder AS ReferenceOrder,
			|	StatesOfTransfersFromProduction.Warehouse AS Warehouse,
			|	StatesOfTransfersFromProduction.Sender AS Sender,
			|	StatesOfTransfersFromProduction.Warehouse AS Recipient,
			|	StatesOfTransfersFromProduction.BusinessTransaction AS BusinessTransaction
			|FROM
			|	TTTransfersStateOfTransferFromProduction AS StatesOfTransfersFromProduction");
		EndIf;
		
	EndDo;
	
	Package.Add(
		StrReplace(
		"SELECT DISTINCT
		|	NestedQuery.ReferenceOrder AS ReferenceOrder,
		|	NestedQuery.Warehouse AS Warehouse,
		|	NestedQuery.Sender AS Sender,
		|	NestedQuery.Recipient AS Recipient,
		|	NestedQuery.BusinessTransaction AS BusinessTransaction
		|FROM
		|	QueryTextNested AS NestedQuery",
		"QueryTextNested", "(" + StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()) + ")"));
	
	Query = New Query(StrConcat(Package, Common.QueryBatchSeparator()));
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BusinessTransaction", BsnsTransactions);
	Query.SetParameter("ActsOfDivergenceAfterMovingAreUsed",
		GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer"));
	
	Return Query.Execute().Select().Count();
	
EndFunction

#EndRegion

#EndIf
