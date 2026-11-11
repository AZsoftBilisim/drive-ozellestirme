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

// Workplace title
// 
// Returns:
//  String
// 
Function WorkplaceTitle() Export
	
	Return NStr("vi = 'Chứng từ tiếp nhận vào gia công (tất cả)';
				|ru = 'Документы приема в переработку (все)';
				|en = 'External subcontracting — All documents'; fa = 'پیمانکاری فرعی خارجی — همه اسناد';
				|it = 'Documenti di accettazione in trasformazione (tutti)';
				|pl = 'Dokumenty przyjmowania do przetwarzania (wszystkie)';
				|tr = 'İşlenecek kabul belgeleri (hepsi)'");
	
EndFunction

// Initialize business transactions and documents.
// 
// Parameters:
//  FilterBusinessTransactions		 - ValueList - list of values of the enum type Link.Economic operations
//  FilterDocumentTypes				 - ValueList - list of values of the reference Link type.IDs of metadata objectsreferences
//  PurposeUseKey		 - String - key of the workplace for which the function is called.
// 
// Returns:
//  See TMCommonUse.AvailableBusinessTransactionsAndDocuments
//
Function InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey) Export
		
	BusinessTransactionsAndDocuments = BusinessTransactionsAndDocuments();
		
	If PurposeUseKey = TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments,
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	TableOfValuesAvailable.Sort("Order");
	
	Return TableOfValuesAvailable;
	
EndFunction

#EndRegion

#Region Internal

// Checks for the availability of documents for registration.
// 
// Parameters:
//  Parameters             - Structure -
//  BusinessOperation - EnumRef.BusinessTransactions -
// 
// Returns:
//  Boolean - There Are Documents For Registration
//
Function ThereAreDocumentsForRegistration(Parameters, BusinessOperation) Export
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(
							Parameters.Organization,, Parameters.Warehouse, BusinessOperation, Parameters.Manager);
	
	BusinessTransactions = New Array;
	BusinessTransactions.Add(BusinessOperation);
	
	States1 = InvoicesServer.StatesByBusinessTransactions(BusinessTransactions);
	If Not ValueIsFilled(States1) Then
		Return False;
	EndIf;
	
	TablesNames = InvoicesServer.NamesOfTemporaryTablesByState();
	Package		= New Array;
	Selection		= New Array;
	
	Text =
	"SELECT
	|	ToRegister
	|FROM
	|	&TableName
	|";
	
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value, True));
		Selection.Add(StrReplace(Text, "&TableName", TablesNames[KZ.Key]));
	EndDo;
	
	Package.Add(StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()));
	
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		BusinessTransactions.Add(TollingSchemeClientServer.ContractBusinessTransaction());
		BusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
		BusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
		BusinessTransactions.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
		BusinessTransactions.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	EndIf;
	
	CompaniesList = New Array;
	If ValueIsFilled(Parameters.Organization) Then
		CompaniesList = Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Parameters.Organization);
		CompaniesList.Add(Parameters.Organization);
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = StrConcat(Package, Common.QueryBatchSeparator());
		
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BusinessTransaction", BusinessTransactions);
	Query.SetParameter("Organization", CompaniesList);
	Query.SetParameter("Warehouse", WarehousesServer.ListOfSubordinateWarehouses(Parameters.Warehouse).UnloadValues());
	Query.SetParameter("Manager", Parameters.Manager);
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction


