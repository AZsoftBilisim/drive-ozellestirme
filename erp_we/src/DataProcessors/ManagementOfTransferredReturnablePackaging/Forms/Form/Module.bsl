
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not ValueIsFilled(FilterReturnCycleLength) Then
		Relevance = NStr("vi = 'Bất kỳ';
						|ru = 'Любой';
						|en = 'Any'; fa = 'هر';
						|it = 'Qualsiasi';
						|pl = 'Dowolny';
						|tr = 'Herhangi'");
	EndIf;
	
	SetRequestTextTransmittedContainer();
	
	CommonClientServer.SetDynamicListParameter(
		TransferredPackage,
		"ReturnDate",
		BegOfDay(CurrentSessionDate()));
	
	CommonClientServer.SetDynamicListParameter(
		TransferredPackage,
		"ImplementationAvailable",
		AccessRight("View", Metadata.Documents.CustomerInvoice));
	
	
	CommonClientServer.SetDynamicListFilterItem(
		PackageReturnsDocuments,
		"Manager",
		FilterManager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterManager));
	
		
	// StandardSubsystems.AttachableCommands
	TypesList = PackageReturnsDocuments.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.PackageReturnsDocumentsCommandBar;
	PlacementParameters.GroupsPrefix = "PackageReturnsDocuments";
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	TypesList = PackageRedemptionDocuments.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.PackageRedemptionDocumentsCommandBar;
	PlacementParameters.GroupsPrefix = "PackageRedemptionDocuments";

	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "PackageReturnsDocuments.Date", Items.PackageReturnsDocumentsDate.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "PackageRedemptionDocuments.Date", Items.PackageRedemptionDocumentsDate.Name);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FilterManager     = Settings.Get("FilterManager");
	FilterPartner      = Settings.Get("FilterPartner");
	FilterReturnDate = Settings.Get("FilterReturnDate");
	FilterReturnCycleLength = Settings.Get("FilterReturnCycleLength");
	
	SetSelectionByManager();
	SetPartnerSelection_();
	SetSelectionInListByReturnDate_(TransferredPackage, FilterReturnCycleLength);
	SetSelectionInListByReturnDate(TransferredPackage, FilterReturnDate);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_CustomerInvoice"
		Or EventName = "Write_ReturnOfGoodsFromCustomer"
		Or EventName = "Write_ReturnablePackagingRedemptionByCustomer" Then
		Items.TransferredPackage.Refresh();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterReturnCycleLengthOnChange(Item)

	WhenChangingSelectionForReturnPeriod(TransferredPackage, FilterReturnCycleLength, FilterReturnDate);

EndProcedure

&AtClient
Procedure FilterReturnCycleLengthChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = "Expires to1 date_" Then
		
		OpenForm(
			"CommonForm.SelectDate",
			New Structure("InitialValue"),,,,,
			New CallbackDescription("WhenSelectingReturnPeriodSelectCompletionDate", ThisObject));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterReturnCycleLengthClearing(Item, StandardProcessing)
	
	WhenClearingSelectionByReturnDate(TransferredPackage, FilterReturnCycleLength, FilterReturnDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FilterPartnerOnChange(Item)
	
	SetPartnerSelection_();
	
EndProcedure

&AtClient
Procedure FilterManagerOnChange(Item)
	
	SetSelectionByManager();
	
EndProcedure

&AtClient
Procedure TransferredPackageSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.TransferredPackage.CurrentData;
	
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.DocumentTransfers_) Then
		Return;
	EndIf;
	
	ShowValue(Undefined, CurrentData.DocumentTransfers_);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterPackageReturnRequest(Command)
	
	IssueDocument("Request");
	
EndProcedure

&AtClient
Procedure RegisterPackageReturn(Command)
	
	IssueDocument("Return");
	
EndProcedure

