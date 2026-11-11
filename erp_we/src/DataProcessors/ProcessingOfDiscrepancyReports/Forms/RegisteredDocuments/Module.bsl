
#Region Variables

&AtServer
Var OutputDocuments_;

&AtServer
Var IssuedDocumentsOnAct; // See NewDocumentsIssuedUnderAct

&AtServer
Var DocumentPatch; // DocumentRef

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseReturnRequests = GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	DisplayLegend = Common.CommonSettingsStorageLoad("DataProcessor.ProcessingOfDiscrepancyReports", "DisplayLegend", False);
	
	DiscrepancyCertificate = Parameters.DiscrepancyCertificate;
	DiscrepanciesServerLocalization.WorkingWithReportsOfDiscrepancies_WhenCreatedOnServer(ThisObject, Cancel, StandardProcessing);
	GenerateReport();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Activate();
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	GenerateReport();
	Activate();
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ReturnOfGoodsFromCustomer"
		Or EventName = "Write_ReturnOfGoodsToVendor"
		Or EventName = "Write_TransferOfGoodsToBailee"
		Or EventName = "Write_ReceiptOfGoodsFromCustodian"
		Or EventName = "Write_GoodsReceiptFromCustomer"
		Or EventName = "Write_GoodsReceiptForStorage"
		Or EventName = "Write_GoodsShipmentFromStorage"
		Or EventName = "Write_GoodsShipmentToCustomer"
		Or EventName = "Write_SalesOrder"
		Or EventName = "Write_TransferOrder"
		Or EventName = "Write_ARAPAdjustment"
		Or EventName = "Write_RequestForReturnOfGoodsFromCustomer"
		Or EventName = "Write_PurchaseAdjustment"
		Or EventName = "Write_SaleAdjustment"
		Or EventName = "Write_InventorySurplusRecognition"
		Or EventName = "Write_RecognitionOfStockSurplusShippedToCustomer"
		Or EventName = "Write_InventoryTransfer"
		Or EventName = "Write_VendorInvoice"
		Or EventName = "Write_CustomerInvoice"
		Or EventName = "Write_DebtCancellation"
		Or EventName = "Write_WriteOffOfGoodsShortages"
		Or EventName = "Record_WriteOffOfDiscrepancies"
		Or EventName = "Write_WriteOffOfShippedGoods"
		Or EventName = "Write_Claim"
		Or EventName = "Write_ARAPAdjustment" 
		Or EventName = "Write_UninvoicedReceipt" Then
		
		GenerateReport();
		
	ElsIf EventName = "ElectronicDocument_Confirmation"
		Or EventName = "ElectronicDocument_Deviation" Then
			
			SearchParameters = New Structure;
			SearchParameters.Insert("Basis", Parameter);
			
			FoundRows = Actions.FindRows(SearchParameters);
			If FoundRows.Count() > 0 Then
				GenerateReport();
			EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DisplayLegendOnChange(Item)
	
	DisplayLegendWhenChangingOnServer();
	
EndProcedure



// LongDesc
// 
// Parameters:
// 	Item - FormField - tabular document in which the selection is made.
// 	Area - SpreadsheetDocumentRange - Contains:
//  * Details - Structure - Contains:
//    ** CommandName - String - name of the command to run.
//    ** Data     - DocumentObject - a document that is being created or modified.
//    ** LongDesc - Structure - Contains:
//       *** DiscrepancyCertificate - DocumentRef.DiscrepancyReportFollowingShipment - 
//                            - DocumentRef.DiscrepancyReportFollowingTransfer - 
//                            - DocumentRef.DiscrepancyReportFollowingReceipt - document act of discrepancies
//       *** BasisOfAct    - DocumentRef - basis of the act.
// 	StandardProcessing - Boolean - indicates whether standard platform processing is being performed.
//
&AtClient
Procedure SpreadsheetDocumentSelection(Item, Area, StandardProcessing)
	
	StandardProcessing = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Area.Details) Then
		Return;
	EndIf;
	
	If TypeOf(Area.Details) <> Type("Structure") Then
		ShowValue(, Area.Details);
	Else
		
		DiscrepanciesClient.ProcessingReportCommandProcessingDocuments(
			ThisForm,
			Area.Details.CommandName,
			Area.Details.LongDesc.DiscrepancyCertificate,
			Area.Details.LongDesc.BasisOfAct,
			Area.Details.Data);
		
		If Area.Details.CommandName = "Change" Then
			Refresh(Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	GenerateReport();
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region ReportGeneration

&AtServer
Procedure GenerateReport()
	
	SpreadsheetDocument.Clear();
	Template = DataProcessors.ProcessingOfDiscrepancyReports.GetTemplate("RegisteredDocuments");
	
	HeaderSelection = RequestTextDiscrepancyReportHeader();
	
	If Not ValueIsFilled(HeaderSelection) Then
		OutputError(NStr("vi = 'Dữ liệu của chứng từ không khả dụng';
						|ru = 'Данные документа недоступны';
						|en = 'Document data is not available'; fa = 'Document data is not available';
						|it = 'I dati del documento non sono disponibili';
						|pl = 'Dane dokumentu są niedostępne';
						|tr = 'Belge verileri mevcut değil'"), Template);
		Return;
	EndIf;
	
	If HeaderSelection.ThereAreErrorsPosting Then
		OutputError(NStr("vi = 'Chứng từ chưa kết chuyển. Không thể lập chứng từ theo kết quả tiếp nhận.';
						|ru = 'Документ не проведен. Оформление документов по результатам приемки невозможно.';
						|en = 'Document is not posted. Cannot register documents according to the receiving results.'; fa = 'Document is not posted. Cannot register documents according to the receiving results.';
						|it = 'Documento non è registrato. La formalizzazione dei documenti per risultati dell''accettazione è impossibile.';
						|pl = 'Dokument nie został zatwierdzony. Sporządzenie dokumentów na podstawie wyników odbioru jest niemożliwe.';
						|tr = 'Belge oluşturulamamıştır. Kabulün sonuçlarını belgelemek mümkün değildir.'"), Template);
		Return;
	EndIf;
	
	If HeaderSelection.ThereAreErrorsStatus Then
		OutputError(NStr("vi = 'Để vẽ chứng từ trên cơ sở kết quả của sự khác biệt, cần phải dịch chứng từ sang trạng thái ""Đã xử lý"" hoặc ""Đã xử lý"".';
						|ru = 'Для оформления документов по результатам расхождений необходимо перевести документ в статус ""Отрабатывается"" или ""Отработано"".';
						|en = 'To register documents based on the result of differences, change the document status to ""Being processed"" or ""Processed"".'; fa = 'To register documents based on the result of differences, change the document status to ""Being processed"" or ""Processed"".';
						|it = 'Per formalizzare i documenti in base ai risultati delle discrepanze, è necessario trasferire il documento nello stato di ""In elaborazione"" o ""Elaborato"".';
						|pl = 'Dla sporządzenia dokumentów na podstawie wyników odchylenia należy przenieść dokument w status ""Opracowuje się"" lub ""Opracowano"".';
						|tr = 'Tutarsızlıkları belgelemek için, belge ""İşleniyor"" veya ""İşlendi"" durumuna ayarlanmalıdır.'"), Template);
		Return;
	EndIf;
	
	OutputDocuments_ = New ValueTable;
	OutputDocuments_.Columns.Add("Name");
	OutputDocuments_.Columns.Add("Ref");
	OutputDocuments_.Columns.Add("AdditionalParameter");
	
	DiscrepanciesPostingMethod   = HeaderSelection.DiscrepanciesPostingMethod;
	BusinessTransactionOfCertificate    = HeaderSelection.BusinessOperation;
	TypeOfBaseDocumentForNonConformanceCertificate = HeaderSelection.TypeOfBaseDocumentForNonConformanceCertificate;
	
	TableAccessRights        = New Structure;
	MatchingDataSets    = New Map;
	
	If Not ValueIsFilled(DiscrepanciesPostingMethod) Then 
		
		OutputError(NStr("vi = 'Trong biên bản tiếp nhận chưa đặt phương thức phản ánh chênh lệch';
						|ru = 'В акте приемки не задан способ отражения расхождений';
						|en = 'Discrepancy record method is not specified in the receiving note'; fa = 'Discrepancy record method is not specified in the receiving note';
						|it = 'Nell''atto di accettazione non è specificata la modalità per riportare le discrepanze';
						|pl = 'W protokole odbioru nie określono sposobu odzwierciedlenia odchylenia';
						|tr = 'Tutarsızlıkların kaydedilme yöntemi kabul belgesinde belirtilmemiştir'"), Template);
		Return;
		
	EndIf;
	
	If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		
		If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableAccessRights.Insert("ReadingWritingOffShortagesOfGoods", AccessRight("Read", Metadata.Documents.WriteOffOfGoodsShortages));
			
			QueryText = QueryTextActOnDiscrepanciesAfterImplementation(TableAccessRights, MatchingDataSets);
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableAccessRights.Insert("ReadingWritingOffShortagesOfGoods", AccessRight("Read", Metadata.Documents.WriteOffOfGoodsShortages));
			
			QueryText = QueryTextOfSalesDisputeOfItemsAfterShipmentToCustomer(TableAccessRights, MatchingDataSets);
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableAccessRights.Insert("ReadingWritingOffShortagesOfGoods", AccessRight("Read", Metadata.Documents.WriteOffOfGoodsShortages));
			
			QueryText = RequestTextReportOfDiscrepanciesAfterReturnToSupplier(TableAccessRights, MatchingDataSets);
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableAccessRights.Insert("ReadingWritingOffShortagesOfGoods", AccessRight("Read", Metadata.Documents.WriteOffOfGoodsShortages));
			
			QueryText = TextOfRequestActOnDiscrepanciesAfterTransferOfGoodsToCustodian(TableAccessRights, MatchingDataSets);
			
		Else
			
			QueryText = RequestTextReportOfDiscrepanciesAfterShipmentOfGoodsFromStorage();
			
		EndIf;
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		
		TableAccessRights.Insert("ReadingRecordingSurplusGoods", AccessRight("Read", Metadata.Documents.InventorySurplusRecognition));
		TableAccessRights.Insert("AddingDebtCancellation", AccessRight("Insert", Metadata.Documents.ARAPAdjustment));
		TableAccessRights.Insert("ReadingWritingOffShortagesOfGoods", AccessRight("Read", Metadata.Documents.WriteOffOfGoodsShortages));
		
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
			
			TableAccessRights.Insert("ReadOrderToSupplier", AccessRight("Read", Metadata.Documents.PurchaseOrder));
			TableAccessRights.Insert("ReadingDebtCancellation", AccessRight("Read", Metadata.Documents.ARAPAdjustment));
			TableAccessRights.Insert("ReadingPurchasingGoodsServices", AccessRight("Read", Metadata.Documents.VendorInvoice));
			TableAccessRights.Insert("ReadAcquisitionAdjustment", AccessRight("Read", Metadata.Documents.PurchaseAdjustment));
			TableAccessRights.Insert("ReadReturnOfGoodsToSupplier", AccessRight("Read", Metadata.Documents.ReturnOfGoodsToVendor));
			TableAccessRights.Insert("ReadingWriteOffOfDiscrepanciesReceiptPurchase", AccessRight("Read", Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase));
			TableAccessRights.Insert("ReadingClaims", AccessRight("Read", Metadata.Catalogs.Complaints));
			TableAccessRights.Insert("ReadingDebtAdjustment", AccessRight("Read", Metadata.Documents.ARAPAdjustment));
			
			If PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessTransactionOfCertificate) Then
				TableAccessRights.Insert("ReadingReceiptOfGoodsInWarehouse", AccessRight("Read", Metadata.Documents.ReceiptOfGoodsToWarehouse));
			Else
				TableAccessRights.Insert("ReadingReceiptOfGoodsInWarehouse", False);
			EndIf;
			
			QueryText = RequestTextReportOfDiscrepanciesAfterReceiptOfGoods(TableAccessRights, MatchingDataSets);
			
		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
			  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
			Then
			
			ReadOrderToSupplier = AccessRight("Read", Metadata.Documents.PurchaseOrder);
			ReadOrderToSupplier =
				ReadOrderToSupplier
				And TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage;
			
			ReadingGiverSOrder2_5 =
				AccessRight("Read", Metadata.Documents.MaterialProviderOrder2_5)
				And TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider;
			TableAccessRights.Insert("ReadOrderToSupplier", ReadOrderToSupplier);
			TableAccessRights.Insert("ReadingShippingGoodsFromStorage",
							AccessRight("Read", Metadata.Documents.GoodsShipmentFromStorage));
			TableAccessRights.Insert("ReadAcceptanceOfGoodsForStorage",
							AccessRight("Read", Metadata.Documents.GoodsReceiptForStorage));
			TableAccessRights.Insert("ReadingDebtCancellation", False);
			TableAccessRights.Insert("ReadingGiverSOrder2_5", ReadingGiverSOrder2_5);
			QueryText = TextOfRequestReportOnDiscrepanciesAfterAcceptanceOfGoodsForStorage(TableAccessRights,
												MatchingDataSets);
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
			
			TableAccessRights.Insert("ReadingTransfers",
							AccessRight("Read", Metadata.Documents.TransferOfGoodsToBailee));
			TableAccessRights.Insert("ReadingReceiptOfGoodsFromCustodian",
							AccessRight("Read", Metadata.Documents.ReceiptOfGoodsFromCustodian));
			TableAccessRights.Insert("ReadingDebtCancellation", False);
			
			QueryText = RequestTextStatementOfDiscrepanciesAfterReturnFromCustodian(TableAccessRights, MatchingDataSets);
			
		Else
			
			TableAccessRights.Insert("ReadingImplementations", AccessRight("Read", Metadata.Documents.CustomerInvoice));
			TableAccessRights.Insert("ReadingDebtCancellation", AccessRight("Read", Metadata.Documents.ARAPAdjustment));
			TableAccessRights.Insert("ReadReturnOfGoodsFromCustomer", AccessRight("Read", Metadata.Documents.ReturnOfGoodsFromCustomer));
			
			QueryText = RequestTextStatementOfDiscrepanciesAfterReturnFromClient(TableAccessRights, MatchingDataSets);
			
		EndIf;
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		
		TableAccessRights.Insert("ReadingRecordingSurplusGoods", AccessRight("Read", Metadata.Documents.InventorySurplusRecognition));
		TableAccessRights.Insert("ReadingWritingOffShortagesOfGoods", AccessRight("Read", Metadata.Documents.WriteOffOfGoodsShortages));
		
		QueryText = QueryTextDiscrepancyReportFollowingTransfer(TableAccessRights, MatchingDataSets);
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("DiscrepancyCertificate",            DiscrepancyCertificate);
	Query.SetParameter("DiscrepanciesPostingMethod",  DiscrepanciesPostingMethod);
	If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") 
		And TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
		RequestSurplus = New Query;
		RequestSurplus.Text = "
		|SELECT TOP 1
		|	GoodsForRegistrationOfSurplusesAndShortages.Recorder
		|FROM
		|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistrationOfSurplusesAndShortages
		|WHERE
		|	GoodsForRegistrationOfSurplusesAndShortages.Recorder = &Ref";
		RequestSurplus.SetParameter("Ref", DiscrepancyCertificate);
		SetPrivilegedMode(True);
		QueryResult = RequestSurplus.Execute();
		ThisIsDiscrepancyReport2_5_12 = Not QueryResult.IsEmpty();
		SetPrivilegedMode(False);
	Else
		ThisIsDiscrepancyReport2_5_12 = False;
	EndIf;
	Query.SetParameter("ThisIsDiscrepancyReport2_5_12", ThisIsDiscrepancyReport2_5_12);
	Query.SetParameter("UseReturnRequests", UseReturnRequests);
	QueryResult = Query.ExecuteBatch();
	
	If QueryResult[1].IsEmpty() Then
		OutputError(NStr("vi = 'Theo kết quả tiếp nhận không phát hiện chênh lệch để lập chứng từ';
						|ru = 'По результатам приемки не выявлено расхождений, требующих оформления документов';
						|en = 'According to the receiving results, discrepancies requiring document registration are not detected'; fa = 'According to the receiving results, discrepancies requiring document registration are not detected';
						|it = 'In base ai risultati dell''accettazione, non sono state rilevate discrepanze che richiedano la formalizzazione di documenti';
						|pl = 'Na podstawie wyników odbioru nie stwierdzono odchylenia, które wymaga sporządzania dokumentów';
						|tr = 'Kabul sonucunda evrak gerektiren herhangi bir tutarsızlık tespit edilmemiştir'"), Template);
		Return;
	EndIf;
	
	FillInActionTable(DiscrepancyCertificate, QueryResult);
	FillTablesOfCreatedDocuments(QueryResult, TypeOfBaseDocumentForNonConformanceCertificate, MatchingDataSets);
	
	ArrayOfCompletedDocuments = New Array;
	IssuedDocumentsOnAct  = NewDocumentsIssuedUnderAct();
	
	SpreadsheetDocument.Put(Template.GetArea("IsBlankString"));
	Area = Template.GetArea("DiscrepancyCertificate");
	Area.Parameters.DiscrepancyCertificate = DiscrepancyCertificate;
	SpreadsheetDocument.Put(Area);
	
	// here either the sale or the return of goods to the supplier
	DisplayBaseGroup = (Actions.Count() > 1 
	                           And BusinessTransactionOfCertificate <> Enums.BusinessTransactions.TransferToCommissionAgent);
	
	For Each ActionString In Actions Do
		
		If DisplayBaseGroup Then
			
			SpreadsheetDocument.Put(Template.GetArea("IsBlankString"));
			
			Area = Template.GetArea("Basis");
			Area.Parameters.Basis = ActionString.Basis;
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.StartRowGroup("Basis");
			
		EndIf;
		
		BusinessOperation = Undefined;
		
		If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
			
			PrintActionLinesForActAfterShipment(ActionString, Template, TypeOfBaseDocumentForNonConformanceCertificate, TableAccessRights);
			
		ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
			
			PrintActionLinesForReportAfterAcceptance(ActionString, Template, TypeOfBaseDocumentForNonConformanceCertificate, TableAccessRights);
			If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
				BusinessOperation = BusinessTransactionOfCertificate;
			EndIf;
		ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
			
			PrintActionLinesForActAfterMove(ActionString, Template, TypeOfBaseDocumentForNonConformanceCertificate, TableAccessRights);
			
		EndIf;
		
		If DisplayBaseGroup Then
			
			SpreadsheetDocument.EndRowGroup();
			
		EndIf;
		
	EndDo;
	
	// The conclusion of the documents being drawn up outside the groups of documents of the grounds (the basis is the act of divergence).
	IssuedDocumentsOnAct.Sort("DocumentKind");
	
	For Each FormalizedView In IssuedDocumentsOnAct Do
		PrintDocumentForRegistration(FormalizedView.DocumentKind, 1, Template, FormalizedView.RegisteredDocuments,
			BusinessOperation, True,
			FormalizedView.LongDesc);
	EndDo;
	
	If SpreadsheetDocument.TableHeight <= 2 Then
		ErrorText = NStr("vi = 'Bạn không được phép tạo bất kỳ văn bản nào.';
						|ru = 'Вам недоступно для оформления ни одного документа.';
						|en = 'Cannot register any documents.'; fa = 'Cannot register any documents.';
						|it = 'Вам недоступно для оформления ни одного документа.';
						|pl = 'Cannot register any documents.';
						|tr = 'Düzenleyeceğiniz herhangi bir belge mevcut değildir.'");
		If Not Users.IsFullUser() Then
			ErrorText = ErrorText + " " + NStr("vi = 'Có thể, không có các quyền cần thiết.';
												|ru = 'Возможно нет необходимых прав.';
												|en = 'You may not have the required rights.'; fa = 'You may not have the required rights.';
												|it = 'Возможно нет необходимых прав.';
												|pl = 'You may not have the required rights.';
												|tr = 'Gerekli yetkiye sahip olmayabilirsiniz.'");
		EndIf;
		ErrorArea = Template.GetArea("StringError");
		ErrorArea.Parameters.ErrorText = ErrorText;
		SpreadsheetDocument.Put(ErrorArea);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInActionTable(DiscrepancyCertificate, QueryResult)
	
	Actions.Clear();
	
	ThisIsActOfDiscrepanciesAfterShipment = TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment");
	
	ResultOfBaseRequest = QueryResult[1]; // QueryResult - 
	SamplingBase = ResultOfBaseRequest.Select(QueryResultIteration.ByGroups);
	While SamplingBase.Next() Do
		
		NewRow = Actions.Add();
		NewRow.Basis               = SamplingBase.Basis;
		NewRow.ByOrders               = SamplingBase.ByOrders;
		NewRow.OrderDocument                   = SamplingBase.OrderDocument;
		
		DiscrepanciesServerLocalization.AddRowToActionTable(NewRow, SamplingBase);
		ActionSelection = SamplingBase.Select();
		While ActionSelection.Next() Do
			
			NewRow.ActionsOptions.Add(ActionSelection.Action);
			If ThisIsActOfDiscrepanciesAfterShipment Then
				NewLineOptionsForActionsWithProduct = NewRow.OptionsForActionsWithGoods.Add();
				NewLineOptionsForActionsWithProduct.VariantOfActionWithDocument = ActionSelection.Action;
				NewLineOptionsForActionsWithProduct.VariantOfActionWithGoods = ActionSelection.DiscrepancyTreatment;
			EndIf;
			
			If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") 
				And TypeOf(ActionSelection.Basis) = Type("DocumentRef.VendorInvoice") Then
				NewRow.ThisIsDiscrepancyReport2_5_12 = ActionSelection.ThisIsDiscrepancyReport2_5_12;
			Else 
				NewRow.ThisIsDiscrepancyReport2_5_12 = False;
			EndIf;
			
			If ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses
				And ActionSelection.ThirdPartyIsGuilty Then
				NewRow.ThirdPartyIsGuilty = True;
			EndIf;
			
			If ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered Then
				
				NewRow.ThereIsSurplusesRecord = True;
				
			EndIf;
			
			If ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses Then
				
				NewRow.ThereIsShortageRecord = True;
				
			EndIf;
			
			If ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices
				Or ActionSelection.Action = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices
				Or (ThisIsActOfDiscrepanciesAfterShipment
					And ActionSelection.DiscrepancyTreatment = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off) Then
				
				NewLineOptionsWarehouses = NewRow.ActionsWarehouses.Add();
				NewLineOptionsWarehouses.PossibleAction = ActionSelection.Action;
				NewLineOptionsWarehouses.Warehouse           = ActionSelection.Warehouse;
				NewLineOptionsWarehouses.OrderDocument           = ActionSelection.OrderDocument;
				If ThisIsActOfDiscrepanciesAfterShipment Then
					NewLineOptionsWarehouses.VariantOfActionWithGoods = ActionSelection.DiscrepancyTreatment;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		OptionsForActionsWithGoods = NewRow.OptionsForActionsWithGoods.Unload();
		OptionsForActionsWithGoods.GroupBy("VariantOfActionWithDocument, VariantOfActionWithGoods");
		NewRow.OptionsForActionsWithGoods.Load(OptionsForActionsWithGoods);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillTablesOfCreatedDocuments(QueryResult, TypeOfBaseDocumentForNonConformanceCertificate, MatchingDataSets)
	
	If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		
		If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			AdjustmentSales.Load(QueryResult[2].Unload());
			SalesReturns.Load(QueryResult[3].Unload());
			ImplementationsOrders.Load(QueryResult[4].Unload());
			SubsequentDeliveries.Load(QueryResult[5].Unload());
			ShipmentsForShipmentsOfItemsToCustomer.Load(QueryResult[6].Unload());
			GroundsForRegisteringSurplusShippedItems.Load(QueryResult[7].Unload());
			GroundsForReceiptOfGoodsFromClient.Load(QueryResult[8].Unload());
			GroundsForWriteOffOfItemsShippedToCustomer.Load(QueryResult[9].Unload());
			ImplementationsOfAdjustmentGetBackOnTrack.Load(QueryResult[10].Unload());
			ShipmentOfItemsToClientUponTransferOfOwnership2_5.Load(QueryResult[11].Unload());
			
			For Each MapItem In MatchingDataSets Do
				ThisObject[MapItem.Key].Load(QueryResult[MapItem.Value].Unload())
			EndDo;
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			GroundsForReceiptOfGoodsFromClient.Load(QueryResult[2].Unload());
			ShipmentsOfItemsToCustomerOrders.Load(QueryResult[3].Unload());
			ShipmentsForShipmentsOfItemsToCustomer.Load(QueryResult[4].Unload());
			GroundsForRegisteringSurplusShippedItems.Load(QueryResult[5].Unload());
			GroundsForWriteOffOfItemsShippedToCustomer.Load(QueryResult[6].Unload());
			
			For Each MapItem In MatchingDataSets Do
				ThisObject[MapItem.Key].Load(QueryResult[MapItem.Value].Unload())
			EndDo;
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			SubsequentDeliveryBySupplierReturns.Load(QueryResult[2].Unload());
			ReturnsByReturnsToSupplier.Load(QueryResult[3].Unload());
			
			For Each MapItem In MatchingDataSets Do
				ThisObject[MapItem.Key].Load(QueryResult[MapItem.Value].Unload())
			EndDo;
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TransfersReturns.Load(QueryResult[2].Unload());
			TransfersOrders.Load(QueryResult[3].Unload());
			AdditionalDeliveryToTheCustodian.Load(QueryResult[4].Unload());
			CorrectionTransfers.Load(QueryResult[5].Unload());
			
			For Each MapItem In MatchingDataSets Do
				ThisObject[MapItem.Key].Load(QueryResult[MapItem.Value].Unload())
			EndDo;
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TransfersReturns.Load(QueryResult[2].Unload());
			TransfersOrders.Load(QueryResult[3].Unload());
			AdditionalDeliveryToTheCustodian.Load(QueryResult[4].Unload());
			CorrectionTransfers.Load(QueryResult[5].Unload());
			
			For Each MapItem In MatchingDataSets Do
				ThisObject[MapItem.Key].Load(QueryResult[MapItem.Value].Unload())
			EndDo;
			
		Else
			SubsequentDeliveryByGoodsShipmentsFromStorage.Load(QueryResult[2].Unload());
			ReturnsByGoodsShipmentsFromStorage.Load(QueryResult[3].Unload());
			CorrectionsOnShipmentsOfGoodsFromStorage.Load(QueryResult[4].Unload());
		EndIf;
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		
		For Each MapItem In MatchingDataSets Do
			ThisObject[MapItem.Key].Load(QueryResult[MapItem.Value].Unload())
		EndDo;
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		
		TransfersByTransfers.Load(QueryResult[2].Unload());
		TransfersByReturnTransfers.Load(QueryResult[3].Unload());
		GoodsTransferTransferOrders.Load(QueryResult[4].Unload());
		
		For Each MapItem In MatchingDataSets Do
			ThisObject[MapItem.Key].Load(QueryResult[MapItem.Value].Unload())
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region QueriesTexts

&AtServer
Function RequestTextDiscrepancyReportHeader()
	
	Query = New Query;
	If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		
		Query.Text = "
		|SELECT ALLOWED
		|	DiscrepancyReportFollowingShipment.Ref,
		|	DiscrepancyReportFollowingShipment.Status,
		|	DiscrepancyReportFollowingShipment.DiscrepanciesPostingMethod,
		|	DiscrepancyReportFollowingShipment.TypeOfBaseDocumentForNonConformanceCertificate,
		|	CASE
		|		WHEN DiscrepancyReportFollowingShipment.Posted
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsPosting,
		|	CASE
		|		WHEN DiscrepancyReportFollowingShipment.Status = VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion)
		|			OR DiscrepancyReportFollowingShipment.Status = VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	DiscrepancyReportFollowingShipment.BusinessOperation
		|FROM
		|	Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
		|WHERE
		|	DiscrepancyReportFollowingShipment.Ref = &DiscrepancyCertificate";
		
	ElsIf TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
		
		Query.Text = "
		|SELECT ALLOWED
		|	DiscrepancyReportFollowingTransfer.Ref,
		|	DiscrepancyReportFollowingTransfer.Status,
		|	VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments) AS DiscrepanciesPostingMethod,
		|	UNDEFINED AS TypeOfBaseDocumentForNonConformanceCertificate,
		|	CASE
		|		WHEN DiscrepancyReportFollowingTransfer.Posted
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsPosting,
		|	CASE
		|		WHEN DiscrepancyReportFollowingTransfer.Status = VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion)
		|			OR DiscrepancyReportFollowingTransfer.Status = VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	DiscrepancyReportFollowingTransfer.BusinessOperation
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer AS DiscrepancyReportFollowingTransfer
		|WHERE
		|	DiscrepancyReportFollowingTransfer.Ref = &DiscrepancyCertificate";
		
	ElsIf  TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		
		Query.Text = "
		|SELECT ALLOWED
		|	DiscrepancyReportFollowingReceipt.Ref,
		|	DiscrepancyReportFollowingReceipt.Status,
		|	DiscrepancyReportFollowingReceipt.DiscrepanciesPostingMethod,
		|	DiscrepancyReportFollowingReceipt.TypeOfBaseDocumentForNonConformanceCertificate,
		|	CASE
		|		WHEN DiscrepancyReportFollowingReceipt.Posted
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsPosting,
		|	CASE
		|		WHEN DiscrepancyReportFollowingReceipt.Status = VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion)
		|			OR DiscrepancyReportFollowingReceipt.Status = VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	DiscrepancyReportFollowingReceipt.BusinessOperation
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
		|WHERE
		|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate";
		
	EndIf;
	
	Query.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	HeaderSelection = QueryResult.Select();
	HeaderSelection.Next();
	
	Return HeaderSelection;
	
EndFunction

&AtServer
Function QueryTextActOnDiscrepanciesAfterImplementation(TableAccessRights, MatchingDataSets)
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Action         AS Action,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices       AS SaleOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse            AS Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder     AS SalesOrder
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	Actions.Action         AS Action,
	|	Actions.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	Actions.SaleOfGoodsAndServices       AS Basis,
	|	Actions.Warehouse            AS Warehouse,
	|	FALSE                      AS ThirdPartyIsGuilty,
	|	MAX(CASE
	|		WHEN Actions.SalesOrder REFS Document.SalesOrder
	|			THEN Actions.SaleOfGoodsAndServices.OrderSales
	|		WHEN Actions.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN Actions.SaleOfGoodsAndServices.OrderSales
	|		ELSE
	|			FALSE
	|	END)                    AS ByOrders,
	|	UNDEFINED              AS OrderDocument
	|FROM
	|	Actions AS Actions
	|
	|GROUP BY
	|	Actions.Action,
	|	Actions.DiscrepancyTreatment,
	|	Actions.SaleOfGoodsAndServices,
	|	Actions.Warehouse
	|
	|TOTALS BY
	|	SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED 
	|	SaleAdjustment.DocumentBasis AS SaleOfGoodsAndServices,
	|	SaleAdjustment.Ref            AS Adjusting,
	|	SaleAdjustment.AdjustmentKind  AS BusinessOperation
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|WHERE
	|	SaleAdjustment.DiscrepancyReportFollowingShipmentBaseDocument = &DiscrepancyCertificate
	|	AND SaleAdjustment.Posted
	|	AND CASE
	|			WHEN &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection)
	|				THEN SaleAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|			WHEN &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties)
	|				THEN SaleAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			ELSE SaleAdjustment.AdjustmentKind IN (VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|			                                                       VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED DISTINCT
	|	RequestForReturnOfGoodsFromCustomerReturnedGoods.DocumentSalesOfGoodsAndServices AS SaleOfGoodsAndServices,
	|	RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref AS DocumentReturnPolicy
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS RequestForReturnOfGoodsFromCustomerReturnedGoods
	|		INNER JOIN Actions AS Actions
	|		ON RequestForReturnOfGoodsFromCustomerReturnedGoods.DocumentSalesOfGoodsAndServices = Actions.SaleOfGoodsAndServices
	|WHERE
	|	&UseReturnRequests
	|	AND RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices,
	|	ReturnOfGoodsFromCustomerGoods.Ref
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS ReturnOfGoodsFromCustomerGoods
	|		INNER JOIN Actions AS Actions
	|		ON ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices = Actions.SaleOfGoodsAndServices
	|WHERE
	|	NOT &UseReturnRequests
	|	AND ReturnOfGoodsFromCustomerGoods.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder AS SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument <> CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder <> UNDEFINED
	|
	|ORDER BY
	|	SalesOrder DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT ALLOWED DISTINCT
	|	CustomerInvoice.Ref AS RegisteredSales,
	|	CustomerInvoice.SubsequentDeliveryBySale AS SubsequentDeliveryBySale
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.CustomerInvoice AS CustomerInvoice
	|		ON (CustomerInvoice.Posted)
	|			AND Actions.SaleOfGoodsAndServices = CustomerInvoice.SubsequentDeliveryBySale
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT ALLOWED DISTINCT
	|	Document.Ref      AS GoodsShipmentToCustomer,
	|	Document.BaseDocumentOfDiscrepancyReportForCorrection AS Basis,
	|	Document.Patch AS Patch,
	|	FALSE                 AS AdditionalDelivery
	|FROM
	|	Actions AS Actions
	|	INNER JOIN Document.GoodsShipmentToCustomer AS Document
	|		ON (Document.Posted)
	|			AND Actions.SaleOfGoodsAndServices = Document.BaseDocumentOfDiscrepancyReportForCorrection
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Document.Ref      AS GoodsShipmentToCustomer,
	|	Document.BaseDocumentForDiscrepancyReport AS Basis,
	|	Document.Patch AS Patch,
	|	TRUE               AS AdditionalDelivery
	|FROM
	|	Actions AS Actions
	|	INNER JOIN Document.GoodsShipmentToCustomer AS Document
	|		ON (Document.Posted)
	|			AND Actions.SaleOfGoodsAndServices = Document.BaseDocumentForDiscrepancyReport
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////7
	|SELECT ALLOWED DISTINCT
	|	RecognitionOfStockSurplusShippedToCustomer.BaseDocumentForDiscrepancyReport AS Basis,
	|	RecognitionOfStockSurplusShippedToCustomer.Ref AS RecordingAsReceived
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.RecognitionOfStockSurplusShippedToCustomer AS RecognitionOfStockSurplusShippedToCustomer
	|		ON RecognitionOfStockSurplusShippedToCustomer.Posted
	|			AND RecognitionOfStockSurplusShippedToCustomer.BaseDocumentForDiscrepancyReport = Actions.SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////8
	|SELECT ALLOWED DISTINCT
	|	GoodsReceiptFromCustomer.BaseDocumentForDiscrepancyReport AS Basis,
	|	GoodsReceiptFromCustomer.Ref AS GoodsReceiptFromCustomer,
	|	GoodsReceiptFromCustomer.ReduceShipmentByReference AS ReduceShipmentByReference
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.GoodsReceiptFromCustomer AS GoodsReceiptFromCustomer
	|		ON GoodsReceiptFromCustomer.Posted
	|			AND GoodsReceiptFromCustomer.BaseDocumentForDiscrepancyReport = Actions.SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////9
	|SELECT ALLOWED DISTINCT
	|	WriteOffOfShippedGoods.BaseDocumentForDiscrepancyReport AS Basis,
	|	WriteOffOfShippedGoods.Ref AS WriteOff,
	|	WriteOffOfShippedGoods.ReduceShipmentByReference AS ReduceShipmentByReference
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.WriteOffOfShippedGoods AS WriteOffOfShippedGoods
	|		ON WriteOffOfShippedGoods.Posted
	|			AND WriteOffOfShippedGoods.BaseDocumentForDiscrepancyReport = Actions.SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////10
	|SELECT ALLOWED DISTINCT
	|	DivergenceTable.Ref.DocumentBasis AS SaleOfGoodsAndServices,
	|	DivergenceTable.Ref                   AS Adjusting
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DivergenceTable
	|WHERE
	|	DivergenceTable.Ref.DiscrepancyReportFollowingShipmentBaseDocument = &DiscrepancyCertificate
	|	AND DivergenceTable.Ref.Posted
	|	AND DivergenceTable.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.ReturnToTransit)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////11
	|SELECT ALLOWED DISTINCT
	|	ShippingGoods.Ref AS GoodsShipmentToCustomer
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
	|	INNER JOIN Document.DiscrepancyReportFollowingShipment.Goods AS ActOfItems
	|		ON ShippingGoods.Products = ActOfItems.Products
	|			AND ShippingGoods.Characteristic = ActOfItems.Characteristic
	|			AND (ShippingGoods.RowCode = ActOfItems.RowCode
	|				OR ActOfItems.RowCode = 0)
	|			AND ShippingGoods.SalesOrder = ActOfItems.SalesOrder
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON (ShippingGoods.Ref = DocumentsRegistry.CorrectedDocument
	|				OR ShippingGoods.Ref = DocumentsRegistry.ReversedDocument)
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsSubsequentCorrections
	|		ON DocumentsRegistry.RefType = RegisterOfDocumentsSubsequentCorrections.RefType
	|			AND DocumentsRegistry.CorrectedDocument = RegisterOfDocumentsSubsequentCorrections.CorrectedDocument
	|			AND DocumentsRegistry.Ref = RegisterOfDocumentsSubsequentCorrections.ReversedDocument
	|			AND NOT RegisterOfDocumentsSubsequentCorrections.AdditionalRecord
	|			AND RegisterOfDocumentsSubsequentCorrections.Posted
	|			AND RegisterOfDocumentsSubsequentCorrections.IBDocumentDate > DocumentsRegistry.IBDocumentDate
	|WHERE
	|	ActOfItems.Ref = &DiscrepancyCertificate
	|	AND ShippingGoods.Ref.Posted
	|	AND ActOfItems.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery)
	|				)
	|	AND (DocumentsRegistry.Ref IS NULL
	|		OR RegisterOfDocumentsSubsequentCorrections.Ref IS NOT NULL)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	ShippingGoods.Ref AS GoodsShipmentToCustomer
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
	|	INNER JOIN Document.DiscrepancyReportFollowingShipment.Goods AS ActOfItems
	|		ON ShippingGoods.Products = ActOfItems.Products
	|			AND ShippingGoods.Characteristic = ActOfItems.Characteristic
	|			AND (ShippingGoods.RowCode = ActOfItems.RowCode
	|				OR ActOfItems.RowCode = 0)
	|			AND ShippingGoods.Ref = ActOfItems.SalesOrder
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON (ShippingGoods.Ref = DocumentsRegistry.CorrectedDocument
	|				OR ShippingGoods.Ref = DocumentsRegistry.ReversedDocument)
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsSubsequentCorrections
	|		ON DocumentsRegistry.RefType = RegisterOfDocumentsSubsequentCorrections.RefType
	|			AND DocumentsRegistry.CorrectedDocument = RegisterOfDocumentsSubsequentCorrections.CorrectedDocument
	|			AND DocumentsRegistry.Ref = RegisterOfDocumentsSubsequentCorrections.ReversedDocument
	|			AND NOT RegisterOfDocumentsSubsequentCorrections.AdditionalRecord
	|			AND RegisterOfDocumentsSubsequentCorrections.Posted
	|			AND RegisterOfDocumentsSubsequentCorrections.IBDocumentDate > DocumentsRegistry.IBDocumentDate
	|WHERE
	|	ActOfItems.Ref = &DiscrepancyCertificate
	|	AND ShippingGoods.Ref.Posted
	|	AND ActOfItems.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery)
	|				)
	|	AND (DocumentsRegistry.Ref IS NULL
	|		OR RegisterOfDocumentsSubsequentCorrections.Ref IS NOT NULL)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	ShippingGoods.Ref AS GoodsShipmentToCustomer
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
	|	INNER JOIN Document.DiscrepancyReportFollowingShipment.Goods AS ActOfItems
	|		ON ShippingGoods.Products = ActOfItems.Products
	|			AND ShippingGoods.Characteristic = ActOfItems.Characteristic
	|			AND (ShippingGoods.RowCode = ActOfItems.RowCode
	|				OR ActOfItems.RowCode = 0)
	|			AND ShippingGoods.Ref.CorrectedDocument = ActOfItems.SalesOrder
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON (ShippingGoods.Ref = DocumentsRegistry.CorrectedDocument
	|				OR ShippingGoods.Ref = DocumentsRegistry.ReversedDocument)
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsSubsequentCorrections
	|		ON DocumentsRegistry.RefType = RegisterOfDocumentsSubsequentCorrections.RefType
	|			AND DocumentsRegistry.CorrectedDocument = RegisterOfDocumentsSubsequentCorrections.CorrectedDocument
	|			AND DocumentsRegistry.Ref = RegisterOfDocumentsSubsequentCorrections.ReversedDocument
	|			AND NOT RegisterOfDocumentsSubsequentCorrections.AdditionalRecord
	|			AND RegisterOfDocumentsSubsequentCorrections.Posted
	|			AND RegisterOfDocumentsSubsequentCorrections.IBDocumentDate > DocumentsRegistry.IBDocumentDate
	|WHERE
	|	ActOfItems.Ref = &DiscrepancyCertificate
	|	AND ShippingGoods.Ref.Posted
	|	AND ActOfItems.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery)
	|				)
	|	AND (DocumentsRegistry.Ref IS NULL
	|		OR RegisterOfDocumentsSubsequentCorrections.Ref IS NOT NULL)
	|";
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref                     AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse                      AS Warehouse,
		|	WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|			AND Actions.SaleOfGoodsAndServices = WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport
		|			AND Actions.Warehouse = WriteOffOfGoodsShortages.Warehouse
		|";
		
		CurrentNumber = 12;
		MatchingDataSets.Insert("GroundsForWriteOffOfShortagesOnShipmentDocuments", CurrentNumber);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function QueryTextOfSalesDisputeOfItemsAfterShipmentToCustomer(TableAccessRights, MatchingDataSets)
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Action         AS Action,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices       AS SaleOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse            AS Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder     AS SalesOrder
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	Actions.Action         AS Action,
	|	Actions.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	Actions.SaleOfGoodsAndServices       AS Basis,
	|	Actions.Warehouse            AS Warehouse,
	|	FALSE                      AS ThirdPartyIsGuilty,
	|	MAX(CASE
	|		WHEN Actions.SalesOrder REFS Document.SalesOrder
	|			THEN Actions.SaleOfGoodsAndServices.ShipmentByOrders
	|		WHEN Actions.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN Actions.SaleOfGoodsAndServices.ShipmentByOrders
	|		ELSE
	|			FALSE
	|	END)              AS ByOrders,
	|	UNDEFINED        AS OrderDocument
	|FROM
	|	Actions AS Actions
	|
	|GROUP BY
	|	Actions.Action,
	|	Actions.DiscrepancyTreatment,
	|	Actions.SaleOfGoodsAndServices,
	|	Actions.Warehouse
	|
	|TOTALS BY
	|	SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED DISTINCT
	|	Document.Ref                          AS GoodsReceiptFromCustomer,
	|	Document.BaseDocumentForDiscrepancyReport      AS Basis,
	|	Document.ReduceShipmentByReference AS ReduceShipmentByReference
	|FROM
	|	Actions AS Actions
	|	INNER JOIN Document.GoodsReceiptFromCustomer AS Document
	|		ON Document.Posted
	|			AND Actions.SaleOfGoodsAndServices = Document.BaseDocumentForDiscrepancyReport
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder AS SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices   AS GoodsShipmentToCustomer
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument <> CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder IN (
	|			VALUE(Document.SalesOrder.EmptyRef),
	|			VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|			VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|			UNDEFINED
	|			)
	|
	|ORDER BY
	|	SalesOrder DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT ALLOWED DISTINCT
	|	Document.Ref      AS GoodsShipmentToCustomer,
	|	Document.BaseDocumentOfDiscrepancyReportForCorrection AS Basis,
	|	Document.Patch AS Patch,
	|	FALSE                 AS AdditionalDelivery
	|FROM
	|	Actions AS Actions
	|	INNER JOIN Document.GoodsShipmentToCustomer AS Document
	|		ON (Document.Posted)
	|			AND Actions.SaleOfGoodsAndServices = Document.BaseDocumentOfDiscrepancyReportForCorrection
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Document.Ref      AS GoodsShipmentToCustomer,
	|	Document.BaseDocumentForDiscrepancyReport AS Basis,
	|	Document.Patch AS Patch,
	|	TRUE               AS AdditionalDelivery
	|FROM
	|	Actions AS Actions
	|	INNER JOIN Document.GoodsShipmentToCustomer AS Document
	|		ON (Document.Posted)
	|			AND Actions.SaleOfGoodsAndServices = Document.BaseDocumentForDiscrepancyReport
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT ALLOWED DISTINCT
	|	RecognitionOfStockSurplusShippedToCustomer.BaseDocumentForDiscrepancyReport AS Basis,
	|	RecognitionOfStockSurplusShippedToCustomer.Ref AS RecordingAsReceived
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.RecognitionOfStockSurplusShippedToCustomer AS RecognitionOfStockSurplusShippedToCustomer
	|		ON RecognitionOfStockSurplusShippedToCustomer.Posted
	|			AND RecognitionOfStockSurplusShippedToCustomer.BaseDocumentForDiscrepancyReport = Actions.SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////6
	|SELECT ALLOWED DISTINCT
	|	WriteOffOfShippedGoods.BaseDocumentForDiscrepancyReport AS Basis,
	|	WriteOffOfShippedGoods.Ref AS WriteOff,
	|	WriteOffOfShippedGoods.ReduceShipmentByReference AS ReduceShipmentByReference
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.WriteOffOfShippedGoods AS WriteOffOfShippedGoods
	|		ON WriteOffOfShippedGoods.Posted
	|			AND WriteOffOfShippedGoods.BaseDocumentForDiscrepancyReport = Actions.SaleOfGoodsAndServices
	|";
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref                     AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse                      AS Warehouse,
		|	WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|			AND Actions.SaleOfGoodsAndServices = WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport
		|			AND Actions.Warehouse = WriteOffOfGoodsShortages.Warehouse
		|";
		
		CurrentNumber = 7;
		MatchingDataSets.Insert("GroundsForWriteOffOfShortagesOnShipmentDocuments", CurrentNumber);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function RequestTextStatementOfDiscrepanciesAfterReturnFromClient(TableAccessRights, MatchingDataSets)

	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis AS Basis,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ThirdPartyIsGuilty AS ThirdPartyIsGuilty
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED DISTINCT
	|	Actions.Action AS Action,
	|	Actions.Basis AS Basis,
	|	Actions.ThirdPartyIsGuilty AS ThirdPartyIsGuilty,
	|	CASE
	|		WHEN Actions.Basis.RequestForReturnOfGoodsFromCustomer = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByOrders,
	|	Actions.Warehouse AS Warehouse,
	|	Actions.Basis.RequestForReturnOfGoodsFromCustomer AS OrderDocument
	|FROM
	|	Actions AS Actions
	|TOTALS BY
	|	Basis
	|";
	
	CurrentNumber = 1;
	
	If TableAccessRights.ReadingImplementations Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	CustomerInvoice.SubsequentDeliveryBySale AS Basis,
		|	CustomerInvoice.Ref AS SaleOfGoodsAndServices
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|		INNER JOIN Actions AS Actions
		|		ON CustomerInvoice.SubsequentDeliveryBySale = Actions.Basis
		|WHERE
		|	CustomerInvoice.Posted
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReturnsFromCustomersSales", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadReturnOfGoodsFromCustomer Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	Document.Ref AS Return,
		|	Document.AdditionalReturnWithinGoodsReturn AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS Document
		|		ON (Document.Posted)
		|			AND Actions.Basis = Document.AdditionalReturnWithinGoodsReturn
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReturnsFromCustomersReturns", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse AS Warehouse,
		|	WriteOffOfGoodsShortages.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|			AND Actions.Basis = WriteOffOfGoodsShortages.Basis
		|			AND Actions.Warehouse     = WriteOffOfGoodsShortages.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("GroundsForWritingOffShortfalls", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingDebtCancellation Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	ARAPAdjustment.Ref AS WriteOff,
		|	Actions.Basis                AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.ARAPAdjustment AS ARAPAdjustment
		|		ON (ARAPAdjustment.Posted)
		|			AND &DiscrepancyCertificate = ARAPAdjustment.DiscrepancyReportBaseDocument
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("BaseDocumentsForDebtRelief", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingRecordingSurplusGoods Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	InventorySurplusRecognition.Ref AS RecordingAsReceived,
		|	InventorySurplusRecognition.Warehouse AS Warehouse,
		|	InventorySurplusRecognition.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.InventorySurplusRecognition AS InventorySurplusRecognition
		|		ON (InventorySurplusRecognition.Posted)
		|			AND Actions.Basis = InventorySurplusRecognition.Basis
		|			AND Actions.Warehouse     = InventorySurplusRecognition.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("TheBasisOfRegistration", CurrentNumber);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function RequestTextReportOfDiscrepanciesAfterReturnToSupplier(TableAccessRights, MatchingDataSets)

	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Action AS Action,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices AS ReturnOfGoodsToVendor,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	Actions.Action                 AS Action,
	|	Actions.DiscrepancyTreatment         AS DiscrepancyTreatment,
	|	Actions.ReturnOfGoodsToVendor AS Basis,
	|	Actions.Warehouse                    AS Warehouse,
	|	FALSE                              AS ThirdPartyIsGuilty,
	|	FALSE                              AS ByOrders,
	|	UNDEFINED                      AS OrderDocument
	|FROM
	|	Actions AS Actions
	|
	|GROUP BY
	|	Actions.Action,
	|	Actions.DiscrepancyTreatment,
	|	Actions.ReturnOfGoodsToVendor,
	|	Actions.Warehouse
	|
	|TOTALS BY
	|	ReturnOfGoodsToVendor
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED DISTINCT
	|	VendorInvoice.SubsequentDeliveryByDocument AS Basis,
	|	VendorInvoice.Ref AS VendorInvoice
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|		INNER JOIN Actions AS Actions
	|		ON VendorInvoice.SubsequentDeliveryByDocument = Actions.ReturnOfGoodsToVendor
	|WHERE
	|	VendorInvoice.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED DISTINCT
	|	Document.Ref AS ReturnOfGoodsToVendor,
	|	Document.AdditionalReturnWithinGoodsReturn AS Basis
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.ReturnOfGoodsToVendor AS Document
	|		ON (Document.Posted)
	|			AND Actions.ReturnOfGoodsToVendor = Document.AdditionalReturnWithinGoodsReturn
	|";
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref                     AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse                      AS Warehouse,
		|	WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|			AND Actions.ReturnOfGoodsToVendor = WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport
		|			AND Actions.Warehouse = WriteOffOfGoodsShortages.Warehouse
		|";
		
		CurrentNumber = 4;
		MatchingDataSets.Insert("GroundsForWriteOffOfShortagesOnShipmentDocuments", CurrentNumber);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function RequestTextReportOfDiscrepanciesAfterReceiptOfGoods(TableAccessRights, MatchingDataSets)

	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref AS Act,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis AS Basis,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder AS OrderDocument,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ThirdPartyIsGuilty AS ThirdPartyIsGuilty,
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument > CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum
	|		ELSE 0
	|	END AS AmountOfShortDelivery,
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument < CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument
	|		ELSE 0
	|	END AS AmountOfReDelivery
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count <> 0
	|	AND
	|		(
	|		(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|			AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices))
	|		
	|		OR
	|		(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)))
	|		)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED DISTINCT
	|	Actions.Act                            AS Act,
	|	Actions.Action                       AS Action,
	|	Actions.Basis                      AS Basis,
	|	Actions.ThirdPartyIsGuilty        AS ThirdPartyIsGuilty,
	|	Actions.Basis.ReceiptUnderOrders AS ByOrders,
	|	Actions.Warehouse AS Warehouse,
	|	Actions.OrderDocument AS OrderDocument,
	|	SUM(Actions.AmountOfShortDelivery) AS AmountOfShortDelivery,
	|	SUM(Actions.AmountOfReDelivery) AS AmountOfReDelivery,
	|	&ThisIsDiscrepancyReport2_5_12 AS ThisIsDiscrepancyReport2_5_12
	|FROM
	|	Actions AS Actions
	|
	|GROUP BY
	|	Actions.Act,
	|	Actions.Action,
	|	Actions.Basis,
	|	Actions.ThirdPartyIsGuilty,
	|	Actions.Basis.ReceiptUnderOrders,
	|	Actions.Warehouse,
	|	Actions.OrderDocument
	|
	|TOTALS
	|	SUM(AmountOfShortDelivery),
	|	SUM(AmountOfReDelivery)
	|BY
	|	Basis";
	
	CurrentNumber = 1;
	
	If TableAccessRights.ReadAcquisitionAdjustment Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED
		|	PurchaseAdjustment.DocumentBasis     AS Basis,
		|	PurchaseAdjustment.Ref                AS Adjusting,
		|	PurchaseAdjustment.AdjustmentKind      AS BusinessOperation
		|FROM
		|	Document.PurchaseAdjustment AS PurchaseAdjustment
		|WHERE
		|	PurchaseAdjustment.DiscrepancyReportFollowingReceiptBaseDocument = &DiscrepancyCertificate
		|	AND PurchaseAdjustment.Posted
		|	AND &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReceiptsAdjustingEntries", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadReturnOfGoodsToSupplier Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	ReturnOfGoodsToSupplier.DocumentInflow AS DocumentInflow,
		|	ReturnOfGoodsToSupplier.Ref AS ReturnToVendor, 
		|	ReturnOfGoodsToSupplier.Ref.Warehouse AS Warehouse
		|FROM
		|	Document.ReturnOfGoodsToVendor.Goods AS ReturnOfGoodsToSupplier
		|		INNER JOIN Actions AS Actions
		|		ON ReturnOfGoodsToSupplier.DocumentInflow = Actions.Basis
		|		AND ReturnOfGoodsToSupplier.Ref.Warehouse = Actions.Warehouse
		|WHERE
		|	ReturnOfGoodsToSupplier.Ref.Posted
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReceiptsReturns", CurrentNumber);
	
	EndIf;	
	
	If TableAccessRights.ReadOrderToSupplier Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder AS PurchaseOrder,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis AS DocumentInflow
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
		|WHERE
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument <> CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_)
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|
		|ORDER BY
		|	PurchaseOrder DESC
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReceiptsOrders", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingPurchasingGoodsServices Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	VendorInvoice.Ref AS RegisteredReceipt,
		|	VendorInvoice.SubsequentDeliveryByDocument AS SubsequentDeliveryByReceipt
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.VendorInvoice AS VendorInvoice
		|		ON (VendorInvoice.Posted)
		|			AND Actions.Basis = VendorInvoice.SubsequentDeliveryByDocument
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReceiptsReceipts", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingReceiptOfGoodsInWarehouse Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	Actions.Basis AS Basis,
		|	ReceiptOfGoodsToWarehouse.Ref AS RegisteredReceipt,
		|	ReceiptOfGoodsToWarehouse.SubsequentDelivery AS SubsequentDeliveryByReceipt,
		|	ReceiptOfGoodsToWarehouse.Warehouse AS Warehouse,
		|	ReceiptOfGoodsToWarehouse.Patch AS Patch
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS ReceiptOfGoodsToWarehouse
		|		ON ReceiptOfGoodsToWarehouse.Posted
		|		AND Actions.Warehouse = ReceiptOfGoodsToWarehouse.Warehouse
		|		AND ReceiptOfGoodsToWarehouse.DiscrepancyReportFollowingReceiptBaseDocument = &DiscrepancyCertificate
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Actions.Basis AS Basis,
		|	ReceiptOfGoodsToWarehouse.Ref AS RegisteredReceipt,
		|	ReceiptOfGoodsToWarehouse.SubsequentDelivery AS SubsequentDeliveryByReceipt,
		|	ReceiptOfGoodsToWarehouse.Warehouse AS Warehouse,
		|	ReceiptOfGoodsToWarehouse.Patch AS Patch
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.VendorInvoice AS PurchaseOfGoods
		|		ON PurchaseOfGoods.Ref = Actions.Basis
		|		
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS ReceiptOfGoodsToWarehouse
		|		ON ReceiptOfGoodsToWarehouse.Posted 
		|		AND Actions.Warehouse  = ReceiptOfGoodsToWarehouse.Warehouse
		|		AND ReceiptOfGoodsToWarehouse.DiscrepancyReportFollowingReceiptBaseDocument =
		|			VALUE(Document.DiscrepancyReportFollowingReceipt.EmptyRef)
		|		AND ReceiptOfGoodsToWarehouse.ReferenceOrder = 
		|			(
		|			CASE
		// If the order is divided by a waybill and it is a waybill and not an order, it means an invoice:
		|				WHEN NOT PurchaseOfGoods.ReceiptUnderOrders
		|					AND PurchaseOfGoods.GoodsReceiptOption = 
		|						VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|				THEN
		|					PurchaseOfGoods.Ref
		|
		// If it is divided by a bill of lading and it is a bill of lading, it means an invoice:
		|				WHEN PurchaseOfGoods.GoodsReceiptOption = 
		|					VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|				THEN
		|					PurchaseOfGoods.Ref
		|				ELSE
		|					PurchaseOfGoods.PurchaseOrder
		|			END
		|			)
		|
		|		INNER JOIN Document.ReceiptOfGoodsToWarehouse.Goods AS ReceiptOfGoodsInWarehouseGoods
		|		ON ReceiptOfGoodsInWarehouseGoods.Ref = ReceiptOfGoodsToWarehouse.Ref
		|			AND ReceiptOfGoodsInWarehouseGoods.Products = Actions.Products
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReceiptsReceiptsToTheWarehouse", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse AS Warehouse,
		|	WriteOffOfGoodsShortages.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|			AND Actions.Basis = WriteOffOfGoodsShortages.Basis
		|			AND Actions.Warehouse     = WriteOffOfGoodsShortages.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("GroundsForWritingOffShortfalls", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingDebtCancellation Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	ARAPAdjustment.Ref AS WriteOff,
		|	ARAPAdjustment.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.ARAPAdjustment AS ARAPAdjustment
		|		ON (ARAPAdjustment.Posted)
		|			AND Actions.Basis = ARAPAdjustment.Basis
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("BaseDocumentsForDebtRelief", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingRecordingSurplusGoods Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	InventorySurplusRecognition.Ref AS RecordingAsReceived,
		|	InventorySurplusRecognition.Warehouse AS Warehouse,
		|	InventorySurplusRecognition.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.InventorySurplusRecognition AS InventorySurplusRecognition
		|		ON (InventorySurplusRecognition.Posted)
		|			AND Actions.Basis = InventorySurplusRecognition.Basis
		|			AND Actions.Warehouse     = InventorySurplusRecognition.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("TheBasisOfRegistration", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingWriteOffOfDiscrepanciesReceiptPurchase Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.Ref AS WriteOff,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.Basis AS Purchase,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.Warehouse AS Warehouse,
		|	WriteOffDiscrepanciesBetweenReceiptAndPurchase.PurchaseOrder AS OrderDocument
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS WriteOffDiscrepanciesBetweenReceiptAndPurchase
		|		ON (WriteOffDiscrepanciesBetweenReceiptAndPurchase.Posted)
		|			AND (Actions.Basis = WriteOffDiscrepanciesBetweenReceiptAndPurchase.Basis
		|				OR Actions.OrderDocument = WriteOffDiscrepanciesBetweenReceiptAndPurchase.PurchaseOrder)
		|			AND Actions.Warehouse = WriteOffDiscrepanciesBetweenReceiptAndPurchase.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("WriteOffOfDiscrepanciesReceiptPurchase", CurrentNumber);
	
	EndIf;

	If TableAccessRights.ReadingClaims Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	Complaints.Ref AS Claim,
		|	Complaints.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Catalog.Complaints AS Complaints
		|		ON NOT (Complaints.DeletionMark)
		|			AND Actions.Basis = CAST(Complaints.Basis AS Document.VendorInvoice)
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("Complaints", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingDebtAdjustment Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED TOP 1
        |	ARAPAdjustment.Ref AS Adjusting,
		|	Complaints.Ref AS Claim,
		|	Complaints.Basis AS Purchase
        |FROM
        |	Actions AS Actions
		|		INNER JOIN Catalog.Complaints AS Complaints
		|		ON NOT (Complaints.DeletionMark)
		|			AND Actions.Basis = CAST(Complaints.Basis AS Document.VendorInvoice)
        |		INNER JOIN Document.ARAPAdjustment.Debt_ AS ARAPAdjustment
        |		ON (ARAPAdjustment.Ref.Posted)
        |			AND (Complaints.ARAPObject = CAST(ARAPAdjustment.ARAPObject AS Catalog.ARAPObjects))
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	ARAPAdjustment.Ref AS Adjusting,
		|	UNDEFINED AS Claim,
		|	Actions.Basis AS Purchase
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.ARAPAdjustment.Debt_ AS ARAPAdjustment
		|		ON (ARAPAdjustment.Ref.Posted)
		|			AND (Actions.Basis = ARAPAdjustment.ARAPObject.Object)
		|
        |UNION
        |
        |SELECT TOP 1
        |	ARAPAdjustment.Ref,
        |	UNDEFINED,
        |	Actions.Basis
        |FROM
        |	Actions AS Actions
        |		INNER JOIN Document.ARAPAdjustment AS ARAPAdjustment
        |		ON (ARAPAdjustment.Ref.Posted)
        |			AND Actions.Act = ARAPAdjustment.DiscrepancyReportBaseDocument"; 
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("DebtAdjustments", CurrentNumber);
	
	EndIf;
	
	Return QueryText;

EndFunction 

&AtServer
Function QueryTextDiscrepancyReportFollowingTransfer(TableAccessRights, MatchingDataSets)
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	DiscrepancyReportFollowingTransfer.Action                AS Action,
	|	DiscrepancyReportFollowingTransfer.Ref.SourceWarehouse AS SourceWarehouse,
	|	DiscrepancyReportFollowingTransfer.Ref.DestinationWarehouse  AS DestinationWarehouse,
	|	DiscrepancyReportFollowingTransfer.DocumentBasis       AS Basis
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransfer
	|WHERE
	|	DiscrepancyReportFollowingTransfer.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingTransfer.NumberOfPackagesByDocument - DiscrepancyReportFollowingTransfer.Count <> 0
	|	AND DiscrepancyReportFollowingTransfer.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	Actions.Action                       AS Action,
	|	Actions.Basis                      AS Basis,
	|	Actions.Basis.TransferAgainstOrders AS ByOrders,
	|	FALSE                                    AS ThirdPartyIsGuilty,
	|	Actions.Basis.TransferOrder   AS OrderDocument
	|FROM
	|	Actions AS Actions
	|TOTALS BY
	|	Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED DISTINCT
	|	Document.Ref AS InventoryTransfer,
	|	Document.TransferOfNonConformanceCertificate AS Basis,
	|	Document.Ref.Patch AS Patch
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.InventoryTransfer AS Document
	|		ON (Document.Posted)
	|			AND Actions.Basis = Document.TransferOfNonConformanceCertificate
	|			AND Actions.SourceWarehouse = Document.SourceWarehouse
	|			AND Actions.DestinationWarehouse = Document.DestinationWarehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED DISTINCT
	|	InventoryTransfer.Ref AS InventoryTransfer,
	|	InventoryTransfer.TransferOfNonConformanceCertificate AS Basis
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.InventoryTransfer AS InventoryTransfer
	|		ON (InventoryTransfer.Posted)
	|			AND Actions.Basis = InventoryTransfer.TransferOfNonConformanceCertificate
	|			AND Actions.DestinationWarehouse = InventoryTransfer.SourceWarehouse
	|			AND Actions.SourceWarehouse = InventoryTransfer.DestinationWarehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT ALLOWED DISTINCT
	|	DiscrepancyReportFollowingTransferGoods.DocumentBasis AS InventoryTransfer,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument             AS TransferOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument <> DiscrepancyReportFollowingTransferGoods.NumberOfPackages
	|	AND DiscrepancyReportFollowingTransferGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|	AND DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingTransferGoods.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|
	|ORDER BY
	|	TransferOrder DESC
	|";
	
	CurrentNumber = 4;
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse AS Warehouse,
		|	WriteOffOfGoodsShortages.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|			AND Actions.Basis = WriteOffOfGoodsShortages.Basis
		|			AND Actions.DestinationWarehouse = WriteOffOfGoodsShortages.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("BasesForWritingOffShortagesInGoodsMovement", CurrentNumber);
	
	EndIf;
	
	If TableAccessRights.ReadingRecordingSurplusGoods Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	InventorySurplusRecognition.Ref AS RecordingAsReceived,
		|	InventorySurplusRecognition.Warehouse AS Warehouse,
		|	InventorySurplusRecognition.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.InventorySurplusRecognition AS InventorySurplusRecognition
		|		ON (InventorySurplusRecognition.Posted)
		|			AND Actions.Basis = InventorySurplusRecognition.Basis
		|			AND Actions.DestinationWarehouse = InventorySurplusRecognition.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("BasesForGoodsMovementRecordingAsReceived", CurrentNumber);
	
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region OutputInformationToReport

&AtServer
Procedure PrintActionLinesForActAfterShipment(ActionString, Template, TypeOfBaseDocumentForNonConformanceCertificate, TableAccessRights)
	
	ThisIsTransferOfOwnership = 
		(BusinessTransactionOfCertificate = Enums.BusinessTransactions.TransferOfTitleToGoods);
	
	UseShipmentWithDeferredTransferOfTitle2_5 = GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
	
	If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments Then
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "Change");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				WithdrawFromSaleOfGoodsAndServices(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					WithdrawGoodsWriteOffShippedToCustomer(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
					
				EndIf;
				
				If ThisIsTransferOfOwnership Then
					
					SearchParameters = New Structure;
					SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
					FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
					If FoundRows.Count() > 0 Then
						
						LongDesc = New Structure;
						LongDesc.Insert("BasisOfAct", ActionString.Basis);
						LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
						LongDesc.Insert("CommandName", "ApplyAppearance");
						LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
						LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
						
						ToDisplayCorrectionOfShipmentsOfItemsToClientDuringTransferOfOwnership(
							ActionString,
							Template,
							LongDesc);
						
					EndIf;
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawShipmentOfItemsToCustomerForAdditionalDeliveryOfUndeliveredItems(ActionString, Template, LongDesc);
					
				Else
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					PrintSalesDocumentForAdditionalDeliveryOfUndeliveredGoods(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				YouNeedToGroupRows = False;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "Change");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc);
					
					YouNeedToGroupRows = True;
					
				EndIf;
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.StartRowGroup();
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					WithdrawGoodsWriteOffShippedToCustomer(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				WithdrawShipmentOfItemsToCustomerForAdditionalDeliveryOfUndeliveredItems(ActionString, Template, LongDesc);
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.EndRowGroup();
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "Change");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				OutputGoodsReturnCorrectionToSupplier(
					ActionString,
					Template,
					LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				PrintReturnOfGoodsToSupplierDocumentToReturnUndeliveredGoods(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				WithdrawOrderOfTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				PrintTransferDocumentForAdditionalDeliveryOfUndeliveredGoods(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				WithdrawCostOfTransferringGoodsToCommission(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				PrintTransferDocumentForAdditionalDeliveryByCommissionOfUndeliveredGoods(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			Else
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				OutputCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				PrintDocumentShipmentOfGoodsFromStorageToReturnUndeliveredGoods(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				// If there are orders:
				// +Output the invoice that needs to be reduced (the Change button).
				// +Output the order in which the lines are subject to cancellation. (Change button).
				// If there are no orders:
				// +We output the invoice, which must be reduced. (Change button).
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "Change");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				WithdrawFromSaleOfGoodsAndServices(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					WithdrawGoodsWriteOffShippedToCustomer(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ThisIsTransferOfOwnership Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					ToDisplayCorrectionOfShipmentsOfItemsToClientDuringTransferOfOwnership(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ThisIsTransferOfOwnership Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ActionString.ByOrders Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					PrintCorrectionOfOrderDocument(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				YouNeedToGroupRows = False;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "Change");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc);
					
					YouNeedToGroupRows = True;
					
				EndIf;
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.StartRowGroup();
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					WithdrawGoodsWriteOffShippedToCustomer(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ActionString.ByOrders Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					PrintCorrectionOfOrderDocument(ActionString, Template, LongDesc);
					
				EndIf;
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.EndRowGroup();
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "Change");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				OutputGoodsReturnCorrectionToSupplier(ActionString, Template, LongDesc);
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					SpreadsheetDocument.StartRowGroup();
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
					SpreadsheetDocument.EndRowGroup();
					
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				
				WithdrawOrderOfTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				If ActionString.ByOrders Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct",    ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName",       "ApplyAppearance");
					LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					
					OutputCorrectionToTransferOrderDocument(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				
				WithdrawCostOfTransferringGoodsToCommission(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				If ActionString.ByOrders Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct",    ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName",       "ApplyAppearance");
					LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					
					OutputCorrectionToTransferOrderDocument(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			Else
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				
				OutputCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				// +Increase of the invoice in excess of the order (Change button)
				// +If there are requests for a refund, then making an application for the return of the over-delivered (commandagiperlink)
				// +If there are no requests for a refund, then processing the return of the over-delivered. (commandagiperlink ).
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "Change");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				WithdrawFromSaleOfGoodsAndServices(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ThisIsTransferOfOwnership Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					ToDisplayCorrectionOfShipmentsOfItemsToClientDuringTransferOfOwnership(
						ActionString,
						Template,
						LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawRegistrationOfSurplusShippedItems(ActionString, Template, LongDesc);
					
				EndIf;
				
				If ThisIsTransferOfOwnership Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection);
					
					If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
						AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection;
					Else
						AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties;
					EndIf;
					
					OutputDocumentCreditNoteReturnToPath(
						ActionString,
						AdjustmentKind,
						Template,
						LongDesc);
					
				Else
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputReturnDocument(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "Change");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc);
					
					YouNeedToGroupRows = True;
					
				EndIf;
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawRegistrationOfSurplusShippedItems(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				LongDesc.Insert("ByOrders", ActionString.ByOrders);
				
				PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				OutputGoodsReturnCorrectionToSupplier(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				PrintDocumentPurchaseOfGoodsServices(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				WithdrawOrderOfTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				PrintReturnDocumentForTransfer(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				WithdrawCostOfTransferringGoodsToCommission(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				PrintRefundDocumentForTransferToCommission(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			Else
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				OutputCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				OutputDocumentAcceptanceOfGoodsForStorage(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			EndIf;
			
		EndIf;
			
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				// +Increase of the invoice in excess of the order. (Change button)
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				
				WithdrawFromSaleOfGoodsAndServices(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawRegistrationOfSurplusShippedItems(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ThisIsTransferOfOwnership Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					ToDisplayCorrectionOfShipmentsOfItemsToClientDuringTransferOfOwnership(
						ActionString,
						Template,
						LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "Change");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawRegistrationOfSurplusShippedItems(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				
				OutputGoodsReturnCorrectionToSupplier(ActionString, Template, LongDesc);
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				
				WithdrawOrderOfTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				
				WithdrawCostOfTransferringGoodsToCommission(ActionString, Template, LongDesc);
				
			Else
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "Change");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				
				OutputCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
			EndIf;
			
		EndIf;
		
	ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
		Or DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties Then
		
		UseDocumentCorrection = GetFunctionalOption("UseDocumentCorrection");
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.ErrorCorrection, Template, LongDesc);
				Else
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties, Template, LongDesc);
				EndIf;
				
				If UseShipmentWithDeferredTransferOfTitle2_5 Then
					
					SpreadsheetDocument.StartRowGroup();
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
						AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection;
					Else
						AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties;
					EndIf;
					
					OutputDocumentCreditNoteReturnToPath(
						ActionString,
						AdjustmentKind,
						Template,
						LongDesc);
					
					SpreadsheetDocument.EndRowGroup();
					
				Else
					
					SpreadsheetDocument.StartRowGroup();
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputReturnDocument(ActionString, Template, LongDesc);
					
					SpreadsheetDocument.EndRowGroup();
					
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("Patch", True);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc, UseDocumentCorrection);
					
					YouNeedToGroupRows = True;
					
				EndIf;
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawRegistrationOfSurplusShippedItems(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				LongDesc.Insert("ByOrders", ActionString.ByOrders);
				
				PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				// +Correction of the document "Transfer of goods to the custodian" (Command Hyperlink).
				// +Output a command to create a correction, by which we increase the invoice in excess of the order (Command Hyperlink).
				// +If there are requests for a refund, then making an application for a refund of the over-delivered one (Command Hyperlink).
				// +If there are no requests for a refund, then making a refund of the over-delivered one. (Command Hyperlink).
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				OutputDocumentCorrectionTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				PrintReturnDocumentForTransfer(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				// +Correction of the document "Transfer of goods to the custodian" (commandagiperlink)
				// +We output a command to create a correction, by which we increase the invoice in excess of the order (Command Hyperlink).
				// +If there are requests for a refund, then making an application for a refund of the over-delivered one (Command Hyperlink).
				// +If there are no requests for a refund, then making a refund of the over-delivered one. (Command Hyperlink).
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				OutputDocumentCorrectionTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				PrintRefundDocumentForTransferToCommission(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And (DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate)
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
				Or False) Then
				
				// +Correction of the document "Shipment of storage goods" (Command Hyperlink).
				// Registration of receipt of the over-delivered (Command hyperlink).
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				OutputDocumentCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
				
				OutputDocumentAcceptanceOfGoodsForStorage(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			EndIf;
		
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.ErrorCorrection, Template, LongDesc);
				Else
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties, Template, LongDesc);
				EndIf;
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				YouNeedToGroupRows = False;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("Patch", True);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc, UseDocumentCorrection);
					
					YouNeedToGroupRows = True;
					
				EndIf;
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.StartRowGroup();
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					WithdrawGoodsWriteOffShippedToCustomer(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ActionString.ByOrders Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					PrintCorrectionOfOrderDocument(ActionString, Template, LongDesc);
					
				EndIf;
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.EndRowGroup();
				EndIf;
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And (DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
					Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate)) Then
				
				// +Correction of the document "Transfer of goods to the custodian" (Command hyperlink).
				// If there are orders:
				// +Output the command to create a correction, by which we reduce the invoice (command Hyperlink).
				// +Output the order in which the lines are subject to cancellation. (Change button).
				// If there are no orders:
				// +We output a command to create a correction, by which we reduce the invoice. (Command Hyperlink).
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				
				OutputDocumentCorrectionTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 And ActionString.ByOrders Then
					
					LongDesc = New Structure;
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("BasisOfAct",    ActionString.Basis);
					LongDesc.Insert("CommandName",       "ApplyAppearance");
					LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
					LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					
					OutputCorrectionToTransferOrderDocument(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And (DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate)
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
				Or False) Then
				
				// +Correction of the document "Shipment of storage goods" (Command Hyperlink)
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
				
				OutputDocumentCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
				// +Document "Shipment of goods to the customer (correction) for identified discrepancies (Command Hyperlink)."
				// +Document "Credit note" for identified discrepancies (Command Hyperlink).
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.ErrorCorrection, Template, LongDesc);
				Else
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties, Template, LongDesc);
				EndIf;
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("Patch", True);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc, UseDocumentCorrection);
					
				EndIf;
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawRegistrationOfSurplusShippedItems(ActionString, Template, LongDesc);
					
				EndIf;
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And (DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
					Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate)) Then
				
				// +Correction of the document "Transfer of goods to the custodian" (commandagiperlink)
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				
				OutputDocumentCorrectionTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And (DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate)
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
				Or False) Then
				
				// +Correction of the document "Shipment of storage goods" (Command Hyperlink)
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
				
				OutputDocumentCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.ErrorCorrection, Template, LongDesc);
				Else
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties, Template, LongDesc);
				EndIf;
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				If ThisIsTransferOfOwnership Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					WithdrawShipmentOfItemsToCustomerForAdditionalDeliveryOfUndeliveredItems(ActionString, Template, LongDesc);
					
				Else
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					PrintSalesDocumentForAdditionalDeliveryOfUndeliveredGoods(ActionString, Template, LongDesc);
					
				EndIf;
					
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				YouNeedToGroupRows = False;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("Patch", True);
					
					OutputCorrectionShipmentOfGoodsToCustomer(ActionString.Basis, Template, LongDesc, UseDocumentCorrection);
					
					YouNeedToGroupRows = True;
					
				EndIf;
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.StartRowGroup();
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					WithdrawGoodsWriteOffShippedToCustomer(ActionString, Template, LongDesc);
					
				EndIf;
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					LongDesc.Insert("ByOrders", ActionString.ByOrders);
					
					PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct", ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName", "ApplyAppearance");
				LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
				WithdrawShipmentOfItemsToCustomerForAdditionalDeliveryOfUndeliveredItems(ActionString, Template, LongDesc);
				
				If YouNeedToGroupRows Then
					SpreadsheetDocument.EndRowGroup();
				EndIf;
			
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				// +Correction of the document "Transfer of goods to the custodian" (Command hyperlink).
				//If there are orders:
				//+Output a command to create a correction, by which we reduce the invoice (Command Hyperlink).
				//+Output a command to create a new invoice for the Transfer of the undelivered (command Hyperlink).
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				OutputDocumentCorrectionTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				PrintTransferDocumentForAdditionalDeliveryOfUndeliveredGoods(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				// +Correction of the document "Transfer of goods to the custodian" (Command hyperlink).
				//If there are orders:
				//+Output a command to create a correction, by which we reduce the invoice (Command Hyperlink).
				//+Output a command to create a new invoice for the Transfer of the undelivered (command Hyperlink).
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				OutputDocumentCorrectionTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
				LongDesc = New Structure;
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				PrintTransferDocumentForAdditionalDeliveryByCommissionOfUndeliveredGoods(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And (DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate)
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
				Or False) Then
				
				// +Correction of the document "Shipment of storage goods" (Command Hyperlink)
				LongDesc = New Structure;
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				OutputDocumentCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = New Structure;
				LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
				LongDesc.Insert("BasisOfAct",    ActionString.Basis);
				LongDesc.Insert("CommandName",       "ApplyAppearance");
				LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
				LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
				
				PrintDocumentShipmentOfGoodsFromStorageToReturnUndeliveredGoods(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow) <> Undefined Then
			
			If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
				And DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
				SearchParameters = New Structure;
				SearchParameters.Insert("VariantOfActionWithDocument", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
				SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
				FoundRows = ActionString.OptionsForActionsWithGoods.FindRows(SearchParameters);
				If FoundRows.Count() > 0 Then
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow;
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					
					PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments Then
		
		If ActionString.ThereIsSurplusesRecord Then
			
			If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) <> Undefined Then
				
				If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
					// +Document "Adjustment of sales" for the sale of over-delivered goods (Commandagiperlink)
					// +If there are requests for a refund, then the execution of an application for the return of over-delivered (Commandagiperlink)
					// +If there are no requests for a refund, then processing the return of the over-delivered. (commandagiperlink ).
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.SaleOfOverdeliveredGoods, Template, LongDesc);
					
					SpreadsheetDocument.StartRowGroup();
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputReturnDocument(ActionString, Template, LongDesc);
					
					SpreadsheetDocument.EndRowGroup();
				
				EndIf;
				
			EndIf;
			
			If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery) <> Undefined Then
				
				If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
					// +Document "Adjustment of sales" for the sale of over-delivered goods (commandagiperlink).
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.SaleOfOverdeliveredGoods, Template, LongDesc);
				
				EndIf;
				
			EndIf;
		
		EndIf;
		
		If ActionString.ThereIsShortageRecord Then
			
			If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired) <> Undefined Then
				
				If TypeOf(DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment")
					And DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
					
					// +Making adjustments for the return of undelivered (commandagiperlink)
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods, Template, LongDesc);
					
				EndIf;
				
			EndIf;
			
			If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired) <> Undefined Then
				
				If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
				
					// +Making adjustments for the return of undelivered (commandagiperlink)
					// +Registration of the sale for the additional delivery of the undelivered goods (Commandagiperlink).
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					OutputDocumentImplementationAdjustment(ActionString, Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods, Template, LongDesc);
					
					SpreadsheetDocument.StartRowGroup();
					
					LongDesc = New Structure;
					LongDesc.Insert("BasisOfAct", ActionString.Basis);
					LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
					LongDesc.Insert("CommandName", "ApplyAppearance");
					LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
					LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
					
					PrintSalesDocumentForAdditionalDeliveryOfUndeliveredGoods(ActionString, Template, LongDesc);
					
					SpreadsheetDocument.EndRowGroup();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure PrintActionLinesForActAfterMove(ActionString, Template, TypeOfBaseDocumentForNonConformanceCertificate, TableAccessRights)

	UseDocumentCorrection = GetFunctionalOption("UseDocumentCorrection");

	If Not UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired) <> Undefined Then
			
			// We output the displacement that needs to be reduced.  (Change button)
			// Output a command to create a new move to the pre-displacement of the under-displaced one. (commandagiperlink ).
			
			LongDesc = New Structure;
			LongDesc.Insert("BasisOfAct", ActionString.Basis);
			LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			LongDesc.Insert("CommandName", "Change");
			LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
			LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
			
			OutputCorrectionOfGoodsMovement(
				ActionString,
				Template,
				LongDesc);
				
				
			LongDesc = New Structure;
			LongDesc.Insert("BasisOfAct", ActionString.Basis);
			LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			LongDesc.Insert("CommandName", "ApplyAppearance");
			LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
			LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
			PrintDocumentMovingGoods(
				ActionString,
				Template,
				LongDesc);
			
	EndIf;
	
	If UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired) <> Undefined Then
			
			// We output a command to create a displacement adjustment that needs to be reduced.  (Change button)
			// Output a command to create a new move to the pre-displacement of the under-displaced one. (commandagiperlink ).
			
			LongDesc = New Structure;
			LongDesc.Insert("BasisOfAct", ActionString.Basis);
			LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			LongDesc.Insert("CommandName", "ApplyAppearance");
			LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
			LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
			
			OutputAdjustmentOfGoodsMovement(
				ActionString,
				Template,
				LongDesc);
				
				
			LongDesc = New Structure;
			LongDesc.Insert("BasisOfAct", ActionString.Basis);
			LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			LongDesc.Insert("CommandName", "ApplyAppearance");
			LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
			LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
				
			PrintDocumentMovingGoods(
				ActionString,
				Template,
				LongDesc,
				False,
				UseDocumentCorrection);
			
	EndIf;

	If Not UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired) <> Undefined Then
		
		// If there are orders:
		//  We output the movement that needs to be reduced (the Change button).
		//  We output a transfer order in which the lines are subject to cancellation. (commandagiperlink ).
		// If there are no orders:
		//  We output the movement that needs to be reduced (the Change button).
		
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct", ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
		LongDesc.Insert("CommandName", "Change");
		LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
		LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
		
		OutputCorrectionOfGoodsMovement(
			ActionString,
			Template,
			LongDesc);
			
		If ActionString.ByOrders Then
			SpreadsheetDocument.StartRowGroup();
			
			LongDesc = New Structure;
			LongDesc.Insert("BasisOfAct", ActionString.Basis);
			LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			LongDesc.Insert("CommandName", "ApplyAppearance");
			LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
			LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
			
			PrintMoveOrderDocument(ActionString, Template, LongDesc);
			SpreadsheetDocument.EndRowGroup();
		EndIf;
			
	EndIf;
	
	If UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired) <> Undefined Then
		
		// If there are orders:
		//  We output a command to create a displacement adjustment that needs to be reduced. (Change button).
		//  We output a transfer order in which the lines are subject to cancellation. (commandagiperlink ).
		// If there are no orders:
		//  We output a command to create a displacement adjustment that needs to be reduced. (Change button).
		
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct", ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
		LongDesc.Insert("CommandName", "ApplyAppearance");
		LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
		LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
		
		OutputAdjustmentOfGoodsMovement(
			ActionString,
			Template,
			LongDesc);
			
		If ActionString.ByOrders Then
			SpreadsheetDocument.StartRowGroup();
			
			LongDesc = New Structure;
			LongDesc.Insert("BasisOfAct", ActionString.Basis);
			LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
			LongDesc.Insert("CommandName", "ApplyAppearance");
			LongDesc.Insert("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
			LongDesc.Insert("ReflectionMethod", DiscrepanciesPostingMethod);
			
			PrintMoveOrderDocument(ActionString, Template, LongDesc);
			SpreadsheetDocument.EndRowGroup();
		EndIf;
			
	EndIf;
		
	If Not UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) <> Undefined Then
		
		// Creating a new transfer for goods over the order (commandagiperlink)
		// Registration of the transfer for the return of the re-moved. (commandagiperlink).
		
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct",    ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
		LongDesc.Insert("CommandName",       "Change");
		LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
		LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
		
		OutputCorrectionOfGoodsMovement(
			ActionString,
			Template,
			LongDesc);
			
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct",        ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate",     DiscrepancyCertificate);
		LongDesc.Insert("CommandName",           "ApplyAppearance");
		LongDesc.Insert("PossibleAction",      Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
		LongDesc.Insert("ReflectionMethod",      DiscrepanciesPostingMethod);
		LongDesc.Insert("MovingToRefund", True);
			
		PrintDocumentMovingGoods(ActionString, Template, LongDesc, True);
		
	EndIf;
	
	If UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) <> Undefined Then
		
		// We output a command to create a displacement adjustment that needs to be increased (the Change button).
		// Registration of the transfer for the return of the re-moved. (commandagiperlink).
		
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct",    ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate", DiscrepancyCertificate);
		LongDesc.Insert("CommandName",       "ApplyAppearance");
		LongDesc.Insert("PossibleAction",  Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
		LongDesc.Insert("ReflectionMethod",  DiscrepanciesPostingMethod);
		
		OutputAdjustmentOfGoodsMovement(
			ActionString,
			Template,
			LongDesc);
			
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct",        ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate",     DiscrepancyCertificate);
		LongDesc.Insert("CommandName",           "ApplyAppearance");
		LongDesc.Insert("PossibleAction",      Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
		LongDesc.Insert("ReflectionMethod",      DiscrepanciesPostingMethod);
		LongDesc.Insert("MovingToRefund", True);
			
		PrintDocumentMovingGoods(ActionString, Template, LongDesc, True, UseDocumentCorrection);
		
	EndIf;

	If Not UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery) <> Undefined Then
		
		//  We output the movement that needs to be increased (the Change button).
		
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct",        ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate",     DiscrepancyCertificate);
		LongDesc.Insert("CommandName",           "Change");
		LongDesc.Insert("PossibleAction",      Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
		LongDesc.Insert("ReflectionMethod",      DiscrepanciesPostingMethod);
		
		OutputCorrectionOfGoodsMovement(ActionString, Template, LongDesc);
		
	EndIf;
	
	If UseDocumentCorrection
		And ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery) <> Undefined Then
		
		//  We output the movement that needs to be increased (the Change button).
		
		LongDesc = New Structure;
		LongDesc.Insert("BasisOfAct",        ActionString.Basis);
		LongDesc.Insert("DiscrepancyCertificate",     DiscrepancyCertificate);
		LongDesc.Insert("CommandName",           "ApplyAppearance");
		LongDesc.Insert("PossibleAction",      Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
		LongDesc.Insert("ReflectionMethod",      DiscrepanciesPostingMethod);
		
		OutputAdjustmentOfGoodsMovement(ActionString, Template, LongDesc);
		
	EndIf;
	
	If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial) <> Undefined Then
		
		If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentWritingOffShortagesOfGoodsMovingGoods(ActionString, Template, LongDesc);
			
		EndIf;
	EndIf;
	
	If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage) <> Undefined Then
		
		If TableAccessRights.ReadingRecordingSurplusGoods Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentRegistrationOfSurplusMovementOfGoods(ActionString, Template, LongDesc);
			
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure PrintActionLinesForReportAfterAcceptance(ActionString, Template, TypeOfBaseDocumentForNonConformanceCertificate, TableAccessRights)
	
	ThisIsDiscrepancyReport2_5_12 = ActionString.ThisIsDiscrepancyReport2_5_12;
	UninvoicedReceiptDocumentIsUsed = ReceiptsReceiptsToTheWarehouse.Count() > 0;
	UseDocumentCorrection = GetFunctionalOption("UseDocumentCorrection");
	If Common.HasObjectAttribute("BusinessOperation", ActionString.Basis.Metadata()) Then
		SeparatePurchaseOperations = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
		BusinessOperation = Common.ObjectAttributeValue(ActionString.Basis, "BusinessOperation");
		SeparatePurchasingIsUsed = SeparatePurchaseOperations.Find(BusinessOperation) <> Undefined;
	Else
		SeparatePurchasingIsUsed = False;
	EndIf;
	
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
	
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			LongDesc.EDIStatus        = ActionString.EDIStatus;
			LongDesc.DocumentEDI      = ActionString.ElectronicDocument;
			
			PrintElectronicDocumentPurchaseOfGoodsServices(ActionString, Template, LongDesc);
			
			If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments Then
				
				LongDesc.CommandName       = "Change";
				OutputCorrectionPurchaseOfGoodsServices(ActionString, Template, LongDesc);
			
				If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered) <> Undefined
					Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined Then
					SpreadsheetDocument.StartRowGroup();
					
					LongDesc = StructuresForDescribingActionDisplayedInReport();
				
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					LongDesc.AmountOfShortDelivery = ActionString.AmountOfShortDelivery;
				
					OutputReceiptDocumentToWarehouseForReposting(ActionString, Template, LongDesc);
				EndIf;
				
			ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries
				And TableAccessRights.ReadAcquisitionAdjustment Then
				
				LongDesc.CommandName       = "ApplyAppearance";
				PrintPurchaseAdjustmentDocument(ActionString, Template, LongDesc);
				
				If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered) <> Undefined
					Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined Then
					SpreadsheetDocument.StartRowGroup();
			
					LongDesc = StructuresForDescribingActionDisplayedInReport();
				
					LongDesc.BasisOfAct    = ActionString.Basis;
					LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
					LongDesc.CommandName       = "ApplyAppearance";
					LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
					LongDesc.AmountOfShortDelivery = ActionString.AmountOfShortDelivery;
				
					OutputReceiptDocumentToWarehouseForReposting(ActionString, Template, LongDesc, True);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined
			And TableAccessRights.ReadReturnOfGoodsToSupplier Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintReturnOfGoodsToSupplierDocument(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined Then
			
			If ActionString.ByOrders 
				And DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments
				And TableAccessRights.ReadOrderToSupplier Then
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = StructuresForDescribingActionDisplayedInReport();
				
				LongDesc.BasisOfAct    = ActionString.Basis;
				LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
				LongDesc.CommandName       = "ApplyAppearance";
				LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered;
				LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
				
				OutputCorrectionToOrderToSupplierDocument(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined
			And TableAccessRights.ReadingPurchasingGoodsServices Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentOfAdditionalDeliveryUponReceipt(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined
			And TableAccessRights.ReadingReceiptOfGoodsInWarehouse
			And SeparatePurchasingIsUsed Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentOfAdditionalDeliveryUponReceiptToWarehouse(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices) <> Undefined
			And TableAccessRights.ReadingReceiptOfGoodsInWarehouse
			And SeparatePurchasingIsUsed Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentOfAdditionalDeliveryUponReceiptToWarehouse(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration) <> Undefined
			And TableAccessRights.ReadingReceiptOfGoodsInWarehouse
			And UninvoicedReceiptDocumentIsUsed
			And DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments 
			And Not SeparatePurchasingIsUsed Then
				
			SpreadsheetDocument.StartRowGroup();
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "Change";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintChangeInDocumentReceiptOfGoods(ActionString, Template, LongDesc);
				
		EndIf;
		
		If (ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration) <> Undefined
				Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome) <> Undefined)
			And TableAccessRights.ReadingReceiptOfGoodsInWarehouse
			And UninvoicedReceiptDocumentIsUsed
			And DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries
			And UseDocumentCorrection 
			And (Not SeparatePurchasingIsUsed 
				Or ThisIsDiscrepancyReport2_5_12) Then
				
			SpreadsheetDocument.StartRowGroup();
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			OutputAdjustmentToReceiptOfGoodsDocument(ActionString, Template, LongDesc);
				
		EndIf;
		
		If (ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses) <> Undefined
				Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome) <> Undefined)
			And TableAccessRights.ReadingWriteOffOfDiscrepanciesReceiptPurchase
			And SeparatePurchasingIsUsed 
			And Not ThisIsDiscrepancyReport2_5_12 Then
				
			SpreadsheetDocument.StartRowGroup();
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			LongDesc.AmountOfShortDelivery = ActionString.AmountOfShortDelivery;
			
			DisplayWriteOffOfDiscrepanciesReceiptPurchaseOfItems(ActionString, Template, LongDesc);
				
		EndIf;          
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses) <> Undefined
			And TableAccessRights.ReadingClaims
			And TableAccessRights.ReadingDebtAdjustment
			And SeparatePurchasingIsUsed
			And DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries 
			And ActionString.ThirdPartyIsGuilty Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "Create";
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			LongDesc.AmountOfShortDelivery = ActionString.AmountOfShortDelivery;

			ShowClaim(ActionString, Template, LongDesc);  
			
			If TableAccessRights.AddingDebtCancellation Then
				LongDesc.BasisOfAct    = ActionString.Basis;
				LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
				LongDesc.CommandName       = "ApplyAppearance";
				LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;

				OutputDebtAdjustment(ActionString, Template, LongDesc);
			Else
				EmptyStringArea = Template.GetArea("IsBlankString");
				SpreadsheetDocument.Put(EmptyStringArea);
				
				OutputError(NStr("vi = 'Chứng từ ""Điều chỉnh công nợ"" không được phép để lập. Có thể, không có quyền cần thiết.';
								|ru = 'Документ ""Корректировка задолженности"" недоступен для оформления. Возможно нет необходимых прав.';
								|en = 'Cannot register the AR/AP adjustment document. You may not have the required rights.'; fa = 'Cannot register the AR/AP adjustment document. You may not have the required rights.';
								|it = 'Документ ""Корректировка задолженности"" недоступен для оформления. Возможно нет необходимых прав.';
								|pl = 'Cannot register the AR/AP adjustment document. You may not have the required rights.';
								|tr = '""Borç tahsisi"" belgesi işlenmek için mevcut değil. Muhtemelen gerekli yetki yok.'"), Template);
			EndIf;
			
		EndIf;
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
		  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		Then
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate  = DiscrepancyCertificate;
			LongDesc.BasisOfAct     = ActionString.Basis;
			LongDesc.ReflectionMethod   = DiscrepanciesPostingMethod;
			LongDesc.PossibleAction   = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome;
			
			If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
				// Correction of the document "Acceptance of inventory" (Command Hyperlink).
				LongDesc.CommandName    = "ApplyAppearance";
				OutputDocumentCorrectionGoodsReceiptForStorage(ActionString, Template, LongDesc);
			Else
				LongDesc.CommandName    = "Change";
				OutputCorrectionAcceptanceOfGoodsForStorage(ActionString, Template, LongDesc);
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined
			And TableAccessRights.ReadingShippingGoodsFromStorage Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			GenerateDocumentsForShipmentOfGoodsFromStorage(ActionString, Template, IssuedDocumentsOnAct, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined Then
			
			If ActionString.ByOrders
				And (TableAccessRights.ReadOrderToSupplier
					Or TableAccessRights.ReadingGiverSOrder2_5
					Or False) Then
				
				SpreadsheetDocument.StartRowGroup();
				
				LongDesc = StructuresForDescribingActionDisplayedInReport();
				LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
				LongDesc.BasisOfAct    = ActionString.Basis;
				LongDesc.CommandName       = "ApplyAppearance";
				LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered;
				LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
				
				OutputCorrectionToOrderToSupplierDocument(ActionString, Template, LongDesc);
				
				SpreadsheetDocument.EndRowGroup();
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined
			And TableAccessRights.ReadAcceptanceOfGoodsForStorage Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			DisplayDocumentOfAdditionalDeliveryForAcceptanceOfGoodsForStorage(ActionString, Template, LongDesc);
			
		EndIf;
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate  = DiscrepancyCertificate;
			LongDesc.ReflectionMethod   = DiscrepanciesPostingMethod;
			LongDesc.PossibleAction   = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome;
			
			If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
				// Correction of the document "Receipt of the storage goods" (Command Hyperlink).
				LongDesc.BasisOfAct = ActionString.Basis;
				LongDesc.CommandName    = "ApplyAppearance";
				PrintDocumentCorrectionReceiptOfGoodsFromCustodian(ActionString, Template, LongDesc);
			Else
				LongDesc.BasisOfAct = ActionString.Basis;
				LongDesc.CommandName    = "Change";
				WithdrawCorrectionReturnOfGoodsFromCustodian(ActionString, Template, LongDesc);
			EndIf;
			
		EndIf;
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			OutputDocumentTransferOfGoodsToCustodian(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined Then
			
			If ActionString.ByOrders Then
				
				LongDesc = StructuresForDescribingActionDisplayedInReport();
				LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
				LongDesc.BasisOfAct    = ActionString.Basis;
				LongDesc.CommandName       = "ApplyAppearance";
				LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
				LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
				
				OutputCorrectionRequestForReturnOfGoods(ActionString, Template, LongDesc, TypeOfBaseDocumentForNonConformanceCertificate);
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			WithdrawDocumentBeforeReturningItUponReceiptFromCustodian(ActionString, Template, LongDesc);
			
		EndIf;
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate  = DiscrepancyCertificate;
			LongDesc.PossibleAction   = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome;
			LongDesc.ReflectionMethod   = DiscrepanciesPostingMethod;
			
			If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
				// Correction of the document "Receipt of the storage goods" (Command Hyperlink).
				LongDesc.BasisOfAct = ActionString.Basis;
				LongDesc.CommandName    = "ApplyAppearance";
				PrintDocumentCorrectionReceiptOfGoodsFromCustodian(ActionString, Template, LongDesc);
			Else
				LongDesc.BasisOfAct = ActionString.Basis;
				LongDesc.CommandName    = "Change";
				WithdrawRefundFromCommissionAgent(ActionString, Template, LongDesc);
			EndIf;
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			LongDesc.CommandName       = "ApplyAppearance";
			PrintDocumentTransferOfGoodsToCommissionAgent(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined Then
			
			If ActionString.ByOrders Then
				
				LongDesc = StructuresForDescribingActionDisplayedInReport();
				LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
				LongDesc.BasisOfAct    = ActionString.Basis;
				LongDesc.CommandName       = "ApplyAppearance";
				LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
				LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
				
				WithdrawCorrectionRequestForRefundFromCommissionAgent(ActionString, Template, LongDesc);
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			WithdrawDocumentBeforeReturnOnReceiptFromCommissionAgent(ActionString, Template, LongDesc);
			
		EndIf;
		
	Else
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined
			Or ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			LongDesc.EDIStatus        = ActionString.EDIStatus;
			LongDesc.DocumentEDI      = ActionString.ElectronicDocument;
			
			PrintElectronicDocumentReturnOfGoodsFromClient(ActionString, Template, LongDesc);
			
			WithdrawAndReturnGoodsFromCustomer(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintImplementationDocumentForReturnFromClient(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_) <> Undefined Then
			
			If ActionString.ByOrders Then
				
				LongDesc = StructuresForDescribingActionDisplayedInReport();
				
				LongDesc.BasisOfAct    = ActionString.Basis;
				LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
				LongDesc.CommandName       = "ApplyAppearance";
				LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered;
				LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
				
				OutputCorrectionRequestForReturnOfGoods(ActionString, Template, LongDesc);
				
			EndIf;
			
		EndIf;
		
		If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices) <> Undefined Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentOfPreReturnOnReturnFromClient(ActionString, Template, LongDesc);
			
		EndIf;
		
	EndIf;
	
	If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses) <> Undefined
		And (Not SeparatePurchasingIsUsed 
			Or ThisIsDiscrepancyReport2_5_12) Then
		
		If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentWriteOffShortageOfGoods(ActionString, Template, LongDesc);
			
		EndIf;
		
		If ActionString.ThirdPartyIsGuilty
			And TableAccessRights.ReadingDebtCancellation Then
			
			LongDesc = StructuresForDescribingActionDisplayedInReport();
			
			LongDesc.BasisOfAct    = ActionString.Basis;
			LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
			LongDesc.CommandName       = "ApplyAppearance";
			LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses;
			LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
			
			PrintDocumentDebtCancellation(ActionString, Template, LongDesc, TableAccessRights);
			
		EndIf;
		
	EndIf;
	
	If ActionString.ActionsOptions.FindByValue(Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome) <> Undefined 
		And TableAccessRights.ReadingRecordingSurplusGoods
		And Not (TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
				And SeparatePurchasingIsUsed
				And Not ThisIsDiscrepancyReport2_5_12) Then
		
		LongDesc = StructuresForDescribingActionDisplayedInReport();
		
		LongDesc.BasisOfAct    = ActionString.Basis;
		LongDesc.DiscrepancyCertificate = DiscrepancyCertificate;
		LongDesc.CommandName       = "ApplyAppearance";
		LongDesc.PossibleAction  = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome;
		LongDesc.ReflectionMethod  = DiscrepanciesPostingMethod;
		
		PrintDocumentRegisteringSurpluses =
			TypeOfBaseDocumentForNonConformanceCertificate <> Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage;
		PrintDocumentRegisteringSurpluses =
			PrintDocumentRegisteringSurpluses
			And TypeOfBaseDocumentForNonConformanceCertificate <> Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider;
		If PrintDocumentRegisteringSurpluses Then
			PrintDocumentRegisteringSurpluses(ActionString, Template, LongDesc);
		Else
			GenerateDocumentsForRegisteringSurpluses(ActionString, Template, LongDesc);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputDocumentImplementationAdjustment(ActionString, BusinessOperation, Template, LongDesc)
	
	If NotOutputToReport("OutputDocumentImplementationAdjustment", ActionString.Basis, BusinessOperation) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("SaleOfGoodsAndServices", ActionString.Basis);
	TheStructureOfTheSearch.Insert("BusinessOperation",BusinessOperation);
	
	CompletedDocuments_4 = AdjustmentSales.FindRows(TheStructureOfTheSearch);
	
	If CompletedDocuments_4.Count() = 0 Then
		
		StructureToDesign = New Structure;
		StructureToDesign.Insert("SaleOfGoodsAndServices", Documents.SaleAdjustment.EmptyRef());
		StructureToDesign.Insert("BusinessOperation", BusinessOperation);
		
		ArrayOfCompletedDocuments.Add(StructureToDesign);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.Adjusting);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"SaleAdjustment",
		1,
		Template,
		ArrayOfCompletedDocuments,
		BusinessOperation,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputDocumentCreditNoteReturnToPath(ActionString, BusinessOperation, Template, LongDesc)
	
	If NotOutputToReport("OutputDocumentCreditNoteReturnToPath", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("SaleOfGoodsAndServices", ActionString.Basis);
	
	CompletedDocuments_4 = ImplementationsOfAdjustmentGetBackOnTrack.FindRows(TheStructureOfTheSearch);
	
	If CompletedDocuments_4.Count() = 0 Then
		
		StructureToDesign = New Structure;
		StructureToDesign.Insert("SaleOfGoodsAndServices", Documents.SaleAdjustment.EmptyRef());
		StructureToDesign.Insert("BusinessOperation", BusinessOperation);
		StructureToDesign.Insert("ThisIsReturnToPath", True);
		
		ArrayOfCompletedDocuments.Add(StructureToDesign);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.Adjusting);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"CreditNoteIsToGetBackOnTrack",
		2,
		Template,
		ArrayOfCompletedDocuments,
		BusinessOperation,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintElectronicDocumentPurchaseOfGoodsServices(ActionString, Template, LongDesc)
	
	If NotOutputToReport("CDisplayElectronicDocumentPurchaseOfGoodsServices", ActionString.Basis) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ActionString.ElectronicDocument) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(LongDesc.DocumentEDI);
	
	DocumentType = "";
	
	If LongDesc.EDIStatus = "EdoIsNotConfigured"
		Or LongDesc.EDIStatus = "NotInitiated"
		Or LongDesc.EDIStatus = "Error" Then
			
		Return;	
		
	Else
		
		If LongDesc.ReflectionMethod =	Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			
			DocumentType        = "ElectronicDocumentConfirmation";
			LongDesc.CommandName = "Confirm";
			
		Else
		
			DocumentType        = "ElectronicDocumentRejection";
			LongDesc.CommandName = "Reject";
		
		EndIf;
		
	EndIf;
	
	PrintDocumentForRegistration(
		DocumentType,
		1,
		Template,
		ArrayOfCompletedDocuments,,False,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintElectronicDocumentReturnOfGoodsFromClient(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintElectronicDocumentReturnOfGoodsFromClient", ActionString.Basis) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ActionString.ElectronicDocument) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(LongDesc.DocumentEDI);
	
	DocumentType = "";
	
	If LongDesc.EDIStatus = "EdoIsNotConfigured"
		Or LongDesc.EDIStatus = "NotInitiated"
		Or LongDesc.EDIStatus = "Error" Then
			
		Return;

	EndIf;
	
	DocumentType        = "ElectronicDocumentRejection";
	LongDesc.CommandName = "Reject";
	
	PrintDocumentForRegistration(
		DocumentType,
		1,
		Template,
		ArrayOfCompletedDocuments,,False,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintPurchaseAdjustmentDocument(ActionString, Template, LongDesc)

	If NotOutputToReport("PrintPurchaseAdjustmentDocument", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = ReceiptsAdjustingEntries.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.PurchaseAdjustment.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.Adjusting);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"PurchaseAdjustment",
		1,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);


EndProcedure

&AtServer
Procedure WithdrawFromSaleOfGoodsAndServices(ActionString, Template, LongDesc)
	
	If NotOutputToReport("WithdrawFromSaleOfGoodsAndServices", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("FixingImplementation", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);
	
EndProcedure

&AtServer
Procedure OutputCorrectionShipmentOfGoodsToCustomer(GoodsShipmentToCustomer,
														Template,
														LongDesc,
														UseDocumentCorrection = False)
	
	If NotOutputToReport("OutputCorrectionShipmentOfGoodsToCustomer", GoodsShipmentToCustomer) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	If UseDocumentCorrection Then 
		
		SearchParameters = New Structure;
		SearchParameters.Insert("Basis",   GoodsShipmentToCustomer);
		SearchParameters.Insert("Patch", True);
		CompletedDocuments_4 = ShipmentsForShipmentsOfItemsToCustomer.FindRows(SearchParameters);
		
		If CompletedDocuments_4.Count() = 0 Then 

			IssuedDocument = New Structure;
			IssuedDocument.Insert("CorrectedDocument", Documents.GoodsShipmentToCustomer.EmptyRef());
			IssuedDocument.Insert("Patch",          True);
			IssuedDocument.Insert("AdditionalDelivery",           False);
			
			ArrayOfCompletedDocuments.Add(IssuedDocument);
			
		Else
			
			For Each IssuedDocument In CompletedDocuments_4 Do 
				ArrayOfCompletedDocuments.Add(IssuedDocument.GoodsShipmentToCustomer);
			EndDo;
			
		EndIf;
		
		LongDesc.CommandName = "ApplyAppearance";
		
		PrintDocumentForRegistration(
			"CorrectionShipmentOfItemsToCustomer",
			1,
			Template,
			ArrayOfCompletedDocuments,
			,
			False,
			LongDesc);
		
	Else
		
		ArrayOfCompletedDocuments.Add(GoodsShipmentToCustomer);
		
		LongDesc.CommandName = "Change";
		
		PrintDocumentForRegistration(
			"ChangeShipmentOfItemsToCustomer",
			1,
			Template,
			ArrayOfCompletedDocuments,
			,
			False,
			LongDesc);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WithdrawRegistrationOfSurplusShippedItems(ActionString, Template, LongDesc)
	
	If NotOutputToReport("WithdrawRegistrationOfSurplusShippedItems", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Basis", ActionString.Basis);
	CompletedDocuments_4 = GroundsForRegisteringSurplusShippedItems.FindRows(SearchParameters);
	
	If CompletedDocuments_4.Count() = 0 Then 
	
		ArrayOfCompletedDocuments.Add(Documents.RecognitionOfStockSurplusShippedToCustomer.EmptyRef());
	
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do 
			ArrayOfCompletedDocuments.Add(IssuedDocument.RecordingAsReceived);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"RecognitionOfStockSurplusShippedToCustomer",
		2,
		Template,
		ArrayOfCompletedDocuments,
		,
		,
		LongDesc);
	
EndProcedure

&AtServer
Procedure WithdrawGoodsWriteOffShippedToCustomer(ActionString, Template, LongDesc)
	
	ReduceShipmentByReference =
		(LongDesc.PossibleAction =
			Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired
			And ActionString.ByOrders);
	
	If ReduceShipmentByReference Then
		CommandName = "GoodsWriteOffShippedToCustomerAndAdditionalDelivery";
	Else
		CommandName = "GoodsWriteOffShippedToCustomerWithoutAdditionalDelivery";
	EndIf;
	
	If NotOutputToReport(CommandName, ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Basis", ActionString.Basis);
	SearchParameters.Insert("ReduceShipmentByReference", ReduceShipmentByReference);
	CompletedDocuments_4 = GroundsForWriteOffOfItemsShippedToCustomer.FindRows(SearchParameters);
	
	If CompletedDocuments_4.Count() = 0 Then 
		
		IssuedDocument = New Structure;
		IssuedDocument.Insert("CreatedDocument", Documents.WriteOffOfShippedGoods.EmptyRef());
		IssuedDocument.Insert("ReduceShipmentByReference", ReduceShipmentByReference);
		
		ArrayOfCompletedDocuments.Add(IssuedDocument);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do 
			ArrayOfCompletedDocuments.Add(IssuedDocument.WriteOff);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		CommandName,
		2,
		Template,
		ArrayOfCompletedDocuments,
		,
		,
		LongDesc);
	
EndProcedure

&AtServer
Procedure ToDisplayCorrectionOfShipmentsOfItemsToClientDuringTransferOfOwnership(ActionString, Template, LongDesc)
	
	NotOutputToReport = NotOutputToReport(
		"ToDisplayCorrectionOfShipmentsOfItemsToClientDuringTransferOfOwnership",
		ActionString.Basis);
	
	If NotOutputToReport Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments =
		ShipmentOfItemsToClientUponTransferOfOwnership2_5.Unload().UnloadColumn("GoodsShipmentToCustomer");
	
	PrintDocumentForRegistration(
		"ChangeShipmentOfItemsToCustomer",
		2,
		Template,
		ArrayOfCompletedDocuments,
		,
		False,
		LongDesc);
	
EndProcedure

&AtServer
Procedure WithdrawShipmentOfItemsToCustomerForAdditionalDeliveryOfUndeliveredItems(ActionString, Template, LongDesc)

	If NotOutputToReport("WithdrawShipmentOfItemsToCustomerForAdditionalDeliveryOfUndeliveredItems",
		ActionString.Basis) Then
		
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Basis",  ActionString.Basis);
	SearchParameters.Insert("AdditionalDelivery", True);
	CompletedDocuments_4 = ShipmentsForShipmentsOfItemsToCustomer.FindRows(SearchParameters);
	
	If CompletedDocuments_4.Count() = 0 Then 

		IssuedDocument = New Structure;
		IssuedDocument.Insert("CorrectedDocument", Documents.GoodsShipmentToCustomer.EmptyRef());
		IssuedDocument.Insert("Patch",          False);
		IssuedDocument.Insert("AdditionalDelivery",           True);
		
		ArrayOfCompletedDocuments.Add(IssuedDocument);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do 
			ArrayOfCompletedDocuments.Add(IssuedDocument.GoodsShipmentToCustomer);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"AdditionalDeliveryShipmentOfItemsToCustomer",
		2,
		Template,
		ArrayOfCompletedDocuments,
		,
		,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputCorrectionPurchaseOfGoodsServices(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputCorrectionPurchaseOfGoodsServices", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("CorrectionOfReceipt", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);
	
EndProcedure

&AtServer
Procedure OutputGoodsReturnCorrectionToSupplier(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputGoodsReturnCorrectionToSupplier", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("CorrectionOfReturnOfGoodsToSupplier", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);
	
EndProcedure

&AtServer
Procedure WithdrawAndReturnGoodsFromCustomer(ActionString, Template, LongDesc)

	If NotOutputToReport("OutputCorrectionOfReturnOfGoodsFromClient", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	LongDesc.CommandName = "Change";
	PrintDocumentForRegistration("CorrectionOfReturnOfGoodsFromCustomer", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);

EndProcedure

&AtServer
Procedure OutputCorrectionOfGoodsMovement(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputCorrectionOfGoodsMovement", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("CorrectionOfMovementOfGoods", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);
	
EndProcedure

&AtServer
Procedure OutputAdjustmentOfGoodsMovement(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentMovingGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(Documents.InventoryTransfer.EmptyRef());
	
	SearchParameters = New Structure("Basis, Patch", ActionString.Basis, True);
	CompletedDocuments_4 = TransfersByTransfers.FindRows(SearchParameters);
	
	If CompletedDocuments_4.Count() = 0 Then
		
		DocumentProcessingParameters = New Structure();
		DocumentProcessingParameters.Insert("InventoryTransfer", Documents.InventoryTransfer.EmptyRef());
		DocumentProcessingParameters.Insert("ThisIsOvershooting", False);
		DocumentProcessingParameters.Insert("Patch", True);
		DocumentProcessingParameters.Insert("CorrectedDocument", ActionString.Basis);
		
		ArrayOfCompletedDocuments.Add(DocumentProcessingParameters);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.InventoryTransfer);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"AdjustingMovementOfGoods",
		1,
		Template,
		ArrayOfCompletedDocuments,,
		,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputReturnDocument(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputReturnDocument", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = SalesReturns.FindRows(New Structure("SaleOfGoodsAndServices", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(
			?(UseReturnRequests,
				Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef(),
				Documents.ReturnOfGoodsFromCustomer.EmptyRef()));
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.DocumentReturnPolicy);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"DocumentReturnPolicy",
		2,
		Template,
		ArrayOfCompletedDocuments,
		BusinessTransactionOfCertificate,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintDocumentReceiptOfGoodsFromClient(ActionString, Template, LongDesc)
	
	ReduceShipmentByReference =
		(LongDesc.PossibleAction =
			Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired
			And ActionString.ByOrders);
	
	If ReduceShipmentByReference Then
		CommandName = "ReceiptOfGoodsFromCustomerAndAdditionalDelivery";
	Else
		CommandName = "ReceiptOfGoodsFromCustomerWithoutAdditionalDelivery";
	EndIf;
	
	If NotOutputToReport(CommandName, ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Basis", ActionString.Basis);
	SearchParameters.Insert("ReduceShipmentByReference", ReduceShipmentByReference);
	CompletedDocuments_4 = GroundsForReceiptOfGoodsFromClient.FindRows(SearchParameters);
	
	If CompletedDocuments_4.Count() = 0 Then
		
		IssuedDocument = New Structure;
		IssuedDocument.Insert("CreatedDocument", Documents.GoodsReceiptFromCustomer.EmptyRef());
		IssuedDocument.Insert("ReduceShipmentByReference", ReduceShipmentByReference);
		
		ArrayOfCompletedDocuments.Add(IssuedDocument);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.GoodsReceiptFromCustomer);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		CommandName,
		2,
		Template,
		ArrayOfCompletedDocuments,
		,
		,
		LongDesc);

EndProcedure

&AtServer
Procedure PrintDocumentPurchaseOfGoodsServices(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentPurchaseOfGoodsServices", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = SubsequentDeliveryBySupplierReturns.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.VendorInvoice.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.VendorInvoice);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"VendorInvoice",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputReceiptDocumentToWarehouseForReposting(ActionString, Template, LongDesc, AfterAdjustment = False)
	
	CommandName = ?(AfterAdjustment, "ReceiptOfGoodsRepostingAfterAdjustment",
		"ReceiptOfGoodsRepostingAfterPurchase");
	
	If NotOutputToReport(CommandName, ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	If ReceiptsReceiptsToTheWarehouse.Count() <> 0 Then
		
		For Each IssuedDocument In ReceiptsReceiptsToTheWarehouse Do
			
			ArrayOfCompletedDocuments = New Array;
			ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredReceipt);
			
			PrintDocumentForRegistration(
				CommandName,
				2,
				Template,
				ArrayOfCompletedDocuments,,,
				LongDesc);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PrintDocumentOfAdditionalDeliveryUponReceiptToWarehouse(ActionString, Template, LongDesc)
	
	If NotOutputToReport("ReceiptOfGoodsAdditionalDeliveryUponReceipt", ActionString.Basis) Then
		Return;
	EndIf;
	
	Level = 1;
	AcquisitionFoundation = ActionString.Basis;
	
	If TypeOf(AcquisitionFoundation) = Type("DocumentRef.VendorInvoice") Then
		
		Attributes = Common.ObjectAttributesValues(AcquisitionFoundation,
			"ReceiptUnderOrders,GoodsReceiptOption");
		
		If (Not Attributes.ReceiptUnderOrders
			And Attributes.GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices)
			Or Attributes.GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly Then
			
			Level = 2;
			AcquisitionFoundation = Undefined;
			If ReceiptsReceipts.Count() > 0 Then
				SelectionByAdmission = New Structure;
				SelectionByAdmission.Insert("SubsequentDeliveryByReceipt", ActionString.Basis);
				DataOnAdmission = ReceiptsReceipts.FindRows(SelectionByAdmission);
				If DataOnAdmission.Count() = 1 Then
					AcquisitionFoundation = DataOnAdmission[0].RegisteredReceipt;
				EndIf;
			EndIf;
			LongDesc.BasisOfAct = AcquisitionFoundation;
		
		EndIf;
		
	EndIf;
	
	WarehouseSearchParametersToExpect = New Structure("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices);
	FoundRows = ActionString.ActionsWarehouses.FindRows(WarehouseSearchParametersToExpect);
	
	WarehouseSearchParametersToIssue = New Structure("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices);
	ArrangeFoundLines = ActionString.ActionsWarehouses.FindRows(WarehouseSearchParametersToIssue);
	
	CommonClientServer.SupplementArray(FoundRows,ArrangeFoundLines);
				
	ArrayOfReceiptWarehouses = New Array;
	For Each LineWithReceipt In FoundRows Do
	
		If ArrayOfReceiptWarehouses.Find(LineWithReceipt.Warehouse) = Undefined Then
			ArrayOfReceiptWarehouses.Add(LineWithReceipt.Warehouse);
		EndIf;
	
	EndDo;
	
	For Each WarehouseForReceipt In ArrayOfReceiptWarehouses Do
		
		LongDesc.Warehouse = WarehouseForReceipt;
		LongDesc.WithdrawWarehouse = (ArrayOfReceiptWarehouses.Count() > 1);
		
		If AcquisitionFoundation = Undefined Then
			LongDesc.CommandName = "ToExpectCompletionOfPurchase";
		EndIf;
		
		ArrayOfCompletedDocuments = New Array;
	
		CompletedDocuments_4 = ReceiptsReceiptsToTheWarehouse.FindRows(New Structure("SubsequentDeliveryByReceipt, Warehouse",
																						True,
																						WarehouseForReceipt));
		
		If CompletedDocuments_4.Count() = 0 Then
			
			ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Warehouse",
																Documents.ReceiptOfGoodsToWarehouse.EmptyRef(),
																WarehouseForReceipt));
			
		 Else
			
			For Each IssuedDocument In CompletedDocuments_4 Do
				
				ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredReceipt);
				
			EndDo;
			
		EndIf;
		
		PrintDocumentForRegistration(
			"ReceiptOfGoodsAdditionalDeliveryUponReceipt",
			Level,
			Template,
			ArrayOfCompletedDocuments,,,
			LongDesc);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PrintDocumentOfAdditionalDeliveryUponReceipt(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentOfAdditionalDeliveryUponReceipt", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = ReceiptsReceipts.FindRows(New Structure("SubsequentDeliveryByReceipt", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.VendorInvoice.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredReceipt);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"PurchaseOfGoodsServicesAdditionalDeliveryUponReceipt",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintDocumentMovingGoods(ActionString, Template, LongDesc, RefundRequest = False, UseDocumentCorrection = False)
	
	If NotOutputToReport("PrintDocumentMovingGoods", ActionString.Basis, RefundRequest) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	If Not RefundRequest Then
		SearchParameters = New Structure("Basis, Patch", ActionString.Basis, False);
		CompletedDocuments_4 = TransfersByTransfers.FindRows(SearchParameters);
		
		If UseDocumentCorrection Then
			SearchParameters = New Structure("Basis", ActionString.Basis);
			FoundRows = TransfersByTransfers.FindRows(SearchParameters);
			If FoundRows.Count() > 0 Then
				// When using the correction functionality, a corrective displacement document has been entered.
				// I.e. it is required to enter the pre-displacement according to the current, last in the chain displacement document.
				FoundRow = FoundRows[0];
				LongDesc.BasisOfAct = FoundRow.InventoryTransfer;
			Else
				Return; // Until an adjustment is made, it is unnecessary to display the move entry point.
			EndIf;
		EndIf;
		
	Else
		SearchParameters = New Structure("Basis", ActionString.Basis);
		CompletedDocuments_4 = TransfersByReturnTransfers.FindRows(SearchParameters);
	EndIf;
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(New Structure("InventoryTransfer, ThisIsOvershooting", Documents.InventoryTransfer.EmptyRef(), RefundRequest));
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.InventoryTransfer);
			
		EndDo;
		
	EndIf;
	
	If RefundRequest Then
		PrintDocumentForRegistration(
			"MovementOfGoodsReturn",
			2,
			Template,
			ArrayOfCompletedDocuments,,,
			LongDesc);
	Else
		PrintDocumentForRegistration(
			"InventoryTransfer",
			2,
			Template,
			ArrayOfCompletedDocuments,,,
			LongDesc);
	EndIf;
	
EndProcedure

&AtServer
Procedure PrintSalesDocumentForAdditionalDeliveryOfUndeliveredGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintSalesDocumentForAdditionalDeliveryOfUndeliveredGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = SubsequentDeliveries.FindRows(New Structure("SubsequentDeliveryBySale", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.CustomerInvoice.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredSales);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"SalesOfGoodsAndServices",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintImplementationDocumentForReturnFromClient(ActionString, Template, LongDesc);

	If NotOutputToReport("PrintImplementationDocumentForReturnFromClient", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = ReturnsFromCustomersSales.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.CustomerInvoice.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.SaleOfGoodsAndServices);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"RealizationOfGoodsAndServicesOnReturnFromClient",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);

EndProcedure

&AtServer
Procedure OutputCorrectionRequestForReturnOfGoods(ActionString, Template, LongDesc, TypeOfBasisOfAct = Undefined)

	If NotOutputToReport("OutputCorrectionRequestForReturnOfGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.OrderDocument);
	
	DocumentKind = "CorrectionRequestForReturnOfGoods";
	If TypeOfBasisOfAct <> Undefined Then
		If DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBasisOfAct) Then
			DocumentKind = "CorrectionRequestForReturnOfTransferGoods";
		EndIf;
	EndIf;
	
	PrintDocumentForRegistration(DocumentKind, 2, Template, ArrayOfCompletedDocuments, , False, LongDesc);

EndProcedure

&AtServer
Procedure WithdrawCorrectionRequestForRefundFromCommissionAgent(ActionString, Template, LongDesc)

	If NotOutputToReport("OutputCorrectionRequestForReturnOfGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.OrderDocument);
	
	PrintDocumentForRegistration("CorrectionRequestForRefundFromCommissionAgent", 2, Template, ArrayOfCompletedDocuments, , False, LongDesc);

EndProcedure

&AtServer
Procedure PrintDocumentOfPreReturnOnReturnFromClient(ActionString, Template, LongDesc)

	If NotOutputToReport("PrintDocumentOfPreReturnOnReturnFromClient", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = ReturnsFromCustomersReturns.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.ReturnOfGoodsFromCustomer.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.Return);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"ReturnOfGoodsFromClientPreReturn",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);


EndProcedure

&AtServer
Procedure PrintChangeInDocumentReceiptOfGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("DisplayChangeReceiptOfGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	RowFilter = New Structure();
	RowFilter.Insert("SubsequentDeliveryByReceipt", False);
	RowFilter.Insert("Basis", ActionString.Basis);
	
	CompletedDocuments_4 = ReceiptsReceiptsToTheWarehouse.FindRows(RowFilter);
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.ReceiptOfGoodsToWarehouse.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			If ValueIsFilled(IssuedDocument.RegisteredReceipt) Then
				ArrayOfCompletedDocuments = New Array;
				ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredReceipt);
				
				LongDesc.BasisOfAct = IssuedDocument.RegisteredReceipt;
				
				PrintDocumentForRegistration("ChangeInReceiptOfGoods", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputAdjustmentToReceiptOfGoodsDocument(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputAdjustmentForReceiptOfGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(Documents.ReceiptOfGoodsToWarehouse.EmptyRef());
	
	RowFilter = New Structure();
	RowFilter.Insert("SubsequentDeliveryByReceipt", False);
	RowFilter.Insert("Basis", ActionString.Basis);
	RowFilter.Insert("Patch", True);
	
	IssuedCorrections = ReceiptsReceiptsToTheWarehouse.FindRows(RowFilter);
	
	RowFilter = New Structure();
	RowFilter.Insert("SubsequentDeliveryByReceipt", False);
	RowFilter.Insert("Basis", ActionString.Basis);
	RowFilter.Insert("Patch", False);
	
	ArrayOfOriginalDocuments = New Array;
	IssuedInitialReceipts = ReceiptsReceiptsToTheWarehouse.FindRows(RowFilter);
	For Each OriginalDocument In IssuedInitialReceipts Do
		ArrayOfOriginalDocuments.Add(OriginalDocument.RegisteredReceipt);
	EndDo;
	
	If IssuedCorrections.Count() = 0
		And ArrayOfOriginalDocuments.Count() > 0 Then
		
		DocumentProcessingParameters = New Structure();
		DocumentProcessingParameters.Insert("ReceiptOfGoodsToWarehouse", Documents.ReceiptOfGoodsToWarehouse.EmptyRef());
		DocumentProcessingParameters.Insert("Patch", True);
		DocumentProcessingParameters.Insert("CorrectedDocument", ArrayOfOriginalDocuments[0]);
		
		ArrayOfCompletedDocuments.Add(DocumentProcessingParameters);
		
	Else
		
		For Each IssuedDocument In IssuedCorrections Do
			
			If ValueIsFilled(IssuedDocument.RegisteredReceipt) Then
				ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredReceipt);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"AdjustmentOfGoodsReceipts",
		1,
		Template,
		ArrayOfOriginalDocuments,,True,
		Undefined);
	
	PrintDocumentForRegistration(
		"AdjustmentOfReceiptOfGoodsCorrections",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure DisplayWriteOffOfDiscrepanciesReceiptPurchaseOfItems(ActionString, Template, LongDesc)
	
	If NotOutputToReport("DisplayWriteOffOfDiscrepanciesReceiptPurchase", ActionString.Basis) Then
		Return;
	EndIf;
	
	FoundRowsWarehousesOrders = New Array;
	
	For Each LineWithReceipt In ActionString.ActionsWarehouses Do
		HasString = False;
		For Each FoundRow In FoundRowsWarehousesOrders Do
			If FoundRow.Warehouse = LineWithReceipt.Warehouse Then 
				HasString = True;
				Break;
			EndIf;
		EndDo;
		If Not HasString Then 
			FoundRowsWarehousesOrders.Add(LineWithReceipt);
		EndIf;
	EndDo;
	
	If FoundRowsWarehousesOrders.Count() = 0 Then 
		Return;
	EndIf;

	For Each LineWarehousesOrders In FoundRowsWarehousesOrders Do
		
		ArrayOfCompletedDocuments = New Array;
		
		ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Warehouse, OrderDocument",
															Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.EmptyRef(),
															LineWarehousesOrders.Warehouse,
															LineWarehousesOrders.OrderDocument));
		
		RowFilter = New Structure();
		RowFilter.Insert("Purchase", ActionString.Basis);
		RowFilter.Insert("Warehouse", LineWarehousesOrders.Warehouse);
		
		LongDesc.OrderDocument = LineWarehousesOrders.OrderDocument;
		LongDesc.WithdrawWarehouse = FoundRowsWarehousesOrders.Count() > 1;
		LongDesc.Warehouse = LineWarehousesOrders.Warehouse;
		
		CompletedWriteOff = WriteOffOfDiscrepanciesReceiptPurchase.FindRows(RowFilter);
		
		For Each IssuedDocument In CompletedWriteOff Do
			If ValueIsFilled(IssuedDocument.WriteOff) Then
				ArrayOfCompletedDocuments.Add(IssuedDocument.WriteOff);
			EndIf;
 			
 		EndDo;
 		
		PrintDocumentForRegistration(
			"WriteOffDiscrepanciesBetweenReceiptAndPurchase",
			1,
			Template,
			ArrayOfCompletedDocuments,,,
			LongDesc);
	EndDo;
	
EndProcedure

&AtServer
Procedure ShowClaim(ActionString, Template, LongDesc)
	
	If NotOutputToReport("ShowClaim", ActionString.Basis) Then
		Return;
	EndIf;
	
	FoundRowsWarehousesOrders = New Array;
	
	ArrayOfDepotsForDebiting  = New Array;
	If ActionString.ActionsWarehouses.Count() > 0 Then   
		FoundRowsWarehousesOrders.Add(ActionString.ActionsWarehouses[0]);
	Else
		Return;
	EndIf;

	For Each LineWarehousesOrders In FoundRowsWarehousesOrders Do
		
		ArrayOfCompletedDocuments = New Array;
		
		ClaimParameters = New Structure;
		ClaimParameters.Insert("CreatedDocument", Catalogs.Complaints.EmptyRef());
		ClaimParameters.Insert("Warehouse", LineWarehousesOrders.Warehouse);
		ClaimParameters.Insert("OrderDocument", LineWarehousesOrders.OrderDocument);
		ClaimParameters.Insert("AmountOfShortDelivery", LongDesc.AmountOfShortDelivery);

		ArrayOfCompletedDocuments.Add(ClaimParameters);
		
		RowFilter = New Structure();
		RowFilter.Insert("Basis", ActionString.Basis);
		
		CompletedClaims = Complaints.FindRows(RowFilter);
		
		For Each DecoratedElement In CompletedClaims Do
			
			If ValueIsFilled(DecoratedElement.Claim) Then
				ArrayOfCompletedDocuments.Add(DecoratedElement.Claim);
			EndIf;
			
		EndDo;
		
		PrintDocumentForRegistration(
			"Claim",
			1,
			Template,
			ArrayOfCompletedDocuments,,False,
			LongDesc);
	EndDo;
	
EndProcedure

&AtServer
Procedure OutputDebtAdjustment(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputDebtAdjustment", ActionString.Basis) Then
		Return;
	EndIf;
	
	FoundRowsWarehousesOrders = New Array;

	ArrayOfDepotsForDebiting  = New Array;
	If ActionString.ActionsWarehouses.Count() > 0 Then   
		FoundRowsWarehousesOrders.Add(ActionString.ActionsWarehouses[0]);
	Else
		Return;
	EndIf;

	For Each LineWarehousesOrders In FoundRowsWarehousesOrders Do
		
		ArrayOfCompletedDocuments = New Array;
		
		ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Basis, Claim",
															Documents.ARAPAdjustment.EmptyRef(),
															LineWarehousesOrders.Warehouse,
															LineWarehousesOrders.OrderDocument));
		
		RowFilter = New Structure();
		RowFilter.Insert("Purchase", ActionString.Basis);
		
		
		CompletedAdjustments = DebtAdjustments.FindRows(RowFilter);
		
		For Each IssuedDocument In CompletedAdjustments Do
			
			If ValueIsFilled(IssuedDocument.Adjusting) Then
				ArrayOfCompletedDocuments.Add(IssuedDocument.Adjusting);
			EndIf;
			
		EndDo;
		
		PrintDocumentForRegistration(
			"ARAPAdjustment",
			1,
			Template,
			ArrayOfCompletedDocuments,,True,
			LongDesc);
	EndDo;
	
EndProcedure

&AtServer
Procedure WithdrawDocumentBeforeReturningItUponReceiptFromCustodian(ActionString, Template, LongDesc)

	If NotOutputToReport("WithdrawDocumentBeforeReturningItUponReceiptFromCustodian", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = ReturnsFromCustodiansReceipts.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.Inpayment);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration(
		"ReturnOfGoodsFromKeeperPreReturn",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);

EndProcedure

&AtServer
Procedure WithdrawDocumentBeforeReturnOnReceiptFromCommissionAgent(ActionString, Template, LongDesc)

	If NotOutputToReport("WithdrawDocumentBeforeReturnOnReceiptFromCommissionAgent", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = ReturnsFromCustodiansReceipts.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.Inpayment);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration(
		"ReturnOfGoodsFromCommissionAgentDovozvrat",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);

EndProcedure

&AtServer
Procedure PrintReturnOfGoodsToSupplierDocumentToReturnUndeliveredGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintReturnOfGoodsToSupplierDocumentToReturnUndeliveredGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = ReturnsByReturnsToSupplier.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(Documents.ReturnOfGoodsToVendor.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.ReturnOfGoodsToVendor);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"ReturnOfGoodsToVendor",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintCorrectionOfOrderDocument(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintCorrectionOfOrderDocument", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	If TypeOf(ActionString.Basis) = Type("DocumentRef.GoodsShipmentToCustomer") Then

		CompletedDocuments_4 = ShipmentsOfItemsToCustomerOrders.FindRows(
			New Structure("GoodsShipmentToCustomer", ActionString.Basis));
			
	Else
		CompletedDocuments_4 = ImplementationsOrders.FindRows(New Structure("SaleOfGoodsAndServices", ActionString.Basis));
	EndIf;
	
	If CompletedDocuments_4.Count() = 0 Then
		
		Return;
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.SalesOrder);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"SalesOrder",
		2,
		Template,
		ArrayOfCompletedDocuments,,False,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputCorrectionToOrderToSupplierDocument(ActionString, Template, LongDesc)

	If NotOutputToReport("PrintCorrectionOfOrderDocument", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = ReceiptsOrders.FindRows(New Structure("DocumentInflow", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		Return;
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.PurchaseOrder);
			
		EndDo;
		
	EndIf;
	If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		DocumentKind = "MaterialProviderOrder2_5";
	Else
		DocumentKind = "PurchaseOrder";
	EndIf;
	PrintDocumentForRegistration(DocumentKind, 2, Template, ArrayOfCompletedDocuments,, False, LongDesc);

EndProcedure

&AtServer
Procedure PrintMoveOrderDocument(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintMoveOrderDocument", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	FoundRows = GoodsTransferTransferOrders.FindRows(New Structure("InventoryTransfer", ActionString.Basis));
	For Each FoundRow In FoundRows Do
		ArrayOfCompletedDocuments.Add(FoundRow.TransferOrder);
	EndDo;
	
	PrintDocumentForRegistration(
		"TransferOrder",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintDocumentWriteOffShortageOfGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentWriteOffShortageOfGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	BusinessOperation = ?(TypeOf(ActionString.Basis) = Type("DocumentRef.GoodsReceiptForStorage"),
					Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale,
					Undefined);
	
	WarehouseSearchParameters = New Structure("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses);
	FoundRows = ActionString.ActionsWarehouses.FindRows(WarehouseSearchParameters);
	ArrayOfDepotsForDebiting = New Array;
	For Each DebitedLine In FoundRows Do
	
		If ArrayOfDepotsForDebiting.Find(DebitedLine.Warehouse) = Undefined Then
			ArrayOfDepotsForDebiting.Add(DebitedLine.Warehouse);
		EndIf;
	
	EndDo;
	
	For Each WriteOffWarehouse In ArrayOfDepotsForDebiting Do
		
		LongDesc.Warehouse = WriteOffWarehouse;
		LongDesc.WithdrawWarehouse = (ArrayOfDepotsForDebiting.Count() > 1);
		
		ArrayOfCompletedDocuments = New Array;
	
		CompletedDocuments_4 = GroundsForWritingOffShortfalls.FindRows(New Structure("Basis, Warehouse",
		                                                                               ActionString.Basis,
		                                                                               WriteOffWarehouse));
		
		If CompletedDocuments_4.Count() = 0 Then
			
			ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Warehouse",
			                                                     Documents.WriteOffOfGoodsShortages.EmptyRef(),
			                                                     WriteOffWarehouse));
			
		 Else
			
			For Each IssuedDocument In CompletedDocuments_4 Do
				
				ArrayOfCompletedDocuments.Add(IssuedDocument.WriteOff);
				
			EndDo;
			
		EndIf;
		
		PrintDocumentForRegistration(
			"WriteOffOfGoodsShortages",
			1,
			Template,
			ArrayOfCompletedDocuments,
			BusinessOperation,,
			LongDesc);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentStockShortageRecognitionSaleOfGoodsAndServices", ActionString.Basis) Then
		Return;
	EndIf;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("VariantOfActionWithGoods", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off);
	
	FoundRows = ActionString.ActionsWarehouses.FindRows(SearchParameters);
	ArrayOfDepotsForDebiting  = New Array;
	For Each DebitedLine In FoundRows Do
	
		If ValueIsFilled(DebitedLine.Warehouse)
			And ArrayOfDepotsForDebiting.Find(DebitedLine.Warehouse) = Undefined Then
			ArrayOfDepotsForDebiting.Add(DebitedLine.Warehouse);
		EndIf;
	
	EndDo;
	
	For Each WriteOffWarehouse In ArrayOfDepotsForDebiting Do
		
		ArrayOfCompletedDocuments = New Array;
		
		SearchParameters = New Structure;
		SearchParameters.Insert("Basis", ActionString.Basis);
		SearchParameters.Insert("Warehouse",     WriteOffWarehouse);
		
		CompletedDocuments_4 = GroundsForWriteOffOfShortagesOnShipmentDocuments.FindRows(SearchParameters);
		
		If CompletedDocuments_4.Count() = 0 Then
			
			Structure = New Structure;
			Structure.Insert("CreatedDocument", Documents.WriteOffOfGoodsShortages.EmptyRef());
			Structure.Insert("Warehouse",               WriteOffWarehouse);
			
			ArrayOfCompletedDocuments.Add(Structure);
			
		Else
			
			For Each IssuedDocument In CompletedDocuments_4 Do
				ArrayOfCompletedDocuments.Add(IssuedDocument.WriteOff);
			EndDo;
			
		EndIf;
		
		PrintDocumentForRegistration(
			"WriteOffOfGoodsShortages",
			2,
			Template,
			ArrayOfCompletedDocuments,
			,
			,
			LongDesc);
			
	EndDo;
	
EndProcedure

&AtServer
Procedure PrintDocumentWritingOffShortagesOfGoodsMovingGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentWritingOffShortagesOfGoodsMovingGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = BasesForWritingOffShortagesInGoodsMovement.FindRows(New Structure("Basis",
	                                                                               ActionString.Basis));
	
	DestinationWarehouse = Common.ObjectAttributeValue(ActionString.Basis, "DestinationWarehouse");
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Warehouse",
		                                                     Documents.WriteOffOfGoodsShortages.EmptyRef(),
		                                                     DestinationWarehouse));
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.WriteOff);
			
		EndDo;
		
	EndIf;
	
	LongDesc.Warehouse = DestinationWarehouse;
	
	PrintDocumentForRegistration(
		"WriteOffOfGoodsShortages",
		1,
		Template,
		ArrayOfCompletedDocuments,
		,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintDocumentDebtCancellation(ActionString, Template, LongDesc, TableAccessRights)
	
	If NotOutputToReport("PrintDocumentDebtCancellation", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = BaseDocumentsForDebtRelief.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		If Not TableAccessRights.AddingDebtCancellation Then
			Return;
		EndIf;
		
		ArrayOfCompletedDocuments.Add(Documents.ARAPAdjustment.EmptyRef());
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.WriteOff);
			
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"ARAPAdjustment",
		1,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintDocumentRegisteringSurpluses(ActionString, Template, LongDesc)

	If NotOutputToReport("PrintDocumentRegisteringSurpluses", ActionString.Basis) Then
		Return;
	EndIf;
	
	WarehouseSearchParameters = New Structure("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome);
	FoundRows        = ActionString.ActionsWarehouses.FindRows(WarehouseSearchParameters);
	ArrayOfDepotsForDebiting  = New Array;
	For Each DebitedLine In FoundRows Do
	
		If ArrayOfDepotsForDebiting.Find(DebitedLine.Warehouse) = Undefined Then
			ArrayOfDepotsForDebiting.Add(DebitedLine.Warehouse);
		EndIf;
	
	EndDo;
	
	For Each WriteOffWarehouse In ArrayOfDepotsForDebiting Do
		
		LongDesc.Warehouse = WriteOffWarehouse;
		LongDesc.WithdrawWarehouse = (ArrayOfDepotsForDebiting.Count() > 1);
		
		ArrayOfCompletedDocuments = New Array;
	
		CompletedDocuments_4 = TheBasisOfRegistration.FindRows(New Structure("Basis, Warehouse",
		                                                                               ActionString.Basis,
		                                                                               WriteOffWarehouse));
		
		If CompletedDocuments_4.Count() = 0 Then
			
			ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Warehouse",
			                                                     Documents.InventorySurplusRecognition.EmptyRef(),
			                                                     WriteOffWarehouse));
			
		 Else
			
			For Each IssuedDocument In CompletedDocuments_4 Do
				
				ArrayOfCompletedDocuments.Add(IssuedDocument.RecordingAsReceived);
				
			EndDo;
			
		EndIf;
		
		 PrintDocumentForRegistration("InventorySurplusRecognition",
		                            1,
		                            Template,
		                            ArrayOfCompletedDocuments,,,
		                            LongDesc);
		
	EndDo;
	
	ArrayOfCompletedDocuments = New Array;
	
EndProcedure

&AtServer
Procedure PrintDocumentRegistrationOfSurplusMovementOfGoods(ActionString, Template, LongDesc)

	If NotOutputToReport("PrintDocumentRegistrationOfSurplusMovementOfGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;

	CompletedDocuments_4 = BasesForGoodsMovementRecordingAsReceived.FindRows(New Structure("Basis",
	                                                                               ActionString.Basis));
	
	DestinationWarehouse = Common.ObjectAttributeValue(ActionString.Basis, "DestinationWarehouse");
	If CompletedDocuments_4.Count() = 0 Then
		
		ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Warehouse",
		                                                     Documents.InventorySurplusRecognition.EmptyRef(),
		                                                     DestinationWarehouse));
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			
			ArrayOfCompletedDocuments.Add(IssuedDocument.RecordingAsReceived);
			
		EndDo;
		
	EndIf;
	
	LongDesc.Warehouse = DestinationWarehouse;
	PrintDocumentForRegistration("InventorySurplusRecognition",
		1,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintReturnOfGoodsToSupplierDocument(ActionString, Template, LongDesc)

	If NotOutputToReport("PrintReturnOfGoodsToSupplierDocument", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	WarehouseSearchParameters = New Structure("PossibleAction", Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered);
	FoundRows = ActionString.ActionsWarehouses.FindRows(WarehouseSearchParameters);
	ArrayOfReturnWarehouses = New Array;
	For Each ReturnString_ In FoundRows Do
		
		If ArrayOfReturnWarehouses.Find(ReturnString_.Warehouse) = Undefined Then
			ArrayOfReturnWarehouses.Add(ReturnString_.Warehouse);
		EndIf;
		
	EndDo;
	
	For Each ReturnWarehouse In ArrayOfReturnWarehouses Do
		
		LongDesc.Warehouse = ReturnWarehouse;
		LongDesc.WithdrawWarehouse = (ArrayOfReturnWarehouses.Count() > 1);
		
		ArrayOfCompletedDocuments = New Array;
	
		CompletedDocuments_4 = ReceiptsReturns.FindRows(New Structure("DocumentInflow, Warehouse",
		                                                                       ActionString.Basis,
		                                                                       ReturnWarehouse));
		
		If CompletedDocuments_4.Count() = 0 Then
			
			ArrayOfCompletedDocuments.Add(New Structure("CreatedDocument, Warehouse",
			                                                     Documents.ReturnOfGoodsToVendor.EmptyRef(),
			                                                     ReturnWarehouse));
			
		 Else
			
			For Each IssuedDocument In CompletedDocuments_4 Do
				
				ArrayOfCompletedDocuments.Add(IssuedDocument.ReturnToVendor);
				
			EndDo;
			
		EndIf;
		
		PrintDocumentForRegistration(
		"ReturnOfGoodsToSupplierUponReceipt",
		2,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
		
	EndDo;

EndProcedure

&AtServer
Procedure OutputError(MessageText, Template)
	
	ErrorArea = Template.GetArea("StringError");
	ErrorArea.Parameters.ErrorText = MessageText;
	SpreadsheetDocument.Put(ErrorArea);
	
	HasError = True;
	
EndProcedure

&AtServer
Procedure PrintDocumentForRegistration(DocumentKind, Level, Template,
	                                 ArrayOfCompletedDocuments,
	                                 BusinessOperation = Undefined,
	                                 DisplayProcessedDocumentsHeader = True,
	                                 LongDesc = Undefined)
	
	EmptyStringArea       = Template.GetArea("IsBlankString");
	AreaIsThinBlankLine = Template.GetArea("ThinEmptyLine");
	DocumentHeaderArea_     = Template.GetArea("LevelHeader"   + String(Level));
	ScopeOfDocument   = Template.GetArea("LegendLevel" + String(Level));
	DocumentLineArea    = Template.GetArea("LineLevel"  + String(Level));
	
	BoldTahoma9                 = New Font("Tahoma", 9, True, False,   True);
	RegularTahoma9Font                = New Font("Tahoma", 9, False,   False,   True);
	BoldTahoma8                 = New Font("Tahoma", 8, False,   True, False);
	
	SpreadsheetDocument.Put(EmptyStringArea);
	DocumentHeaderArea_.Parameters.Text = HeaderText(DocumentKind, LongDesc, BusinessOperation);
	SpreadsheetDocument.Put(DocumentHeaderArea_);
	
	If DisplayLegend Then
		SpreadsheetDocument.Put(AreaIsThinBlankLine);
		ScopeOfDocument.Parameters.Text = LegendText(DocumentKind, BusinessOperation);
		SpreadsheetDocument.Put(ScopeOfDocument);
		SpreadsheetDocument.Put(AreaIsThinBlankLine);
	EndIf;
	
	//Rows
	
	IssuedDocumentsAreDisplayed = False;
	
	For Each ArrayElement In ArrayOfCompletedDocuments Do
		
		If TypeOf(ArrayElement) <> Type("Structure") And ValueIsFilled(ArrayElement) Then
			
			If Not IssuedDocumentsAreDisplayed And DisplayProcessedDocumentsHeader Then
				DocumentLineArea.Parameters.Text = String(NStr("vi = 'Chứng từ đã lập:';
																|ru = 'Оформленные документы:';
																|en = 'Created documents:'; fa = 'Created documents:';
																|it = 'Documenti formalizzati:';
																|pl = 'Sporządzone dokumenty:';
																|tr = 'Düzenlenmiş belgeler:'"));
				DocumentLineArea.Areas["LineLevel" + String(Level)].TextColor = New Color(0, 0, 0);
				DocumentLineArea.Areas["LineLevel" + String(Level)].Font = BoldTahoma8;
				SpreadsheetDocument.Put(DocumentLineArea);
				SpreadsheetDocument.Put(AreaIsThinBlankLine);
			EndIf;
			
			DocumentLineArea.Parameters.Text = String(ArrayElement);
			DocumentLineArea.Areas["LineLevel" + String(Level)].TextColor = New Color(0, 0, 0);
			DocumentLineArea.Areas["LineLevel" + String(Level)].Font = RegularTahoma9Font;
			
			IssuedDocumentsAreDisplayed = True;
			
			DocumentLineArea.Parameters.Data = ArrayElement;
			SpreadsheetDocument.Put(DocumentLineArea);
			
		EndIf;
		
	EndDo;
	
	If LongDesc <> Undefined Then
		
		UseHyperlink = False;
		LabelColor = StyleColors.HyperlinkColor;
		If LongDesc.CommandName = "Change" Then
			
			Result = DiscrepanciesServer.DocumentDoesNotCorrespondToAct(LongDesc.DiscrepancyCertificate, LongDesc.BasisOfAct);
			If Result.DocumentState = "ChangesRequired" Then
				LabelColor = StyleColors.HyperlinkColor;
				HyperlinkText = NStr("vi = 'Thay đổi';
									|ru = 'Изменить';
									|en = 'Change'; fa = 'تغییر';
									|it = 'Modificare';
									|pl = 'Zmień';
									|tr = 'Değiştir'");
				UseHyperlink = True;
			ElsIf Result.DocumentState = "NoModificationsAreRequired" Then
				LabelColor = StyleColors.InaccessibleCellTextColor;
				HyperlinkText = NStr("vi = 'Không cần thay đổi';
									|ru = 'Изменения не требуются';
									|en = 'No modifications are required'; fa = 'No modifications are required';
									|it = 'Nessuna modifica richiesta';
									|pl = 'Zmiany nie są wymagane';
									|tr = 'Değişiklik gerekmiyor'");
			ElsIf Result.DocumentState = "ChangesAreMade" Then
				LabelColor = StyleColors.SuccessResultColor;
				HyperlinkText = NStr("vi = 'Thay đổi được thực hiện';
									|ru = 'Изменения выполнены';
									|en = 'Changes are made'; fa = 'Changes are made';
									|it = 'Modifiche eseguite';
									|pl = 'Zmiany zostały wykonane';
									|tr = 'Değişiklikler yapıldı'");
			ElsIf Result.DocumentState = "BaseDocumentDoesNotMatchTheCertificate" Then
				LabelColor = StyleColors.ErrorNoteText;
				HyperlinkText = NStr("vi = 'Cơ sở không tuân thủ giao dịch';
									|ru = 'Основание не соответствует акту';
									|en = 'Base document does not match the certificate'; fa = 'Base document does not match the certificate';
									|it = 'La causale non è conforme all''atto';
									|pl = 'Podstawa nie pokrywa się z aktem';
									|tr = 'Taban tutanakla uyuşmuyor'");
			EndIf;
			
		ElsIf LongDesc.CommandName = "ApplyAppearance" Then
			
			LabelColor = StyleColors.HyperlinkColor;
			HyperlinkText = NStr("vi = 'Tạo';
								|ru = 'Оформить';
								|en = 'Register'; fa = 'ثبات';
								|it = 'Preparare';
								|pl = 'Sporządź';
								|tr = 'Biçimlendir'");
			UseHyperlink = True;
			
		ElsIf LongDesc.CommandName = "Create" Then
			
			LabelColor = StyleColors.HyperlinkColor;
			HyperlinkText = NStr("vi = 'Tạo mới';
								|ru = 'Создать';
								|en = 'Create'; fa = 'ایجاد';
								|it = 'Создать';
								|pl = 'Create';
								|tr = 'Oluştur'");
			UseHyperlink = True;

		ElsIf LongDesc.CommandName = "Confirm" Then	
			
			If LongDesc.EDIStatus = "Received" Then
				
				If ThereIsARightToExchangeEDI Then
				
					LabelColor = StyleColors.HyperlinkColor;
					HyperlinkText = NStr("vi = 'Xác nhận';
										|ru = 'Подтвердить';
										|en = 'Confirm'; fa = 'تأیید';
										|it = 'Confermare';
										|pl = 'Potwierdź';
										|tr = 'Onayla'");
					UseHyperlink = True;
				
				Else
					
					LabelColor = StyleColors.InaccessibleCellTextColor;
					HyperlinkText = NStr("vi = 'Bạn không thể xác nhận chứng từ điện tử.';
										|ru = 'Вам недоступно подтверждение электронного документа.';
										|en = 'You cannot confirm an electronic document.'; fa = 'You cannot confirm an electronic document.';
										|it = 'Non vi è consentito l''accesso alla conferma del documento elettronico.';
										|pl = 'Nie możesz potwierdzić dokumentu elektronicznego.';
										|tr = 'Elektronik belgeyi onaylayamazsınız.'");
					
				EndIf;
				
			ElsIf LongDesc.EDIStatus = "ApprovalInProcessing" Then
				
				LabelColor = StyleColors.InaccessibleCellTextColor;
				HyperlinkText = NStr("vi = 'Lời cảm ơn bắt đầu.';
									|ru = 'Подтверждение инициировано.';
									|en = 'Confirmation initiated.'; fa = 'Confirmation initiated.';
									|it = 'Conferma avviata.';
									|pl = 'Zainicjowano potwierdzenie.';
									|tr = 'Onaylama işlemi başlatıldı.'");
				
			ElsIf LongDesc.EDIStatus = "Upholded" Then
				
				LabelColor = StyleColors.SuccessResultColor;
				HyperlinkText = NStr("vi = 'Chứng từ điện tử xác nhận.';
									|ru = 'Электронный документ подтвержден.';
									|en = 'Electronic document confirmed.'; fa = 'Electronic document confirmed.';
									|it = 'Il documento elettronico è stato confermato.';
									|pl = 'Dokument elektroniczny zostaje potwierdzony.';
									|tr = 'Elektronik belge onaylandı.'");
				
			ElsIf LongDesc.EDIStatus = "DeviationInProcessing" Then
				
				LabelColor = StyleColors.ErrorNoteText;
				HyperlinkText = NStr("vi = 'Việc từ chối chứng từ điện tử đã được bắt đầu, không tương ứng với phương pháp được chọn để xử lý sự khác biệt';
									|ru = 'Инициировано отклонение электронного документа, что не соответствует выбранному способу отработки расхождений';
									|en = 'The electronic document rejection is initiated, which does not match the selected method of processing discrepancies'; fa = 'The electronic document rejection is initiated, which does not match the selected method of processing discrepancies';
									|it = 'È stata avviata la variazione del documento elettronico, che non corrisponde al metodo scelto di elaborazione delle discrepanze';
									|pl = 'Rozpoczęto odrzucenie dokumentu elektronicznego, co nie odpowiada wybranej metodzie odpracowywania odchylenia';
									|tr = 'Seçilen tutarsızlık işleme yöntemine uymayan bir elektronik belgenin reddedilmesi başlatıldı'");
				
			ElsIf LongDesc.EDIStatus = "Rejected" Then
				
				LabelColor = StyleColors.ErrorNoteText;
				HyperlinkText = NStr("vi = 'Chứng từ điện tử bị từ chối, không tương ứng với phương pháp xử lý sai lệch đã chọn';
									|ru = 'Электронный документ отклонен, что не соответствует выбранному способу отработки расхождений';
									|en = 'The electronic document is rejected, which does not match the selected method of processing discrepancies'; fa = 'The electronic document is rejected, which does not match the selected method of processing discrepancies';
									|it = 'Il documento elettronico è stato respinto in quanto non corrisponde al metodo scelto di elaborazione delle discrepanze';
									|pl = 'Dokument elektroniczny został odrzucony, co nie odpowiada wybranej metodzie odpracowywania odchylenia';
									|tr = 'Seçilen tutarsızlıkların ele alınması yöntemine uymayan elektronik belge reddedildi'");
				
			EndIf;
			
		ElsIf LongDesc.CommandName = "Reject" Then
			
			If LongDesc.EDIStatus = "Received" Then
				
				If ThereIsARightToExchangeEDI Then
				
					LabelColor = StyleColors.HyperlinkColor;
					HyperlinkText = NStr("vi = 'Không ký';
										|ru = 'Отклонить';
										|en = 'Reject'; fa = 'رد';
										|it = 'Declinare';
										|pl = 'Odrzuć';
										|tr = 'Reddet'");
					UseHyperlink = True;
				
				Else
					
					LabelColor = StyleColors.InaccessibleCellTextColor;
					HyperlinkText = NStr("vi = 'Bạn không được phép từ chối một chứng từ điện tử.';
										|ru = 'Вам недоступно отклонение электронного документа.';
										|en = 'You cannot reject an electronic document.'; fa = 'You cannot reject an electronic document.';
										|it = 'Non vi è consentita la variazione del documento elettronico.';
										|pl = 'Nie można uzyskać dostępu do odrzucenia dokumentu elektronicznego.';
										|tr = 'Elektronik belgeyi reddedemezsiniz.'");
					
				EndIf;
				
			ElsIf LongDesc.EDIStatus = "ApprovalInProcessing" Then
				
				LabelColor = StyleColors.ErrorNoteText;
				HyperlinkText = NStr("vi = 'Một xác nhận của chứng từ điện tử đã được bắt đầu, không tương ứng với phương pháp được chọn để xử lý sự khác biệt.';
									|ru = 'Инициировано подтверждение электронного документа, что не соответствует выбранному способу отработки расхождений.';
									|en = 'The electronic document confirmation is initiated, which does not match the selected method of processing discrepancies.'; fa = 'The electronic document confirmation is initiated, which does not match the selected method of processing discrepancies.';
									|it = 'È stata avviata la conferma del documento elettronico, che non corrisponde al metodo scelto di elaborazione delle discrepanze.';
									|pl = 'Zainicjowano potwierdzenie dokumentu elektronicznego, który nie odpowiada wybranej metodzie odpracowywania odchylenia.';
									|tr = 'Seçilen tutarsızlıkları ele alma yöntemine karşılık gelmeyen bir elektronik belge onayı başlatıldı.'");
				
			ElsIf LongDesc.EDIStatus = "Upholded" Then
				
				LabelColor = StyleColors.ErrorNoteText;
				HyperlinkText = NStr("vi = 'Một chứng từ điện tử được xác nhận không tương ứng với phương pháp xử lý sai lệch đã chọn';
									|ru = 'Электронный документ подтвержден, что не соответствует выбранному способу отработки расхождений';
									|en = 'The electronic document is confirmed, which does not match the selected method of processing discrepancies'; fa = 'The electronic document is confirmed, which does not match the selected method of processing discrepancies';
									|it = 'Il documento elettronico è stato confermato, che non corrisponde al metodo scelto di elaborazione delle discrepanze';
									|pl = 'Dokument elektroniczny został potwierdzony, co nie odpowiada wybranej metodzie odpracowywania odchylenia';
									|tr = 'Elektronik belgenin seçilen tutarsızlıkları ele alma yöntemiyle tutarsız olduğu doğrulandı'");
				
			ElsIf LongDesc.EDIStatus = "DeviationInProcessing" Then
				
				LabelColor = StyleColors.InaccessibleCellTextColor;
				HyperlinkText = NStr("vi = 'Bắt đầu từ chối chứng từ điện tử.';
									|ru = 'Инициировано отклонение электронного документа.';
									|en = 'The electronic document rejection is initiated.'; fa = 'The electronic document rejection is initiated.';
									|it = 'È stata avviata la variazione del documento elettronico.';
									|pl = 'Zainicjowane odrzucenie dokumentu elektronicznego.';
									|tr = 'Elektronik belgenin reddi başlatıldı.'");
				
			ElsIf LongDesc.EDIStatus = "Rejected" Then
				
				LabelColor = StyleColors.SuccessResultColor;
				HyperlinkText = NStr("vi = 'Chứng từ điện tử bị từ chối.';
									|ru = 'Электронный документ отклонен.';
									|en = 'Electronic document rejected.'; fa = 'Electronic document rejected.';
									|it = 'Il documento elettronico è stato rifiutato.';
									|pl = 'Dokument elektroniczny odrzucony.';
									|tr = 'Elektronik belge reddedildi.'");
				
			EndIf;
			
		ElsIf LongDesc.CommandName = "ToExpectCompletionOfPurchase" Then
			
			LabelColor = StyleColors.ErrorNoteText;
			HyperlinkText = NStr("vi = 'Cần tạo trước mua hàng.';
								|ru = 'Предварительно необходимо оформить приобретение.';
								|en = 'First register the purchase.'; fa = 'First register the purchase.';
								|it = 'First register the purchase.';
								|pl = 'First register the purchase.';
								|tr = 'Önce bir satın alma işlemi yapmanız gerekmektedir.'");
			
		EndIf;
		
		If (IssuedDocumentsAreDisplayed And LongDesc.CommandName = "Change")
			Or (LongDesc.CommandName = "ApplyAppearance" And Not IssuedDocumentsAreDisplayed) 
			Or (LongDesc.CommandName = "Create" And Not IssuedDocumentsAreDisplayed) 
			Or LongDesc.CommandName = "Reject"
			Or LongDesc.CommandName = "Confirm"
			Or LongDesc.CommandName = "ToExpectCompletionOfPurchase" Then
		
			If UseHyperlink Then
				If Level = 1 Then
					AreaName = "LineLevel1";
				Else
					AreaName = "LineLevel2";
				EndIf;
			Else
				If Level = 1 Then
					AreaName = "LineLevel1WithoutHyperlink";
				Else
					AreaName = "LineLevel2WithoutHyperlink";
				EndIf;
			EndIf;
		
			DocumentLineArea = Template.GetArea(AreaName);
			DocumentLineArea.Parameters.Text = HyperlinkText;
			
			If UseHyperlink Then
				
				DocumentLineArea.Parameters.Data = New Structure(
					"LongDesc, Data, CommandName", LongDesc, ArrayElement, LongDesc.CommandName);
				
				DocumentLineArea.Areas[AreaName].Font = BoldTahoma9;
				DocumentLineArea.Areas[AreaName].TextColor = LabelColor;
				
			Else
				
				DocumentLineArea.Areas[AreaName].TextColor = LabelColor;
				
			EndIf;
			
			SpreadsheetDocument.Put(DocumentLineArea);
		
		EndIf;
		
	EndIf;
	
	ArrayOfCompletedDocuments.Clear();

EndProcedure

#EndRegion

#Region InformationLabels

&AtServer
Function HeaderText(DocumentType, LongDesc , BusinessOperation = Undefined)
	
	If DocumentType = "SaleAdjustment" Then
		If BusinessOperation = Enums.BusinessTransactions.ErrorCorrection Then
			HeaderText = NStr("vi = 'Chứng từ ""Điều chỉnh bán hàng (sửa lỗi)""';
								|ru = 'Документ ""Корректировка реализации (исправление ошибок)""';
								|en = 'Document ""Sales adjustment (error correction)""'; fa = 'Document ""Sales adjustment (error correction)""';
								|it = 'Documento ""Rettifica di realizzo (correzione degli errori)""';
								|pl = 'Dokument ""Zapis korygujący sprzedaży (poprawka błędów)""';
								|tr = '""Satış düzeltmesi (hata düzeltme)"" belgesi'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties Then
			HeaderText = NStr("vi = 'Chứng từ ""Điều chỉnh bán hàng (theo thỏa thuận của các bên)""';
								|ru = 'Документ ""Корректировка реализации (по согласованию сторон)""';
								|en = 'Document ""Sales adjustment (as agreed by the parties)""'; fa = 'Document ""Sales adjustment (as agreed by the parties)""';
								|it = 'Documento ""Rettifica di realizzo (mediante accordo delle parti)""';
								|pl = 'Dokument ""Zapis korygujący sprzedaży (według uzgodnienia stron)""';
								|tr = '""Satış düzeltmesi (taraflarca mutabık kalındığı üzere)"" belgesi'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.SaleOfOverdeliveredGoods Then
			HeaderText = NStr("vi = 'Chứng từ ""Điều chỉnh bán hàng (bán mặt hàng giao lại)""';
								|ru = 'Документ ""Корректировка реализации (реализация перепоставленного товара)""';
								|en = 'Document ""Sales adjustment (overdelivered goods sales)""'; fa = 'Document ""Sales adjustment (overdelivered goods sales)""';
								|it = 'Documento ""Rettifica di realizzo (realizzo della merce consegnata in eccesso)""';
								|pl = 'Dokument ""Zapis korygujący sprzedaży (sprzedaż nadmiaru dostarczonego towaru)""';
								|tr = '""Satış düzeltmesi (fazla tedarik edilen malların satılması)"" belgesi'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
			HeaderText = NStr("vi = 'Chứng từ ""Điều chỉnh bán hàng (trả lại hàng giao thiếu)""';
								|ru = 'Документ ""Корректировка реализации (возврат недопоставленного товара)""';
								|en = 'Document ""Sales adjustment (return of underdelivered goods)""'; fa = 'Document ""Sales adjustment (return of underdelivered goods)""';
								|it = 'Documento ""Rettifica di realizzo (reso della merce mancante in consegna)""';
								|pl = 'Dokument ""Zapis korygujący sprzedaży (zwrot niedoboru towaru)""';
								|tr = '""Satış düzeltmesi (fazla tedarik edilen malların iadesi)"" belgesi'");
		EndIf;
	ElsIf DocumentType = "CreditNoteIsToGetBackOnTrack" Then
		HeaderText = NStr("vi = 'Chứng từ ""Điều chỉnh bán hàng"" để hoàn trả ""hàng đi đường""';
							|ru = 'Документ ""Корректировка реализации"" для возврата ""в путь""';
							|en = 'The ""Sales adjustment"" document for return ""in transit""'; fa = 'The ""Sales adjustment"" document for return ""in transit""';
							|it = 'The ""Sales adjustment"" document for return ""in transit""';
							|pl = 'The ""Sales adjustment"" document for return ""in transit""';
							|tr = '""Yolda"" durumundaki iade için ""Satış düzeltmesi"" belgesi'");
	ElsIf DocumentType = "PurchaseAdjustment" Then
		HeaderText = NStr("vi = 'Chứng từ ""Điều chỉnh mua hàng""';
							|ru = 'Документ ""Корректировка приобретения""';
							|en = 'Document: Purchase adjustment'; fa = 'Document: Purchase adjustment';
							|it = 'Документ ""Корректировка приобретения""';
							|pl = 'Document: Purchase adjustment';
							|tr = '""Edinim düzeltmesi"" belgesi'");
	ElsIf DocumentType = "FixingImplementation" Then
		HeaderText = NStr("vi = 'Phản ánh sự khác biệt trong chứng từ ""Bán hàng hóa và dịch vụ""';
							|ru = 'Отразить расхождения в документе ""Реализация товаров и услуг""';
							|en = 'Record discrepancies in document ""Customer invoice""'; fa = 'Record discrepancies in document ""Customer invoice""';
							|it = 'Riportare le discrepanze nel documento ""Realizzo delle merci e servizi""';
							|pl = 'Odzwierciedlij odchylenie w dokumencie ""Sprzedaż towarów i usług""';
							|tr = '""Müşteri faturası"" belgesindeki tutarsızlıkları yansıt'");
	ElsIf DocumentType = "ChangeShipmentOfItemsToCustomer" Then 
		HeaderText = NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""Giao hàng cho khách""';
							|ru = 'Отразить расхождения в документе ""Отгрузка товаров клиенту""';
							|en = 'Record discrepancies in the ""Goods shipment to customer"" document'; fa = 'Record discrepancies in the ""Goods shipment to customer"" document';
							|it = 'Record discrepancies in the ""Goods shipment to customer"" document';
							|pl = 'Record discrepancies in the ""Goods shipment to customer"" document';
							|tr = '""Müşteriye ürün sevkiyatı"" belgesindeki tutarsızlıkları yansıt'");
	ElsIf DocumentType = "CorrectionShipmentOfItemsToCustomer" Then 
		HeaderText = NStr("vi = 'Chứng từ ""Giao hàng cho khách (chỉnh sửa)""';
							|ru = 'Документ ""Отгрузка товаров клиенту (исправление)""';
							|en = 'The ""Goods shipment to customer (correction)"" document'; fa = 'The ""Goods shipment to customer (correction)"" document';
							|it = 'The ""Goods shipment to customer (correction)"" document';
							|pl = 'The ""Goods shipment to customer (correction)"" document';
							|tr = '""Müşteriye ürün sevkiyatı (düzeltme)"" belgesi'");
	ElsIf DocumentType = "AdditionalDeliveryShipmentOfItemsToCustomer" Then 
		HeaderText = NStr("vi = 'Chứng từ ""Giao hàng cho khách"" để giao hàng chưa giao bổ sung';
							|ru = 'Документ ""Отгрузка товаров клиенту"" для отгрузки недопоставленного товара';
							|en = 'The ""Goods shipment to customer"" document to ship underdelivered goods'; fa = 'The ""Goods shipment to customer"" document to ship underdelivered goods';
							|it = 'The ""Goods shipment to customer"" document to ship underdelivered goods';
							|pl = 'The ""Goods shipment to customer"" document to ship underdelivered goods';
							|tr = 'Eksik teslim edilen ürünlerin sevkiyatı için ""Müşteriye ürün sevkiyatı belgesi'");
	ElsIf DocumentType = "RecognitionOfStockSurplusShippedToCustomer" Then
		HeaderText = NStr("vi = 'Chứng từ ""Ghi tăng hàng thừa đã giao"" để ghi tăng ""hàng đi đường""';
							|ru = 'Документ ""Оприходование излишков отгруженных товаров"" для оприходования ""в путь""';
							|en = 'The ""Stock surplus of shipped goods"" document for receipt ""in transit""'; fa = 'The ""Stock surplus of shipped goods"" document for receipt ""in transit""';
							|it = 'The ""Stock surplus of shipped goods"" document for receipt ""in transit""';
							|pl = 'The ""Stock surplus of shipped goods"" document for receipt ""in transit""';
							|tr = '""Yolda"" durumundaki sevkiyatlar için ""Sevkiyat fazlası ürünlerin teslim alınması"" belgesi'");
	ElsIf DocumentType = "GoodsWriteOffShippedToCustomerWithoutAdditionalDelivery" Then
		HeaderText = NStr("vi = 'Chứng từ ""Ghi giảm hàng hóa đã giao cho khách"" (không giao hàng đã ghi giảm) để ghi giảm ""loại bỏ khỏi hàng đi đường""';
							|ru = 'Документ ""Списание товаров, отгруженных клиенту"" (списанные товары не отгружать) для списания ""из пути""';
							|en = 'The ""Write-off of goods shipped to customer"" document (do not ship written off goods) for write-off ""from transit""'; fa = 'The ""Write-off of goods shipped to customer"" document (do not ship written off goods) for write-off ""from transit""';
							|it = 'The ""Write-off of goods shipped to customer"" document (do not ship written off goods) for write-off ""from transit""';
							|pl = 'The ""Write-off of goods shipped to customer"" document (do not ship written off goods) for write-off ""from transit""';
							|tr = '""Müşteriye sevk edilen ürünlerin gider yazma"" (tekrar sevk edilecek olan ürünlerin gider yazılması) ""yolda"" olarak gider yazılması belgesi'");
	ElsIf DocumentType = "GoodsWriteOffShippedToCustomerAndAdditionalDelivery" Then
		HeaderText = NStr("vi = 'Chứng từ ""Ghi giảm hàng hóa đã giao cho khách"" (không giao hàng lại đã ghi giảm) để ghi giảm ""loại bỏ khỏi hàng đi đường""';
							|ru = 'Документ ""Списание товаров, отгруженных клиенту"" (списанные товары отгрузить вновь) для списания ""из пути""';
							|en = 'The ""Write-off of goods shipped to customer"" document (ship written off goods again) for write-off ""from transit""'; fa = 'The ""Write-off of goods shipped to customer"" document (ship written off goods again) for write-off ""from transit""';
							|it = 'The ""Write-off of goods shipped to customer"" document (ship written off goods again) for write-off ""from transit""';
							|pl = 'The ""Write-off of goods shipped to customer"" document (ship written off goods again) for write-off ""from transit""';
							|tr = '""Müşteriye sevk edilen ürünlerin gider yazılması"" (tekrar sevk edilecek olan ürünlerin gider yazılması) ""yolda"" olarak gider yazılması belgesi'");
	ElsIf DocumentType = "CorrectionOfReturnOfGoodsToSupplier" Then
		HeaderText = NStr("vi = 'Phản ánh sự khác biệt trong Trả về cho Nhà cung cấp';
							|ru = 'Отразить расхождения в документе ""Возврат товаров поставщику""';
							|en = 'Record discrepancies in document ""Return of goods to vendor""'; fa = 'Record discrepancies in document ""Return of goods to vendor""';
							|it = 'Riportare le discrepanze nel documento ""Reso della merce al fornitore""';
							|pl = 'Odzwierciedlij odchylenie w dokumencie ""Zwrot towarów dostawcy""';
							|tr = '""Malların tedarikçiye iadesi"" belgesindeki tutarsızlıkların yansıtılması'");
	ElsIf DocumentType = "GoodsShipmentFromStorage" Then
		
		PresentationOperation = NStr("vi = 'trả lại hàng chưa hoàn trả';
									|ru = 'довозврата недовозращенного товара';
									|en = 'additional return of unreturned goods'; fa = 'additional return of unreturned goods';
									|it = 'довозврата недовозращенного товара';
									|pl = 'additional return of unreturned goods';
									|tr = 'teslim edilmemiş ürünlerin iadesi'");
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
			PresentationOperation = NStr("vi = 'chuyển hàng chưa giao';
										|ru = 'передачи недопоставленного товара';
										|en = 'transfer of underdelivered goods'; fa = 'transfer of underdelivered goods';
										|it = 'передачи недопоставленного товара';
										|pl = 'transfer of underdelivered goods';
										|tr = 'teslim edilmemiş ürünlerin aktarımı'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		Else	
			ObjectPresentation = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" cho %2';
										|ru = 'Документ ""%1"" для %2';
										|en = 'The ""%1"" document for %2'; fa = 'The ""%1"" document for %2';
										|it = 'Документ ""%1"" для %2';
										|pl = 'The ""%1"" document for %2';
										|tr = '%2 için ""%1"" belgesi'"), ObjectPresentation, PresentationOperation);
		
	ElsIf DocumentType = "ShipmentOfGoodsFromStorageUponAcceptance" Then
		If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		Else
			ObjectPresentation = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" để trả lại mặt hàng giao lại';
										|ru = 'Документ ""%1"" для возврата перепоставленного товара';
										|en = 'The ""%1"" document to return overdelivered goods'; fa = 'The ""%1"" document to return overdelivered goods';
										|it = 'Documento ""%1"" per il reso di merci consegnate in eccesso';
										|pl = 'Dokument ""%1"" dla zwrotu nadmiernie dostarczonego towaru';
										|tr = 'Fazla tedarik edilen malların iadesi için ""%1"" belgesi'"), ObjectPresentation);
	ElsIf DocumentType = "CorrectionShipmentOfGoodsFromStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		Else
			ObjectPresentation = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""%1""';
										|ru = 'Отразить расхождения в документе ""%1""';
										|en = 'Register discrepancies in document ""%1""'; fa = 'Register discrepancies in document ""%1""';
										|it = 'Riflettere discrepanze nel documento ""%1""';
										|pl = 'Pokaż odchylenia w dokumencie ""%1""';
										|tr = '""%1"" belgesindeki tutarsızlıkları yansıtın'"), ObjectPresentation);
	ElsIf DocumentType = "DocumentCorrectionShipmentOfGoodsFromStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		Else
			ObjectPresentation = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" (chỉnh sửa)';
										|ru = 'Документ ""%1"" (исправление)';
										|en = '""%1"" document (correction)'; fa = '""%1"" document (correction)';
										|it = '""%1"" document (correction)';
										|pl = '""%1"" document (correction)';
										|tr = '""%1"" belgesi (yama)'"), ObjectPresentation);
	ElsIf DocumentType = "TransferCorrection" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);
		HeaderText = StrTemplate(NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""%1""';
										|ru = 'Отразить расхождения в документе ""%1""';
										|en = 'Register discrepancies in document ""%1""'; fa = 'Register discrepancies in document ""%1""';
										|it = 'Riflettere discrepanze nel documento ""%1""';
										|pl = 'Pokaż odchylenia w dokumencie ""%1""';
										|tr = '""%1"" belgesindeki tutarsızlıkları yansıtın'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "CorrectionOfTransferToCommission" Then
		HeaderText = NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""Chuyển đi ký gửi""';
							|ru = 'Отразить расхождения в документе ""Передача на комиссию""';
							|en = 'Record discrepancies in the ""Consignment sales"" document'; fa = 'Record discrepancies in the ""Consignment sales"" document';
							|it = 'Riflettere le discrepanze nel documento ""Trasferimento in commissione""';
							|pl = 'Odzwierciedlij odchylenie w dokumencie ""Wydanie do komisu""';
							|tr = '""Konsinye satış"" belgesindeki tutarsızlıkları yansıtın'");
	ElsIf DocumentType = "TransferOfGoodsToBailee" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" để chuyển giao hàng hóa chưa cung cấp';
										|ru = 'Документ ""%1"" для передачи недопоставленного товара';
										|en = 'Document ""%1"" for underdelivered goods transfer'; fa = 'Document ""%1"" for underdelivered goods transfer';
										|it = 'Documento ""%1"" per il trasferimento dell''articolo non ricollocato';
										|pl = 'Dokument ""%1"" do przekazania niedostarczonego towaru';
										|tr = 'Teslim edilmemiş malların transferi için ""%1"" belgesi'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "TransferOfGoodsForCommission" Then
		HeaderText = NStr("vi = 'Chứng từ ""Chuyển giao vào ký gửi"" để chuyển hàng chưa giao';
							|ru = 'Документ ""Передача товаров на комиссию"" для передачи недопоставленного товара';
							|en = 'The ""Customer stock fill-up documents"" document for underdelivered goods transfer'; fa = 'The ""Customer stock fill-up documents"" document for underdelivered goods transfer';
							|it = 'Documento ""Trasferimento articoli in commissione"" per il trasferimento dell''articolo non consegnato';
							|pl = 'Dokument ""Wydanie towarów do komisu"" do przekazania niedostarczonego towaru';
							|tr = 'Teslim edilmemiş malların transferi için ""komisyon üzerine mal transferi"" belgesi'");
	ElsIf DocumentType = "AcceptanceOfGoodsForStorageAdditionalDeliveryUponAcceptance" Then
		If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		Else
			ObjectPresentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" để tiếp nhận hàng hóa chưa giao';
										|ru = 'Документ ""%1"" для поступления недопоставленного товара';
										|en = 'The ""%1"" document to receive underdelivered goods'; fa = 'The ""%1"" document to receive underdelivered goods';
										|it = 'Documento ""%1"" per la ricezione di merci non consegnate';
										|pl = 'Dokument ""%1"" do przyjęcia niedostarczonego towaru';
										|tr = 'Teslim edilmemiş malların teslim alındığına dair ""%1"" belgesi'"), ObjectPresentation);
	ElsIf DocumentType = "GoodsReceiptForStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		 Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		 	ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		Else
			ObjectPresentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" để tiếp nhận mặt hàng giao lại';
										|ru = 'Документ ""%1"" для поступления перепоставленного товара';
										|en = 'The ""%1"" document to receive overdelivered goods'; fa = 'The ""%1"" document to receive overdelivered goods';
										|it = 'Documento ""%1"" per la ricezione di merci consegnate in eccesso';
										|pl = 'Dokument ""%1"" dla przyjęcia nadmiernie dostarczonego towaru';
										|tr = 'Fazla tedarik edilen malların teslim alındığına dair ""%1"" belgesi'"), ObjectPresentation);
	ElsIf DocumentType = "CorrectionOfReturnOfGoodsFromCustodian" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		HeaderText = StrTemplate(NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""%1""';
										|ru = 'Отразить расхождения в документе ""%1""';
										|en = 'Register discrepancies in document ""%1""'; fa = 'Register discrepancies in document ""%1""';
										|it = 'Riflettere discrepanze nel documento ""%1""';
										|pl = 'Pokaż odchylenia w dokumencie ""%1""';
										|tr = '""%1"" belgesindeki tutarsızlıkları yansıtın'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "DocumentCorrectionReceiptOfGoodsFromCustodian" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" (chỉnh sửa)';
										|ru = 'Документ ""%1"" (исправление)';
										|en = '""%1"" document (correction)'; fa = '""%1"" document (correction)';
										|it = '""%1"" document (correction)';
										|pl = '""%1"" document (correction)';
										|tr = '""%1"" belgesi (yama)'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "DocumentCorrectionGoodsReceiptForStorage" Then
		If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		Else
			ObjectPresentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" (chỉnh sửa)';
										|ru = 'Документ ""%1"" (исправление)';
										|en = '""%1"" document (correction)'; fa = '""%1"" document (correction)';
										|it = '""%1"" document (correction)';
										|pl = '""%1"" document (correction)';
										|tr = '""%1"" belgesi (yama)'"), ObjectPresentation);
	ElsIf DocumentType = "CorrectionOfReturnFromCommissionAgent" Then
		HeaderText = NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""Tiếp nhận hàng hóa từ người nhận ký gửi""';
							|ru = 'Отразить расхождения в документе ""Поступление товаров от комиссионера""';
							|en = 'Record discrepancies in the ""Receipt of goods from consignee"" document'; fa = 'Record discrepancies in the ""Receipt of goods from consignee"" document';
							|it = 'Riflettere le discrepanze nel documento ""Ricezione articoli dal commissionario""';
							|pl = 'Odzwierciedlij odchylenie w dokumencie „Przyjęcie towarów od komisanta”';
							|tr = '""Konsinye mal makbuzu"" belgesindeki tutarsızlıkları yansıtın'");
	ElsIf DocumentType = "ReturnOfGoodsFromKeeperPreReturn" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" đối với hàng hóa không hoàn trả';
										|ru = 'Документ ""%1"" по недовозвращенным товарам';
										|en = 'Document ""%1"" by unreturned goods'; fa = 'Document ""%1"" by unreturned goods';
										|it = 'Documento ""%1"" per articoli non restituiti';
										|pl = 'Dokument ""%1"" według niezwróconych towarów';
										|tr = 'Eksik teslim edilen mallara ilişkin ""%1"" belgesi'"), Handler.ObjectPresentation());
		If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
			HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" để tiếp nhận hàng hóa chưa giao';
											|ru = 'Документ ""%1"" для поступления недопоставленного товара';
											|en = 'The ""%1"" document to receive underdelivered goods'; fa = 'The ""%1"" document to receive underdelivered goods';
											|it = 'Documento ""%1"" per la ricezione di merci non consegnate';
											|pl = 'Dokument ""%1"" do przyjęcia niedostarczonego towaru';
											|tr = 'Teslim edilmemiş malların teslim alındığına dair ""%1"" belgesi'"), Handler.SynonymForOrder());
		EndIf;
	ElsIf DocumentType = "ReturnOfGoodsFromCommissionAgentDovozvrat" Then
		HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận hàng hóa từ người nhận ký gửi"" đối với hàng hóa không trả lại';
							|ru = 'Документ ""Поступление товаров от комиссионера"" по недовозвращенным товарам';
							|en = 'The ""Receipt of goods from consignee"" document by unreturned goods'; fa = 'The ""Receipt of goods from consignee"" document by unreturned goods';
							|it = 'Documento ""Ricezione articoli dal commissionario"" su articoli non restituiti';
							|pl = 'Dokument ""Przyjęcie towarów od komisanta"" według niezwróconych towarów';
							|tr = 'Eksik teslim edilen mallara ilişkin ""Konsinye mal makbuzu"" belgesi'");
	ElsIf DocumentType = "ReturnOfGoodsFromCustodianReturnToCustodian" Then
		PresentationOfDocument = NStr("vi = 'Chuyển giao hàng hóa cho bên lưu kho';
										|ru = 'Передача товаров хранителю';
										|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
										|it = 'Consegna di merci al depositario';
										|pl = 'Przekazanie towaru do magazyniera';
										|tr = 'Malların emanetçiye transferi'");
		If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
			PresentationOfDocument = NStr("vi = 'Chuyển giao nguyên liệu cho bên nhận gia công';
											|ru = 'Передача сырья переработчику';
											|en = 'Goods issue — Subcontracting services received'; fa = 'صدور کالا — خدمات پیمانکاری فرعی دریافتی';
											|it = 'Trasferimento di materie prime al subfornitore';
											|pl = 'Przenoszenie surowców do procesora';
											|tr = 'Hammaddelerin fason üreticiye transferi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" đối với hàng thừa trả lại';
										|ru = 'Документ ""%1"" по излишне возвращенным товарам';
										|en = 'The ""%1"" document of goods returned in excess'; fa = 'The ""%1"" document of goods returned in excess';
										|it = 'Documento ""%1"" per articoli resi in eccesso';
										|pl = 'Dokument ""%1"" według nadmiernie zwróconych towarów';
										|tr = 'Fazla iade edilen mallara ilişkin ""%1"" belgesi'"), PresentationOfDocument);
	ElsIf DocumentType = "ReturnOfGoodsFromCommissionAgentReturnToCommissionAgent" Then
		HeaderText = NStr("vi = 'Chứng từ ""Chuyển giao hàng hóa cho người nhận ký gửi"" đối với hàng trả lại thừa';
							|ru = 'Документ ""Передача товаров комиссионеру"" по излишне возвращенным товарам';
							|en = 'The ""Goods transfer to consignee"" document by goods returned in excess'; fa = 'The ""Goods transfer to consignee"" document by goods returned in excess';
							|it = 'Documento ""Trasferimento articoli al commissionario"" per eccedenza di articoli resi';
							|pl = 'Dokument ""Wydanie towarów komisantowi"" według nadmiernie zwróconych towarów';
							|tr = 'İade fazlası olan mallara ilişkin "" Müşteri stoku doldurma"" belgesi'");
	ElsIf DocumentType = "DocumentCorrectionTransferOfGoodsToCustodian" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);
		HeaderText = StrTemplate(NStr("vi = 'Chứng từ ""%1"" (chỉnh sửa)';
										|ru = 'Документ ""%1"" (исправление)';
										|en = '""%1"" document (correction)'; fa = '""%1"" document (correction)';
										|it = '""%1"" document (correction)';
										|pl = '""%1"" document (correction)';
										|tr = '""%1"" belgesi (yama)'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "CorrectionOfReturnOfGoodsFromCustomer" Then
		HeaderText = NStr("vi = 'Phản ánh sự khác biệt trong chứng từ ""Nhận hàng bán bị trả lại""';
							|ru = 'Отразить расхождения в документе ""Возврат товаров от клиента""';
							|en = 'Record discrepancies in document ""Sales return""'; fa = 'Record discrepancies in document ""Sales return""';
							|it = 'Riportare le discrepanze nel documento ""Reso della merce dal cliente""';
							|pl = 'Odzwierciedlij odchylenie w dokumencie ""Zwrot towarów od klienta""';
							|tr = '""Müşteriden Mal İadesi"" belgesindeki tutarsızlıkların yansıtılması'");
	ElsIf DocumentType = "CorrectionOfMovementOfGoods" Then
		HeaderText = NStr("vi = 'Phản ánh sự khác biệt trong chứng từ Điều chuyển hàng hóa';
							|ru = 'Отразить расхождения в документе ""Перемещение товаров""';
							|en = 'Record discrepancies in document ""Goods transfer""'; fa = 'Record discrepancies in document ""Goods transfer""';
							|it = 'Riportare le discrepanze nel documento ""Trasferimento delle merci""';
							|pl = 'Odzwierciedlij odchylenia w dokumencie ""Przemieszczenie towarów""';
							|tr = '""Mal Transferi"" belgesindeki tutarsızlıkları yansıt'");
	ElsIf DocumentType = "AdjustingMovementOfGoods" Then
		HeaderText = NStr("vi = 'Nhập điều chỉnh chứng từ ""Điều chuyển hàng hóa nội bộ""';
							|ru = 'Ввести корректировку документа ""Перемещение товаров""';
							|en = 'Enter ""Inventory transfer"" document adjustment'; fa = 'Enter ""Inventory transfer"" document adjustment';
							|it = 'Inserire la correzione del documento ""Trasferimento delle merci""';
							|pl = 'Wprowadź korektę dokumentu ""Przemieszczenie towarów""';
							|tr = '""Mal Transferi"" belgesini düzelt'");
	ElsIf DocumentType = "DocumentReturnPolicy" Then
		If UseReturnRequests Then
			If BusinessTransactionOfCertificate = Enums.BusinessTransactions.TransferToCommissionAgent Then
				HeaderText = NStr("vi = 'Chứng từ ""Giấy đề nghị trả hàng từ người nhận ký gửi"" đối với mặt hàng giao lại cần trả lại';
									|ru = 'Документ ""Заявка на возврат товаров от комиссионера"" по перепоставленным товарам к возврату';
									|en = 'The ""Consignment pick-up request"" document for overdelivered goods for return'; fa = 'The ""Consignment pick-up request"" document for overdelivered goods for return';
									|it = 'Documento ""Dichiarazione di reso articoli dal commissionario"" per articoli riconsegnati in reso';
									|pl = 'Dokument ""Wniosek o zwrot towarów od komisanta"" dla nadmiaru dostarczanych towarów do zwrotu';
									|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""Konsinyeden mal iadesi talebi"" belgesi'");
			Else
				HeaderText = NStr("vi = 'Chứng từ ""Giấy đề nghị trả hàng từ người mua"" đối với mặt hàng  giao lại cần trả lại';
									|ru = 'Документ ""Заявка на возврат товаров от клиента"" по перепоставленным товарам к возврату';
									|en = 'Document ""Sales return request"" for overdelivered goods for return'; fa = 'Document ""Sales return request"" for overdelivered goods for return';
									|it = 'Il documento ""Domanda di reso merci dal cliente"" per il reso delle merci consegnate in eccesso';
									|pl = 'Dokument ""Wniosek o zwrot towaru od klienta"" dla nadmiaru towarów do zwrotu';
									|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""müşteriden mal iade talebi"" belgesi'");
			EndIf;
		Else
			HeaderText = NStr("vi = 'Chứng từ ""Nhận hàng bán bị trả lại"" đối với mặt hàng giao lại cần trả lại';
								|ru = 'Документ ""Возврат товаров от клиента"" по перепоставленным товарам к возврату';
								|en = 'Document ""Sales return"" for overdelivered goods for return'; fa = 'Document ""Sales return"" for overdelivered goods for return';
								|it = 'Il documento ""Il reso delle merci dal cliente"" per il reso delle merci consegnate in eccesso';
								|pl = 'Dokument ""Zwrot towaru od klienta"" dla nadmiaru towarów do zwrotu';
								|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""müşteriden mal iadesi"" belgesi'");
		EndIf;
	ElsIf DocumentType = "ReceiptOfGoodsFromCustomerWithoutAdditionalDelivery" Then
		HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận hàng hóa từ khách"" (không giao hàng đã tiếp nhận) để trả lại ""hàng đi đường""';
							|ru = 'Документ ""Поступление товаров от клиента"" (поступившие товары не отгружать) для возврата ""из пути""';
							|en = 'The ""Goods receipt from customer"" document (do not ship the received goods) for return ""from transit""'; fa = 'The ""Goods receipt from customer"" document (do not ship the received goods) for return ""from transit""';
							|it = 'The ""Goods receipt from customer"" document (do not ship the received goods) for return ""from transit""';
							|pl = 'The ""Goods receipt from customer"" document (do not ship the received goods) for return ""from transit""';
							|tr = '""Yoldaki"" iade için “Müşteriden ürün girişi” belgesi (gelen ürünler sevk edilmeyecek)'");
	ElsIf DocumentType = "ReceiptOfGoodsFromCustomerAndAdditionalDelivery" Then
		HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận hàng hóa từ khách"" (giao lại hàng đã tiếp nhận) để trả lại ""hàng đi đường""';
							|ru = 'Документ ""Поступление товаров от клиента"" (поступившие товары отгрузить вновь) для возврата ""из пути""';
							|en = 'The ""Goods receipt from customer"" document (ship the received goods again) for return ""from transit""'; fa = 'The ""Goods receipt from customer"" document (ship the received goods again) for return ""from transit""';
							|it = 'The ""Goods receipt from customer"" document (ship the received goods again) for return ""from transit""';
							|pl = 'The ""Goods receipt from customer"" document (ship the received goods again) for return ""from transit""';
							|tr = '“Yoldan” iade için “Müşteriden ürün girişi” belgesi (gelen ürünler yeniden sevk edilecek).'");
	ElsIf DocumentType = "TransferReturnDocument" Then
		If UseReturnRequests
		   And BusinessTransactionOfCertificate <> Enums.BusinessTransactions.TransferToToller2_5
		   Then
			HeaderText = NStr("vi = 'Chứng từ ""Giấy đề nghị trả hàng từ người mua"" đối với mặt hàng  giao lại cần trả lại';
								|ru = 'Документ ""Заявка на возврат товаров от клиента"" по перепоставленным товарам к возврату';
								|en = 'Document ""Sales return request"" for overdelivered goods for return'; fa = 'Document ""Sales return request"" for overdelivered goods for return';
								|it = 'Il documento ""Domanda di reso merci dal cliente"" per il reso delle merci consegnate in eccesso';
								|pl = 'Dokument ""Wniosek o zwrot towaru od klienta"" dla nadmiaru towarów do zwrotu';
								|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""müşteriden mal iade talebi"" belgesi'");
		ElsIf BusinessTransactionOfCertificate = Enums.BusinessTransactions.TransferToToller2_5 Then
			HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận từ bên nhận gia công"" đối với mặt hàng giao lại cần trả lại';
								|ru = 'Документ ""Поступление от переработчика"" по перепоставленным товарам к возврату';
								|en = 'The ""Goods receipt — External subcontracting"" document for overdelivered goods for return'; fa = 'The ""Goods receipt — External subcontracting"" document for overdelivered goods for return';
								|it = 'Documento ""Ricezione dall''addetto alla lavorazione"" per articoli forniti in eccesso da rendere';
								|pl = 'Dokument ""Przyjęcie od przetwórcy"" według nadmiaru dostarczanych towarów do zwrotu';
								|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""Fason üreticiden gelen ürünleri teslim alma"" belgesi'");
		Else
			HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận hàng hóa từ bên lưu kho"" đối với mặt hàng giao lại cần trả lại';
								|ru = 'Документ ""Поступление товаров от хранителя"" по перепоставленным товарам к возврату';
								|en = 'The ""VMI return"" document by overdelivered goods for return'; fa = 'The ""VMI return"" document by overdelivered goods for return';
								|it = 'Documento ""Ricezione articoli dal magazzino"" per articoli riconsegnati in reso';
								|pl = 'Dokument ""Przyjęcie towarów od depozytariusza"" według nadmiaru dostarczanych towarów do zwrotu';
								|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""Malların VMI''dan teslim alınması"" belgesi'");
		EndIf;
	ElsIf DocumentType = "CommissionAgentSReturnDocument" Then
		If UseReturnRequests Then
			HeaderText = NStr("vi = 'Chứng từ ""Giấy đề nghị trả hàng từ người nhận ký gửi"" đối với mặt hàng giao lại cần trả lại';
								|ru = 'Документ ""Заявка на возврат товаров от комиссионера"" по перепоставленным товарам к возврату';
								|en = 'The ""Consignment pick-up request"" document for overdelivered goods for return'; fa = 'The ""Consignment pick-up request"" document for overdelivered goods for return';
								|it = 'Documento ""Dichiarazione di reso articoli dal commissionario"" per articoli riconsegnati in reso';
								|pl = 'Dokument ""Wniosek o zwrot towarów od komisanta"" dla nadmiaru dostarczanych towarów do zwrotu';
								|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""Konsinyeden mal iadesi talebi"" belgesi'");
		Else
			HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận hàng hóa từ người nhận ký gửi"" đối với mặt hàng giao lại cần trả lại';
								|ru = 'Документ ""Поступление товаров от комиссионера"" по перепоставленным товарам к возврату';
								|en = 'The ""Receipt of goods from consignee"" document by overdelivered goods for return'; fa = 'The ""Receipt of goods from consignee"" document by overdelivered goods for return';
								|it = 'Documento ""Ricezione articoli dal commissionario"" per articoli riconsegnati in reso';
								|pl = 'Dokument ""Przyjęcie towarów od komisanta"" według nadmiaru dostarczanych towarów do zwrotu';
								|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""Konsinye mal makbuzu"" belgesi'");
		EndIf;
	ElsIf DocumentType = "ReturnOfGoodsFromClientPreReturn" Then
		HeaderText = NStr("vi = 'Chứng từ ""Nhận hàng bán bị trả lại"" cho hàng không trả lại';
							|ru = 'Документ ""Возврат товаров от клиента"" по недовозвращенным товарам';
							|en = 'Document ""Sales return"" for unreturned goods'; fa = 'Document ""Sales return"" for unreturned goods';
							|it = 'Il documento ""Il reso delle merci dal cliente"" per le merci mancanti in consegna';
							|pl = 'Dokument ""Zwrot towaru od klienta"" dla niezwróconych towarów';
							|tr = 'İade edilmemiş mallara ilişkin ""Müşteriden mal iadesi"" belgesi'");
	ElsIf DocumentType = "SalesOrder" Then
		HeaderText = NStr("vi = 'Hủy dòng trong chứng từ ""Đơn hàng của khách"" theo hàng hóa chưa giao thêm';
							|ru = 'Отменить строки документов ""Заказ клиента"" по недопоставленным товарам';
							|en = 'Cancel lines of documents ""Sales order"" for underdelivered goods'; fa = 'Cancel lines of documents ""Sales order"" for underdelivered goods';
							|it = 'Annullare le righe dei documenti ""Ordine del cliente"" per le merci mancanti in consegna';
							|pl = 'Anulować wiersze dokumentów ""Zamówienie sprzedaży"" dla niedoboru towaru';
							|tr = 'Teslim edilmeyen mallara ilişkin ""müşteri siparişi"" belgesi satırlarını iptal edin'");
	ElsIf DocumentType = "PurchaseOrder" Then
		HeaderText = NStr("vi = 'Hủy bỏ các dòng chứng từ ""Đặt hàng cho nhà cung cấp"" đối với hàng hóa chưa được giao';
							|ru = 'Отменить строки документов ""Заказ поставщику"" по недопоставленным товарам';
							|en = 'Cancel lines of documents ""Purchase order"" for underdelivered goods'; fa = 'Cancel lines of documents ""Purchase order"" for underdelivered goods';
							|it = 'Annullare le righe dei documenti ""Ordine del cliente"" per le merci mancanti in consegna';
							|pl = 'Anulować wiersze dokumentów ""Zamówienie zakupu"" dla niedoboru towaru';
							|tr = 'Teslim edilmeyen mallara ilişkin ""Satın alma siparişi"" belgesi satırlarını iptal edin'");
	ElsIf DocumentType = "MaterialProviderOrder2_5" Then
		HeaderText = NStr("vi = 'Hủy bỏ dòng chứng từ ""Đơn hàng của bên đặt gia công"" theo hàng hóa chưa giao';
							|ru = 'Отменить строки документов ""Заказ давальца"" по недопоставленным товарам';
							|en = 'Cancel lines of the ""Subcontracting sales order"" documents by underdelivered goods'; fa = 'Cancel lines of the ""Subcontracting sales order"" documents by underdelivered goods';
							|it = 'Annullare le stringhe dei documenti ""Ordine del fornitore"" per le merci non consegnate';
							|pl = 'Anulować wiersze dokumentów ""Zamówienie właściciela surowców"" dla niedoboru towaru';
							|tr = 'Teslim edilmeyen mallara ilişkin ""sağlayıcı siparişi"" belgesi satırlarını iptal edin'");
	ElsIf DocumentType = "TransferOrder" Then
		HeaderText = NStr("vi = 'Hủy bỏ các dòng của các chứng từ Lệnh đặt hàng chuyển giao trên mạng đối với hàng hóa được giao';
							|ru = 'Отменить строки документов ""Заказ на перемещение"" по недопоставленным товарам';
							|en = 'Cancel lines of documents ""Transfer order"" for underdelivered goods'; fa = 'Cancel lines of documents ""Transfer order"" for underdelivered goods';
							|it = 'Annullare le righe dei documenti ""Ordine di trasferimento"" per le merci mancanti in consegna';
							|pl = 'Anulować wiersze dokumentów ""Zamówienie na przemieszczenie"" dla niedostarczonych towarów';
							|tr = 'Teslim edilmeyen mallara ilişkin ""Transfer emri"" belgesi satırlarını iptal edin'");
	ElsIf DocumentType = "OrderTransfers" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);	
		HeaderText = StrTemplate(NStr("vi = 'Hủy các dòng chứng từ ""%1"" đối với hàng hóa chưa cung cấp';
										|ru = 'Отменить строки документов ""%1"" по недопоставленным товарам';
										|en = 'Cancel lines of documents ""%1"" for underdelivered goods'; fa = 'Cancel lines of documents ""%1"" for underdelivered goods';
										|it = 'Annullare righe dei documenti ""%1"" per non ricollocati';
										|pl = 'Anuluj wiersze dokumentów ""%1"" według niedostarczonych towarów';
										|tr = 'Teslim edilmeyen mallara ilişkin ""%1"" belgesi satırlarını iptal edin'"), Handler.SynonymForOrder());
	ElsIf DocumentType = "CorrectionRequestForReturnOfGoods" Then
		HeaderText = NStr("vi = 'Hủy bỏ dòng chứng từ ""Giấy đề nghị trả hàng từ người mua"" đối với hàng thiếu khi trả lại';
							|ru = 'Отменить строки документов ""Заявка на возврат товаров от клиента"" по недостачам при возврате';
							|en = 'Cancel lines of documents ""Sales return request"" by the shortages on return'; fa = 'Cancel lines of documents ""Sales return request"" by the shortages on return';
							|it = 'Annullare le righe dei documenti ""Domanda di reso merci dal cliente"" per gli ammanchi durante il reso';
							|pl = 'Anulować wiersze dokumentów ""Wniosek o zwrot towaru od klienta"" dla niedoborów przy zwrocie';
							|tr = 'İadelerdeki eksikliklere ilişkin ""Müşteriden mal iade talebi"" belgesi satırlarını iptal edin'");
	ElsIf DocumentType = "CorrectionRequestForReturnOfTransferGoods" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		HeaderText = StrTemplate(NStr("vi = 'Hủy các dòng chứng từ ""%1"" đối với hàng thiếu khi trả lại';
										|ru = 'Отменить строки документов ""%1"" по недостачам при возврате';
										|en = 'Cancel the ""%1"" document lines by shortage on return'; fa = 'Cancel the ""%1"" document lines by shortage on return';
										|it = 'Annullare righe dei documenti ""%1"" per ammanchi al reso';
										|pl = 'Anuluj wiersze dokumentów ""%1"" według niedoborów przy zwrocie';
										|tr = 'İadelerdeki eksiklikler için ""%1"" belge satırlarını iptal edin'"), Handler.SynonymForOrder());
		If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
			HeaderText = StrTemplate(NStr("vi = 'Hủy các dòng chứng từ ""%1"" đối với hàng hóa chưa cung cấp';
											|ru = 'Отменить строки документов ""%1"" по недопоставленным товарам';
											|en = 'Cancel lines of documents ""%1"" for underdelivered goods'; fa = 'Cancel lines of documents ""%1"" for underdelivered goods';
											|it = 'Annullare righe dei documenti ""%1"" per non ricollocati';
											|pl = 'Anuluj wiersze dokumentów ""%1"" według niedostarczonych towarów';
											|tr = 'Teslim edilmeyen mallara ilişkin ""%1"" belgesi satırlarını iptal edin'"), Handler.SynonymForOrder());
		EndIf;
	ElsIf DocumentType = "CorrectionRequestForRefundFromCommissionAgent" Then
		HeaderText = NStr("vi = 'Hủy các dòng của chứng từ ""Giấy đề nghị trả lại hàng từ người nhận ký gửi"" về hàng thiếu khi trả lại';
							|ru = 'Отменить строки документов ""Заявка на возврат товаров от комиссионера"" по недостачам при возврате';
							|en = 'Cancel lines of the ""Consignment pick-up request"" documents by shortages upon return'; fa = 'Cancel lines of the ""Consignment pick-up request"" documents by shortages upon return';
							|it = 'Annullare le righe dei documenti ""Dichiarazione di reso articoli dal commissionario"" per gli ammanchi al reso';
							|pl = 'Anuluj wiersze dokumentów ""Wniosek o zwrot towarów od komisanta"" według niedoborów przy zwrocie';
							|tr = 'İadelerdeki eksikliklere ilişkin ""Konsinyeden mal iadesi talebi"" belgesi satırlarını iptal edin'");
	ElsIf DocumentType = "SalesOfGoodsAndServices" Then
		HeaderText = NStr("vi = 'Chứng từ ""Giao hàng và cung cấp dịch vụ"" dùng để bán hàng hóa chưa giao đủ';
							|ru = 'Документ ""Реализация товаров и услуг"" для реализации недопоставленного товара';
							|en = 'Document ""Customer invoice"" for sales of underdelivered goods'; fa = 'Document ""Customer invoice"" for sales of underdelivered goods';
							|it = 'Documento ""Realizzo delle merci e servizi"" per il realizzo delle merci mancanti in consegna';
							|pl = 'Dokument ""Sprzedaż towarów i usług"" dla sprzedaży niedoboru towaru';
							|tr = 'Teslim edilmemiş malların satışı için ""Müşteri faturası"" belgesi'");
	ElsIf DocumentType = "RealizationOfGoodsAndServicesOnReturnFromClient" Then 
		HeaderText = NStr("vi = 'Chứng từ ""Bán hàng hóa và dịch vụ"" để thực hiện lợi nhuận thặng dư từ khách hàng';
							|ru = 'Документ ""Реализация товаров и услуг"" для реализации излишков возврата от клиента';
							|en = 'Document ""Customer invoice"" for sales of surpluses of return from customer'; fa = 'Document ""Customer invoice"" for sales of surpluses of return from customer';
							|it = 'Documento ""Realizzo delle merci e servizi"" per il realizzo delle eccedenze del reso dal cliente';
							|pl = 'Dokument ""Sprzedaż towarów i usług"" dla sprzedaży nadwyżek zwrotu od klienta';
							|tr = 'Bir müşteriden iade edilen fazla malların satışı için ""Müşteri faturası"" belgesi'");
	ElsIf DocumentType = "ReturnOfGoodsToVendor" Then
		HeaderText = NStr("vi = 'Chứng từ ""Trả lại hàng cho nhà cung cấp"" để trả lại hàng trả lại';
							|ru = 'Документ ""Возврат товаров поставщику"" для довозврата недовозращенного товара';
							|en = 'Document ""Return of goods to vendor"" for additional return of unreturned goods'; fa = 'Document ""Return of goods to vendor"" for additional return of unreturned goods';
							|it = 'Il documento ""Il reso delle merci al fornitore"" per il reso supplementare delle merci mancanti nel reso';
							|pl = 'Dokument ""Zwrot towaru do dostawcy"" dla zwrotu niezwróconego towaru';
							|tr = 'Eksik teslim edilen malları iade etmek için ""Malların tedarikçiye iadesi"" belgesi'");
	ElsIf DocumentType = "VendorInvoice" Then 
		HeaderText = NStr("vi = 'Chứng từ ""Mua hàng hóa và dịch vụ"" để tiếp nhận mặt hàng giao lại';
							|ru = 'Документ ""Приобретение товаров и услуг"" для поступления перепоставленного товара';
							|en = 'The ""Vendor invoice"" document for overdelivered goods receipt'; fa = 'The ""Vendor invoice"" document for overdelivered goods receipt';
							|it = 'Il documento ""Acquisto delle merci e servizi"" per l''arrivo delle merci consegnate in eccesso';
							|pl = 'Dokument ""Nabycie towarów i usług"" dla dostawy nadmiaru towaru.';
							|tr = 'Fazla tedarik edilen malların teslim alınması için ""Satın alma faturası"" belgesi'");
	ElsIf DocumentType = "PurchaseOfGoodsServicesAdditionalDeliveryUponReceipt" Then
		HeaderText = NStr("vi = 'Chứng từ ""Mua hàng hóa và dịch vụ"" để nhận hàng giao thiếu';
							|ru = 'Документ ""Приобретение товаров и услуг"" для поступления недопоставленного товара';
							|en = 'The ""Vendor invoice"" document for underdelivered goods receipt'; fa = 'The ""Vendor invoice"" document for underdelivered goods receipt';
							|it = 'Il documento ""Acquisto delle merci e servizi"" per l''arrivo delle merci mancanti in consegna';
							|pl = 'Dokument ""Nabycie towarów i usług"" dla dostawy niedoboru towaru';
							|tr = 'Teslim edilmemiş malların teslim alınmasına ilişkin ""Satın alma faturası"" belgesi'");
	ElsIf DocumentType = "ReceiptOfGoodsAdditionalDeliveryUponReceipt" Then
		HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận hàng hóa"" để tiếp nhận hàng hóa giao thiếu';
							|ru = 'Документ ""Поступление товаров"" для поступления недопоставленного товара';
							|en = 'The ""Goods pick-up from customer"" for receiving the underdelivered goods'; fa = 'The ""Goods pick-up from customer"" for receiving the underdelivered goods';
							|it = 'Documento ""Arrivo delle merci"" per l''arrivo della merce mancante';
							|pl = 'Dokument ""Wpływ towarów"" dla wpływu niedostarczonego towaru';
							|tr = 'Teslim alınmamış malların teslim alınmasına ilişkin ""İrsaliye"" belgesi'");
	ElsIf DocumentType = "InventoryTransfer" Then
		HeaderText = NStr("vi = 'Chứng từ ""Lưu chuyển hàng hóa"" đối với việc giao hàng giao thiếu';
							|ru = 'Документ ""Перемещение товаров"" на допоставку недопоставленного товара';
							|en = 'Document ""Goods transfer"" for additional delivery of underdelivered goods'; fa = 'Document ""Goods transfer"" for additional delivery of underdelivered goods';
							|it = 'Il documento ""Trasferimento merci"" per la consegna supplementare delle merci mancanti in consegna';
							|pl = 'Dokument ""Przemieszczenie towarów"" dla dostawy niedoboru towaru';
							|tr = 'Teslim edilmemiş malların ek teslimatları için ""Mal Transferi"" belgesi'");
	ElsIf DocumentType = "MovementOfGoodsReturn" Then
		HeaderText = NStr("vi = 'Chứng từ ""Điều chuyển hàng hóa"" để trả lại mặt hàng giao lại';
							|ru = 'Документ ""Перемещение товаров"" на возврат перепоставленного товара';
							|en = 'Document ""Goods transfer"" for return of overdelivered goods'; fa = 'Document ""Goods transfer"" for return of overdelivered goods';
							|it = 'Il documento ""Trasferimento merci"" per il reso delle merci consegnate in eccesso';
							|pl = 'Dokument ""Przemieszczenie towarów"" dla zwrotu nadmiaru towaru';
							|tr = 'Fazla tedarik edilen malların iadesi için ""Mal Transferi"" belgesi'");
	ElsIf DocumentType = "ReceiptOfGoodsRepostingAfterAdjustment" Then
		HeaderText = NStr("vi = 'Cần kết chuyển chứng từ ""Tiếp nhận hàng hóa"" để phản ánh các thay đổi hiện có sau khi tạo chứng từ ""Điều chỉnh mua lại""';
							|ru = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений имеющихся после оформления документа ""Корректировка приобретения""';
							|en = 'Repost the ""Receipt of goods"" document to record the changes that occurred after registering the ""Purchase adjustment"" document'; fa = 'Repost the ""Receipt of goods"" document to record the changes that occurred after registering the ""Purchase adjustment"" document';
							|it = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений имеющихся после оформления документа ""Корректировка приобретения""';
							|pl = 'Repost the ""Receipt of goods"" document to record the changes that occurred after registering the ""Purchase adjustment"" document';
							|tr = '""Edinim düzeltmesi"" belgesinin düzenlenmesinden sonra mevcut değişiklikleri yansıtmak için ""İrsaliye"" belgesinin yeniden işlenmesi gerekmektedir'");
	ElsIf DocumentType = "ReceiptOfGoodsRepostingAfterPurchase" Then
		HeaderText = NStr("vi = 'Cần kết chuyển chứng từ ""Tiếp nhận hàng hóa"" để phản ánh các thay đổi đã nhập vào chứng từ ""Điều chỉnh mua lại""';
							|ru = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений внесенных в документ ""Приобретение товаров""';
							|en = 'Repost the ""Receipt of goods"" document to record the changes made in the ""Vendor invoice"" document'; fa = 'Repost the ""Receipt of goods"" document to record the changes made in the ""Vendor invoice"" document';
							|it = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений внесенных в документ ""Приобретение товаров""';
							|pl = 'Repost the ""Receipt of goods"" document to record the changes made in the ""Vendor invoice"" document';
							|tr = '""Ürün edinimi"" belgesinde yapılan değişiklikleri yansıtmak için ""İrsaliye"" belgesinin yeniden işlenmesi gerekmektedir'");
	ElsIf DocumentType = "WriteOffOfGoodsShortages" Then
		HeaderText = NStr("vi = 'Chứng từ Vượt qua tình trạng thiếu hàng hóa ""để xóa đi những thiếu hụt không được công nhận';
							|ru = 'Документ ""Списание недостач товаров"" для списания непризнанных недостач';
							|en = 'The ""Stock shortage recognition"" document to write off unrecognized shortage'; fa = 'The ""Stock shortage recognition"" document to write off unrecognized shortage';
							|it = 'Documento ""Cancellazione degli ammanchi delle merci"" per cancellare gli ammanchi non riconosciuti';
							|pl = 'Dokument ""Wycofanie niedoborów towarów"" dla wycofania nieuznanych niedoborów';
							|tr = 'Muhasebeleştirilmemiş eksikliklerin gider yazılması için ""Mal eksikliklerinin gider yazılması"" belgesi'");
	ElsIf DocumentType = "ARAPAdjustment" Then
		HeaderText = NStr("vi = 'Chứng từ ""Điều chỉnh công nợ"" để phản ánh công nợ của công ty bên thứ ba';
							|ru = 'Документ ""Корректировка задолженности"" для отражения задолженности сторонней компании';
							|en = 'Document ""AR/AP adjustment"" for recording a third party debt'; fa = 'Document ""AR/AP adjustment"" for recording a third party debt';
							|it = 'Documento ""Rettifica debito"" per la riflessione del debito della società terza';
							|pl = 'Dokument ""Korekta zadłużenia"" dla odzwierciedlenia zadłużenia innej firmy';
							|tr = 'Üçüncü taraf borçları için ""borç düzenleme"" belgesi'");
	ElsIf DocumentType = "InventorySurplusRecognition" Then
		HeaderText = NStr("vi = 'Chứng từ ""Đăng hàng hóa dư thừa"" để ghi hoa của hàng hóa giao thừa';
							|ru = 'Документ ""Оприходование излишков товаров"" для оприходования излишков поставленных товаров';
							|en = 'Document ""Stock surplus recognition"" for recording as received of delivered goods surpluses'; fa = 'Document ""Stock surplus recognition"" for recording as received of delivered goods surpluses';
							|it = 'Il documento ""Presa in carico delle eccedenze merci"" per prendere in carico le eccedenze delle merci fornite';
							|pl = 'Dokument ""Zaliczenie do przychodów nadwyżki towarów"" dla zaliczenia do przychodów nadwyżki dostarczonych towarów';
							|tr = 'Teslim edilen stok fazlası malların tahakkuku için ""Stok fazlası tahakkuku"" belgesi'");
	ElsIf DocumentType = "CorrectionOfReceipt" Then
		HeaderText = NStr("vi = 'Phản ánh sự khác biệt trong chứng từ Mua hàng hóa và dịch vụ.';
							|ru = 'Отразить расхождения в документе ""Приобретение товаров и услуг""';
							|en = 'Record discrepancies in the ""Vendor invoice"" document'; fa = 'Record discrepancies in the ""Vendor invoice"" document';
							|it = 'Riportare le discrepanze nel documento ""Acquisto delle merci e servizi""';
							|pl = 'Odzwierciedlij odchylenie w dokumencie ""Nabycie towarów i usług""';
							|tr = '""Satın alma faturası"" belgesindeki tutarsızlıkların yansıtılması'");
	ElsIf DocumentType = "ChangeInReceiptOfGoods" Then
		HeaderText = NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""Tiếp nhận hàng hóa vào kho""';
							|ru = 'Отразить расхождения в документе ""Поступление товаров на склад""';
							|en = 'Record discrepancies in the ""Warehouse receipt"" document'; fa = 'Record discrepancies in the ""Warehouse receipt"" document';
							|it = 'Riportare le discrepanze nel documento ""Arrivodi merci in magazzino""';
							|pl = 'Odzwierciedlij odchylenie w dokumencie „Wpływ towaru do magazynu”';
							|tr = '""Ambara mal girişi"" belgesindeki tutarsızlıkların yansıtılması'");
	ElsIf DocumentType = "AdjustmentOfGoodsReceipts" Then
		HeaderText = NStr("vi = 'Chứng từ ""Tiếp nhận hàng hóa vào kho""';
							|ru = 'Документ ""Поступление товаров на склад""';
							|en = '""Warehouse receipt"" document'; fa = '""Warehouse receipt"" document';
							|it = 'Documento ""Arrivo di merci in magazzino""';
							|pl = 'Dokument ""Wpływ towarów do magazynu""';
							|tr = '""Ambara mal girişi"" belgesi'");
	ElsIf DocumentType = "AdjustmentOfReceiptOfGoodsCorrections" Then
		HeaderText = NStr("vi = 'Nhập điều chỉnh chứng từ ""Tiếp nhận hàng hóa vào kho""';
							|ru = 'Ввести корректировку документа ""Поступление товаров на склад""';
							|en = 'Enter ""Warehouse receipt"" document adjustment'; fa = 'Enter ""Warehouse receipt"" document adjustment';
							|it = 'Inserire la correzione del documento ""Arrivodi merci in magazzino""';
							|pl = 'Wprowadź korektę dokumentu ""Wpływ towaru do magazynu""';
							|tr = '""Ambara mal girişi"" belgesine bir düzenleme getirin'");
	ElsIf DocumentType = "WriteOffDiscrepanciesBetweenReceiptAndPurchase" Then
		HeaderText = NStr("vi = 'Chứng từ ""Ghi giảm chênh lệch giữa tiếp nhận và mua hàng""';
							|ru = 'Документ ""Списание расхождений между поступлением и приобретением""';
							|en = 'Document: Write off discrepancies between receipt and purchase'; fa = 'Document: Write off discrepancies between receipt and purchase';
							|it = 'Документ ""Списание расхождений между поступлением и приобретением""';
							|pl = 'Document: Write off discrepancies between receipt and purchase';
							|tr = '""Giriş ve edinme arasındaki tutarsızlıkların gider yazılması"" belgesi'");
	ElsIf DocumentType = "CorrectionOfAcceptanceOfGoodsForStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		Else
			ObjectPresentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
		EndIf;
		HeaderText = StrTemplate(NStr("vi = 'Phản ánh chênh lệch trong chứng từ ""%1""';
										|ru = 'Отразить расхождения в документе ""%1""';
										|en = 'Register discrepancies in document ""%1""'; fa = 'Register discrepancies in document ""%1""';
										|it = 'Riflettere discrepanze nel documento ""%1""';
										|pl = 'Pokaż odchylenia w dokumencie ""%1""';
										|tr = '""%1"" belgesindeki tutarsızlıkları yansıtın'"), ObjectPresentation);
	ElsIf DocumentType = "ReturnOfGoodsToSupplierUponReceipt" Then
		HeaderText = NStr("vi = 'Chứng từ ""Trả lại hàng cho nhà cung cấp"" để trả lại mặt hàng giao lại';
							|ru = 'Документ ""Возврат товаров поставщику"" для возврата перепоставленного товара';
							|en = 'Document ""Return of goods to vendor"" for return of overdelivered goods'; fa = 'Document ""Return of goods to vendor"" for return of overdelivered goods';
							|it = 'Il documento ""Il reso delle merci al fornitore"" per il reso delle merci consegnate in eccesso';
							|pl = 'Dokument ""Zwrot towaru do dostawcy"" dla zwrotu nadmiaru towaru';
							|tr = 'Fazla tedarik edilen malları iade etmek için ""Malların tedarikçiye iadesi"" belgesi'");
	ElsIf DocumentType = "Claim" Then
		HeaderText = NStr("vi = 'Khiếu nại nhà cung cấp';
							|ru = 'Претензия поставщику';
							|en = 'Complaint to vendor'; fa = 'Complaint to vendor';
							|it = 'Reclamo al fornitore';
							|pl = 'Roszczenie do dostawcy';
							|tr = 'Tedarikçiye şikayet'");
	EndIf;
	
	If DocumentType = "WriteOffOfGoodsShortages"
		Or DocumentType = "InventorySurplusRecognition"   
		Or DocumentType = "ReceiptOfGoodsAdditionalDeliveryUponReceipt"
		Or DocumentType = "ShipmentOfGoodsFromStorageUponAcceptance"
		Or DocumentType = "ReturnOfGoodsToSupplierUponReceipt"
		Or DocumentType = "WriteOffDiscrepanciesBetweenReceiptAndPurchase" Then
		
		If LongDesc.WithdrawWarehouse Then
			
			WarehouseLine = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối với kho bãi ''''%1''''.';
																							|ru = 'для склада ""%1"".';
																							|en = 'for warehouse ""%1"".'; fa = 'for warehouse ""%1"".';
																							|it = 'per magazzino ""%1"".';
																							|pl = 'dla magazynu ""%1"".';
																							|tr = '""%1"" deposu için.'"), LongDesc.Warehouse);
			HeaderText = HeaderText + " " + WarehouseLine;
			
		EndIf;
		
	EndIf;
	
	If DocumentType = "ElectronicDocumentConfirmation" Then
		HeaderText = NStr("vi = 'Xác nhận chứng từ điện tử đã nhận';
							|ru = 'Подтвердить полученный электронный документ';
							|en = 'Confirm received electronic document'; fa = 'Confirm received electronic document';
							|it = 'Confermare il documento elettronico ricevuto';
							|pl = 'Potwierdź otrzymany dokument elektroniczny';
							|tr = 'Alınan elektronik bir belgeyi onaylama'");
	ElsIf DocumentType = "ElectronicDocumentRejection" Then
		HeaderText = NStr("vi = 'Từ chối nhận chứng từ điện tử';
							|ru = 'Отклонить полученный электронный документ';
							|en = 'Reject received electronic document'; fa = 'Reject received electronic document';
							|it = 'Rifiutare il documento elettronico ricevuto';
							|pl = 'Odrzuć otrzymany dokument elektroniczny';
							|tr = 'Alınan elektronik bir belgeyi reddetme'");	
	EndIf;
	
	Return HeaderText;
	
EndFunction

&AtServer
Function LegendText(DocumentType, BusinessOperation = Undefined)
	
	If DocumentType = "SaleAdjustment" Then
		If BusinessOperation = Enums.BusinessTransactions.ErrorCorrection Then
			Return NStr("vi = 'Cần lập một chứng từ ""Điều chỉnh thực hiện (sửa lỗi)"" để phản ánh thặng dư và thiếu hụt. Chứng từ này là cơ sở để ban hành các chứng từ chính được điều chỉnh và một hóa đơn điều chỉnh.';
						|ru = 'Необходимо оформить документ ""Корректировка реализации (исправление ошибок)"" для отражения излишков и недостач. Документ является основанием для выставления исправленных первичных документов и исправительного счета-фактуры.';
						|en = 'Register document ""Sales adjustment (error correction)"" for recording surpluses and shortages. This is the base document for issuing corrected source documents and a replacement tax invoice.'; fa = 'Register document ""Sales adjustment (error correction)"" for recording surpluses and shortages. This is the base document for issuing corrected source documents and a replacement tax invoice.';
						|it = 'È necessario generare il documento ""Rettifica di realizzo (correzione degli errori)"" per riportare le eccedenze e gli ammanchi. Il documento rappresenta la casuale per l''emissione di documenti primari corretti e della fattura di rettifica.';
						|pl = 'Konieczne jest wydanie dokumentu ""Korekcja realizacji (korekta błędów)"" w celu odzwierciedlenia nadwyżek i braków. Dokument jest podstawą do wydania poprawionych dokumentów pierwotnych i faktury korygującej.';
						|tr = 'Fazlalıkları ve eksiklikleri yansıtmak için bir ""Satış düzeltmesi (hata düzeltme)"" belgesi düzenlenmelidir. Bu belge, düzenlenmiş birincil belgelerin ve düzenlenmiş bir faturanın temelini oluşturur.'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties Then
			Return NStr("vi = 'Cần lập chứng từ ""Điều chỉnh giao hàng (theo thỏa thuận của các bên)"" để phản ánh hàng thừa và hàng thiếu. Chứng từ là cơ sở để xuất chứng từ gốc đã chỉnh sửa và hóa đơn GTGT đã điều chỉnh.';
						|ru = 'Необходимо оформить документ ""Корректировка реализации (по согласованию сторон)"" для отражения излишков и недостач. Документ является основанием для выставления исправленных первичных документов и корректировочного счета-фактуры.';
						|en = 'Register document ""Sales adjustment (as agreed by the parties)"" for recording surpluses and shortages. The document is a basis for issuing corrected source documents and an adjustment tax invoice.'; fa = 'Register document ""Sales adjustment (as agreed by the parties)"" for recording surpluses and shortages. The document is a basis for issuing corrected source documents and an adjustment tax invoice.';
						|it = 'È necessario emettere il documento ""Rettifica di vendita (mediante accordo delle parti)"" per la registrazione di ammanchi ed eccedenze. Il documento è un documento causale per l''emissione dei documenti primari rettificati e della fattura di rettifica.';
						|pl = 'Należy utworzyć dokument ""Zapis korygujący sprzedaży (wg uzgodnienia stron)"" w celu odzwierciedlenia nadwyżek i braków. Dokument jest podstawą do wydania poprawionych dokumentów pierwotnych i faktury korygującej.';
						|tr = 'Fazlalıkları ve eksiklikleri yansıtmak için ""Satış düzeltmesi (tarafların mutabakatı ile)"" belgesi düzenlenmelidir. Bu belge, düzenlenmiş birincil belgelerin ve düzeltici bir faturanın düzenlenmesi için temel oluşturur.'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.SaleOfOverdeliveredGoods Then
			Return NStr("vi = 'Cần lập chứng từ ""Điều chỉnh doanh số (bán mặt hàng giao lại)"" để phản ánh thực tế bán hàng hóa được giao quá mức. Chứng từ này là cơ sở để phát hành các chứng từ và hóa đơn chính. Nó lập trên các dòng của chứng nhận chấp nhận với các tùy chọn xử lý: ""Thanh toán"" và ""Thanh toán và trả lại"".';
						|ru = 'Необходимо оформить документ ""Корректировка реализации (реализация перепоставленного товара)"" для отражения в учете факта продажи излишне доставленных товаров. Документ является основанием для выставления первичных документов и счета-фактуры. Оформляется на строки акта приемки с вариантами отработки: ""Оформить"" и ""Оформить и вернуть"".';
						|en = 'Register the ""Sales adjustment (return of overdelivered goods)"" document for recording sales of overdelivered goods. This is the base document for issuing source documents and tax invoice. It is registered for receiving note lines with the ""Invoice the surplus"" and the ""Invoice the surplus and create Goods return"" tolling options.'; fa = 'Register the ""Sales adjustment (return of overdelivered goods)"" document for recording sales of overdelivered goods. This is the base document for issuing source documents and tax invoice. It is registered for receiving note lines with the ""Invoice the surplus"" and the ""Invoice the surplus and create Goods return"" tolling options.';
						|it = 'È necessario generare il documento ""Rettifica di realizzo (realizzo della merce consegnata in eccesso)"" per riportare nella contabilità le merci consegnate in eccesso. Il documento rappresenta la casuale per l''emissione dei documenti primari corretti e delle fatture. Viene formalizzato sulle righe dell''atto di accettazione con le versioni di elaborazione ""Formalizzare"" e ""Formalizzare e restituire"".';
						|pl = 'Konieczne jest sporządzenie dokumentu ""Korekcja realizacji (realizacja ponownie dostarczanych towarów)"" w celu odzwierciedlenia w rozliczeniu faktu sprzedaży nad-produkowanych towarów. Dokument jest podstawą do wystawiania podstawowych dokumentów i faktur. Zatwierdzane jest na wiersze o podstawie aktu akceptacji z opcjami do opracowania: ""Zatwierdź"" i ""Zatwierdź i zwróć"".';
						|tr = 'Tedarik fazlası malların satışını hesaplara yansıtmak için ""Satış düzeltmesi (tedarik fazlası malların satışı)"" belgesi hazırlanmalıdır. Belge, birincil belgelerin ve faturaların düzenlenmesi için temel oluşturur. ""Düzenle"" ve ""Düzenle ve iade et"" işleme seçenekleri ile kabul raporu satırlarında düzenlenir.'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
			Return NStr("vi = 'Cần phải đăng ký chứng từ ""Điều chỉnh doanh số (trả lại hàng chưa giao đủ)"". Thực hiện đảo ngược có tính đến thực tế bán hàng đã được phản ánh trong khi bán, nhưng không được giao. Chứng từ được ghi nhận dựa trên cơ sở các chứng từ gốc và hóa đơn GTGT nhận được từ khách hàng. Đang tạo đối với các dòng của biên bản chênh lệch có phương án xử lý: ""Tạo"" và ""Tạo và giao thêm"".';
						|ru = 'Необходимо зарегистрировать документ ""Корректировка реализации (возврат недопоставленного товара)"". Выполняется сторнирование в учете факта продажи товаров, которые были отражены при реализации, но не были доставлены. Документ регистрируется на основании первичных документов и счета-фактуры, полученных от клиента. Оформляется на строки акта о расхождениях с вариантами отработки: ""Оформить"" и ""Оформить и допоставить"".';
						|en = 'Register the ""Sales adjustment (return of underdelivered goods)"" document. Reversal is carried out in accounting of sale of goods which were recorded on sale, but were not delivered. The document is registered on the basis of source documents and the tax invoice received from the customer. It is registered for discrepancy report lines with processing options: ""Register"" and ""Register and supply additionally"".'; fa = 'Register the ""Sales adjustment (return of underdelivered goods)"" document. Reversal is carried out in accounting of sale of goods which were recorded on sale, but were not delivered. The document is registered on the basis of source documents and the tax invoice received from the customer. It is registered for discrepancy report lines with processing options: ""Register"" and ""Register and supply additionally"".';
						|it = 'È necessario registrare il documento ""Adeguamento del realizzo (reso delle merci mancanti in consegna)."" Viene effettuato uno storno in contabilità per la vendita delle merci che sono stati registrate durante il realizzo, ma non sono stati consegnate. Il documento è registrato sulla base dei documenti primari e delle fatture ricevute dal cliente. Viene formalizzato sulle righe dell''atto sulle discrepanze con le versioni di elaborazione: ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
						|pl = 'Należy zarejestrować dokument ""Korekta realizacji (zwrot niedostarczonych towarów)."" Dokonuje się odwrócenia przy rozliczaniu sprzedaży towarów, które zostały odzwierciedlone podczas sprzedaży, ale nie zostały dostarczone. Dokument jest rejestrowany na podstawie podstawowych dokumentów i faktur otrzymanych od klienta. Zatwierdzane jest na wiersze o podstawie protokołu o odchyleniu z opcjami dotyczącymi odpracowania: ""Zatwierdź"" i ""Zatwierdź i dodaj"".';
						|tr = '""Satış düzeltmesi (teslim edilmeyen malların iadesi)"" belgesinin tescil edilmesi gerekmektedir. Satış olarak kaydedilmiş ancak teslim edilmemiş malların satışı tersine çevrilecektir. Belge, birincil belgeler ve müşteriden alınan fatura temelinde kaydedilir. Tutarsızlık raporunun satırlarında ""Düzenleme"" ve ""Düzenleme ve ek teslimat"" seçenekleri ile yürütülür.'");
		EndIf;
	ElsIf DocumentType = "CreditNoteIsToGetBackOnTrack" Then
		Return NStr("vi = 'Cần lập chứng từ ""Điều chỉnh bán hàng"" theo hàng thừa được đánh dấu để trả lại. Đang lập đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Tạo và trả lại"".';
					|ru = 'Необходимо оформить документ ""Корректировка реализации"" по излишкам, отмеченным к возврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
					|en = 'Register the ""Sales adjustment"" document by the surplus marked for return to customers. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" processing option.'; fa = 'Register the ""Sales adjustment"" document by the surplus marked for return to customers. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" processing option.';
					|it = 'Register the ""Sales adjustment"" document by the surplus marked for return to customers. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" processing option.';
					|pl = 'Register the ""Sales adjustment"" document by the surplus marked for return to customers. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" processing option.';
					|tr = 'Müşteri tarafından iade edilmek üzere işaretlenen fazlalıklar için ""Satış düzeltmesi"" belgesi düzenlenmelidir. Bu belge, ""Düzenle ve iade et"" işleme seçeneğine sahip uyuşmazlık tutanağının satırları üzerinden düzenlenir. '");
	ElsIf DocumentType = "PurchaseAdjustment" Then
		Return NStr("vi = 'Cần lập chứng từ ""Điều chỉnh mua hàng"" để phản ánh hàng thừa và hàng thiếu. Chứng từ này là cơ sở để ghi nhận các chứng từ gốc được điều chỉnh và hóa đơn GTGT điều chỉnh.';
					|ru = 'Необходимо оформить документ ""Корректировка приобретения"" для отражения излишков и недостач. Документ является основанием для регистрации исправленных первичных документов и исправительного счета-фактуры.';
					|en = 'Register the ""Purchase adjustment"" document to record surpluses and shortages. This is a base document to register corrected source documents and a replacement tax invoice.'; fa = 'Register the ""Purchase adjustment"" document to record surpluses and shortages. This is a base document to register corrected source documents and a replacement tax invoice.';
					|it = 'Необходимо оформить документ ""Корректировка приобретения"" для отражения излишков и недостач. Документ является основанием для регистрации исправленных первичных документов и исправительного счета-фактуры.';
					|pl = 'Register the ""Purchase adjustment"" document to record surpluses and shortages. This is a base document to register corrected source documents and a replacement tax invoice.';
					|tr = 'Fazlalıkları ve eksiklikleri yansıtmak için ""Edinim düzeltmesi"" belgesinin düzenlenmesi gerekmektedir. Belge, düzeltilmiş birincil belgelerin ve düzeltilmiş vergi faturasının kaydedilmesi için temel oluşturmaktadır.'");
	ElsIf DocumentType = "FixingImplementation" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Giao hàng và cung cấp dịch vụ"" bằng cách phản ánh số lượng thực tế. Cần thực hiện đối với dòng của biên bản chênh lệch với tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
					|ru = 'Необходимо скорректировать документ ""Реализация товаров и услуг"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"" и ""Оформить и допоставить"".';
					|en = 'Correct the ""Customer invoice"" document by recording an actual quantity in it. Make the changes to discrepancy report lines with processing options: ""Register and return"", ""Register"", and ""Register and supply additionally"".'; fa = 'Correct the ""Customer invoice"" document by recording an actual quantity in it. Make the changes to discrepancy report lines with processing options: ""Register and return"", ""Register"", and ""Register and supply additionally"".';
					|it = 'Correct the ""Customer invoice"" document by recording an actual quantity in it. Make the changes to discrepancy report lines with processing options: ""Register and return"", ""Register"", and ""Register and supply additionally"".';
					|pl = 'Correct the ""Customer invoice"" document by recording an actual quantity in it. Make the changes to discrepancy report lines with processing options: ""Register and return"", ""Register"", and ""Register and supply additionally"".';
					|tr = 'Gerçek miktar yansıtılarak ""Ürün ve hizmet satışı"" belgesi düzeltilmelidir. Bu işlem, şu işleme seçeneklerine sahip tutarsızlık tutanağı satırları için uygulanmalıdır: “Düzenle ve iade et”, “Düzenle” ve “Düzenle ve takviye yap”.'");
	ElsIf DocumentType = "ChangeShipmentOfItemsToCustomer" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Giao hàng và cung cấp dịch vụ"" bằng cách phản ánh số lượng thực tế. Cần thực hiện đối với dòng của biên bản chênh lệch với tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
					|ru = 'Необходимо скорректировать документ ""Отгрузка товаров клиенту"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"" и ""Оформить и допоставить"".';
					|en = 'Correct the ""Goods shipment to customer"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.'; fa = 'Correct the ""Goods shipment to customer"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.';
					|it = 'Correct the ""Goods shipment to customer"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.';
					|pl = 'Correct the ""Goods shipment to customer"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.';
					|tr = 'Gerçek miktar yansıtılarak ""Müşteriye ürün sevkiyatı"" belgesi düzeltilmelidir. Bu işlem, şu işleme seçeneklerine sahip tutarsızlık tutanağı satırları için uygulanmalıdır: “Düzenle ve iade et”, “Düzenle” ve “Düzenle ve takviye yap”.'");
	ElsIf DocumentType = "CorrectionShipmentOfItemsToCustomer" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Giao hàng và cung cấp dịch vụ"" bằng cách phản ánh số lượng thực tế. Cần thực hiện đối với dòng của biên bản chênh lệch với tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
					|ru = 'Необходимо оформить документ ""Отгрузка товаров клиенту (исправление)"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"" и ""Оформить и допоставить"".';
					|en = 'Register the ""Goods shipment to customer (correction)"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.'; fa = 'Register the ""Goods shipment to customer (correction)"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.';
					|it = 'Register the ""Goods shipment to customer (correction)"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.';
					|pl = 'Register the ""Goods shipment to customer (correction)"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and supply additionally"" processing options.';
					|tr = 'Fiili miktar yansıtılarak ""Müşteriye ürün sevkiyatı (düzeltme)"" belgesi düzenlenmelidir. Bu işlem, şu işleme seçeneklerine sahip tutarsızlık tutanağı satırları için uygulanmalıdır: “Düzenle ve iade et”, “Düzenle” ve “Düzenle ve takviye yap”.'");
	ElsIf DocumentType = "AdditionalDeliveryShipmentOfItemsToCustomer" Then 
		Return NStr("vi = 'Cần lập chứng từ ""Giao hàng cho khách"" đối với hàng thiếu được đánh dấu cần giao thêm cho khách. Được tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và giao thêm"".';
					|ru = 'Необходимо оформить документ ""Отгрузка товаров клиенту"" по недостачам, отмеченным к допоставке клиенту. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и допоставить"".';
					|en = 'Register document ""Goods shipment to customer"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with the ""Register and supply additionally"" processing option.'; fa = 'Register document ""Goods shipment to customer"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with the ""Register and supply additionally"" processing option.';
					|it = 'Register document ""Goods shipment to customer"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with the ""Register and supply additionally"" processing option.';
					|pl = 'Register document ""Goods shipment to customer"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with the ""Register and supply additionally"" processing option.';
					|tr = 'Müşteriye takviye yapılacak şeklinde işaretlenen eksiklikler için ""Müşteriye ürün sevkiyatı"" belgesi düzenlenmelidir. Bu belge, ""Düzenle ve takviye yap"" işleme seçeneğine sahip tutarsızlık tutanağının satırları üzerinden düzenlenir.'");
	ElsIf DocumentType = "RecognitionOfStockSurplusShippedToCustomer" Then
		Return NStr("vi = 'Cần tạo chứng từ ""Ghi tăng hàng thừa đã giao"" đối với hàng thừa được ghi nhận cần ghi tăng ""hàng đi đường"". Được thực hiện tại các dòng có biên bản chênh lệch với tùy chọn xử lý ""Ghi tăng ""hàng đi đường"""".';
					|ru = 'Необходимо оформить документ ""Оприходование излишков отгруженных товаров"" по излишкам, отмеченным к оприходованию ""в путь"". Оформляется на строки акта о расхождениях с вариантом отработки ""Оприходовать ""в путь"""".';
					|en = 'Register the ""Stock surplus of shipped goods"" document for surpluses marked to receive ""in transit"". It is registered in discrepancy report lines with the ""Receive in transit"" processing option.'; fa = 'Register the ""Stock surplus of shipped goods"" document for surpluses marked to receive ""in transit"". It is registered in discrepancy report lines with the ""Receive in transit"" processing option.';
					|it = 'Register the ""Stock surplus of shipped goods"" document for surpluses marked to receive ""in transit"". It is registered in discrepancy report lines with the ""Receive in transit"" processing option.';
					|pl = 'Register the ""Stock surplus of shipped goods"" document for surpluses marked to receive ""in transit"". It is registered in discrepancy report lines with the ""Receive in transit"" processing option.';
					|tr = 'Fazlalık olarak tespit edilen ve ""yolda"" olarak kayda alınacak fazla ürünler için ""Fazla ürün kaydı"" belgesinin düzenlenmesi gerekmektedir. İşlem seçeneği ""Yolda olarak kaydet"" olan tutarsızlık tutanağı satırları için düzenlenir.'");
	ElsIf DocumentType = "GoodsWriteOffShippedToCustomerWithoutAdditionalDelivery" Then
		Return NStr("vi = 'Cần tạo chứng từ ""Ghi giảm hàng hóa đã giao cho khách"" theo hàng thiếu được ghi nhận để ghi giảm ""hàng đi đường"". Được thực hiện trên dòng có biên bản chênh lệch với phương án xử lý ""Ghi giảm từ ""hàng đi đường"""".';
					|ru = 'Необходимо оформить документ ""Списание товаров, отгруженных клиенту"" по недостачам, отмеченным к списанию ""из пути"". Оформляется на строки акта о расхождениях с вариантом отработки ""Списать из ""пути"""".';
					|en = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.'; fa = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.';
					|it = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.';
					|pl = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.';
					|tr = 'Eksik olarak tespit edilen ve ""yoldan"" kaydı düşülecek mallar için ""Müşteriye sevk edilen malların kaydının düşülmesi"" belgesinin düzenlenmesi gerekmektedir. İşlem seçeneği ""Yoldan kaydını düş"" olan tutarsızlık tutanağı satırları için düzenlenir.'");
	ElsIf DocumentType = "GoodsWriteOffShippedToCustomerAndAdditionalDelivery" Then
		Return NStr("vi = 'Cần tạo chứng từ ""Ghi giảm hàng hóa đã giao cho khách"" theo hàng thiếu được ghi nhận để ghi giảm ""hàng đi đường"". Được thực hiện trên dòng có biên bản chênh lệch với phương án xử lý ""Ghi giảm từ ""hàng đi đường"""".';
					|ru = 'Необходимо оформить документ ""Списание товаров, отгруженных клиенту"" по недостачам, отмеченным к списанию ""из пути"". Оформляется на строки акта о расхождениях с вариантом отработки ""Списать из ""пути"""".';
					|en = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.'; fa = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.';
					|it = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.';
					|pl = 'Register the ""Write-off of goods shipped to customer"" document for shortages marked to be written off ""from transit"". It is registered in discrepancy report lines with the ""Write off in transit"" processing option.';
					|tr = 'Eksik olarak tespit edilen ve ""yoldan"" kaydı düşülecek mallar için ""Müşteriye sevk edilen malların kaydının düşülmesi"" belgesinin düzenlenmesi gerekmektedir. İşlem seçeneği ""Yoldan kaydını düş"" olan tutarsızlık tutanağı satırları için düzenlenir.'");
	ElsIf DocumentType = "CorrectionOfReturnOfGoodsToSupplier" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Trả lại hàng cho nhà cung cấp"" bằng cách phản ánh số lượng thực tế trong đó. Cần thực hiện đối với dòng có biên bản chênh lệch với phương án xử lý: ""Tạo và trả lại"", ""Tạo"", ""Tạo và giao thêm"".';
					|ru = 'Необходимо скорректировать документ ""Возврат товаров поставщику"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и допоставить"".';
					|en = 'Correct the ""Return of goods to vendor"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.'; fa = 'Correct the ""Return of goods to vendor"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.';
					|it = 'È necessario rettificare il documento ""Il reso delle merci al fornitore"", riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le versioni di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
					|pl = 'Konieczne jest skorygowanie dokumentu ""Zwrot towarów dostawcy"", odzwierciedlając w nim faktycznie ilość. Należy to zrobić na wierszach protokołu o odchyleniu z opcjami do pracy: ""Zatwierdź i odeślij"", ""Zatwierdź"", ""Zatwierdź i dodaj"".';
					|tr = '""Malların Satıcıya İadesi"" belgesinin gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade"", ""Düzenle"", "" Düzenle ve teslim et"" seçenekleri ile düzenlenmelidir.'");
	ElsIf DocumentType = "CorrectionOfReturnOfGoodsFromCustomer" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Trả lại hàng cho nhà cung cấp"" bằng cách phản ánh số lượng thực tế trong đó. Cần thực hiện đối với dòng có biên bản chênh lệch với phương án xử lý: ""Tạo và trả lại"", ""Tạo"", ""Tạo và giao thêm"".';
					|ru = 'Необходимо скорректировать документ ""Возврат товаров поставщику"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и допоставить"".';
					|en = 'Correct the ""Return of goods to vendor"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.'; fa = 'Correct the ""Return of goods to vendor"" document recording an actual quantity in it. Execute for discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.';
					|it = 'È necessario rettificare il documento ""Il reso delle merci al fornitore"", riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le versioni di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
					|pl = 'Konieczne jest skorygowanie dokumentu ""Zwrot towarów dostawcy"", odzwierciedlając w nim faktycznie ilość. Należy to zrobić na wierszach protokołu o odchyleniu z opcjami do pracy: ""Zatwierdź i odeślij"", ""Zatwierdź"", ""Zatwierdź i dodaj"".';
					|tr = '""Malların Satıcıya İadesi"" belgesinin gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade"", ""Düzenle"", "" Düzenle ve teslim et"" seçenekleri ile düzenlenmelidir.'");
	ElsIf DocumentType = "CorrectionOfMovementOfGoods" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Điều chuyển hàng hóa nội bộ"" bằng cách phản ánh số lượng thực tế trong đó. Cần thực hiện cho các dòng của giao dịch trong biên bản chênh lệch với các phương án xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
					|ru = 'Необходимо скорректировать документ ""Перемещение товаров"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и допоставить"".';
					|en = 'Correct the ""Goods transfer"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.'; fa = 'Correct the ""Goods transfer"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.';
					|it = 'È necessario rettificare il documento ""Trasferimento delle merci"", riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le versioni di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
					|pl = 'Konieczne jest poprawienie dokumentu ""Przemieszczenie towarów"", odzwierciedlającego w nim faktyczną kwotę. Należy to zrobić na wierszach protokołu o odchyleniu z opcjami do pracy: ""Zatwierdź i zwróć"", ""Zatwierdź"", ""Zatwierdź i dodaj"".';
					|tr = '""Mal Transferi"" belgesi gerçek miktarı yansıtacak şekilde düzeltilmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade"", ""Düzenle"", "" Düzenle ve teslim et"" seçenekleri ile düzenlenmelidir.'");
	ElsIf DocumentType = "AdjustingMovementOfGoods" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Điều chuyển hàng hóa nội bộ"", sau khi phản ánh số lượng thực tế trong đó. Cần thực hiện cho các dòng của giao dịch trong biên bản chênh lệch với các phương án xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao hàng"".';
					|ru = 'Необходимо ввести корректировочный документ ""Перемещение товаров"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и допоставить"".';
					|en = 'Enter the ""Inventory transfer"" correction document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.'; fa = 'Enter the ""Inventory transfer"" correction document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.';
					|it = 'È necessario inserire il documento di rettifica""Trasferimento delle merci"", riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le versioni di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
					|pl = 'Konieczne jest wprowadzenie dokumentu korygującego ""Przemieszczenie towarów"", odzwierciedlającego w nim faktyczną ilość. Należy to zrobić w wierszach protokołu o odchyleniu z opcjami do pracy: ""Zatwierdź i zwróć"", ""Zatwierdź"", ""Zatwierdź i dodaj"".';
					|tr = 'Gerçek miktarı yansıtan düzeltici bir ""Mal transferi"" belgesi girilmesi gereklidir. Tutarsızlık raporu satırları ""Düzenle ve iade"", ""Düzenle"", "" Düzenle ve teslim et"" seçenekleri ile düzenlenmelidir.'");
	ElsIf DocumentType = "DocumentReturnPolicy" Then
		If UseReturnRequests Then
			Return NStr("vi = 'Cần tạo chứng từ ""Giấy đề nghị trả hàng từ người mua"" đối với hàng thừa được đánh dấu để nhận hàng bán bị trả lại. Đang tạo đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và trả lại"".';
						|ru = 'Необходимо оформить документ ""Заявка на возврат товаров от клиента"" по излишкам, отмеченным к возврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
						|en = 'Register the ""Sales return request"" document for surpluses marked for return by the customer. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Sales return request"" document for surpluses marked for return by the customer. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
						|it = 'È necessario formalizzare il documento ""Domanda di reso delle merci dal cliente"" per le eccedenze segnate dal cliente al reso. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e restituire"".';
						|pl = 'Konieczne jest wystawienie dokumentu ""Wniosek o zwrot towaru od klienta"" na nadwyżce, oznaczonej do zwrotu przez klienta. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją odpracowania ""Zatwierdź i odeślij"".';
						|tr = 'Müşteri tarafından iade edilmek üzere işaretlenen ihtiyaç fazlası mallar için ""Müşteriden mal iade talebi"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
		Else
			Return NStr("vi = 'Cần tạo chứng từ ""Nhận hàng bán bị trả lại"" đối với hàng thừa được đánh dấu để nhận hàng bán bị trả lại. Đang tạo đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và trả lại"".';
						|ru = 'Необходимо оформить документ ""Возврат товаров от клиента"" по излишкам, отмеченным к возврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
						|en = 'Register the ""Sales return"" document for surpluses marked for return by the customer. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Sales return"" document for surpluses marked for return by the customer. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
						|it = 'È necessario formalizzare il documento ""Il reso delle merci dal cliente"" per le eccedenze segnate dal cliente al reso. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e restituire"".';
						|pl = 'Konieczne jest wykonanie dokumentu ""Zwrot towarów od klienta"" na nadwyżce, oznaczonej do zwrotu przez klienta. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją odpracowania ""Zatwierdź i odeślij"".';
						|tr = 'Müşteri tarafından iade edilmek üzere işaretlenen ihtiyaç fazlası mallar için ""Müşteriden mal iadesi"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
		EndIf;
	ElsIf DocumentType = "ReceiptOfGoodsFromCustomerWithoutAdditionalDelivery" Then
		Return NStr("vi = 'Cần lập chứng từ ""Tiếp nhận hàng hóa từ khách"" theo chênh lệch được đánh dấu cần trả lại. Lập chứng từ đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Trả lại"", ""Lập chứng từ và trả lại"".';
					|ru = 'Необходимо оформить документ ""Поступление товаров от клиента"" по расхождениям, отмеченным к возврату. Оформляется на строки акта о расхождениях с вариантом отработки ""Вернуть"", ""Оформить и вернуть"".';
					|en = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.'; fa = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.';
					|it = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.';
					|pl = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.';
					|tr = 'İade edilecek farklar için ""Müşteriden mal girişi"" belgesinin düzenlenmesi gerekmektedir. İşlem seçeneği ""İade et"", ""Düzenle ve iade et"" olan tutarsızlık tutanağı satırları için düzenlenir.'");
	ElsIf DocumentType = "ReceiptOfGoodsFromCustomerAndAdditionalDelivery" Then
		Return NStr("vi = 'Cần lập chứng từ ""Tiếp nhận hàng hóa từ khách"" theo chênh lệch được đánh dấu cần trả lại. Lập chứng từ đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Trả lại"", ""Lập chứng từ và trả lại"".';
					|ru = 'Необходимо оформить документ ""Поступление товаров от клиента"" по расхождениям, отмеченным к возврату. Оформляется на строки акта о расхождениях с вариантом отработки ""Вернуть"", ""Оформить и вернуть"".';
					|en = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.'; fa = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.';
					|it = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.';
					|pl = 'Register the ""Goods receipt from customer"" document by discrepancies marked for return. It is registered in the discrepancy report lines with the ""Return"" and ""Invoice the surplus and create Goods return"" processing option.';
					|tr = 'İade edilecek farklar için ""Müşteriden mal girişi"" belgesinin düzenlenmesi gerekmektedir. İşlem seçeneği ""İade et"", ""Düzenle ve iade et"" olan tutarsızlık tutanağı satırları için düzenlenir.'");
	ElsIf DocumentType = "TransferReturnDocument" Then
		If UseReturnRequests
		   And BusinessTransactionOfCertificate <> Enums.BusinessTransactions.TransferToToller2_5
		   Then
			Return NStr("vi = 'Chứng từ ""Giấy đề nghị trả hàng từ người mua"" đối với hàng hóa đã giao lại cần trả lại';
						|ru = 'Документ ""Заявка на возврат товаров от клиента"" по перепоставленным товарам к возврату';
						|en = 'Document ""Sales return request"" for overdelivered goods for return'; fa = 'Document ""Sales return request"" for overdelivered goods for return';
						|it = 'Il documento ""Domanda di reso merci dal cliente"" per il reso delle merci consegnate in eccesso';
						|pl = 'Dokument ""Wniosek o zwrot towaru od klienta"" dla nadmiaru towarów do zwrotu';
						|tr = 'Fazla tedarik edilen malların iade edilmesine ilişkin ""müşteriden mal iade talebi"" belgesi'");
		ElsIf BusinessTransactionOfCertificate = Enums.BusinessTransactions.TransferToToller2_5 Then
			Return NStr("vi = 'Cần lập chứng từ ""Tiếp nhận hàng hóa từ bên nhận gia công"" về hàng giao lại được đánh dấu để nhận trả lại từ bên nhận gia công. Đang tạo đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và trả lại"".';
						|ru = 'Необходимо оформить документ ""Поступление от переработчика"" по излишкам, отмеченным к возврату переработчиком. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
						|en = 'Register the ""Goods receipt — External subcontracting"" document for surplus marked for return by the subcontractor. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Goods receipt — External subcontracting"" document for surplus marked for return by the subcontractor. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
						|it = 'È necessario redigere il documento ""Ricezione dall''addetto alla lavorazione"" per eccedenze contrassegnate da rendere dall''addetto alla lavorazione. Viene registrato nelle righe dell''atto sulle difformità con opzione di elaborazione ""Redigere e restituire"".';
						|pl = 'Należy wygenerować dokument ""Przyjęcie od przetwórcy"" według nadwyżek, zaznaczonych do zwrotu przetwórcom. Jest generowany na wiersze protokołu o odchyleniu z wariantem przetworzenia ""Utwórz i zwróć"".';
						|tr = 'Fason üretici tarafından iade edilmek üzere işaretlenen fazlalıklar için ""Fason üreticiden gelen ürünleri teslim alma"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
		Else
			Return NStr("vi = 'Cần lập chứng từ ""Tiếp nhận hàng hóa từ bên lưu kho"" về hàng thừa được đánh dấu để nhận hàng bán bị trả lại. Đang tạo đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và trả lại"".';
						|ru = 'Необходимо оформить документ ""Поступление товаров от хранителя"" по излишкам, отмеченным к возврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
						|en = 'Register the ""VMI return"" document by surplus marked for return by the customer. It is registered in the discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""VMI return"" document by surplus marked for return by the customer. It is registered in the discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
						|it = 'È necessario registrare il documento ""Ricezione articoli da magazzino"" per le eccedenze contrassegnate in reso dal cliente. Viene registrato nella riga dell''atto sulle dscrepanze con variante di elaborazione ""Registrare e restituire"".';
						|pl = 'Należy zarejestrować dokument ""Wpływ towarów od magazyniera"" według nadwyżek, zaznaczonych do zwrotu nabywcom. Są rejestrowane wiersze protokołu o odchyleniu z wariantem opracowania ""Zatwierdź i zwróć"".';
						|tr = 'Müşteri tarafından iade edilmek üzere işaretlenen ihtiyaç fazlası mallar için ""Malların VMI''dan teslim alınması"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
		EndIf;
	ElsIf DocumentType = "CommissionAgentSReturnDocument" Then
		If UseReturnRequests Then
			Return NStr("vi = 'Cần lập chứng từ ""Giấy đề nghị trả lại hàng hóa từ người nhận ký gửi"" về hàng thừa được đánh dấu để nhận hàng bán bị trả lại. Lập chứng từ đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và trả lại"".';
						|ru = 'Необходимо оформить документ ""Заявка на возврат товаров от комиссионера"" по излишкам, отмеченным к возврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
						|en = 'Register the ""Consignment pick-up request"" document for surplus marked for return by the customer. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Consignment pick-up request"" document for surplus marked for return by the customer. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
						|it = 'È necessario registrare il documento ""Dichiarazione di reso articoli dal commissionario"" per le eccedenze segnate dal cliente al reso. Viene registrato nella riga dell''atto sulle discrepanze con la variante di elaborazione: ""Registrare e restituire"".';
						|pl = 'Należy zarejestrować dokument ""Wniosek o zwrot towarów od komisanta"" według nadwyżek, zaznaczonych do zwrotu nabywcom. Są rejestrowane wiersze protokołu o odchyleniu z wariantem opracowania ""Zatwierdź i zwróć"".';
						|tr = 'Müşteri tarafından iade edilmek üzere işaretlenen ihtiyaç fazlası mallar için bir ""Konsinye Mal İade Talebi"" belgesi düzenlenmesi gerekmektedir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
		Else
			Return NStr("vi = 'Cần lập chứng từ ""Tiếp nhận hàng hóa từ người nhận ký gửi"" về hàng thừa được đánh dấu để nhận hàng bán bị trả lại. Lập chứng từ đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và trả lại"".';
						|ru = 'Необходимо оформить документ ""Поступление товаров от комиссионера"" по излишкам, отмеченным к возврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
						|en = 'Register the ""Receipt of goods from consignee"" document for surplus marked for return by the customer. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Receipt of goods from consignee"" document for surplus marked for return by the customer. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
						|it = 'È necessario registrare il documento ""Ricezione articoli da commissionario"" per le eccedenze contrassegnate in reso dal cliente. Viene registrato nella riga dell''atto sulle dscrepanze con variante di elaborazione ""Registrare e restituire"".';
						|pl = 'Należy zarejestrować dokument ""Wpływ towarów od komisanta"" według nadwyżek, zaznaczonych do zwrotu nabywcom. Są rejestrowane wiersze protokołu o odchyleniu z wariantem opracowania ""Zatwierdź i zwróć"".';
						|tr = 'Müşteri tarafından iade edilmek üzere işaretlenen ihtiyaç fazlası mallar için bir ""Konsinyeden mal makbuzu"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
		EndIf;
	ElsIf DocumentType = "ReturnOfGoodsFromClientPreReturn" Then
			Return NStr("vi = 'Cần lập chứng từ ""Nhận hàng bán bị trả lại"" về hàng thiếu được đánh dấu để nhận hàng bán bị trả lại bổ sung. Đang tạo đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và đợi giao thêm""';
						|ru = 'Необходимо оформить документ ""Возврат товаров от клиента"" по недостачам, отмеченным к довозврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и ожидать допоставку"".';
						|en = 'Register document ""Sales return"" by shortages selected by a customer for additional return. It is registered for discrepancy report lines with processing option ""Register and wait for subsequent delivery"".'; fa = 'Register document ""Sales return"" by shortages selected by a customer for additional return. It is registered for discrepancy report lines with processing option ""Register and wait for subsequent delivery"".';
						|it = 'È necessario formalizzare il documento ""Il reso delle merci dal cliente"" per gli ammanchi segnati dal cliente al reso. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e attendere la consegna della merce mancante"".';
						|pl = 'Konieczne jest wystawienie dokumentu ""Zwrot towarów od klienta"" na brakach wskazanych do zwrotu przez klienta. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i oczekuj dodatkowej dostawy"".';
						|tr = 'Müşteri tarafından ek teslimat için not edilen eksiklikler için ""Müşteriden mal iadesi"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Ek teslimatları düzenle ve bekle"" seçeneği ile tutarsızlık raporu satırları düzenlenmelidir.'");
	ElsIf DocumentType = "SalesOrder" Then
		Return NStr("vi = 'Cần điều chỉnh các chứng từ ""Đơn hàng của khách"" bằng cách hủy các dòng với hàng hóa được phản ánh trong khi bán, nhưng không được giao. Cần thực hiện cho các dòng của biên bản chênh lệch với  với tùy chọn xử lý ""Lập chứng từ"".';
					|ru = 'Необходимо скорректировать документы ""Заказ клиента"", отменив строки с товарами, которые были отражены при реализации, но не были доставлены. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
					|en = 'Correct documents ""Sales order"" by canceling lines with goods which were recorded on sale, but were not delivered. Make the changes to discrepancy report lines with processing option ""Register"".'; fa = 'Correct documents ""Sales order"" by canceling lines with goods which were recorded on sale, but were not delivered. Make the changes to discrepancy report lines with processing option ""Register"".';
					|it = 'È necessario rettificare i documenti ""Ordini del cliente"" annullando le righe con le merci che sono state registrate al realizzo, ma non sono state consegnate. Deve essere eseguito per le righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare"".';
					|pl = 'Konieczne jest poprawienie dokumentów ""Zlecenie klienta"", anulowanie wierszy z towarami, które zostały odzwierciedlone podczas realizacji, ale nie zostały dostarczone. Powinien być wykonany dla wierszy protokołu o odchyleniu z opcją ""Zatwierdź"".';
					|tr = '""Müşteri siparişi"" belgeleri, satış için raporlanan ancak teslim edilmeyen mallar için satırlar iptal edilerek düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "PurchaseOrder" Then
		Return NStr("vi = 'Cần điều chỉnh các chứng từ ""Đặt hàng đặt nhà cung cấp"" bằng cách hủy các dòng với hàng hóa được phản ánh khi nhận, nhưng không được giao. Cần thực hiện đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ"".';
					|ru = 'Необходимо скорректировать документы ""Заказ поставщику"", отменив строки с товарами, которые были отражены при поступлении, но не были доставлены. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
					|en = 'Correct documents ""Purchase order"" by canceling lines with goods which were recorded on receipt, but were not delivered. Make these changes to the discrepancy report lines with processing option ""Register"".'; fa = 'Correct documents ""Purchase order"" by canceling lines with goods which were recorded on receipt, but were not delivered. Make these changes to the discrepancy report lines with processing option ""Register"".';
					|it = 'È necessario rettificare i documenti ""Ordini del cliente"" annullando le righe con le merci che sono state registrate all''arrivo, ma non sono state consegnate. Deve essere eseguito per le righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare"".';
					|pl = 'Konieczne jest skorygowanie dokumentów ""Zamówienie do dostawcy"", anulowanie linii z towarami, które zostały odzwierciedlone przy odbiorze, ale nie zostały dostarczone. Powinien być wykonany dla wierszy protokołu o odchyleniu z opcją ""Zatwierdź"".';
					|tr = '""Satın alma siparişi"" belgeleri, teslim alındığı bildirilen ancak teslim edilmeyen mallar için satırlar iptal edilerek düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "MaterialProviderOrder2_5" Then
		Return NStr("vi = 'Cần điều chỉnh các chứng từ ""Đơn hàng đặt nhà cung cấp"" bằng cách hủy các dòng có hàng hóa đã được phản ánh vào chứng từ tiếp nhận, nhưng chưa được giao. Cần thực hiện đối với các dòng biên bản chênh lệch với phương án xử lý ""Lập chứng từ"".';
					|ru = 'Необходимо скорректировать документы ""Заказ давальца"", отменив строки с товарами, которые были отражены при поступлении, но не были доставлены. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
					|en = 'Correct the ""Subcontracting sales order"" documents by canceling lines with goods that were recorded at receipt but were not delivered. Make these changes to the discrepancy report lines with the ""Register"" option.'; fa = 'Correct the ""Subcontracting sales order"" documents by canceling lines with goods that were recorded at receipt but were not delivered. Make these changes to the discrepancy report lines with the ""Register"" option.';
					|it = 'È necessario correggere i documenti ""Ordine del fornitore"", dopo aver annullato le stringhe con le merci riflesse in ricezione ma non consegnate. Occorre eseguire per le stringhe un atto di accettazione con riserva con variante di elaborazione ""Formalizzare"".';
					|pl = 'Konieczne jest skorygowanie dokumentów ""Zamówienie właściciela surowców"", anulowanie wiersza z towarami, które zostały wyświetlone przy wyborze, ale nie zostały dostarczone. Powinien być wykonany dla wierszy protokołu o odchyleniu z opcją ""Zatwierdź"".';
					|tr = 'Makbuzda kaydedilen ancak teslim edilmeyen mallar için satırları iptal ederek ""Sağlayıcı siparişi"" belgelerinin düzenlemesi gerekir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "TransferOrder" Then
		Return NStr("vi = 'Cần điều chỉnh các chứng từ ""Đơn hàng điều chuyển nội bộ"" bằng cách hủy các dòng có hàng hóa được phản ánh khi điều chuyển, nhưng không được điều chuyển. Cần thực hiện đối với các dòng của Biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ"".';
					|ru = 'Необходимо скорректировать документы ""Заказ на перемещение"", отменив строки с товарами, которые были отражены при перемещении, но не были перемещены. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
					|en = 'Correct documents ""Transfer order"" canceling lines with goods which were recorded when moving, but were not transferred. Make the changes to discrepancy report lines with tolling option: ""Register"".'; fa = 'Correct documents ""Transfer order"" canceling lines with goods which were recorded when moving, but were not transferred. Make the changes to discrepancy report lines with tolling option: ""Register"".';
					|it = 'È necessario rettificare i documenti ""Ordine di trasferimento"" annullando le righe con le merci che sono state registrate per il trasferimento, ma non sono state trasferite. Deve essere eseguito per le righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare"".';
					|pl = 'Konieczne jest poprawienie dokumentów ""Zamówienie do przeniesienia"", anulowanie wierszy z towarami, które zostały odzwierciedlone podczas ruchu, ale nie zostały przeniesione. Powinien być wykonany dla wierszy protokołu o odchyleniu z opcją ""Zatwierdź"".';
					|tr = '""Transfer emri"" belgelerinin, taşımaya yansıtılan ancak taşınmayan malların bulunduğu satırlar iptal edilerek düzenlenmesi gerekir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "OrderTransfers" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần điều chỉnh các chứng từ ""%1"" bằng cách hủy các dòng với hàng hóa được phản ánh khi chuyển giao, nhưng chưa được giao. Nên được thực hiện cho các dòng trong Biên bản chênh lệch với phương án xử lý ""Cần lập"".';
								|ru = 'Необходимо скорректировать документы ""%1"", отменив строки с товарами, которые были отражены при передачи, но не были доставлены. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
								|en = 'Correct documents ""%1"" by canceling lines with goods which were registered upon transfer but were not delivered. Make the changes to the discrepancy report lines with processing option ""Register"".'; fa = 'Correct documents ""%1"" by canceling lines with goods which were registered upon transfer but were not delivered. Make the changes to the discrepancy report lines with processing option ""Register"".';
								|it = 'Dopo l''annullamento delle righe con gli articoli è necessario rettificare i documenti ""%1"" riflessi durante il trasferimento ma non consegnati. È necessario compilare per le righe l''atto sulle discrepanze con variante di elaborazione ""Formalizzare"".';
								|pl = 'Konieczne jest skorygowanie dokumentów ""%1"", anulowanie wierszy z towarami, które zostały odzwierciadlone podczas przekazania, ale nie były dostarczone. Należy utworzyć dla wierszy protokołu o odchyleniu z wariantem opracowania ""Zatwierdź"".';
								|tr = '""%1"" belgelerinin, devir teslimde yansıtılan ancak teslim edilmeyen malların bulunduğu satırların iptal edilmesi suretiyle düzeltilmesi gerekmektedir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'"), Handler.SynonymForOrder());
	ElsIf DocumentType = "CorrectionRequestForReturnOfGoods" Then
		Return NStr("vi = 'Cần điều chỉnh các chứng từ ""Giấy đề nghị trả hàng từ người mua"" bằng cách hủy bỏ các dòng có hàng hóa bị thiếu khi trả lại. Cần thực hiện cho các dòng của Biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ"".';
					|ru = 'Необходимо скорректировать документы ""Заявка на возврат товаров от клиента"", отменив строки с товарами, по которым были выявлены недостачи при возврате. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
					|en = 'Correct the ""Sales return request"" documents by canceling lines with goods for which shortages on return were detected. This is relevant to lines of discrepancy report with the ""Register"" processing option.'; fa = 'Correct the ""Sales return request"" documents by canceling lines with goods for which shortages on return were detected. This is relevant to lines of discrepancy report with the ""Register"" processing option.';
					|it = 'È necessario rettificare i documenti ""Domanda di reso delle merci dal cliente"" annullando le righe con le merci per le quali sono stati rilevati gli ammanchi durante il reso. Deve essere eseguito per le righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare"".';
					|pl = 'Konieczne jest poprawienie dokumentów ""Wniosek o zwrot towarów od klienta"", anulowanie wiersza z towarami, dla których stwierdzono braki podczas zwrotu. Powinien być wykonany dla wierszy protokołu o odchyleniu z opcją ""Zatwierdź"".';
					|tr = '""Müşteriden Mal İade Talebi"" belgelerini, iade sırasında eksiklik tespit edilen malların bulunduğu satırların iptal edilerek düzenlenmesi gerekir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "CorrectionRequestForReturnOfTransferGoods" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần điều chỉnh các chứng từ ""%1"" bằng cách hủy các dòng với hàng hóa bị thiếu khi trả lại. Cần thực hiện cho các dòng trong biên bản chênh lệch với phương án xử lý ""Lập chứng từ"".';
								|ru = 'Необходимо скорректировать документы ""%1"", отменив строки с товарами, по которым были выявлены недостачи при возврате. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
								|en = 'Correct the ""%1"" documents by canceling lines with goods for which shortages on return were detected. This is relevant to lines of discrepancy report with the ""Register"" processing option.'; fa = 'Correct the ""%1"" documents by canceling lines with goods for which shortages on return were detected. This is relevant to lines of discrepancy report with the ""Register"" processing option.';
								|it = 'Dopo l''annullamento delle righe con gli articoli è necessario rettificare i documenti ""%1"" per i quali sono stati registrati ammanchi al reso. È necessario compilare per le righe l''atto sulle discrepanze con variante di elaborazione ""Formalizzare"".';
								|pl = 'Należy skorygować dokumenty ""%1"", anulując wiersze z towarami, według których wykryto niedobory przy zwrocie. Należy zrobić to dla wierszy protokołu o odchyleniu z wariantem opracowania ""Zatwierdź"".';
								|tr = '""%1"" belgelerinin, iade sırasında eksiklikleri tespit edilen malların bulunduğu satırların iptal edilerek düzenlenmesi gerekmektedir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'"), Handler.SynonymForOrder());
	ElsIf DocumentType = "CorrectionRequestForRefundFromCommissionAgent" Then
		Return NStr("vi = 'Cần điều chỉnh các chứng từ ""Giấy đề nghị trả hàng từ người nhận ký gửi"" bằng cách hủy bỏ các dòng với hàng hóa bị thiếu khi trả lại. Cần thực hiện đối với các dòng của Biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ"".';
					|ru = 'Необходимо скорректировать документы ""Заявка на возврат товаров от комиссионера"", отменив строки с товарами, по которым были выявлены недостачи при возврате. Следует выполнить для строк акта о расхождениях с вариантом отработки ""Оформить"".';
					|en = 'Correct the ""Consignment pick-up request"" documents by canceling lines with goods for which shortages were detected upon return. This is relevant to lines of the discrepancy report with the ""Register"" processing option.'; fa = 'Correct the ""Consignment pick-up request"" documents by canceling lines with goods for which shortages were detected upon return. This is relevant to lines of the discrepancy report with the ""Register"" processing option.';
					|it = 'È necessario correggere i documenti ""Dichiarazione di reso articoli dal commissionario"" annullando le righe con gli articoli per le quali sono stati rilevati gli ammanchi durante il reso. Deve essere eseguito per le righe dell''atto sulle discrepanze con la variante di elaborazione: ""Registrare"".';
					|pl = 'Należy skorygować dokumenty ""Wniosek o zwrot towarów od komisanta"", anulując wiersze z towarami, według których wykryto niedobory przy zwrocie. Należy zrobić to dla wierszy protokołu o odchyleniu z wariantem opracowania ""Zatwierdź"".';
					|tr = '""Malların konsinyeden iadesi"" belgelerini, iade sırasında eksiklik tespit edilen malların bulunduğu satırların iptal edilerek düzenlenmesi gerekmektedir. Tutarsızlık raporu satırları ""Düzenle"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "SalesOfGoodsAndServices" Then
		Return NStr("vi = 'Cần lập chứng từ ""Giao hàng và cung cấp dịch vụ"" đối với hàng thiếu để giao thêm cho khách. Đang tạo đối với các dòng của Biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và giao thêm"".';
					|ru = 'Необходимо оформить документ ""Реализация товаров и услуг"" по недостачам, отмеченным к допоставке клиенту. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и допоставить"".';
					|en = 'Register document ""Customer invoice"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with processing option ""Register and supply additionally"".'; fa = 'Register document ""Customer invoice"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with processing option ""Register and supply additionally"".';
					|it = 'È necessario formalizzare il documento ""Realizzo delle merci e servizi"" per gli ammanchi segnati per la consegna al cliente. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e consegnare la merce mancante"".';
					|pl = 'Konieczne jest wykonanie dokumentu ""Sprzedaż towarów i usług"" na brakach odnotowanych dla dodatkowej dostawy do klienta. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją wypracowania ""wydania i dodania"".';
					|tr = 'Müşteriye ek teslimat için not edilen eksiklikler için ""Müşteri faturası"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenleme ve ek teslimat"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "RealizationOfGoodsAndServicesOnReturnFromClient" Then
		Return NStr("vi = 'Cần tạo chứng từ ""Giao hàng và cung cấp dịch vụ"" đối với hàng thừa được đánh dấu để hoàn trả cho khách. Đang tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"".';
					|ru = 'Необходимо оформить документ ""Реализация товаров и услуг"" по излишкам, отмеченным к возврату клиенту. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
					|en = 'Register the ""Customer invoice"" document for surpluses marked for return to the customer. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Customer invoice"" document for surpluses marked for return to the customer. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
					|it = 'È necessario formalizzare il documento ""Realizzo delle merci e servizi"" per le eccedenze segnate per il reso al cliente. Deve essere eseguito sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e restituire"".';
					|pl = 'Konieczne jest wykonanie dokumentu ""Sprzedaż towarów i usług"" na nadwyżce, oznaczonej do zwrotu klientowi. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i odeślij"". ';
					|tr = 'Müşteriye iade edilmek üzere işaretlenen fazlalıklar için ""Müşteri faturası"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "ReturnOfGoodsToVendor" Then
		Return NStr("vi = 'Cần lập chứng từ ""Trả lại hàng cho nhà cung cấp"" đối với hàng thiếu khi giao trả thêm cho nhà cung cấp. Được tạo đối với các dòng của Biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và giao thêm"".';
					|ru = 'Необходимо оформить документ ""Возврат товаров поставщику"" по недостачам, отмеченным к допоставке поставщику. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и допоставить"".';
					|en = 'Register document ""Return of goods to vendor"" for shortages marked for additional delivery to the vendor. It is registered in discrepancy report lines with processing option ""Register and supply additionally"".'; fa = 'Register document ""Return of goods to vendor"" for shortages marked for additional delivery to the vendor. It is registered in discrepancy report lines with processing option ""Register and supply additionally"".';
					|it = 'È necessario formalizzare il documento ""Il reso delle merci al fornitore"" per gli ammanchi segnati per la consegna aggiuntiva al fornitore. Deve essere eseguito sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e consegnare la merce mancante"".';
					|pl = 'Konieczne jest wykonanie dokumentu ""Zwrot towarów dostawcy"" na temat niedostatecznych ilości stwierdzonych dla dodatkowej dostawy do dostawcy. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją wypracowania ""Zatwierdź i dodaj"".';
					|tr = 'Tedarikçiye ek teslimat için işaretlenen eksiklikler için ""Malların tedarikçiye iadesi"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenleme ve ek teslimat"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "VendorInvoice" Then
		Return NStr("vi = 'Cần lập chứng từ ""Mua hàng hóa và dịch vụ"" đối với hàng thừa được đánh dấu để nhận lại hàng từ nhà cung cấp. Đang tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"".';
					|ru = 'Необходимо оформить документ ""Приобретение товаров и услуг"" по излишкам, отмеченным к возврату поставщиком. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
					|en = 'Register the ""Vendor invoice"" document for surpluses marked for return by the vendor. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Vendor invoice"" document for surpluses marked for return by the vendor. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
					|it = 'È necessario formalizzare il documento ""Acquisto delle merci e servizi"" per le eccedenze segnate per il reso dal fornitore. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e restituire"".';
					|pl = 'Konieczne jest wykonanie dokumentu ""Zakup towarów i usług"" nadwyżki, oznaczonej do zwrotu przez dostawcę. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i odeślij"".';
					|tr = 'Tedarikçi tarafından iade edilmek üzere işaretlenen fazlalıklar için ""Satın alma faturası"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "GoodsShipmentFromStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			ObjectPresentation    =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
			SupplierPresentation = NStr("vi = 'cho bên đặt gia công';
										|ru = 'давальцу';
										|en = 'provider'; fa = 'provider';
										|it = 'al fornitore';
										|pl = 'właścicielowi surowców';
										|tr = 'sağlayıcıya'");
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ObjectPresentation    =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
			SupplierPresentation = NStr("vi = 'cho bên đặt gia công';
										|ru = 'давальцу';
										|en = 'provider'; fa = 'provider';
										|it = 'al fornitore';
										|pl = 'właścicielowi surowców';
										|tr = 'sağlayıcıya'");
		Else
			ObjectPresentation    = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
			SupplierPresentation = NStr("vi = 'dành cho nhà cung cấp';
										|ru = 'поставщику';
										|en = 'vendor'; fa = 'تأمین‌کننده';
										|it = 'al fornitore';
										|pl = 'dostawcy';
										|tr = 'tedarikçiye'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần lập chứng từ ""%1"" đối với hàng thiếu đã đánh dấu cần giao thêm %2. Được tạo đối với các dòng của biên bản chênh lệch có tùy chọn xử lý ""Lập chứng từ và giao thêm"".';
								|ru = 'Необходимо оформить документ ""%1"" по недостачам, отмеченным к допоставке %2. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и допоставить"".';
								|en = 'Register the ""%1"" document by the shortage marked for additional delivery %2. It is registered for discrepancy report lines with the ""Register and supply additionally"" option.'; fa = 'Register the ""%1"" document by the shortage marked for additional delivery %2. It is registered for discrepancy report lines with the ""Register and supply additionally"" option.';
								|it = 'È necessario formalizzare il documento ""%1"" per ammanchi registrati alla consegna %2. Viene formalizzato nella stringa dell''atto di accettazione con riserva con variante di elaborazione ""Formalizzare e consegnare"".';
								|pl = 'Należy zarejestrować dokument ""%1"" według niedoborów, zaznaczonych do dodatkowej dostawy %2. Jest rejestrowany dla wierszy protokołu o odchyleniu z wariantem procesora danych ""Zatwierdź i dodaj"".';
								|tr = 'Yeniden teslimat için işaretlenen eksiklikler için bir ""%1"" belgesi düzenlenmelidir%2. Tutarsızlık raporu satırları ""Düzenle ve teslim et"" seçeneği ile düzenlenecektir.'"), ObjectPresentation, SupplierPresentation);
	ElsIf DocumentType = "CorrectionShipmentOfGoodsFromStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		Else
			ObjectPresentation = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần điều chỉnh chứng từ ""%1"" bằng cách phản ánh vào đó số lượng thực tế. Cần thực hiện đối với các dòng của biên bản chênh lệch có tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
								|ru = 'Необходимо скорректировать документ ""%1"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и допоставить"".';
								|en = 'Correct the ""%1"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.'; fa = 'Correct the ""%1"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.';
								|it = 'È necessario rettificare il documento ""%1"", riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con variante di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
								|pl = 'Należy skorygować dokument ""%1"", odzwierciedlając w nim faktyczną ilość. Należy to zrobić w wierszach protokołu o odchyleniu z wariantami opracowania: ""Zatwierdź i zwróć"", ""Zatwierdź"", ""Zatwierdź i dodaj"".';
								|tr = '""%1"" belgesi gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"", ""Düzenle"", ""Düzenle ve teslim et"" seçenekleri ile düzenlenmelidir.'"), ObjectPresentation);
	ElsIf DocumentType = "DocumentCorrectionShipmentOfGoodsFromStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ObjectPresentation =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		Else
			ObjectPresentation = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần tạo chỉnh sửa chứng từ ""%1"".';
								|ru = 'Необходимо оформить исправление документа ""%1"".';
								|en = 'Register a correction to the ""%1"" document.'; fa = 'Register a correction to the ""%1"" document.';
								|it = 'Register a correction to the ""%1"" document.';
								|pl = 'Register a correction to the ""%1"" document.';
								|tr = '""%1"" belgesinin düzeltmesi oluşturulmalıdır.'"), ObjectPresentation);
	ElsIf DocumentType = "ShipmentOfGoodsFromStorageUponAcceptance" Then
		If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation    =
				TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
			SupplierPresentation = NStr("vi = 'cho bên đặt gia công';
										|ru = 'давальцу';
										|en = 'provider'; fa = 'provider';
										|it = 'al fornitore';
										|pl = 'właścicielowi surowców';
										|tr = 'sağlayıcıya'");
		Else
			ObjectPresentation    = NStr("vi = 'Xuất kho hàng hóa từ kho cất giữ';
										|ru = 'Отгрузка товаров с хранения';
										|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
										|it = 'Spedizione delle merci dal deposito';
										|pl = 'Wysyłka towarów z przechowywania';
										|tr = 'Malların VMI''dan sevkiyat talebi'");
			SupplierPresentation = NStr("vi = 'dành cho nhà cung cấp';
										|ru = 'поставщику';
										|en = 'vendor'; fa = 'تأمین‌کننده';
										|it = 'al fornitore';
										|pl = 'dostawcy';
										|tr = 'tedarikçiye'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần lập chứng từ ""%1"" theo hàng hóa giao lại được đánh dấu để trả lại %2. Đang lập đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"".';
								|ru = 'Необходимо оформить документ ""%1"" по перепоставленному товару, отмеченному к возврату %2. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
								|en = 'Register the ""%1"" document for the overdelivered goods marked for return %2. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""%1"" document for the overdelivered goods marked for return %2. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
								|it = 'È necessario formalizzare il documento ""%1"" per le merci consegnate in eccedenza contrassegnate per il reso %2. Occorre formalizzare nella stringa dell''atto di accettazione con riserva con variante di elaborazione ""Formalizzare ed effettuare il reso"".';
								|pl = 'Należy zarejestrować dokument ""%1"" dla nadmiernie dostarczonego towaru, zaznaczonego do zwrotu %2. Jest rejestrowany dla wierszy protokołu o odchyleniu z opcją wypracowania ""Zatwierdź i zwróć"".';
								|tr = 'İade edilmek üzere işaretlenmiş fazla tedarik edilen mallar için bir ""%1"" belgesi düzenlenmelidir%2. Tutarsızlık raporu satırları ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'"), ObjectPresentation, SupplierPresentation);
	ElsIf DocumentType = "TransferCorrection" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần điều chỉnh chứng từ ""%1"" bằng cách phản ánh vào đó số lượng thực tế. Cần thực hiện đối với các dòng của biên bản chênh lệch có tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
								|ru = 'Необходимо скорректировать документ ""%1"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и допоставить"".';
								|en = 'Correct the ""%1"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.'; fa = 'Correct the ""%1"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.';
								|it = 'È necessario rettificare il documento ""%1"", riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con variante di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
								|pl = 'Należy skorygować dokument ""%1"", odzwierciedlając w nim faktyczną ilość. Należy to zrobić w wierszach protokołu o odchyleniu z wariantami opracowania: ""Zatwierdź i zwróć"", ""Zatwierdź"", ""Zatwierdź i dodaj"".';
								|tr = '""%1"" belgesi gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"", ""Düzenle"", ""Düzenle ve teslim et"" seçenekleri ile düzenlenmelidir.'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "TransferOfGoodsToBailee" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần lập chứng từ ""%1"" đối với hàng thiếu đã đánh dấu cần giao cho khách. Được thực hiện tại các dòng của biên bản chênh lệch có tùy chọn xử lý ""Lập chứng từ và giao hàng"".';
								|ru = 'Необходимо оформить документ ""%1"" по недостачам, отмеченным к допоставке клиенту. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и допоставить"".';
								|en = 'Register document ""%1"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with processing option ""Register and supply additionally"".'; fa = 'Register document ""%1"" for shortages marked for subsequent delivery to the customer. It is registered in discrepancy report lines with processing option ""Register and supply additionally"".';
								|it = 'È necessario formalizzare il documento ""%1"" per ammanchi registrati alla consegna al cliente. Viene formalizzato nelle righe dell''atto sulle discrepanze con variante di elaborazione ""Formalizzare e consegnare"".';
								|pl = 'Należy utworzyć dokument ""%1"" według niedoborów, zaznaczonych do dodatkowej dostawy klientowi. Jest tworzony na wiersze protokołu o odchyleniach z wariantem przetwarzania ""Utwórz i dodaj"".';
								|tr = 'Müşteriye ek teslimat için işaretlenen eksiklikler için bir ""%1"" belgesi düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve teslim et"" seçeneği ile düzenlenecektir.'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "GoodsReceiptForStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		 Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		 	ObjectPresentation    = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		 	SupplierPresentation = NStr("vi = 'cho bên đặt gia công';
										|ru = 'давальцу';
										|en = 'provider'; fa = 'provider';
										|it = 'al fornitore';
										|pl = 'właścicielowi surowców';
										|tr = 'sağlayıcıya'");
		Else
			ObjectPresentation    = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
			SupplierPresentation = NStr("vi = 'dành cho nhà cung cấp';
										|ru = 'поставщику';
										|en = 'vendor'; fa = 'تأمین‌کننده';
										|it = 'al fornitore';
										|pl = 'dostawcy';
										|tr = 'tedarikçiye'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần lập chứng từ ""%1"" theo hàng thừa được đánh dấu để trả lại %2. Đang lập đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"".';
								|ru = 'Необходимо оформить документ ""%1"" по излишкам, отмеченным к возврату %2. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
								|en = 'Register the ""%1"" document by the surplus marked for return %2. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""%1"" document by the surplus marked for return %2. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
								|it = 'È necessario formalizzare il documento ""%1"" per eccedenze contrassegnate per il reso %2. Viene formalizzato nella stringa dell''atto di accettazione con riserva con variante di elaborazione ""Formalizzare ed effettuare il reso"".';
								|pl = 'Konieczne jest wystawienie dokumentu ""%1"" według nadwyżek, zaznaczonych do zwrotu%2. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i zwróć"".';
								|tr = 'İade için işaretlenen fazlalıklar için bir ""%1"" belgesi düzenlenmelidir%2. Tutarsızlık raporu satırlarında ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'"), ObjectPresentation, SupplierPresentation);
	ElsIf DocumentType = "AcceptanceOfGoodsForStorageAdditionalDeliveryUponAcceptance" Then
		If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		Else
			ObjectPresentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần lập chứng từ ""%1"" theo hàng thiếu mà cần giao thêm. Đang lập chứng từ cho các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và dự kiến giao hàng bổ sung"".';
								|ru = 'Необходимо оформить документ ""%1"" по недостачам, для которых требуется допоставка. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и ожидать допоставку"".';
								|en = 'Register the ""%1"" document by the shortage that requires additional delivery. It is registered for discrepancy report lines with the ""Register and wait for subsequent delivery"" option.'; fa = 'Register the ""%1"" document by the shortage that requires additional delivery. It is registered for discrepancy report lines with the ""Register and wait for subsequent delivery"" option.';
								|it = 'È necessario formalizzare il documento ""%1"" per gli ammanchi per i quali è richiesta la consegna. Viene formalizzato nella stringa dell''atto di accettazione con riserva con variante di elaborazione ""Formalizzare e attendere la consegna"".';
								|pl = 'Konieczne jest wydanie dokumentu ""%1"" w przypadku braków wymagających dodatkowej dostawy. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i oczekuj dodatkowej dostawy"".';
								|tr = 'Ek teslimat gerektiren eksiklikler için bir ""%1"" belgesi düzenlenmelidir. Tutarsızlık raporu satırlarında  ""Düzenle ve ek teslimatları bekle"" seçeneği ile düzenlenmelidir.'"), ObjectPresentation);
	ElsIf DocumentType = "CorrectionOfReturnOfGoodsFromCustodian" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần điều chỉnh chứng từ ""%1"" bằng cách phản ánh vào đó số lượng thực tế. Cần thực hiện đối với các dòng của biên bản chênh lệch có tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
								|ru = 'Необходимо скорректировать документ ""%1"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и допоставить"".';
								|en = 'Correct the ""%1"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.'; fa = 'Correct the ""%1"" document by recording an actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and supply additionally"" tolling options.';
								|it = 'È necessario rettificare il documento ""%1"", riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con variante di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e consegnare la merce mancante"".';
								|pl = 'Należy skorygować dokument ""%1"", odzwierciedlając w nim faktyczną ilość. Należy to zrobić w wierszach protokołu o odchyleniu z wariantami opracowania: ""Zatwierdź i zwróć"", ""Zatwierdź"", ""Zatwierdź i dodaj"".';
								|tr = '""%1"" belgesi gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"", ""Düzenle"", ""Düzenle ve teslim et"" seçenekleri ile düzenlenmelidir.'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "DocumentCorrectionReceiptOfGoodsFromCustodian" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần tạo chỉnh sửa chứng từ ""%1"".';
								|ru = 'Необходимо оформить исправление документа ""%1"".';
								|en = 'Register a correction to the ""%1"" document.'; fa = 'Register a correction to the ""%1"" document.';
								|it = 'Register a correction to the ""%1"" document.';
								|pl = 'Register a correction to the ""%1"" document.';
								|tr = '""%1"" belgesinin düzeltmesi oluşturulmalıdır.'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "DocumentCorrectionGoodsReceiptForStorage" Then
		If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		Else
			ObjectPresentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần tạo chỉnh sửa chứng từ ""%1"".';
								|ru = 'Необходимо оформить исправление документа ""%1"".';
								|en = 'Register a correction to the ""%1"" document.'; fa = 'Register a correction to the ""%1"" document.';
								|it = 'Register a correction to the ""%1"" document.';
								|pl = 'Register a correction to the ""%1"" document.';
								|tr = '""%1"" belgesinin düzeltmesi oluşturulmalıdır.'"), ObjectPresentation);
	ElsIf DocumentType = "ReturnOfGoodsFromKeeperPreReturn" Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần lập chứng từ ""%1"" đối với hàng thiếu đã đánh dấu là nhận hàng trả lại từ khách hàng. Được thực hiện đối với các dòng của biên bản chênh lệch với phương án xử lý ""Lập chứng từ và chờ giao thêm"".';
								|ru = 'Необходимо оформить документ ""%1"" по недостачам, отмеченным к довозврату клиентом. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и ожидать допоставку"".';
								|en = 'Register document ""%1"" by shortages selected by a customer for additional return. It is registered for discrepancy report lines with processing option ""Register and wait for subsequent delivery"".'; fa = 'Register document ""%1"" by shortages selected by a customer for additional return. It is registered for discrepancy report lines with processing option ""Register and wait for subsequent delivery"".';
								|it = 'È necessario formalizzare il documento ""%1"" per gli ammanchi segnati dal cliente al reso. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e attendere la consegna della merce mancante"".';
								|pl = 'Należy utworzyć dokument ""%1"" według niedoborów, zaznaczonych do zwrotu przez klienta. Zatwierdzane jest na wiersze protokołu o odchyleniu z wariantem przetwarzania ""Utwórz i oczekuj na dodatkową dostawę"".';
								|tr = 'Müşteri tarafından yeniden teslimat için not edilen eksiklikler için bir ""%1"" belgesi düzenlenmelidir. Tutarsızlık raporu satırlarında ""Düzenle ve ek teslimatları bekle"" seçeneği ile düzenlenmelidir.'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "ReturnOfGoodsFromCustodianReturnToCustodian" Then
		PresentationOfDocument = NStr("vi = 'Chuyển giao hàng hóa cho bên lưu kho';
										|ru = 'Передача товаров хранителю';
										|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
										|it = 'Consegna di merci al depositario';
										|pl = 'Przekazanie towaru do magazyniera';
										|tr = 'Malların emanetçiye transferi'");
		If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
			PresentationOfDocument = NStr("vi = 'Chuyển giao nguyên liệu cho bên nhận gia công';
											|ru = 'Передача сырья переработчику';
											|en = 'Goods issue — Subcontracting services received'; fa = 'صدور کالا — خدمات پیمانکاری فرعی دریافتی';
											|it = 'Trasferimento di materie prime al subfornitore';
											|pl = 'Przenoszenie surowców do procesora';
											|tr = 'Hammaddelerin fason üreticiye transferi'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần lập chứng từ ""%1"" theo hàng thừa được đánh dấu để trả lại. Đang lập đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"".';
								|ru = 'Необходимо оформить документ ""%1"" по излишкам, отмеченным к возврату. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
								|en = 'Register the ""%1"" document of surpluses marked for return. Use the discrepancy report line with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""%1"" document of surpluses marked for return. Use the discrepancy report line with the ""Invoice the surplus and create Goods return"" tolling option.';
								|it = 'È necessario redigere il documento ""%1"" per eccedenze contrassegnate da rendere. Viene redatto nelle righe dell''atto sulle difformità con opzione di elaborazione ""Redigere e restituire"".';
								|pl = 'Konieczne jest wystawienie dokumentu ""%1"" według nadwyżek, zaznaczonych do zwrotu. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i zwróć"".';
								|tr = 'İade için işaretlenen fazlalıklar için bir ""%1"" belgesi düzenlenmelidir. Tutarsızlık raporu satırlarında ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'"), PresentationOfDocument);
	ElsIf DocumentType = "DocumentCorrectionTransferOfGoodsToCustodian" Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessTransactionOfCertificate);
		Return StrTemplate(NStr("vi = 'Cần tạo chỉnh sửa chứng từ ""%1"".';
								|ru = 'Необходимо оформить исправление документа ""%1"".';
								|en = 'Register a correction to the ""%1"" document.'; fa = 'Register a correction to the ""%1"" document.';
								|it = 'Register a correction to the ""%1"" document.';
								|pl = 'Register a correction to the ""%1"" document.';
								|tr = '""%1"" belgesinin düzeltmesi oluşturulmalıdır.'"), Handler.ObjectPresentation());
	ElsIf DocumentType = "PurchaseOfGoodsServicesAdditionalDeliveryUponReceipt" Then
		Return NStr("vi = 'Cần lập chứng từ ""Mua hàng hóa và dịch vụ"" đối với hàng thiếu cần giao thêm. Đang tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và dự tính giao thêm"".';
					|ru = 'Необходимо оформить документ ""Приобретение товаров и услуг"" по недостачам, для которых требуется допоставка. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и ожидать допоставку"".';
					|en = 'Register the ""Vendor invoice"" document for shortages that require additional delivery. It is registered for discrepancy report lines with the ""Register and wait for subsequent delivery"" processing option.'; fa = 'Register the ""Vendor invoice"" document for shortages that require additional delivery. It is registered for discrepancy report lines with the ""Register and wait for subsequent delivery"" processing option.';
					|it = 'È necessario formalizzare il documento ""Acquisto delle merci e servizi"" per gli ammanchi per i quali è richiesta la consegna aggiuntiva. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e attendere la consegna della merce mancante"".';
					|pl = 'Konieczne jest wykonanie dokumentu ""Zakup towarów i usług"" z powodu niedoborów, dla których wymagana jest dodatkowa dostawa. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i oczekuj dodatkowej dostawy"".';
					|tr = 'Ek teslimat gerektiren eksiklikler için bir ""Satın alma faturası"" belgesinin düzenlenmesi gereklidir. Tutarsızlık raporu satırlarında ""Düzenle ve ek teslimatları bekle"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "ReceiptOfGoodsAdditionalDeliveryUponReceipt" Then
		Return NStr("vi = 'Cần lập chứng từ ""Tiếp nhận hàng hóa"" theo hàng thiếu cần giao thêm. Đang lập chứng từ cho các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và dự kiến giao hàng bổ sung"".';
					|ru = 'Необходимо оформить документ ""Поступление товаров"" по недостачам, для которых требуется допоставка. Оформляется на строки акта о расхождениях с вариантами отработки ""Оформить и ожидать допоставку"", ""Ожидать допоставку без оформления"".';
					|en = 'Register the ""Warehouse receipt"" document for shortages that require additional delivery. It is registered for discrepancy report lines with the ""Register and wait for subsequent delivery"" and ""Wait for subsequent delivery without registration"" processing options.'; fa = 'Register the ""Warehouse receipt"" document for shortages that require additional delivery. It is registered for discrepancy report lines with the ""Register and wait for subsequent delivery"" and ""Wait for subsequent delivery without registration"" processing options.';
					|it = 'Необходимо оформить документ ""Поступление товаров"" по недостачам, для которых требуется допоставка. Оформляется на строки акта о расхождениях с вариантами отработки ""Оформить и ожидать допоставку"", ""Ожидать допоставку без оформления"".';
					|pl = 'Register the ""Warehouse receipt"" document for shortages that require additional delivery. It is registered for discrepancy report lines with the ""Register and wait for subsequent delivery"" and ""Wait for subsequent delivery without registration"" processing options.';
					|tr = 'Ek teslimat gerektiren eksiklikler için ""İrsaliye"" belgesinin düzenlenmesi gerekmektedir. Tutarsızlık raporu satırlarında ""Düzenle ve ek teslimatı bekle"", ""Düzenlemeden ek teslimatı bekle"" işleme seçenekleriyle düzenlenmektedir.'");
	ElsIf DocumentType = "InventoryTransfer" Then
		Return NStr("vi = 'Cần lập chứng từ ""Điều chuyển hàng hóa nội bộ"" để giao thêm hàng hóa chưa được giao thêm đến kho nhận. Đang tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"", ""Lập chứng từ"".';
					|ru = 'Необходимо оформить документ ""Перемещение товаров"" на допоставку недопоставленного товара на склад-получатель. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"", ""Оформить"".';
					|en = 'Register the ""Goods transfer"" document for subsequent delivery of underdelivered products to destination warehouse. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"",  ""Invoice the surplus"" tolling options.'; fa = 'Register the ""Goods transfer"" document for subsequent delivery of underdelivered products to destination warehouse. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"",  ""Invoice the surplus"" tolling options.';
					|it = 'È necessario formalizzare il documento ""Trasferimento delle merci"" per la consegna aggiuntiva delle merci mancanti al magazzino-destinatario. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"".';
					|pl = 'Konieczne jest wydanie dokumentu ""Przemieszczenie towarów"" w celu dodatkowej dostawy niedostarczonych towarów do magazynu odbiorczego. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i zwróć"", ""Zatwierdź"".';
					|tr = 'Eksik teslim edilen malların hedef ambara ek teslimatı için ""Mal transferi"" belgesi düzenlenmelidir. Tutarsızlık raporu satırlarında"" Düzenle ve iade et"", ""Düzenle"" seçeneği ile tutarsızlık raporu satırlarında düzenlenmelidir.'");
	ElsIf DocumentType = "MovementOfGoodsReturn" Then
		Return NStr("vi = 'Cần tạo chứng từ ""Điều chuyển hàng hóa nội bộ"" để nhận lại hàng thừa từ kho nhận sang kho gửi. Đang tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"".';
					|ru = 'Необходимо оформить документ ""Перемещение товаров"" на возврат излишков со склада-получателя на склад-отправитель. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
					|en = 'Register the ""Goods transfer"" document for surpluses return from a destination warehouse to an origin warehouse. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Goods transfer"" document for surpluses return from a destination warehouse to an origin warehouse. It is registered for discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
					|it = 'È necessario formalizzare il documento ""Trasferimento delle merci"" per il reso delle eccedenze dal magazzino-destinatario al magazzino-mittente. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e restituire"".';
					|pl = 'Konieczne jest wydanie dokumentu ""Przemieszczenie towarów"" w celu zwrotu nadwyżki z magazynu odbiorcy do magazynu nadawcy. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i zwróć"".';
					|tr = 'İhtiyaç fazlası malların hedef ambardan çıkış ambarına iadesi için ""Mal Transferi"" belgesinin düzenlenmesi gerekmektedir. Tutarsızlık raporu satırlarında ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "WriteOffOfGoodsShortages" Then
		If BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
			Return NStr("vi = 'Cần tạo chứng từ ""Ghi giảm hàng thiếu"" để ghi giảm hàng thiếu chưa được công nhận. Đang tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Ghi giảm hàng thiếu"".';
						|ru = 'Необходимо оформить документ ""Списание недостач товаров"" для списания  непризнанных недостач. Оформляется на строки акта о расхождениях с вариантом отработки ""Списать недостачи"".';
						|en = 'Register the ""Stock shortage recognition"" document to write-off unrecognized shortages. It is registered in discrepancy report lines with the ""Write-off shortages"" processing option.'; fa = 'Register the ""Stock shortage recognition"" document to write-off unrecognized shortages. It is registered in discrepancy report lines with the ""Write-off shortages"" processing option.';
						|it = 'È necessario formalizzare il documento ""Cancellazione della quantità mancante di merci"" per cancellare gli ammanchi non riconosciuti. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione ""Cancellare gli ammanchi"".';
						|pl = 'Konieczne jest wydanie dokumentu „Odpisanie niedoborów towarów” w celu odpisania nierozpoznanych braków. Wydany na linii protokołu o odchyleniu z opcją wyłączenia „Odłóż niedobory”.';
						|tr = 'Tanınmayan eksikliklerin gider yazılması için bir ""Mal eksikliklerinin gider yazılması"" belgesi düzenlenmelidir. Tutarsızlık raporu satırlarında ""Eksikliklerin gider yazılması"" seçeneği ile düzenlenmelidir.'");
		Else
			Return NStr("vi = 'Cần tạo chứng từ ""Ghi giảm hàng thiếu"" để ghi giảm hàng thiếu chưa được công nhận vào chi phí khác. Đang tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Do lỗi của công ty bên thứ ba"", hoặc ""Vào chi phí của doanh nghiệp"".';
						|ru = 'Необходимо оформить документ ""Списание недостач товаров"" для списания на прочие расходы непризнанных недостач. Оформляется на строки акта о расхождениях с вариантом отработки ""По вине сторонней компании"" или ""За наш счет"".';
						|en = 'Register ""Stock shortage recognition"" to write off unrecognized shortages as other expenses. It is registered for discrepancy report lines with processing option ""Due to the fault of the third party"" or ""At our expense"".'; fa = 'Register ""Stock shortage recognition"" to write off unrecognized shortages as other expenses. It is registered for discrepancy report lines with processing option ""Due to the fault of the third party"" or ""At our expense"".';
						|it = 'È necessario formalizzare il documento ""Cancellazione degli ammanchi delle merci"" per stornare gli ammanchi non riconosciuti sulle spese varie. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Per colpa di una società esterna"" o ""A nostre spese"".';
						|pl = 'Konieczne jest wystawienie dokumentu ""Odpisanie niedoborów towarów"" za spisanie innych wydatków związanych z nierozpoznanym brakiem. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Wina po stronie innej firmy"" lub ""Na nasz koszt"".';
						|tr = 'Muhasebeleştirilmemiş eksikliklerin diğer giderlere yazılması için bir ""Mal eksikliklerinin gider yazılması"" belgesinin düzenlenmesi gerekmektedir. Tutarsızlık raporu satırlarında ""Üçüncü taraf hatası"" veya ""Masraflar bize ait"" seçenekleriyle düzenlenmelidir.'");
		EndIf;
	ElsIf DocumentType = "ReceiptOfGoodsRepostingAfterAdjustment" Then
		Return NStr("vi = 'Cần kết chuyển chứng từ ""Tiếp nhận hàng hóa"" để phản ánh các thay đổi hiện có sau khi tạo chứng từ ""Điều chỉnh mua lại""';
					|ru = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений имеющихся после оформления документа ""Корректировка приобретения""';
					|en = 'Repost the ""Receipt of goods"" document to record the changes that occurred after registering the ""Purchase adjustment"" document'; fa = 'Repost the ""Receipt of goods"" document to record the changes that occurred after registering the ""Purchase adjustment"" document';
					|it = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений имеющихся после оформления документа ""Корректировка приобретения""';
					|pl = 'Repost the ""Receipt of goods"" document to record the changes that occurred after registering the ""Purchase adjustment"" document';
					|tr = '""Edinim düzeltmesi"" belgesinin düzenlenmesinden sonra mevcut değişiklikleri yansıtmak için ""İrsaliye"" belgesinin yeniden işlenmesi gerekmektedir'");
	ElsIf DocumentType = "ReceiptOfGoodsRepostingAfterPurchase" Then
		Return NStr("vi = 'Cần kết chuyển chứng từ ""Tiếp nhận hàng hóa"" để phản ánh các thay đổi đã nhập vào chứng từ ""Điều chỉnh mua lại""';
					|ru = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений внесенных в документ ""Приобретение товаров""';
					|en = 'Repost the ""Receipt of goods"" document to record the changes made in the ""Vendor invoice"" document'; fa = 'Repost the ""Receipt of goods"" document to record the changes made in the ""Vendor invoice"" document';
					|it = 'Требуется перепровести документ ""Поступление товаров"" для отражения изменений внесенных в документ ""Приобретение товаров""';
					|pl = 'Repost the ""Receipt of goods"" document to record the changes made in the ""Vendor invoice"" document';
					|tr = '""Ürün edinimi"" belgesinde yapılan değişiklikleri yansıtmak için ""İrsaliye"" belgesinin yeniden işlenmesi gerekmektedir'");
	ElsIf DocumentType = "ARAPAdjustment" Then
		Return NStr("vi = 'Cần lập chứng từ ""Điều chỉnh công nợ"" để phản ánh công nợ của nhà cung cấp về hàng thiếu do lỗi của bên đó. Điều này được thực hiện đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Ghi giảm vào tài khoản của nhà cung cấp"".';
					|ru = 'Необходимо оформить документ ""Корректировка задолженности"" для отражения задолженности поставщика по недостачам, произошедшим по его вине. Оформляется на строки акта о расхождениях с вариантом отработки ""Списать за счет поставщика"".';
					|en = 'Register the ""AR/AP adjustment"" document to record vendor''s payables for shortages that occurred due to their fault. Register the document for discrepancy report lines with the ""Write off at vendor''s expense"" processing option.'; fa = 'Register the ""AR/AP adjustment"" document to record vendor''s payables for shortages that occurred due to their fault. Register the document for discrepancy report lines with the ""Write off at vendor''s expense"" processing option.';
					|it = 'Необходимо оформить документ ""Корректировка задолженности"" для отражения задолженности поставщика по недостачам, произошедшим по его вине. Оформляется на строки акта о расхождениях с вариантом отработки ""Списать за счет поставщика"".';
					|pl = 'Register the ""AR/AP adjustment"" document to record vendor''s payables for shortages that occurred due to their fault. Register the document for discrepancy report lines with the ""Write off at vendor''s expense"" processing option.';
					|tr = 'Tedarikçinin kendi hatasından kaynaklanan eksikliklere ilişkin borcunu yansıtacak şekilde ""Borç düzeltmesi"" belgesinin düzenlenmesi gerekmektedir. Tutarsızlık raporu doğrultusunda ""Tedarikçinin hesabına yaz"" seçeneği ile düzenlenir.'");
	ElsIf DocumentType = "InventorySurplusRecognition" Then
		Return NStr("vi = 'Cần lập chứng từ ""Ghi tăng hàng hóa"" để ghi tăng hàng hóa. Được thực hiện đối với dòng của biên bản chênh lệch với tùy chọn xử lý ""Đối với thu nhập khác"".';
					|ru = 'Необходимо оформить документ ""Оприходование излишков товаров"" для оприходования излишков товаров. Оформляется на строки акта о расхождениях с вариантом отработки ""На прочие доходы"".';
					|en = 'Register document ""Stock surplus recognition"" to record as received goods surpluses. It is registered in discrepancy report lines with processing option ""For income"".'; fa = 'Register document ""Stock surplus recognition"" to record as received goods surpluses. It is registered in discrepancy report lines with processing option ""For income"".';
					|it = 'È necessario formalizzare il documento ""Presa in carico delle eccedenze di merce"" per prendere in carico le eccedenze delle merci. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Sui ricavi diversi"".';
					|pl = 'Konieczne jest wydanie dokumentu ""Nadwyżki towarów"" do księgowania nadwyżek towarów. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją wypracowania ""O innych dochodach"". ';
					|tr = 'Stok fazlası tahakkuku için ""Stok fazlası tahakkuku"" belgesi düzenlenmesi gerekmektedir. Tutarsızlık raporunun satırlarında ""Diğer Gelirler"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "CorrectionOfReceipt" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Mua hàng hóa và dịch vụ"" bằng cách phản ánh số lượng thực tế. Cần thực hiện đối với dòng của biên bản chênh lệch với tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và đợi giao thêm"".';
					|ru = 'Необходимо скорректировать документ ""Приобретение товаров и услуг"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и ожидать допоставку"".';
					|en = 'Correct the ""Vendor invoice"" document by recording an actual quantity in it. Make the changes to discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and wait for subsequent delivery"" tolling options.'; fa = 'Correct the ""Vendor invoice"" document by recording an actual quantity in it. Make the changes to discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", ""Register and wait for subsequent delivery"" tolling options.';
					|it = 'È necessario rettificare il documento ""Acquisto delle merci e servizi"" riportandone la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le versioni di elaborazione: ""Formalizzare e restituire"", ""Formalizzare"" e ""Formalizzare e attendere la consegna aggiuntiva"".';
					|pl = 'Konieczne jest skorygowanie dokumentu ""Zakup towarów i usług"", odzwierciedlając w nim faktyczną kwotę. Należy zatwierdzić na wiersze protokołu o odchyleniu z opcją opracowania: ""Zatwierdź i odeślij"", ""Zatwierdź"", ""Zatwierdź i oczekuj dodatkowej dostawy"".';
					|tr = '""Satın alma faturası"" belgesi gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları aşağıdaki çözüm seçenekleriyle düzenlenmelidir: ""Düzenle ve iade et"", ""Düzenle"", ""Düzenle ve ek teslimat bekle"".'");
	ElsIf DocumentType = "ChangeInReceiptOfGoods" Then
		Return NStr("vi = 'Cần điều chỉnh chứng từ ""Tiếp nhận hàng hóa vào kho"" bằng cách phản ánh số lượng thực tế trong đó. Cần thực hiện đối với dòng của biên bản chênh lệch với tùy chọn xử lý: ""Trả lại không có lập chứng từ"", ""Đối với thu nhập khác"", ""Ghi giảm vào tài khoản của doanh nghiệp"", ""Ghi giảm vào tài khoản của doanh nghiệp bên ngoài"".';
					|ru = 'Необходимо скорректировать документ ""Поступление товаров на склад"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Вернуть без оформления"", ""На прочие доходы"", ""Списать за наш счет"", ""Списать за счет сторонней компании"".';
					|en = 'The ""Warehouse receipt"" document must be adjusted by recording the actual quantity. This must be done for the discrepancy report lines with the processing options: ""Return the surplus"", ""For income"", ""Write off at our expense"", ""Write off at the expense of a third party"".'; fa = 'The ""Warehouse receipt"" document must be adjusted by recording the actual quantity. This must be done for the discrepancy report lines with the processing options: ""Return the surplus"", ""For income"", ""Write off at our expense"", ""Write off at the expense of a third party"".';
					|it = 'È necessario rettificare il documento ""Arrivo delle merci nel magazzino"", riportando nel documento la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le opzioni di elaborazione: ""Restituire senza registrare"", ""Per altre entrate"", ""Stornare a nostre spese"", ""Stornare a spese di un''altra società"".';
					|pl = 'Konieczne skorygowanie dokumentu ""Wpływ towarów do magazynu"", odzwierciedlającego ilość faktyczną. Należy to zrobić w wierszach protokołu o odchyleniu z wariantami do pracy: ""Zwróć bez sporządzenia"", ""Na inne dochody"",  ""Rozchoduj na nasz koszt"", ""Rozchoduj na koszt firmy zewnętrznej"".';
					|tr = '""Ambara mal girişi"" belgesi, içindeki gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları aşağıdaki çözüm seçenekleriyle düzenlenmelidir: ""İşlem yapılmadan iade"", ""Diğer gelire"", ""Bizim giderimize yazılsın"", ""Üçüncü taraf firmanın giderine yazılsın"".'");
	ElsIf DocumentType = "AdjustmentOfGoodsReceipts" Then
		Return NStr("vi = 'Cần nhập chứng từ điều chỉnh ""Tiếp nhận hàng hóa vào kho"" bằng cách phản ánh số lượng thực tế trong đó. Cần thực hiện đối với các dòng của biên bản chênh lệch với các phương án xử lý: ""Trả lại không lập chứng từ"", ""Đối với thu nhập khác"", ""Ghi giảm vào tài khoản doanh nghiệp"", ""Ghi giảm vào tài khoản của doanh nghiệp bên ngoài"".';
					|ru = 'Необходимо ввести корректировочный документ ""Поступление товаров на склад"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Вернуть без оформления"", ""На прочие доходы"", ""Списать за наш счет"", ""Списать за счет сторонней компании"".';
					|en = 'The ""Warehouse receipt"" adjustment document must be entered with recording the actual quantity. This must be done for the discrepancy report lines with the processing options: ""Return the surplus"", ""For income"", ""Write off at our expense"", ""Write off at the expense of a third party"".'; fa = 'The ""Warehouse receipt"" adjustment document must be entered with recording the actual quantity. This must be done for the discrepancy report lines with the processing options: ""Return the surplus"", ""For income"", ""Write off at our expense"", ""Write off at the expense of a third party"".';
					|it = 'È necessario inserire il documento di rettifica ""Arrivo delle merci nel magazzino"", riportando nel documento la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le opzioni di elaborazione: ""Restituire senza registrare"", ""Per altre entrate"", ""Stornare a nostre spese"", ""Stornare a spese di un''altra società"".';
					|pl = 'Konieczne jest wprowadzenie dokumentu korygującego ""Wpływ towarów do magazynu"", odzwierciedlającego ilość faktyczną. Należy to zrobić w wierszach protokołu o odchyleniu z wariantami do pracy: ""Zwróć bez sporządzenia"", ""Na inne dochody"", ""Rozchoduj na nasz koszt"", ""Rozchoduj na koszt firmy zewnętrznej"".';
					|tr = '""Ambara mal girişi"" belgesi, içindeki gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları aşağıdaki çözüm seçenekleriyle düzenlenmelidir: ""İşlem yapılmadan iade"", ""Diğer gelire"", ""Bizim giderimize yazılsın"", ""Üçüncü taraf firmanın giderine yazılsın"".'");
	ElsIf DocumentType = "AdjustmentOfReceiptOfGoodsCorrections" Then
		Return NStr("vi = 'Cần nhập chứng từ điều chỉnh ""Tiếp nhận hàng hóa vào kho"" bằng cách phản ánh số lượng thực tế trong đó. Cần thực hiện đối với các dòng của biên bản chênh lệch với các phương án xử lý: ""Trả lại không lập chứng từ"", ""Đối với thu nhập khác"", ""Ghi giảm vào tài khoản doanh nghiệp"", ""Ghi giảm vào tài khoản của doanh nghiệp bên ngoài"".';
					|ru = 'Необходимо ввести корректировочный документ ""Поступление товаров на склад"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Вернуть без оформления"", ""На прочие доходы"", ""Списать за наш счет"", ""Списать за счет сторонней компании"".';
					|en = 'The ""Warehouse receipt"" adjustment document must be entered with recording the actual quantity. This must be done for the discrepancy report lines with the processing options: ""Return the surplus"", ""For income"", ""Write off at our expense"", ""Write off at the expense of a third party"".'; fa = 'The ""Warehouse receipt"" adjustment document must be entered with recording the actual quantity. This must be done for the discrepancy report lines with the processing options: ""Return the surplus"", ""For income"", ""Write off at our expense"", ""Write off at the expense of a third party"".';
					|it = 'È necessario inserire il documento di rettifica ""Arrivo delle merci nel magazzino"", riportando nel documento la quantità effettiva. Deve essere eseguito per le righe dell''atto sulle discrepanze con le opzioni di elaborazione: ""Restituire senza registrare"", ""Per altre entrate"", ""Stornare a nostre spese"", ""Stornare a spese di un''altra società"".';
					|pl = 'Konieczne jest wprowadzenie dokumentu korygującego ""Wpływ towarów do magazynu"", odzwierciedlającego ilość faktyczną. Należy to zrobić w wierszach protokołu o odchyleniu z wariantami do pracy: ""Zwróć bez sporządzenia"", ""Na inne dochody"", ""Rozchoduj na nasz koszt"", ""Rozchoduj na koszt firmy zewnętrznej"".';
					|tr = '""Ambara mal girişi"" belgesi, içindeki gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları aşağıdaki çözüm seçenekleriyle düzenlenmelidir: ""İşlem yapılmadan iade"", ""Diğer gelire"", ""Bizim giderimize yazılsın"", ""Üçüncü taraf firmanın giderine yazılsın"".'");
	ElsIf DocumentType = "WriteOffDiscrepanciesBetweenReceiptAndPurchase" Then
		Return NStr("vi = 'Cần tạo chứng từ ""Ghi giảm chênh lệch giữa tiếp nhận và mua hàng"" bằng cách phản ánh chênh lệch trong đó. Cần thực hiện đối với các dòng biên bản chênh lệch với phương án xử lý: ""Đối với thu nhập khác"", ""Ghi giảm vào tài khoản doanh nghiệp"", ""Ghi giảm vào tài khoản của doanh nghiệp bên ngoài"".';
					|ru = 'Необходимо оформить документ ""Списание расхождений между поступлением и приобретением"", отразив в нем расхождения. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""На прочие доходы"", ""Списать за наш счет"", ""Списать за счет сторонней компании"".';
					|en = 'Register the ""Write off discrepancies between receipt and purchase"" document to record discrepancies in it. Register the document for discrepancy report lines with the processing options: For income, Write off at our expense, Write off at the expense of a third party.'; fa = 'Register the ""Write off discrepancies between receipt and purchase"" document to record discrepancies in it. Register the document for discrepancy report lines with the processing options: For income, Write off at our expense, Write off at the expense of a third party.';
					|it = 'Необходимо оформить документ ""Списание расхождений между поступлением и приобретением"", отразив в нем расхождения. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""На прочие доходы"", ""Списать за наш счет"", ""Списать за счет сторонней компании"".';
					|pl = 'Register the ""Write off discrepancies between receipt and purchase"" document to record discrepancies in it. Register the document for discrepancy report lines with the processing options: For income, Write off at our expense, Write off at the expense of a third party.';
					|tr = '""Giriş ve edinme arasındaki tutarsızlıkların gider yazılması"" belgesini, içindeki tutarsızlıkları yansıtarak düzenlemek gerekmektedir. Tutarsızlık raporunun satırları için aşağıdaki seçeneklerle düzenlenmesi gerekmektedir: ""Diğer gelirlere"", ""Hesabımıza yaz"", ""Üçüncü taraf bir şirketin hesabına yaz"".'");
	ElsIf DocumentType = "CorrectionOfAcceptanceOfGoodsForStorage" Then
		If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		Else
			ObjectPresentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
										|ru = 'Приемка товаров на хранение';
										|en = 'VMI procurement'; fa = 'تدارکات VMI';
										|it = 'Accettazione delle merci per il deposito';
										|pl = 'Przyjęcie towarów do przechowania';
										|tr = 'Malların depoya girişi'");
		EndIf;
		Return StrTemplate(NStr("vi = 'Cần điều chỉnh chứng từ ""%1"", bằng cách phản ánh số lượng thực tế trong đó. Cần thực hiện đối với các dòng biên bản chênh lệch có tùy chọn xử lý: ""Lập chứng từ và trả lại"", ""Lập chứng từ"", ""Lập chứng từ và giao thêm"".';
								|ru = 'Необходимо скорректировать документ ""%1"", отразив в нем количество по факту. Следует выполнить для строк акта о расхождениях с вариантами отработки: ""Оформить и вернуть"", ""Оформить"", ""Оформить и ожидать допоставку"".';
								|en = 'Correct the ""%1"" document by recording the actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and wait for subsequent delivery"" tolling options.'; fa = 'Correct the ""%1"" document by recording the actual quantity in it. Make the changes to the discrepancy report lines with the ""Invoice the surplus and create Goods return"", ""Invoice the surplus"", and ""Register and wait for subsequent delivery"" tolling options.';
								|it = 'È necessario correggere il documento ""%1"", riflettendo in esso la quantità effettiva. Occorre eseguire per le stringhe un atto di accettazione con riserva con varianti di elaborazione: ""Formalizzare ed effettuare il reso"", ""Formalizzare"", ""Formalizzare e attendere la consegna"".';
								|pl = 'Należy skorygować dokument ""%1"", odzwierciedlając w nim faktyczną ilość. Należy to zrobić w wierszach protokołu o odchyleniu z wariantami opracowania: ""Zatwierdź i zwróć"", ""Zatwierdź"", ""Zatwierdź i oczekuj dodatkowej dostawy"".';
								|tr = '""%1"" belgesi gerçek miktarı yansıtacak şekilde düzenlenmelidir. Tutarsızlık raporu satırları ""Düzenle ve iade et"", ""Düzenle"", ""Düzenle ve ek teslimat için bekle"" seçenekleri ile düzenlenmelidir.'"), ObjectPresentation);
	ElsIf DocumentType = "ReturnOfGoodsToSupplierUponReceipt" Then
		Return NStr("vi = 'Cần lập chứng từ ""Trả lại hàng hóa cho nhà cung cấp"", đối với hàng hóa được giao lại được đánh dấu để trả lại cho nhà cung cấp. Được tạo đối với các dòng của biên bản chênh lệch với tùy chọn xử lý ""Lập chứng từ và trả lại"".';
					|ru = 'Необходимо оформить документ ""Возврат товаров поставщику"" по перепоставленному товару, отмеченному к возврату поставщику. Оформляется на строки акта о расхождениях с вариантом отработки ""Оформить и вернуть"".';
					|en = 'Register the ""Return of goods to vendor"" document for overdelivered goods marked for return to the vendor. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.'; fa = 'Register the ""Return of goods to vendor"" document for overdelivered goods marked for return to the vendor. It is registered in discrepancy report lines with the ""Invoice the surplus and create Goods return"" tolling option.';
					|it = 'È necessario formalizzare il documento ""Spedizione delle merci al fornitore"" per le merci fornite in eccesso segnate per il reso al fornitore. Viene formalizzato sulle righe dell''atto sulle discrepanze con la versione di elaborazione: ""Formalizzare e restituire"".';
					|pl = 'Konieczne jest wystawienie dokumentu ""Zwrot towarów dostawcy"" na ponownie dostarczone towary, oznaczone do zwrotu do dostawcy. Zatwierdzane jest na wiersze protokołu o odchyleniu z opcją opracowania ""Zatwierdź i odeślij"". ';
					|tr = 'Tedarikçiye iade edilmek üzere işaretlenmiş fazla tedarik edilen mallar için ""Malların tedarikçiye iadesi"" belgesinin düzenlenmesi gerekmektedir. Tutarsızlık raporunun satırlarında ""Düzenle ve iade et"" seçeneği ile düzenlenmelidir.'");
	ElsIf DocumentType = "ElectronicDocumentConfirmation" Then
		Return NStr("vi = 'Cần phải xác nhận chứng từ điện tử đã nhận, vì chứng từ ""Điều chỉnh mua hàng"" được lập ra để phản ánh sự chênh lệch.';
					|ru = 'Необходимо подтвердить полученный электронный документ, так как для отражения расхождения оформляется документ ""Корректировка приобретения"".';
					|en = 'Confirm the received electronic document, as the ""Purchase adjustment"" document is registered to record a discrepancy.'; fa = 'Confirm the received electronic document, as the ""Purchase adjustment"" document is registered to record a discrepancy.';
					|it = 'Необходимо подтвердить полученный электронный документ, так как для отражения расхождения оформляется документ ""Корректировка приобретения"".';
					|pl = 'Confirm the received electronic document, as the ""Purchase adjustment"" document is registered to record a discrepancy.';
					|tr = 'Tutarsızlığı yansıtmak için ""Satın alım tahsisi"" belgesi düzenlendiğinden dolayı alınan elektronik belgenin onaylanması gerekmektedir.'");
	ElsIf DocumentType = "ElectronicDocumentRejection" Then
		Return NStr("vi = 'Cần phải từ chối chứng từ điện tử nhận được, vì chứng từ nhận ban đầu được thay đổi để phản ánh sự khác biệt.';
					|ru = 'Необходимо отклонить полученный электронный документ, так как для отражения расхождения изменяется исходный документ поступления.';
					|en = 'Reject received electronic document, as the original document for incoming payments is changed to record a discrepancy.'; fa = 'Reject received electronic document, as the original document for incoming payments is changed to record a discrepancy.';
					|it = 'È necessario rifiutare il documento elettronico ricevuto, in quanto per rilevare la discrepanza il documento originario di accettazione viene modificato.';
					|pl = 'Konieczne jest odchylenie otrzymanego dokumentu elektronicznego, ponieważ oryginalny dokument odbioru zmienia się w celu odzwierciedlenia odchylenia.';
					|tr = 'Alınan elektronik belge reddedilmelidir çünkü orijinal makbuz belgesi tutarsızlığı yansıtacak şekilde değiştirilmiştir.'");
	ElsIf DocumentType = "Claim" Then
		Return NStr("vi = 'Cần tạo phần tử danh mục ""Khiếu nại"" để phản ánh hạch toán với nhà cung cấp về chênh lệch.';
					|ru = 'Необходимо создать элемент справочника ""Претензии"" для отражения расчетов с поставщиком по расхождениям.';
					|en = 'Create a Complaints catalog item to record AR/AP with the vendor for discrepancies.'; fa = 'Create a Complaints catalog item to record AR/AP with the vendor for discrepancies.';
					|it = 'Необходимо создать элемент справочника ""Претензии"" для отражения расчетов с поставщиком по расхождениям.';
					|pl = 'Create a Complaints catalog item to record AR/AP with the vendor for discrepancies.';
					|tr = 'Tutarsızlıklar için tedarikçiyle yapılan sözleşmeleri yansıtacak ""Şikayetler"" kataloğunun öğesini oluşturmanız gerekmektedir.'");
	EndIf;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure DisplayLegendWhenChangingOnServer()
	
	Common.CommonSettingsStorageSave("DataProcessor.ProcessingOfDiscrepancyReports", "DisplayLegend", DisplayLegend);
	
EndProcedure

&AtClient
Procedure AvailabilityControl()

	Items.SpreadsheetDocument.ReadOnly = HasError;

EndProcedure 

&AtServer
Function NotOutputToReport(Name, Ref, AdditionalParameter = Undefined)
	
	Filter = New Structure(
		"Name, Ref, AdditionalParameter", Name, Ref, AdditionalParameter);
	
	FoundRows = OutputDocuments_.FindRows(Filter);
	If FoundRows.Count() > 0 Then
		Return True;
	EndIf;
	
	FillPropertyValues(OutputDocuments_.Add(), Filter);
	
	Return False;
	
EndFunction

&AtServerNoContext
Function StructuresForDescribingActionDisplayedInReport()
	
	DetailsStructure1 = New Structure(
	                 "BasisOfAct, DiscrepancyCertificate, CommandName, PossibleAction,
	                 |ReflectionMethod, Warehouse, WithdrawWarehouse, DocumentEDI, EDIStatus, OrderDocument, AmountOfShortDelivery, AmountOfReDelivery");
	
	DetailsStructure1.WithdrawWarehouse = False;
	
	Return DetailsStructure1;
	
EndFunction

// Constructor for the table of documents to be processed.
// 
// Returns:
// 	ValueTable - LongDesc:
// * DocumentKind           - String - type of document to be issued.
// * Warehouse                  - CatalogRef.Warehouses - warehouse of the document being processed.
// * RegisteredDocuments   - Array - legalize papers. 
// * LongDesc               - String - description of the design action. 
//
&AtServer
Function NewDocumentsIssuedUnderAct()
	
	TypeArray    = New TypeDescription("Array");
	StructureType = New TypeDescription("Structure");
	WarehouseType_     = New TypeDescription("CatalogRef.Warehouses");
	StringType    = New TypeDescription("String", , New StringQualifiers(100));
	
	IssuedDocumentsOnAct = New ValueTable;
	IssuedDocumentsOnAct.Columns.Add("DocumentKind",         StringType);
	IssuedDocumentsOnAct.Columns.Add("Warehouse",                WarehouseType_);
	IssuedDocumentsOnAct.Columns.Add("RegisteredDocuments", TypeArray);
	IssuedDocumentsOnAct.Columns.Add("LongDesc",             StructureType);
	
	Return IssuedDocumentsOnAct;
	
EndFunction

&AtServer
Function RequestTextReportOfDiscrepanciesAfterShipmentOfGoodsFromStorage()

	Return "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Action         AS Action,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices       AS GoodsShipmentFromStorage
	|
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	Actions.Action                          AS Action,
	|	Actions.DiscrepancyTreatment                  AS DiscrepancyTreatment,
	|	Actions.GoodsShipmentFromStorage          AS Basis,
	|	FALSE                                       AS ThirdPartyIsGuilty,
	|	Actions.GoodsShipmentFromStorage.ByOrder AS ByOrders,
	|	UNDEFINED                               AS OrderDocument
	|FROM
	|	Actions AS Actions
	|TOTALS BY
	|	GoodsShipmentFromStorage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED DISTINCT
	|	GoodsReceiptForStorage.SubsequentDeliveryByDocument AS Basis,
	|	GoodsReceiptForStorage.Ref                   AS GoodsReceiptForStorage
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|		INNER JOIN Actions AS Actions
	|		ON GoodsReceiptForStorage.SubsequentDeliveryByDocument = Actions.GoodsShipmentFromStorage
	|WHERE
	|	GoodsReceiptForStorage.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT ALLOWED DISTINCT
	|	Document.Ref AS GoodsShipmentFromStorage,
	|	Document.AdditionalReturnWithinGoodsReturn AS Basis
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.GoodsShipmentFromStorage AS Document
	|		ON (Document.Posted)
	|			AND Actions.GoodsShipmentFromStorage = Document.AdditionalReturnWithinGoodsReturn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT ALLOWED DISTINCT
	|	Actions.GoodsShipmentFromStorage AS GoodsShipmentFromStorage,
	|	Document.Ref AS ShipmentOfGoodsFromStorageCorrection
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.GoodsShipmentFromStorage AS Document
	|		ON Document.Posted
	|			AND (Actions.GoodsShipmentFromStorage = Document.CorrectedDocument
	|				OR (Actions.GoodsShipmentFromStorage = Document.ReversedDocument
	|					AND Actions.GoodsShipmentFromStorage.CorrectedDocument = Document.CorrectedDocument))";
	
EndFunction

&AtServer
Function TextOfRequestReportOnDiscrepanciesAfterAcceptanceOfGoodsForStorage(TableAccessRights, MatchingDataSets)
	
	CurrentNumber = 1;
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action                AS Action,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis       AS Basis,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse                   AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ThirdPartyIsGuilty AS ThirdPartyIsGuilty
	|
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED DISTINCT
	|	Actions.Action                       AS Action,
	|	Actions.Basis                      AS Basis,
	|	Actions.ThirdPartyIsGuilty        AS ThirdPartyIsGuilty,
	|	Actions.Basis.ReceiptUnderOrders AS ByOrders,
	|	Actions.Warehouse                          AS Warehouse,
	|	UNDEFINED                            AS OrderDocument
	|FROM
	|	Actions AS Actions
	|
	|TOTALS BY
	|	Basis
	|";
	
	If TableAccessRights.ReadingShippingGoodsFromStorage Then
		
		CurrentNumber = CurrentNumber + 1;
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	GoodsShipmentFromStorage.Basis AS Basis,
		|	GoodsShipmentFromStorage.Ref    AS ShipFromStorage,
		|	GoodsShipmentFromStorage.Warehouse     AS Warehouse
		|FROM
		|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
		|		INNER JOIN Actions AS Actions
		|		ON GoodsShipmentFromStorage.Posted
		|			AND GoodsShipmentFromStorage.Basis = &DiscrepancyCertificate
		|			AND GoodsShipmentFromStorage.Warehouse = Actions.Warehouse";
		
		MatchingDataSets.Insert("ShipmentBases", CurrentNumber);
		
	EndIf;
	
	If TableAccessRights.ReadOrderToSupplier
	 Or TableAccessRights.ReadingGiverSOrder2_5
	Then
		
		CurrentNumber = CurrentNumber + 1;
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder   AS PurchaseOrder,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis AS DocumentInflow
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
		|WHERE
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument <> CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_)
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
		|	AND &FilterOrders
		|
		|ORDER BY
		|	PurchaseOrder DESC
		|";
		If TableAccessRights.ReadOrderToSupplier And TableAccessRights.ReadingGiverSOrder2_5 Then
			
			TextSelectionOrders =
			"NOT CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder IN (
			|											VALUE(Document.PurchaseOrder.EmptyRef),
			|											VALUE(Document.MaterialProviderOrder2_5.EmptyRef))
			|	AND VALUETYPE(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder) IN (
			|														TYPE(Document.PurchaseOrder),
			|														TYPE(Document.MaterialProviderOrder2_5))";
			
		ElsIf TableAccessRights.ReadingGiverSOrder2_5 Then
			
			TextSelectionOrders =
			"CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder <> VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
			|	AND VALUETYPE(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder) = TYPE(Document.MaterialProviderOrder2_5)";
			
		ElsIf TableAccessRights.ReadOrderToSupplier Then
			TextSelectionOrders =
			"CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
			|	AND VALUETYPE(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder) = TYPE(Document.PurchaseOrder)";
		EndIf;
		QueryText = StrReplace(QueryText, "&FilterOrders", TextSelectionOrders);
		
		MatchingDataSets.Insert("ReceiptsOrders", CurrentNumber);
		
	EndIf;
	
	If TableAccessRights.ReadAcceptanceOfGoodsForStorage Then
		
		CurrentNumber = CurrentNumber + 1;
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	GoodsReceiptForStorage.Ref                   AS RegisteredReceipt,
		|	GoodsReceiptForStorage.SubsequentDeliveryByDocument AS SubsequentDeliveryByReceipt
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
		|		ON GoodsReceiptForStorage.Posted
		|			AND Actions.Basis = GoodsReceiptForStorage.SubsequentDeliveryByDocument";
		
		MatchingDataSets.Insert("ReceiptsReceipts", CurrentNumber);
		
		CurrentNumber = CurrentNumber + 1;
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	Actions.Basis              AS Inpayment,
		|	GoodsReceiptForStorage.Ref AS ReceiptCorrection
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
		|		ON GoodsReceiptForStorage.Posted
		|			AND (Actions.Basis = GoodsReceiptForStorage.CorrectedDocument
		|				OR (Actions.Basis = GoodsReceiptForStorage.ReversedDocument
		|					AND Actions.Basis.CorrectedDocument = GoodsReceiptForStorage.CorrectedDocument))";
		
		MatchingDataSets.Insert("CorrectionsReceived", CurrentNumber);
		
	EndIf;
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
		
		CurrentNumber = CurrentNumber + 1;
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref    AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse     AS Warehouse,
		|	WriteOffOfGoodsShortages.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON WriteOffOfGoodsShortages.Posted
		|			AND Actions.Basis = WriteOffOfGoodsShortages.Basis
		|			AND Actions.Warehouse = WriteOffOfGoodsShortages.Warehouse
		|";
		
		MatchingDataSets.Insert("GroundsForWritingOffShortfalls", CurrentNumber);
		
	EndIf;
	
	If TableAccessRights.ReadingRecordingSurplusGoods Then
		
		CurrentNumber = CurrentNumber + 1;
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	InventorySurplusRecognition.Basis AS Basis,
		|	InventorySurplusRecognition.Ref    AS RecordingAsReceived,
		|	InventorySurplusRecognition.Warehouse     AS Warehouse
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.InventorySurplusRecognition AS InventorySurplusRecognition
		|		ON InventorySurplusRecognition.Posted
		|			AND InventorySurplusRecognition.Basis = &DiscrepancyCertificate
		|			AND InventorySurplusRecognition.Warehouse = Actions.Warehouse
		|";
		
		MatchingDataSets.Insert("TheBasisOfRegistration", CurrentNumber);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function RequestTextStatementOfDiscrepanciesAfterReturnFromCustodian(TableAccessRights, MatchingDataSets)

	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action,
	|	CAST(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis AS Document.ReceiptOfGoodsFromCustodian) AS Basis,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ThirdPartyIsGuilty AS ThirdPartyIsGuilty
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED DISTINCT
	|	Actions.Action AS Action,
	|	Actions.Basis AS Basis,
	|	Actions.ThirdPartyIsGuilty AS ThirdPartyIsGuilty,
	|	NOT Actions.Basis.ReferenceOrder IN (
	|					VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|					VALUE(Document.SubcontractOrder2_5.EmptyRef),
	|					VALUE(Document.ProductionStage2_2.EmptyRef),
	|					UNDEFINED) AS ByOrders,
	|	Actions.Warehouse AS Warehouse,
	|	Actions.Basis.ReferenceOrder AS OrderDocument
	|FROM
	|	Actions AS Actions
	|TOTALS BY
	|	Basis
	|";
	
	CurrentNumber = 1;
	
	If TableAccessRights.ReadingTransfers Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	TransferOfGoodsToBailee.SubsequentDeliveryByTransfer AS Basis,
		|	TransferOfGoodsToBailee.Ref AS Transfer_
		|FROM
		|	Document.TransferOfGoodsToBailee AS TransferOfGoodsToBailee
		|		INNER JOIN Actions AS Actions
		|		ON TransferOfGoodsToBailee.SubsequentDeliveryByTransfer = Actions.Basis
		|WHERE
		|	TransferOfGoodsToBailee.Posted";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReturnsFromCustodiansTransfers", CurrentNumber);
		
	EndIf;
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText +
		"SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse AS Warehouse,
		|	WriteOffOfGoodsShortages.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|		AND Actions.Basis = WriteOffOfGoodsShortages.Basis
		|		AND Actions.Warehouse = WriteOffOfGoodsShortages.Warehouse";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("GroundsForWritingOffShortfalls", CurrentNumber);
		
	EndIf;
	
	If TableAccessRights.ReadingReceiptOfGoodsFromCustodian Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	ReceiptFromTheCustodian.Ref AS Inpayment,
		|	ReceiptFromTheCustodian.AdditionalReturnWithinGoodsReceipt AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
		|		ON Actions.Basis = ReceiptFromTheCustodian.AdditionalReturnWithinGoodsReceipt
		|WHERE
		|	ReceiptFromTheCustodian.Posted";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("ReturnsFromCustodiansReceipts", CurrentNumber);
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	Actions.Basis            AS Inpayment,
		|	ReceiptFromTheCustodian.Ref AS ReceiptCorrection
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
		|		ON ReceiptFromTheCustodian.Posted
		|			AND (Actions.Basis = ReceiptFromTheCustodian.CorrectedDocument
		|				OR (Actions.Basis = ReceiptFromTheCustodian.ReversedDocument
		|					AND Actions.Basis.CorrectedDocument = ReceiptFromTheCustodian.CorrectedDocument))";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("CorrectionsReceived", CurrentNumber);
		
	EndIf;
	
	If TableAccessRights.ReadingRecordingSurplusGoods Then
	
		QueryText = QueryText + Common.QueryBatchSeparator();

		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	InventorySurplusRecognition.Ref AS RecordingAsReceived,
		|	InventorySurplusRecognition.Warehouse AS Warehouse,
		|	InventorySurplusRecognition.Basis AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.InventorySurplusRecognition AS InventorySurplusRecognition
		|		ON (InventorySurplusRecognition.Posted)
		|			AND Actions.Basis = InventorySurplusRecognition.Basis
		|			AND Actions.Warehouse     = InventorySurplusRecognition.Warehouse
		|";
		
		CurrentNumber = CurrentNumber + 1;
		MatchingDataSets.Insert("TheBasisOfRegistration", CurrentNumber);
	
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure OutputCorrectionAcceptanceOfGoodsForStorage(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputCorrectionAcceptanceOfGoodsForStorage", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration(
		"CorrectionOfAcceptanceOfGoodsForStorage",
		1,
		Template,
		ArrayOfCompletedDocuments,
		BusinessTransactionOfCertificate,
		False,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputCorrectionShipmentOfGoodsFromStorage", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration(
		"CorrectionShipmentOfGoodsFromStorage",
		1,
		Template,
		ArrayOfCompletedDocuments,
		BusinessTransactionOfCertificate,
		False,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputDocumentCorrectionShipmentOfGoodsFromStorage(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputDocumentCorrectionShipmentOfGoodsFromStorage", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = CorrectionsOnShipmentsOfGoodsFromStorage.FindRows(
		New Structure("GoodsShipmentFromStorage", ActionString.Basis));
	If CompletedDocuments_4.Count() = 0 Then
		
		DescriptionOfDocumentBeingDrawnUp = New Structure("CreatedDocument, Warehouse, Patch",
			ActionString.Basis,
			Catalogs.Warehouses.EmptyRef(),
			True);
		ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			DocumentPatch = IssuedDocument.ShipmentOfGoodsFromStorageCorrection;
			ArrayOfCompletedDocuments.Add(IssuedDocument.ShipmentOfGoodsFromStorageCorrection);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"DocumentCorrectionShipmentOfGoodsFromStorage",
		1,
		Template,
		ArrayOfCompletedDocuments,
		BusinessTransactionOfCertificate,
		False,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputDocumentAcceptanceOfGoodsForStorage(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputDocumentAcceptanceOfGoodsForStorage", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	Filter                = New Structure("Basis", ActionString.Basis);
	CompletedDocuments_4 = SubsequentDeliveryByGoodsShipmentsFromStorage.FindRows(Filter);
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.GoodsReceiptForStorage.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.GoodsReceiptForStorage.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.GoodsReceiptForStorage);
		EndDo;
	EndIf;
	
	BusinessOperation = Undefined;
	If BusinessTransactionOfCertificate = Enums.BusinessTransactions.TransferToMaterialProvider2_5
	 Or BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		BusinessOperation = BusinessTransactionOfCertificate;
	EndIf;
	PrintDocumentForRegistration(
		"GoodsReceiptForStorage",
		2,
		Template,
		ArrayOfCompletedDocuments,
		BusinessOperation,
		True,
		LongDesc);
	
EndProcedure

&AtServer
Procedure DisplayDocumentOfAdditionalDeliveryForAcceptanceOfGoodsForStorage(ActionString, Template, LongDesc)
	
	If NotOutputToReport("DisplayDocumentOfAdditionalDeliveryForAcceptanceOfGoodsForStorage", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	SelectionByRevenue  = New Structure("SubsequentDeliveryByReceipt", ActionString.Basis);
	CompletedDocuments_4 = ReceiptsReceipts.FindRows(SelectionByRevenue);
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.GoodsReceiptForStorage.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.GoodsReceiptForStorage.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredReceipt);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration(
		"AcceptanceOfGoodsForStorageAdditionalDeliveryUponAcceptance",
		2,
		Template,
		ArrayOfCompletedDocuments,
		BusinessTransactionOfCertificate,
		True,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintDocumentShipmentOfGoodsFromStorageToReturnUndeliveredGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentShipmentOfGoodsFromStorageToReturnUndeliveredGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	Filter                = New Structure("Basis", ActionString.Basis);
	CompletedDocuments_4 = ReturnsByGoodsShipmentsFromStorage.FindRows(Filter);
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.GoodsShipmentFromStorage.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Warehouse",               Catalogs.Warehouses.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     True);
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.GoodsShipmentFromStorage.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.GoodsShipmentFromStorage);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration(
		"GoodsShipmentFromStorage",
		2,
		Template,
		ArrayOfCompletedDocuments,
		BusinessTransactionOfCertificate,
		True,
		LongDesc);
	
EndProcedure

&AtServer
Procedure GenerateDocumentsForRegisteringSurpluses(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentRegisteringSurpluses", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfDepotsForDebiting  = New Array;
	WarehouseSearchParameters = New Structure("PossibleAction",
		Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome);
	FoundRows        = ActionString.ActionsWarehouses.FindRows(WarehouseSearchParameters);
	
	For Each DebitedLine In FoundRows Do
		If ArrayOfDepotsForDebiting.Find(DebitedLine.Warehouse) = Undefined Then
			ArrayOfDepotsForDebiting.Add(DebitedLine.Warehouse);
		EndIf;
	EndDo;
	
	For Each WriteOffWarehouse In ArrayOfDepotsForDebiting Do
		
		ArrayOfCompletedDocuments = New Array;
		
		LongDesc.Warehouse         = WriteOffWarehouse;
		LongDesc.WithdrawWarehouse = True;
		
		FilterByWarehouse = New Structure("Warehouse", WriteOffWarehouse);
		CompletedDocuments_4 = TheBasisOfRegistration.FindRows(FilterByWarehouse); 
		
		If CompletedDocuments_4.Count() = 0 Then
			IssuedDocument= New Structure("CreatedDocument, Warehouse",
				Documents.InventorySurplusRecognition.EmptyRef(), WriteOffWarehouse);
			
			ArrayOfCompletedDocuments.Add(IssuedDocument);
		Else
			For Each IssuedDocument In CompletedDocuments_4 Do
				ArrayOfCompletedDocuments.Add(IssuedDocument.RecordingAsReceived);
			EndDo;
		EndIf;
		
		Filter = New Structure("DocumentKind, Warehouse", "InventorySurplusRecognition", WriteOffWarehouse);
		DocumentsOnAct = IssuedDocumentsOnAct.FindRows(Filter);
		
		If DocumentsOnAct.Count() = 0 Then
	
			ActionDetails = StructuresForDescribingActionDisplayedInReport();
			FillPropertyValues(ActionDetails, LongDesc);
			
			NewRow = IssuedDocumentsOnAct.Add();
			NewRow.DocumentKind         = "InventorySurplusRecognition";
			NewRow.Warehouse                = WriteOffWarehouse;
			NewRow.RegisteredDocuments = ArrayOfCompletedDocuments;
			NewRow["LongDesc"]          = ActionDetails;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PrintTransferDocumentForAdditionalDeliveryOfUndeliveredGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintTransferDocumentForAdditionalDeliveryOfUndeliveredGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	Filter = New Structure("SubsequentDeliveryByTransfer", ActionString.Basis);
	CompletedDocuments_4 = AdditionalDeliveryToTheCustodian.FindRows(Filter);
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument",   Documents.TransferOfGoodsToBailee.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",           False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",       ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch",   DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.TransferOfGoodsToBailee.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredTransfer);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration("TransferOfGoodsToBailee", 2, Template, ArrayOfCompletedDocuments, Undefined, True,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintTransferDocumentForAdditionalDeliveryByCommissionOfUndeliveredGoods(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintTransferDocumentForAdditionalDeliveryByCommissionOfUndeliveredGoods", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	Filter = New Structure("SubsequentDeliveryByTransfer", ActionString.Basis);
	CompletedDocuments_4 = AdditionalDeliveryToTheCustodian.FindRows(Filter);
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument",   Documents.TransferOfGoodsToBailee.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",           False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",       ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch",   DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.TransferOfGoodsToBailee.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.RegisteredTransfer);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration("TransferOfGoodsForCommission", 2, Template, ArrayOfCompletedDocuments, Undefined, True,
		LongDesc);
	
EndProcedure

&AtServer
Procedure GenerateDocumentsForShipmentOfGoodsFromStorage(ActionString, Template, IssuedDocumentsOnAct, LongDesc)
	
	If NotOutputToReport("PrintDocumentShipmentOfGoodsFromStorage", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfReturnWarehouses  = New Array;
	WarehouseSearchParameters = New Structure("PossibleAction",
		Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered);
	FoundRows        = ActionString.ActionsWarehouses.FindRows(WarehouseSearchParameters);
	
	For Each ShippingLine_ In FoundRows Do
		If ArrayOfReturnWarehouses.Find(ShippingLine_.Warehouse) = Undefined Then
			ArrayOfReturnWarehouses.Add(ShippingLine_.Warehouse);
		EndIf;
	EndDo;
	
	For Each OriginWarehouse In ArrayOfReturnWarehouses Do
		
		ArrayOfCompletedDocuments = New Array;
		
		LongDesc.Warehouse         = OriginWarehouse;
		LongDesc.WithdrawWarehouse = True;
		
		FilterByWarehouse = New Structure("Warehouse", OriginWarehouse);
		CompletedDocuments_4 = ShipmentBases.FindRows(FilterByWarehouse);
		
		If CompletedDocuments_4.Count() = 0 Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.GoodsShipmentFromStorage.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("Warehouse",               OriginWarehouse);
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
			If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
				DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
				DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
			Else
				DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix", False);
			EndIf;
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			For Each IssuedDocument In CompletedDocuments_4 Do
				ArrayOfCompletedDocuments.Add(IssuedDocument.ShipFromStorage);
			EndDo;
		EndIf;
		
		Filter = New Structure("DocumentKind, Warehouse", "ShipmentOfGoodsFromStorageUponAcceptance", OriginWarehouse);
		DocumentsOnAct = IssuedDocumentsOnAct.FindRows(Filter);
		
		If DocumentsOnAct.Count() = 0 Then
			
			ActionDetails = StructuresForDescribingActionDisplayedInReport();
			FillPropertyValues(ActionDetails, LongDesc);
			
			NewRow = IssuedDocumentsOnAct.Add();
			NewRow.DocumentKind         = "ShipmentOfGoodsFromStorageUponAcceptance";
			NewRow.Warehouse                = OriginWarehouse;
			NewRow.RegisteredDocuments = ArrayOfCompletedDocuments;
			NewRow["LongDesc"]          = ActionDetails;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function TextOfRequestActOnDiscrepanciesAfterTransferOfGoodsToCustodian(TableAccessRights, MatchingDataSets)
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Action   AS Action,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices AS Transfer_,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse
	|,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref.BusinessOperation AS BusinessOperation
	|INTO Actions
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count <> 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED
	|	Actions.Action         AS Action,
	|	Actions.DiscrepancyTreatment AS DiscrepancyTreatment,
	|	Actions.Transfer_         AS Basis,
	|	Actions.Warehouse            AS Warehouse,
	|	FALSE                      AS ThirdPartyIsGuilty,
	|	Actions.Transfer_.TransferByOrders AS ByOrders,
	|	UNDEFINED              AS OrderDocument
	|FROM
	|	Actions AS Actions
	|
	|GROUP BY
	|	Actions.Action,
	|	Actions.DiscrepancyTreatment,
	|	Actions.Transfer_,
	|	Actions.Warehouse
	|
	|TOTALS BY
	|	Transfer_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED DISTINCT
	|	ReturnedGoods.DocumentSalesOfGoodsAndServices AS Transfer_,
	|	ReturnedGoods.Ref             AS DocumentReturnPolicy
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS ReturnedGoods
	|		INNER JOIN Actions AS Actions
	|		ON ReturnedGoods.DocumentSalesOfGoodsAndServices = Actions.Transfer_
	|WHERE
	|	&UseReturnRequests
	|	AND ReturnedGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Inpayment.DocumentTransfers_ AS Transfer_,
	|	Inpayment.Ref           AS DocumentReturnPolicy
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS Inpayment
	|		INNER JOIN Actions AS Actions
	|		ON Inpayment.DocumentTransfers_ = Actions.Transfer_
	|WHERE
	|	NOT &UseReturnRequests
	|	AND Inpayment.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Inpayment.DocumentTransfers_ AS Transfer_,
	|	Inpayment.Ref           AS DocumentReturnPolicy
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS Inpayment
	|		INNER JOIN Actions AS Actions
	|		ON Inpayment.DocumentTransfers_ = Actions.Transfer_
	|WHERE
	|	&UseReturnRequests
	|	AND Inpayment.Posted
	|	AND Actions.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT ALLOWED DISTINCT
	|	DiscrepancyCertificate.SalesOrder AS SalesOrder,
	|	DiscrepancyCertificate.SaleOfGoodsAndServices   AS Transfer_
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS DiscrepancyCertificate
	|WHERE
	|	DiscrepancyCertificate.NumberOfPackagesByDocument <> DiscrepancyCertificate.NumberOfPackages
	|	AND DiscrepancyCertificate.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|	AND DiscrepancyCertificate.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyCertificate.SalesOrder <> UNDEFINED
	|
	|ORDER BY
	|	SalesOrder DESC
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT ALLOWED DISTINCT
	|	GoodsHandover.Ref               AS RegisteredTransfer,
	|	GoodsHandover.SubsequentDeliveryByTransfer AS SubsequentDeliveryByTransfer
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.TransferOfGoodsToBailee AS GoodsHandover
	|		ON GoodsHandover.Posted
	|			AND Actions.Transfer_ = GoodsHandover.SubsequentDeliveryByTransfer
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT ALLOWED DISTINCT
	|	Actions.Transfer_ AS Transfer_,
	|	CorrectionOfTransferOfGoods.Ref AS Transfer_Correction
	|FROM
	|	Actions AS Actions
	|		INNER JOIN Document.TransferOfGoodsToBailee AS CorrectionOfTransferOfGoods
	|		ON CorrectionOfTransferOfGoods.Posted
	|			AND (Actions.Transfer_ = CorrectionOfTransferOfGoods.CorrectedDocument
	|				OR (Actions.Transfer_ = CorrectionOfTransferOfGoods.ReversedDocument
	|					AND Actions.Transfer_.CorrectedDocument = CorrectionOfTransferOfGoods.CorrectedDocument))
	|";
	
	If TableAccessRights.ReadingWritingOffShortagesOfGoods Then
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
		QueryText = QueryText + "
		|SELECT ALLOWED DISTINCT
		|	WriteOffOfGoodsShortages.Ref                     AS WriteOff,
		|	WriteOffOfGoodsShortages.Warehouse                      AS Warehouse,
		|	WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport AS Basis
		|FROM
		|	Actions AS Actions
		|		INNER JOIN Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
		|		ON (WriteOffOfGoodsShortages.Posted)
		|			AND Actions.Transfer_ = WriteOffOfGoodsShortages.BaseDocumentForDiscrepancyReport
		|			AND Actions.Warehouse = WriteOffOfGoodsShortages.Warehouse
		|";
		
		CurrentNumber = 6;
		MatchingDataSets.Insert("GroundsForWriteOffOfShortagesOnShipmentDocuments", CurrentNumber);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure WithdrawOrderOfTransferOfGoodsToCustodian(ActionString, Template, LongDesc)
	
	If NotOutputToReport("WithdrawOrderOfTransferOfGoodsToCustodian", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("TransferCorrection", 1, Template, ArrayOfCompletedDocuments, Undefined, False, LongDesc);
	
EndProcedure

&AtServer
Procedure WithdrawCostOfTransferringGoodsToCommission(ActionString, Template, LongDesc)
	
	If NotOutputToReport("WithdrawTransferCorrectionToCommission", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("CorrectionOfTransferToCommission", 1, Template, ArrayOfCompletedDocuments, Undefined, False, LongDesc);
	
EndProcedure

&AtServer
Procedure OutputCorrectionToTransferOrderDocument(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputCorrectionToTransferOrderDocument", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	Filter = New Structure("Transfer_", ActionString.Basis);
	CompletedDocuments_4 = TransfersOrders.FindRows(Filter);
	
	If CompletedDocuments_4.Count() = 0 Then
		Return;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.SalesOrder);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration("OrderTransfers", 2, Template, ArrayOfCompletedDocuments, Undefined, False, LongDesc);
	
EndProcedure

&AtServer
Procedure PrintReturnDocumentForTransfer(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintReturnDocumentForTransfer", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	Filter = New Structure("Transfer_", ActionString.Basis);
	CompletedDocuments_4 = TransfersReturns.FindRows(Filter);
	
	If CompletedDocuments_4.Count() = 0 Then
		
		AddRefundRequests = UseReturnRequests;
		AddRefundRequests =
						AddRefundRequests
						And BusinessTransactionOfCertificate <> Enums.BusinessTransactions.TransferToToller2_5;
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
			If AddRefundRequests Then
				DescriptionOfDocumentBeingDrawnUp = New Structure;
				DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef());
				DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
				DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
				ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
			Else
				DescriptionOfDocumentBeingDrawnUp = New Structure;
				DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
				DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
				DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
				DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
				ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
			EndIf;
		Else
			ArrayOfCompletedDocuments.Add(?(AddRefundRequests,
													Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef(),
													Documents.ReceiptOfGoodsFromCustodian.EmptyRef()));
		EndIf;
		
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.DocumentReturnPolicy);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration("TransferReturnDocument", 2, Template, ArrayOfCompletedDocuments, Undefined, True,LongDesc);
	
EndProcedure

&AtServer
Procedure PrintRefundDocumentForTransferToCommission(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintRefundDocumentForTransferToCommission", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	Filter = New Structure("Transfer_", ActionString.Basis);
	CompletedDocuments_4 = TransfersReturns.FindRows(Filter);
	
	If CompletedDocuments_4.Count() = 0 Then
		
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
			If UseReturnRequests Then
				DescriptionOfDocumentBeingDrawnUp = New Structure;
				DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef());
				DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
				DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
				ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
			Else
				DescriptionOfDocumentBeingDrawnUp = New Structure;
				DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument", Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
				DescriptionOfDocumentBeingDrawnUp.Insert("Patch",         False);
				DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
				DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
				ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
			EndIf;
		Else
			ArrayOfCompletedDocuments.Add(?(UseReturnRequests,
													Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef(),
													Documents.ReceiptOfGoodsFromCustodian.EmptyRef()));
		EndIf;
		
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.DocumentReturnPolicy);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration("CommissionAgentSReturnDocument", 2, Template, ArrayOfCompletedDocuments, Undefined, True,LongDesc);
	
EndProcedure


&AtServer
Procedure WithdrawCorrectionReturnOfGoodsFromCustodian(ActionString, Template, LongDesc)

	If NotOutputToReport("WithdrawCorrectionReturnOfGoodsFromCustodian", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("CorrectionOfReturnOfGoodsFromCustodian", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);

EndProcedure

&AtServer
Procedure PrintDocumentCorrectionReceiptOfGoodsFromCustodian(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentCorrectionReceiptOfGoodsFromCustodian", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = CorrectionsReceived.FindRows(
		New Structure("Inpayment", ActionString.Basis));
	If CompletedDocuments_4.Count() = 0 Then
		
		DescriptionOfDocumentBeingDrawnUp = New Structure("CreatedDocument, Patch",
			ActionString.Basis,
			True);
		ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			DocumentPatch = IssuedDocument.ReceiptCorrection;
			ArrayOfCompletedDocuments.Add(IssuedDocument.ReceiptCorrection);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"DocumentCorrectionReceiptOfGoodsFromCustodian",
		1,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputDocumentCorrectionGoodsReceiptForStorage(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputDocumentCorrectionGoodsReceiptForStorage", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = CorrectionsReceived.FindRows(
		New Structure("Inpayment", ActionString.Basis));
	If CompletedDocuments_4.Count() = 0 Then
		
		DescriptionOfDocumentBeingDrawnUp = New Structure("CreatedDocument, Patch",
			ActionString.Basis,
			True);
		ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			DocumentPatch = IssuedDocument.ReceiptCorrection;
			ArrayOfCompletedDocuments.Add(IssuedDocument.ReceiptCorrection);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"DocumentCorrectionGoodsReceiptForStorage",
		1,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure OutputDocumentTransferOfGoodsToCustodian(ActionString, Template, LongDesc)

	If NotOutputToReport("OutputDocumentTransferOfGoodsToCustodian", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = ReturnsFromCustodiansTransfers.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		
		If BusinessTransactionOfCertificate = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
			DocumentOperation_ = Enums.BusinessTransactions.TransferToToller2_5;
		Else
			DocumentOperation_ = Enums.BusinessTransactions.TransferToCommissionAgent;
		EndIf;
		
		DescriptionOfDocumentBeingDrawnUp = New Structure;
		DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument",     Documents.TransferOfGoodsToBailee.EmptyRef());
		DescriptionOfDocumentBeingDrawnUp.Insert("BusinessOperation",   DocumentOperation_);
		DescriptionOfDocumentBeingDrawnUp.Insert("Patch",             False);
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch", DocumentPatch);
		Else
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",     False);
		EndIf;
		ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.Transfer_);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"ReturnOfGoodsFromCustodianReturnToCustodian",
		1,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);

EndProcedure

&AtServer
Procedure OutputDocumentCorrectionTransferOfGoodsToCustodian(ActionString, Template, LongDesc)
	
	If NotOutputToReport("OutputDocumentCorrectionTransferOfGoodsToCustodian", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = CorrectionTransfers.FindRows(New Structure("Transfer_", ActionString.Basis));
	If CompletedDocuments_4.Count() = 0 Then
		
		DescriptionOfDocumentBeingDrawnUp = New Structure("CreatedDocument, Patch",
			ActionString.Basis,
			True);
		ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		
	Else
		
		For Each IssuedDocument In CompletedDocuments_4 Do
			DocumentPatch = IssuedDocument.Transfer_Correction;
			ArrayOfCompletedDocuments.Add(IssuedDocument.Transfer_Correction);
		EndDo;
		
	EndIf;
	
	PrintDocumentForRegistration(
		"DocumentCorrectionTransferOfGoodsToCustodian",
		1,
		Template,
		ArrayOfCompletedDocuments,,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure PrintDocumentTransferOfGoodsToCommissionAgent(ActionString, Template, LongDesc)
	
	If NotOutputToReport("PrintDocumentTransferOfGoodsToCommissionAgent", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	
	CompletedDocuments_4 = ReturnsFromCustodiansTransfers.FindRows(New Structure("Basis", ActionString.Basis));
	
	If CompletedDocuments_4.Count() = 0 Then
		If LongDesc.ReflectionMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection Then
			DescriptionOfDocumentBeingDrawnUp = New Structure;
			DescriptionOfDocumentBeingDrawnUp.Insert("CreatedDocument",   Documents.TransferOfGoodsToBailee.EmptyRef());
			DescriptionOfDocumentBeingDrawnUp.Insert("BusinessOperation", Enums.BusinessTransactions.TransferToCommissionAgent);
			DescriptionOfDocumentBeingDrawnUp.Insert("Patch",           False);
			DescriptionOfDocumentBeingDrawnUp.Insert("ThereIsFix",       ValueIsFilled(DocumentPatch));
			DescriptionOfDocumentBeingDrawnUp.Insert("DocumentPatch",   DocumentPatch);
			ArrayOfCompletedDocuments.Add(DescriptionOfDocumentBeingDrawnUp);
		Else
			ArrayOfCompletedDocuments.Add(Documents.TransferOfGoodsToBailee.EmptyRef());
		EndIf;
	Else
		For Each IssuedDocument In CompletedDocuments_4 Do
			ArrayOfCompletedDocuments.Add(IssuedDocument.Transfer_);
		EndDo;
	EndIf;
	
	PrintDocumentForRegistration(
		"ReturnOfGoodsFromCommissionAgentReturnToCommissionAgent",
		1,
		Template,
		ArrayOfCompletedDocuments,
		Enums.BusinessTransactions.TransferToCommissionAgent,,
		LongDesc);
	
EndProcedure

&AtServer
Procedure WithdrawRefundFromCommissionAgent(ActionString, Template, LongDesc)

	If NotOutputToReport("WithdrawRefundFromCommissionAgent", ActionString.Basis) Then
		Return;
	EndIf;
	
	ArrayOfCompletedDocuments = New Array;
	ArrayOfCompletedDocuments.Add(ActionString.Basis);
	
	PrintDocumentForRegistration("CorrectionOfReturnFromCommissionAgent", 1, Template, ArrayOfCompletedDocuments, , False, LongDesc);

EndProcedure

#EndRegion

#EndRegion