// Returns the number of rows for the layout.
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions
// 
// Returns:
//  Number - Number Of Lines For The Layout
//
Function NumberOfLinesForLayout(BusinessOperation) Export
	
	BusinessTransactions = New Array;
	BusinessTransactions.Add(BusinessOperation);
	
	Package   = New Array;
	Selection = New Array;
	
	States1 = InvoicesServer.StatesByBusinessTransactions(BusinessTransactions);
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(,,, BusinessOperation);
	
	For Each KZ In States1 Do
		
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value));
		
		If KZ.Key = "StatesOfSpendingOrders" Then
			
			QueryTextSelection =
			"SELECT
			|	StatesOfSpendingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfSpendingOrders.Warehouse        AS Warehouse
			|FROM
			|	TTStateOfSpendingOrders AS StatesOfSpendingOrders";
			
		ElsIf KZ.Key = "StatesOfIncomingOrders" Then
			
			QueryTextSelection =
			"SELECT
			|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfIncomingOrders.Warehouse        AS Warehouse
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders";
			
		ElsIf KZ.Key = "TransfersStates" Then
			
			QueryTextSelection =
			"SELECT
			|	TransfersStates.ReferenceOrder AS ReferenceOrder,
			|	TransfersStates.Warehouse        AS Warehouse
			|FROM
			|	TTTransfersState AS TransfersStates";
			
		ElsIf KZ.Key = "RevenueStates" Then
			
			QueryTextSelection =
			"SELECT
			|	RevenueStates.ReferenceOrder AS ReferenceOrder,
			|	RevenueStates.Warehouse        AS Warehouse
			|FROM
			|	TTStateReceipts AS RevenueStates";
			
		EndIf;
		
		Selection.Add(QueryTextSelection);
		
	EndDo;
	
	QueryText =
	"SELECT DISTINCT
	|	NestedQuery.ReferenceOrder AS ReferenceOrder,
	|	NestedQuery.Warehouse        AS Warehouse
	|FROM
	|	QueryTextNested AS NestedQuery
	|";
	
	QueryText = StrReplace(
					QueryText,
					"QueryTextNested",
					StrTemplate("(%1)", StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin())));
	
	Package.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(Package, Common.QueryBatchSeparator());
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	BusinessTransactions.Add(TollingSchemeClientServer.ContractBusinessTransaction());
	BusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	
	Query.SetParameter("BusinessTransaction",       BusinessTransactions);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	
	Return Query.Execute().Select().Count();
	
EndFunction