&AtClient
Procedure IssuePackageRedemption(Command)
	
	IssueDocument("Buyout");
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If Items.Pages.CurrentPage = Items.TareReturnDocumentsGroup Then
		CurrentList = Items.PackageReturnsDocuments;
	ElsIf Items.Pages.CurrentPage = Items.GroupDocumentsForThePurchaseOfContainers Then
		CurrentList = Items.PackageRedemptionDocuments;
	Else
		Return;
	EndIf;
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, CurrentList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	If Items.Pages.CurrentPage = Items.TareReturnDocumentsGroup Then
		CurrentList = Items.PackageReturnsDocuments;
	ElsIf Items.Pages.CurrentPage = Items.GroupDocumentsForThePurchaseOfContainers Then
		CurrentList = Items.PackageRedemptionDocuments;
	Else
		Return;
	EndIf;
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, CurrentList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If Items.Pages.CurrentPage = Items.TareReturnDocumentsGroup Then
		CurrentList = Items.PackageReturnsDocuments;
	ElsIf Items.Pages.CurrentPage = Items.GroupDocumentsForThePurchaseOfContainers Then
		CurrentList = Items.PackageRedemptionDocuments;
	Else
		Return;
	EndIf;
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, CurrentList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Function ReportErrorsInGeneratingDataForFillingInReturningRedeemingContainers(SampleBankingDetails)
	
	Cancel = False;
	
	MessageText = NStr("vi = 'Trong các dòng đã chọn của chứng từ tiếp nhận có trường khác ""%FieldPresentation%""';
						|ru = 'У выделенных строк в документе поступления отличается поле ""%FieldPresentation%""';
						|en = 'The ""%FieldPresentation%"" field of the selected receipt document lines differs.'; fa = 'The ""%FieldPresentation%"" field of the selected receipt document lines differs.';
						|it = 'Le righe evidenziate nel documento di ricevimento hanno il campo ""%FieldPresentation%"" diverso';
						|pl = 'W wybranych wierszach w dokumencie wpłaty różni się pole ""%FieldPresentation%""';
						|tr = 'Teslim alım belgesindeki seçili satırlarda farklı bir ""%FieldPresentation%"" alanı vardır'");
	
	If SampleBankingDetails.ThereAreDifferencesPartner Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Khách hàng';
																|ru = 'Клиент';
																|en = 'Customer'; fa = 'مشتری';
																|it = 'Cliente';
																|pl = 'Klient';
																|tr = 'Müşteri'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	
	If SampleBankingDetails.ThereAreDifferencesCounterparty Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Controparte';
																|pl = 'Kontrahent';
																|tr = 'Cari hesap'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesCompany Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Doanh nghiệp';
																|ru = 'Организация';
																|en = 'Company'; fa = 'Company';
																|it = 'Azienda';
																|pl = 'Firma';
																|tr = 'İş yeri'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesAgreement Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thỏa thuận';
																|ru = 'Соглашение';
																|en = 'Agreement'; fa = 'توافق‌نامه';
																|it = 'Accordo';
																|pl = 'Porozumienie';
																|tr = 'Anlaşma'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesInDirectionOfActivity Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Lĩnh vực hoạt động';
																|ru = 'Направление деятельности';
																|en = 'Line of business'; fa = 'خط کسب‌وکار';
																|it = 'Settore di attività';
																|pl = 'Rodzaj działalności';
																|tr = 'Faaliyet alanı'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesContract Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Hợp đồng';
																|ru = 'Договор';
																|en = 'Contract'; fa = 'قرارداد';
																|it = 'Contratto';
																|pl = 'Contract';
																|tr = 'Sözleşme'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesEconomicOperation Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giao dịch';
																|ru = 'Операция';
																|en = 'Transaction'; fa = 'تراکنش';
																|it = 'Operazione';
																|pl = 'Transaction';
																|tr = 'İşlem'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesCurrency Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tiền tệ';
																|ru = 'Валюта';
																|en = 'Currency'; fa = 'ارز';
																|it = 'Valuta';
																|pl = 'Waluta';
																|tr = 'Para birimi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesInCurrencyOfMutualSettlements Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tiền tệ hạch toán công nợ';
																|ru = 'Валюта взаиморасчетов';
																|en = 'AR/AP currency'; fa = 'ارز دریافتنی/پرداختنی';
																|it = 'Valuta di regolamento dei conti';
																|pl = 'Waluta rozliczeń wzajemnych';
																|tr = 'Alacak/Borç muhasebesi para birimi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesVATTaxation Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Chịu thuế GTGT';
																|ru = 'Налогообложение НДС';
																|en = 'VAT taxation'; fa = 'مشمولیت مالیات بر ارزش افزوده';
																|it = 'Tassazione IVA';
																|pl = 'Opodatkowanie VAT';
																|tr = 'KDV vergilendirmesi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SampleBankingDetails.ThereAreDifferencesDepositForContainerIsProvided Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Có sẵn ký cược';
																|ru = 'Предусмотрен залог';
																|en = 'Deposit is required'; fa = 'ودیعه لازم است';
																|it = 'È prevista la cauzione';
																|pl = 'Przewidziano zaliczkę';
																|tr = 'Depozito sağlandı'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtClient
Procedure WhenSelectingReturnPeriodSelectCompletionDate(ReturnDate, AdditionalParameters) Export
	
	FilterReturnDate = ReturnDate;
	
	If ValueIsFilled(ReturnDate) Then
		
		FilterReturnCycleLength = NStr("vi = 'Hết hạn vào %Date%';
										|ru = 'Истекает на %Date%';
										|en = 'Expires on %Date%'; fa = 'Expires on %Date%';
										|it = 'Scade il %Date%';
										|pl = 'Wygasa na %Date%';
										|tr = 'Son kullanma tarihi %Date%'");
		FilterReturnCycleLength = StrReplace(FilterReturnCycleLength, "%Date%", Format(ReturnDate, "DLF=D"));
		
	EndIf;
	
	WhenChangingSelectionForReturnPeriod(TransferredPackage, FilterReturnCycleLength, FilterReturnDate);
	
EndProcedure

&AtClient
Procedure WhenClearingSelectionByReturnDate(List, ReturnCycleLength, ReturnDate, StandardProcessing)
	
	StandardProcessing = False;
	If ReturnCycleLength <> "Any" Then
		ReturnCycleLength = "Any";
		WhenChangingSelectionForReturnPeriod(List, ReturnCycleLength, ReturnDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingSelectionForReturnPeriod(List, ReturnCycleLength, ReturnDate)
	
	SetSelectionInListByReturnDate_(List, ReturnCycleLength);
	
	NotShowAll = (ReturnCycleLength <> "Any");
	
	If Not NotShowAll Then
		ReturnDate = Date(1,1,1);
	EndIf;
	
	SetSelectionInListByReturnDate(List, ReturnDate);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionInListByReturnDate_(List, ReturnCycleLength)
	
	FilterValue = (ReturnCycleLength = "Overdue" Or StrFind(ReturnCycleLength, "Expires to1") > 0);
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Overdue",
		FilterValue,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(ReturnCycleLength) And ReturnCycleLength <> "Any");
	
EndProcedure 

&AtClientAtServerNoContext
Procedure SetSelectionInListByReturnDate(List, ReturnDate)
	
	If ValueIsFilled(ReturnDate) Then
		List.Parameters.SetParameterValue("ReturnDate", ReturnDate);
	Else
		#If Client Then
			List.Parameters.SetParameterValue("ReturnDate", BegOfDay(CommonClient.SessionDate()));
		#Else
			List.Parameters.SetParameterValue("ReturnDate", BegOfDay(CurrentSessionDate()));
		#EndIf
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueDocument(OperationType)
	
	If Items.TransferredPackage.CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
										|ru = 'Команда не может быть выполнена для указанного объекта.';
										|en = 'Command cannot be executed for the specified object.'; fa = 'Command cannot be executed for the specified object.';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
										|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
										|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	RowsArray = New Array();
	ThereAreImplementations = False;
	ThereAreTransfers = False;
	For Each CurRow In Items.TransferredPackage.SelectedRows Do
		
		If TypeOf(CurRow) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		RowData = Items.TransferredPackage.RowData(CurRow);
		RowsArray.Add(RowData);
			ThereAreImplementations = True;
		
	EndDo;
	If ThereAreTransfers And ThereAreImplementations Then
		
		MessageText = NStr("vi = 'Một lệnh không thể được thực thi cùng lúc đối với các bao bì được chuyển đến gia công và cho các bao bì được chuyển cho khách hàng.';
							|ru = 'Команда не может быть выполнена одновременно для тары, переданной переработчикам, и для тары, переданной клиентам.';
							|en = 'The command cannot be executed simultaneously for the package sent to subcontractors and package transferred to customers.'; fa = 'The command cannot be executed simultaneously for the package sent to subcontractors and package transferred to customers.';
							|it = 'Il comando non può essere eseguito simultaneamente per l''imballaggio consegnato ai trasformatori e per quello consegnato ai clienti.';
							|pl = 'Polecenie nie może być wykonane jednocześnie dla tary, przekazanej przetwórcom i dla tary, przekazanej klientom.';
							|tr = 'Komut, fason üreticilere aktarılan ambalajlar ve müşterilere aktarılan ambalajlar için aynı anda çalıştırılamaz.'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
		
	ElsIf ThereAreTransfers And OperationType = "Request" Then
		
		MessageText = NStr("vi = 'Một đơn cho việc trả lại các bao bì được chuyển đến gia công không được cung cấp.';
							|ru = 'Заявка на возврат тары, переданной переработчикам, не предусмотрена.';
							|en = 'Request for return of package transferred to subcontractors is unavailable.'; fa = 'Request for return of package transferred to subcontractors is unavailable.';
							|it = 'Non è prevista alcuna domanda di reso dell''imballaggio consegnato ai trasformatori.';
							|pl = 'Zlecenie na zwrot tary, przekazanej przetwórcom nie jest przewidziane.';
							|tr = 'Fason üreticilere teslim edilen ambalajların iadesi için herhangi bir uygulama bulunmamaktadır.'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
		
	EndIf;
	If OperationType = "Request" Then
		NameOfDocumentForm = "Document.RequestForReturnOfGoodsFromCustomer.Form.DocumentForm";
	ElsIf OperationType = "Return" Then
		NameOfDocumentForm = "Document.ReturnOfGoodsFromCustomer.Form.DocumentForm";
	Else // Buyout
		NameOfDocumentForm = "Document.ReturnablePackagingRedemptionByCustomer.Form.DocumentForm";
	EndIf;
	
	If RowsArray.Count() > 0 Then
		
		ClearMessages();
		AttributesStructure1 = PlaceContainerInTemporaryStorage(RowsArray);
		If AttributesStructure1 <> Undefined Then
			OpenForm(NameOfDocumentForm, New Structure("Basis", AttributesStructure1));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function PlaceContainerInTemporaryStorage(RowsArray)
	
	TypeOfImplementation = New TypeDescription("DocumentRef.CustomerInvoice");
	
	PackageTable = New ValueTable();
	PackageTable.Columns.Add("Partner",                 New TypeDescription("CatalogRef.Partners"));
	PackageTable.Columns.Add("Products",            New TypeDescription("CatalogRef.Products"));
	PackageTable.Columns.Add("Characteristic",          New TypeDescription("CatalogRef.ItemsCharacteristics"));
	PackageTable.Columns.Add("Count",              New TypeDescription("Number"));
	PackageTable.Columns.Add("QuantityByGBRN",        New TypeDescription("Number"));
	PackageTable.Columns.Add("Sum",                   New TypeDescription("Number"));
	PackageTable.Columns.Add("DocumentSalesOfGoodsAndServices",      TypeOfImplementation);
	PackageTable.Columns.Add("DepositForPackageIsRequired", New TypeDescription("Boolean"));
	
	For Each CurRow In RowsArray Do
		
		NewRow = PackageTable.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.Count = CurRow.CountBalance;
		NewRow.QuantityByGBRN = CurRow.QuantityByGBRNBalance;
		NewRow.Sum = CurRow.SumBalance;
		NewRow.DocumentSalesOfGoodsAndServices = CurRow.DocumentTransfers_;
		NewRow.DepositForPackageIsRequired = CurRow.DepositForPackageIsRequired;
		
	EndDo;
	
	Query = New Query("
	|SELECT
	|	PackageTable.Partner                 AS Partner,
	|	PackageTable.Products            AS Products,
	|	PackageTable.Characteristic          AS Characteristic,
	|	PackageTable.Count              AS Count,
	|	PackageTable.QuantityByGBRN        AS QuantityByGBRN,
	|	PackageTable.DocumentSalesOfGoodsAndServices      AS DocumentSalesOfGoodsAndServices,
	|	PackageTable.DepositForPackageIsRequired AS DepositForPackageIsRequired
	|INTO
	|	TTTareTable
	|FROM
	|	&PackageTable AS PackageTable
	|;
	|SELECT
	|	MIN(TTTareTable.Partner)                                       AS Partner,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.Counterparty)                 AS Counterparty,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.Contract)                    AS Contract,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.Organization)                AS Organization,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.Terms)                 AS Terms,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.LineOfBusiness)    AS LineOfBusiness,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.BusinessOperation)      AS BusinessOperation,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.Currency)                     AS Currency,
	|	MIN(CASE
	|				WHEN TTTareTable.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice 
	|					THEN TTTareTable.DocumentSalesOfGoodsAndServices.ARAPCurrency
	|				ELSE TTTareTable.DocumentSalesOfGoodsAndServices.Currency
	|			END)                                                       AS ARAPCurrency,
	|	MIN(
	|	CASE
	|		WHEN TTTareTable.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice THEN
	|			CASE
	|				WHEN &ToUseTermsOfSales
	|					THEN TTTareTable.DocumentSalesOfGoodsAndServices.Terms.PaymentMethod
	|				ELSE TTTareTable.DocumentSalesOfGoodsAndServices.PaymentMethod
	|			END
	|		ELSE UNDEFINED
	|	END)                                                               AS PaymentMethod,
	|	MIN(
	|	CASE
	|		WHEN TTTareTable.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice THEN
	|			CASE
	|				WHEN &ToUseTermsOfSales
	|					THEN TTTareTable.DocumentSalesOfGoodsAndServices.Terms.PriceIncludesVAT
	|				ELSE TTTareTable.DocumentSalesOfGoodsAndServices.PriceIncludesVAT
	|			END
	|		ELSE UNDEFINED
	|	END)                                                               AS PriceIncludesVAT,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.VATTaxation)         AS VATTaxation,
	|	MIN(TTTareTable.DepositForPackageIsRequired)                       AS DepositForPackageIsRequired,
	|	MIN(CASE
	|				WHEN TTTareTable.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice 
	|					THEN TTTareTable.DocumentSalesOfGoodsAndServices.CustomerCounterparty
	|				ELSE UNDEFINED
	|			END)                                                       AS CustomerCounterparty,
	|	MIN(CASE
	|				WHEN TTTareTable.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice 
	|					THEN TTTareTable.DocumentSalesOfGoodsAndServices.CustomerPartner
	|				ELSE UNDEFINED
	|			END)                                                       AS CustomerPartner,
	|	MIN(CASE
	|				WHEN TTTareTable.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice 
	|					THEN TTTareTable.DocumentSalesOfGoodsAndServices.CustomerContract
	|				ELSE UNDEFINED
	|			END)                                                       AS CustomerContract,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Warehouse) = 1 AND
	|			MAX(TTTareTable.DocumentSalesOfGoodsAndServices.Warehouse.IsFolder) = FALSE
	|		THEN
	|			MAX(TTTareTable.DocumentSalesOfGoodsAndServices.Warehouse)
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	MIN(TTTareTable.DocumentSalesOfGoodsAndServices.ContactPerson)             AS ContactPerson,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.Partner) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPartner,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Counterparty) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCounterparty,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Organization) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCompany,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Terms) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesAgreement,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.LineOfBusiness) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInDirectionOfActivity,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Contract) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesContract,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.BusinessOperation) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesEconomicOperation,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Currency) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCurrency,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CASE
	|									WHEN TTTareTable.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice 
	|										THEN TTTareTable.DocumentSalesOfGoodsAndServices.ARAPCurrency
	|									ELSE TTTareTable.DocumentSalesOfGoodsAndServices.Currency
	|								END) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInCurrencyOfMutualSettlements,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.VATTaxation) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesVATTaxation,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DepositForPackageIsRequired) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesDepositForContainerIsProvided,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.CompanyBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Organization) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentSalesOfGoodsAndServices.CompanyBankAccount)
	|		ELSE
	|			VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|	END AS CompanyBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.CounterpartyBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT TTTareTable.DocumentSalesOfGoodsAndServices.Counterparty) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentSalesOfGoodsAndServices.CounterpartyBankAccount)
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS CounterpartyBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.Shipper
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentSalesOfGoodsAndServices.Shipper)
	|		ELSE
	|			VALUE(Catalog.Counterparties.EmptyRef)
	|	END AS GoodsRecipient,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.ShipperBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.ShipperBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentSalesOfGoodsAndServices.Shipper
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentSalesOfGoodsAndServices.ShipperBankAccount)
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS GoodsRecipientBankAccount
	|FROM
	|	TTTareTable AS TTTareTable
	|");
	
	Query.SetParameter("PackageTable", PackageTable);
	Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	SampleBankingDetails = QueryResult.Select();
	SampleBankingDetails.Next();
	
	If ReportErrorsInGeneratingDataForFillingInReturningRedeemingContainers(SampleBankingDetails) Then
		
		ErrorText = NStr("vi = 'Không thể nhập một chứng từ theo dòng đã chọn';
						|ru = 'Ввод одного документа по выделенным строкам невозможен';
						|en = 'Cannot enter one document by selected rows'; fa = 'Cannot enter one document by selected rows';
						|it = 'Il singolo documento non può essere inserito per le righe selezionate';
						|pl = 'Wprowadzenie jednego dokumentu według wydzielonych wierszy jest niemożliwe';
						|tr = 'Seçili satır başına bir belge girmek mümkün değildir'");
		Common.MessageToUser(ErrorText);
		
		Return Undefined;
		
	Else
		
		HeaderAttributes = New Structure();
		HeaderAttributes.Insert("Partner",                       SampleBankingDetails.Partner);
		HeaderAttributes.Insert("Counterparty",                    SampleBankingDetails.Counterparty);
		HeaderAttributes.Insert("Contract",                       SampleBankingDetails.Contract);
		HeaderAttributes.Insert("Organization",                   SampleBankingDetails.Organization);
		HeaderAttributes.Insert("Warehouse",                         SampleBankingDetails.Warehouse);
		HeaderAttributes.Insert("Terms",                    SampleBankingDetails.Terms);
		HeaderAttributes.Insert("LineOfBusiness",       SampleBankingDetails.LineOfBusiness);
		HeaderAttributes.Insert("BusinessOperation",         SalesServer.GetRefundTransactionForSale(SampleBankingDetails.BusinessOperation));
		HeaderAttributes.Insert("Currency",                        SampleBankingDetails.Currency);
		HeaderAttributes.Insert("ARAPCurrency",          SampleBankingDetails.ARAPCurrency);
		HeaderAttributes.Insert("PaymentMethod",                   SampleBankingDetails.PaymentMethod);
		HeaderAttributes.Insert("VATTaxation",            SampleBankingDetails.VATTaxation);
		HeaderAttributes.Insert("PriceIncludesVAT",               SampleBankingDetails.PriceIncludesVAT);
		HeaderAttributes.Insert("GoodsRecipient",               SampleBankingDetails.GoodsRecipient);
		HeaderAttributes.Insert("GoodsRecipientBankAccount", SampleBankingDetails.GoodsRecipientBankAccount);
		HeaderAttributes.Insert("CompanyBankAccount",     SampleBankingDetails.CompanyBankAccount);
		HeaderAttributes.Insert("CounterpartyBankAccount",     SampleBankingDetails.CounterpartyBankAccount);
		HeaderAttributes.Insert("DepositForPackageIsRequired",       SampleBankingDetails.DepositForPackageIsRequired);
		HeaderAttributes.Insert("CustomerCounterparty",              SampleBankingDetails.CustomerCounterparty);
		HeaderAttributes.Insert("CustomerPartner",                 SampleBankingDetails.CustomerPartner);
		HeaderAttributes.Insert("CustomerContract",                 SampleBankingDetails.CustomerContract);
		HeaderAttributes.Insert("ContactPerson",                SampleBankingDetails.ContactPerson);
		
		ContainerAddressInTemporaryStorage = PutToTempStorage(PackageTable, UUID);
		Return New Structure(
						"HeaderAttributes,ContainerAddressInTemporaryStorage,FillInTransferredContainer",
						HeaderAttributes,
						ContainerAddressInTemporaryStorage);
		
	EndIf;
	
EndFunction

&AtServer
Procedure SetPartnerSelection_()
	
	CommonClientServer.SetDynamicListFilterItem(TransferredPackage,        "Partner", FilterPartner, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterPartner));
	CommonClientServer.SetDynamicListFilterItem(PackageReturnsDocuments, "Partner", FilterPartner, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterPartner));
	CommonClientServer.SetDynamicListFilterItem(PackageRedemptionDocuments,   "Partner", FilterPartner, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterPartner));
	