#Region CreatingHyperlinkInJournal

Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export
	
	Result = New Structure("ToRegister, SeeAlsoInProgress");
	Result.ToRegister = TMCommonUse.CreateHyperlinkToDesign(Parameters[0], Parameters[1]);
	
	ArrayCalculationManagersSeeAlsoInWork = New Array;
	
	If GetFunctionalOption("UseMaterialProviderOrder2_5") Then
		ArrayCalculationManagersSeeAlsoInWork.Add("Document.MaterialProviderOrder2_5");
	EndIf;
	
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.IssuedLetterOfAuthority");
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption");
	
	DocumentsOfReceiptForTollingAll2_5Localization.ToCompleteArrayOfCalculationManagersSeeAlsoLocalization(ArrayCalculationManagersSeeAlsoInWork);
	
	Result.SeeAlsoInProgress =
		TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, Parameters[1]);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

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
				"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.DocumentsList");
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function BusinessTransactionsAndDocuments()
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.NewTableBusinessOperationsAndDocuments();
	VTBusinessTransactionsAndDocumentTypes.Columns.Add("Order", Common.TypeDescriptionNumber(2));
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "GoodsReceiptForStorage";
	String.BusinessOperation	   = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	String.AddButtonCreate	   = True;
	String.DocumentType				   = Type("DocumentRef.GoodsReceiptForStorage");
	String.FullDocumentName		   = Metadata.Documents.GoodsReceiptForStorage.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (tiếp nhận từ người đặt gia công)';
										|ru = 'Документы приема в переработку (поступления от давальца)';
										|en = 'External subcontracting (from provider)'; fa = 'External subcontracting (from provider)';
										|it = 'Documenti di ricezione in elaborazione (ricezione dal fornitore)';
										|pl = 'Dokumenty przyjęcia do przetwarzania (wpływy od właściciela surowców)';
										|tr = 'İşlenecek kabul belgeleri (sağlayıcıdan teslim alım)'");
	String.DocumentPresentation	   = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
	String.Order					   = 11;
	String.HyperlinkCalculationManagerForRegistration = "ReceiptFromMaterialProvider";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "ReportToMaterialProvider";
	String.BusinessOperation	   = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
	String.AddButtonCreate	   = False;
	String.DocumentType				   = Type("DocumentRef.ReportToMaterialProvider2_5");
	String.FullDocumentName		   = Metadata.Documents.ReportToMaterialProvider2_5.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (báo cáo cho người đặt gia công)';
										|ru = 'Документы приема в переработку (отчеты давальцу)';
										|en = 'External subcontracting (consumption reports)'; fa = 'External subcontracting (consumption reports)';
										|it = 'Documenti di ricezione in elaborazione (report al fornitore)';
										|pl = 'Dokumenty przyjęcia do przetworzenia (raporty właścicielowi raportów)';
										|tr = 'İşlenecek kabul belgeleri (Tüketim raporları - Verilen fason hizmetleri)'");
	String.Order					   = 12;
	String.HyperlinkCalculationManagerForRegistration = "Document.ReportToMaterialProvider2_5";
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.Subcontracting2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 13;
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 14;
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 15;
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 15;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "GoodsShipmentFromStorage";
	String.BusinessOperation	   = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	String.AddButtonCreate	   = True;
	String.DocumentType				   = Type("DocumentRef.GoodsShipmentFromStorage");
	String.FullDocumentName		   = Metadata.Documents.GoodsShipmentFromStorage.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (chuyển giao cho người đặt gia công)';
										|ru = 'Документы приема в переработку (передачи давальцу)';
										|en = 'External subcontracting (transfers to provider)'; fa = 'External subcontracting (transfers to provider)';
										|it = 'Documenti di ricezione in elaborazione (trasferimento al fornitore)';
										|pl = 'Dokumenty przyjęcia do przetworzenia (przekazania właścicielowi surowców)';
										|tr = 'İşlenecek kabul belgeleri (sağlayıcıya transfer)'");
	String.DocumentPresentation	   = NStr("vi = 'Chuyển giao cho người đặt gia công';
											|ru = 'Передача давальцу';
											|en = 'Goods issue — Subcontracting services delivered'; fa = 'حواله انبار — خدمات پیمانکاری فرعی ارائه‌شده';
											|it = 'Trasmissione al proprietario delle materie prime';
											|pl = 'Przekazanie właścicielowi surowców';
											|tr = 'Mal çıkışı — Fason hizmetleri teslim edildi'");
	String.Order					   = 16;
	String.HyperlinkCalculationManagerForRegistration = "TransferToMaterialProvider";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "GoodsShipmentFromStorage";
	String.BusinessOperation	   = Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
	String.AddButtonCreate	   = True;
	String.DocumentType				   = Type("DocumentRef.GoodsShipmentFromStorage");
	String.FullDocumentName		   = Metadata.Documents.GoodsShipmentFromStorage.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (chuyển giao cho người đặt gia công)';
										|ru = 'Документы приема в переработку (передачи давальцу)';
										|en = 'External subcontracting (transfers to provider)'; fa = 'External subcontracting (transfers to provider)';
										|it = 'Documenti di ricezione in elaborazione (trasferimento al fornitore)';
										|pl = 'Dokumenty przyjęcia do przetworzenia (przekazania właścicielowi surowców)';
										|tr = 'İşlenecek kabul belgeleri (sağlayıcıya transfer)'");
	String.DocumentPresentation	   = NStr("vi = 'Chuyển giao cho người đặt gia công';
											|ru = 'Передача давальцу';
											|en = 'Goods issue — Subcontracting services delivered'; fa = 'حواله انبار — خدمات پیمانکاری فرعی ارائه‌شده';
											|it = 'Trasmissione al proprietario delle materie prime';
											|pl = 'Przekazanie właścicielowi surowców';
											|tr = 'Mal çıkışı — Fason hizmetleri teslim edildi'");
	String.Order					   = 17;
	String.HyperlinkCalculationManagerForRegistration = "ReturnToMaterialProvider";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "ReportOnVMIAdjustment";
	String.BusinessOperation	   = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider;
	String.AddButtonCreate	   = True;
	String.DocumentType				   = Type("DocumentRef.ReportOnVMIAdjustment");
	String.FullDocumentName		   = Metadata.Documents.ReportOnVMIAdjustment.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (báo cáo ghi giảm)';
										|ru = 'Документы приема в переработку (отчеты о списании)';
										|en = 'External subcontracting (write-off reports)'; fa = 'External subcontracting (write-off reports)';
										|it = 'Documenti di ricezione in elaborazione (report di storno)';
										|pl = 'Dokumenty przyjęcia do przetworzenia (raporty o rozchodzie)';
										|tr = 'İşlenecek kabul belgeleri (zarar raporları)'");
	String.DocumentPresentation	   = TollingSchemeClientServer.SynonymOfDocumentReportOnWriteOffOfGoodsFromStorage();
	String.Order					   = 30;
	String.HyperlinkCalculationManagerForRegistration = "Document.ReportOnVMIAdjustment";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "ReportOnVMIAdjustment";
	String.BusinessOperation	   = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses;
	String.AddButtonCreate	   = True;
	String.DocumentType				   = Type("DocumentRef.ReportOnVMIAdjustment");
	String.FullDocumentName		   = Metadata.Documents.ReportOnVMIAdjustment.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (báo cáo ghi giảm)';
										|ru = 'Документы приема в переработку (отчеты о списании)';
										|en = 'External subcontracting (write-off reports)'; fa = 'External subcontracting (write-off reports)';
										|it = 'Documenti di ricezione in elaborazione (report di storno)';
										|pl = 'Dokumenty przyjęcia do przetworzenia (raporty o rozchodzie)';
										|tr = 'İşlenecek kabul belgeleri (zarar raporları)'");
	String.DocumentPresentation	   = TollingSchemeClientServer.SynonymOfDocumentReportOnWriteOffOfGoodsFromStorage();
	String.Order					   = 31;
	String.HyperlinkCalculationManagerForRegistration = "Document.ReportOnVMIAdjustment";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "RedemptionOfGoodsFromStorage";
	String.BusinessOperation	   = Enums.BusinessTransactions.RedemptionOfProviderGoods;
	String.AddButtonCreate	   = True;
	String.DocumentType				   = Type("DocumentRef.RedemptionOfGoodsFromStorage");
	String.FullDocumentName		   = Metadata.Documents.RedemptionOfGoodsFromStorage.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (mua lại hàng hóa)';
										|ru = 'Документы приема в переработку (выкупы товаров)';
										|en = 'External subcontracting (redemptions of goods)'; fa = 'External subcontracting (redemptions of goods)';
										|it = 'Documenti di ricezione in elaborazione (riscatti merci)';
										|pl = 'Dokumenty przyjęcia do przetworzenia (wykupy towarów)';
										|tr = 'İşlenecek kabul belgeleri (malların alınması)'");
	String.DocumentPresentation	   = TollingSchemeClientServer.SynonymForDocumentRedemptionOfGoodsAcceptedForStorage();
	String.Order					   = 32;
	String.HyperlinkCalculationManagerForRegistration = "Document.RedemptionOfGoodsFromStorage";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey = "SaleAdjustment";
	String.BusinessOperation	   = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
	String.AddButtonCreate	   = False;
	String.DocumentType				   = Type("DocumentRef.SaleAdjustment");
	String.FullDocumentName		   = Metadata.Documents.SaleAdjustment.FullName();
	String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (điều chỉnh bán hàng)';
										|ru = 'Документы приема в переработку (корректировки реализации)';
										|en = 'External subcontracting (sales adjustments)'; fa = 'External subcontracting (sales adjustments)';
										|it = 'Documenti di ricezione in elaborazione (aggiustamento di vendita)';
										|pl = 'Dokumenty przyjęcia do przetworzenia (korekty sprzedaży)';
										|tr = 'İşlenecek kabul belgeleri (satışların düzeltilmesi)'");
	String.DocumentPresentation	   = NStr("vi = 'Điều chỉnh bảng kê dành cho bên thuê gia công';
											|ru = 'Корректировка отчета давальцу';
											|en = 'Adjust ""Consumption report — Subcontracting services delivered""'; fa = 'Adjust ""Consumption report — Subcontracting services delivered""';
											|it = 'Rettifica del report al datore';
											|pl = 'Korekta raportu do właściciela surowców';
											|tr = 'Tüketim raporu-Verilen fason hizmetlerini düzeltme'");
	String.Order					   = 40;
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.Subcontracting2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 41;
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 42;
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 43;
	
	LineCopy = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(LineCopy, String);
	LineCopy.BusinessOperation  = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
	LineCopy.AddButtonCreate  = True;
	LineCopy.Order				   = 43;
	
	If GetFunctionalOption("UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5") Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.PurposeUseKey = "DiscrepancyReportFollowingReceipt";
		String.BusinessOperation	   = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
		String.DocumentType				   = Type("DocumentRef.DiscrepancyReportFollowingReceipt");
		String.FullDocumentName		   = Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName();
		String.AddButtonCreate	   = True;
		String.StatusesAreUsed		   = True;
		String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (chênh lệch)';
											|ru = 'Документы приема в переработку (расхождения)';
											|en = 'External subcontracting (discrepancies)'; fa = 'External subcontracting (discrepancies)';
											|it = 'Documenti di ricezione in elaborazione (discrepanze)';
											|pl = 'Dokumenty przyjmowania do przetwarzania (odchylenia)';
											|tr = 'İşlenecek kabul belgeleri (tutarsızlık)'");
		String.DocumentPresentation	   = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận từ người đặt gia công';
												|ru = 'Акт о расхождениях после приемки от давальца';
												|en = 'Discrepancy report following receipt from provider'; fa = 'Discrepancy report following receipt from provider';
												|it = 'Atto di accettazione con riserva dopo la ricezione dal fornitore';
												|pl = 'Protokół o odchyleniu po przyjęciu od właściciela surowców';
												|tr = 'Sağlayıcıdan stok farkları raporu'");
		String.Order					   = 50;
		
	EndIf;
	
	If GetFunctionalOption("UseCertificatesOfDiscrepanciesAfterShipmentForShipmentsOfGoodsToGiver2_5") Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.PurposeUseKey = "DiscrepancyReportFollowingShipment";
		String.BusinessOperation	   = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
		String.DocumentType				   = Type("DocumentRef.DiscrepancyReportFollowingShipment");
		String.FullDocumentName		   = Metadata.Documents.DiscrepancyReportFollowingShipment.FullName();
		String.AddButtonCreate	   = True;
		String.StatusesAreUsed		   = True;
		String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (chênh lệch)';
											|ru = 'Документы приема в переработку (расхождения)';
											|en = 'External subcontracting (discrepancies)'; fa = 'External subcontracting (discrepancies)';
											|it = 'Documenti di ricezione in elaborazione (discrepanze)';
											|pl = 'Dokumenty przyjmowania do przetwarzania (odchylenia)';
											|tr = 'İşlenecek kabul belgeleri (tutarsızlık)'");
		String.DocumentPresentation	   = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho người đặt gia công';
												|ru = 'Акт о расхождениях после отгрузки давальцу';
												|en = 'Discrepancy report following shipment to provider'; fa = 'Discrepancy report following shipment to provider';
												|it = 'Atto di accettazione con riserva dopo la spedizione al fornitore';
												|pl = 'Protokół o odchyleniu po wysyłce właścicielowi surowców';
												|tr = 'Sağlayıcıya sevkiyat sonrası tutarsızlık raporu'");
		String.Order					   = 51;
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.PurposeUseKey = "DiscrepancyReportFollowingShipment";
		String.BusinessOperation	   = Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
		String.DocumentType				   = Type("DocumentRef.DiscrepancyReportFollowingShipment");
		String.FullDocumentName		   = Metadata.Documents.DiscrepancyReportFollowingShipment.FullName();
		String.AddButtonCreate	   = True;
		String.StatusesAreUsed		   = True;
		String.WorkplaceTitle	   = NStr("vi = 'Chứng từ tiếp nhận vào gia công (chênh lệch)';
											|ru = 'Документы приема в переработку (расхождения)';
											|en = 'External subcontracting (discrepancies)'; fa = 'External subcontracting (discrepancies)';
											|it = 'Documenti di ricezione in elaborazione (discrepanze)';
											|pl = 'Dokumenty przyjmowania do przetwarzania (odchylenia)';
											|tr = 'İşlenecek kabul belgeleri (tutarsızlık)'");
		String.DocumentPresentation	   = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho người đặt gia công';
												|ru = 'Акт о расхождениях после отгрузки давальцу';
												|en = 'Discrepancy report following shipment to provider'; fa = 'Discrepancy report following shipment to provider';
												|it = 'Atto di accettazione con riserva dopo la spedizione al fornitore';
												|pl = 'Protokół o odchyleniu po wysyłce właścicielowi surowców';
												|tr = 'Sağlayıcıya sevkiyat sonrası tutarsızlık raporu'");
		String.Order					   = 52;
		
	EndIf;
	
	VATAccountingERP.DescriptionOfOperationsAndTypesOfDocumentsForJournalOfDocumentsAcceptedForProcessing2_5(VTBusinessTransactionsAndDocumentTypes);
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

#EndRegion

#EndIf