EndProcedure

&AtServer
Procedure SetSelectionByManager()
	
	CommonClientServer.SetDynamicListFilterItem(TransferredPackage,        "DocumentTransfers_.Manager", FilterManager, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterManager));
	CommonClientServer.SetDynamicListFilterItem(PackageReturnsDocuments, "Manager", FilterManager, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterManager));
	CommonClientServer.SetDynamicListFilterItem(PackageRedemptionDocuments,   "Manager", FilterManager, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterManager));
	
EndProcedure

&AtServer
Procedure SetRequestTextTransmittedContainer()
	
	QueryText =
	"SELECT ALLOWED
	|	VALUETYPE(UNDEFINED) AS AvailableType
	|INTO AvailableGearTypes
	|
	|UNION ALL
	|
	|SELECT
	|	TYPE(Document.CustomerInvoice) AS AvailableType
	|WHERE
	|	&ImplementationAvailable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN TransferredPackage.DocumentTransfers_.ReusablePackagesReturnDate <= ENDOFPERIOD(&ReturnDate, DAY)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Overdue,
	|	TransferredPackage.DocumentTransfers_.ReusablePackagesReturnDate AS ReusablePackagesReturnDate,
	|	TransferredPackage.Products AS Products,
	|	TransferredPackage.Characteristic AS Characteristic,
	|	TransferredPackage.Partner AS Partner,
	|	TransferredPackage.DepositIsRequired AS DepositForPackageIsRequired,
	|	TransferredPackage.DocumentTransfers_ AS DocumentTransfers_,
	|	TransferredPackage.CountBalance AS CountBalance,
	|	TransferredPackage.QuantityByGBRNBalance AS QuantityByGBRNBalance,
	|	TransferredPackage.SumBalance AS SumBalance
	|FROM
	|	AccumulationRegister.TransferredReturnablePackaging.Balance(
	|			,
	|			VALUETYPE(DocumentTransfers_) IN
	|				(SELECT
	|					AvailableType
	|				FROM
	|					AvailableGearTypes)
	|		) AS TransferredPackage
	|";
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, TransferredPackage);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.TransferredPackage, ListProperties);
	
EndProcedure

#EndRegion
