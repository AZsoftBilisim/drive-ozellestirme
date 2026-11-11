
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
	
	SetRequestTextAcceptedContainer();
	
	CommonClientServer.SetDynamicListParameter(
		ReceivedPackage,
		"ReturnDate",
		BegOfDay(CurrentSessionDate()));
		
	CommonClientServer.SetDynamicListParameter(
		ReceivedPackage,
		"AcquisitionIsAvailable",
		AccessRight("View", Metadata.Documents.VendorInvoice));
	RawMaterialSupplyIsAvailable = False;
	
	CommonClientServer.SetDynamicListParameter(
		ReceivedPackage,
		"RawMaterialSupplyIsAvailable",
		RawMaterialSupplyIsAvailable);
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
	SetSelectionInListByReturnDate_(ReceivedPackage, FilterReturnCycleLength);
	SetSelectionInListByReturnDate(ReceivedPackage, FilterReturnDate);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_VendorInvoice"
		Or EventName = "Write_ReturnOfGoodsToVendor"
		Or EventName = "Recording_RepurchaseOfMultiTurnContainersFromSupplier" Then
		Items.ReceivedPackage.Refresh();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterReturnCycleLengthOnChange(Item)

	WhenChangingSelectionForReturnPeriod(ReceivedPackage, FilterReturnCycleLength, FilterReturnDate);

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
	
	WhenClearingSelectionByReturnDate(ReceivedPackage, FilterReturnCycleLength, FilterReturnDate, StandardProcessing);
	
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
Procedure ReceivedPackageSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.ReceivedPackage.CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(Undefined, Items.ReceivedPackage.CurrentData.DocumentInflow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
	EndIf;
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, CurrentList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	If Items.Pages.CurrentPage = Items.TareReturnDocumentsGroup Then
		CurrentList = Items.PackageReturnsDocuments;
	ElsIf Items.Pages.CurrentPage = Items.GroupDocumentsForThePurchaseOfContainers Then
		CurrentList = Items.PackageRedemptionDocuments;
	EndIf;
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, CurrentList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If Items.Pages.CurrentPage = Items.TareReturnDocumentsGroup Then
		CurrentList = Items.PackageReturnsDocuments;
	ElsIf Items.Pages.CurrentPage = Items.GroupDocumentsForThePurchaseOfContainers Then
		CurrentList = Items.PackageRedemptionDocuments;
	EndIf;
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, CurrentList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Function ReportErrorsInGeneratingDataForFillingInReturningRedeemingContainers(SampleBankingDetails)
	
	Cancel = False;
	
	MessageText = NStr("vi = 'Các dòng được chọn trong chứng từ mua lại có trường khác ""% ViewFields%""';
						|ru = 'У выделенных строк в документе приобретения отличается поле ""%FieldPresentation%""';
						|en = 'The ""%FieldPresentation%"" field of the selected purchase document lines differs'; fa = 'The ""%FieldPresentation%"" field of the selected purchase document lines differs';
						|it = 'Le righe evidenziate nel documento di acquisto hanno il campo ""%FieldPresentation%"" diverso';
						|pl = 'W wybranych wierszach w dokumencie nabycia różni się pole ""%FieldPresentation%""';
						|tr = 'Satın alma belgesinde seçili satırlarda farklı bir ""%FieldPresentation%"" alanı vardır'");
	
	If SampleBankingDetails.ThereAreDifferencesPartner Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Nhà cung cấp';
																|ru = 'Поставщик';
																|en = 'Vendor'; fa = 'تأمین‌کننده';
																|it = 'Fornitore';
																|pl = 'Dostawca';
																|tr = 'Tedarikçi'")),
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
																|tr = 'İş kolu'")),
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
																|tr = 'KDV Vergilendirmesi'")),
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
	
	WhenChangingSelectionForReturnPeriod(ReceivedPackage, FilterReturnCycleLength, FilterReturnDate);
	
EndProcedure


&AtClient
Procedure WhenClearingSelectionByReturnDate(List, ReturnCycleLength, ReturnDate, StandardProcessing)
	
	StandardProcessing = False;
	If ReturnCycleLength <> "Any" Then
		ReturnCycleLength = NStr("vi = 'Bất kỳ';
								|ru = 'Любой';
								|en = 'Any'; fa = 'هر';
								|it = 'Qualsiasi';
								|pl = 'Dowolny';
								|tr = 'Herhangi'");
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
	
	If Items.ReceivedPackage.CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
										|ru = 'Команда не может быть выполнена для указанного объекта.';
										|en = 'Command cannot be executed for the specified object.'; fa = 'Command cannot be executed for the specified object.';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
										|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
										|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	RowsArray = New Array();
	ThereAreReceipts = False;
	ThereAreReceiptsOfRawMaterials = False;
	For Each CurRow In Items.ReceivedPackage.SelectedRows Do
		
		If TypeOf(CurRow) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		RowData = Items.ReceivedPackage.RowData(CurRow);
		RowsArray.Add(RowData);
			ThereAreReceipts = True;

	EndDo;
	If ThereAreReceipts And ThereAreReceiptsOfRawMaterials Then
		
		MessageText = NStr("vi = 'Một lệnh không thể được thực thi cùng lúc đối với các bao bì nhận được từ các nhà cung cấp và cho các bao bì nhận từ các nhà cung cấp.';
							|ru = 'Команда не может быть выполнена одновременно для тары, полученной от давальцев, и для тары, полученной от поставщиков.';
							|en = 'Command can not be executed simultaneously for package received from processors and vendors.'; fa = 'Command can not be executed simultaneously for package received from processors and vendors.';
							|it = 'Il comando non può essere eseguito simultaneamente per l''imballaggio ricevuto dai prestatori e per quello ricevuto dai fornitori.';
							|pl = 'Polecenie nie może być wykonane jednocześnie dla tary, otrzymanej od właścicieli surowców i dla tary otrzymanej od dostawców.';
							|tr = 'Komut, sağlayıcılardan alınan ambalajlar ve tedarikçilerden alınan ambalajlar için aynı anda gerçekleştirilemez.'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
		
	EndIf;
	If OperationType = "Buyout" Then
		NameOfDocumentForm = "Document.RedemptionOfReturnablePackagingFromVendor.Form.DocumentForm";
	Else // "Refund"
		NameOfDocumentForm = "Document.ReturnOfGoodsToVendor.Form.DocumentForm";
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
	
	TypeOfReceipt = New TypeDescription("DocumentRef.VendorInvoice");
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.VendorInvoice"));
	TypeOfReceipt = New TypeDescription(TypesArray);
	PackageTable = New ValueTable();
	PackageTable.Columns.Add("Partner",                 New TypeDescription("CatalogRef.Partners"));
	PackageTable.Columns.Add("Products",            New TypeDescription("CatalogRef.Products"));
	PackageTable.Columns.Add("Characteristic",          New TypeDescription("CatalogRef.ItemsCharacteristics"));
	PackageTable.Columns.Add("Count",              New TypeDescription("Number"));
	PackageTable.Columns.Add("Sum",                   New TypeDescription("Number"));
	PackageTable.Columns.Add("DocumentInflow",     TypeOfReceipt);
	PackageTable.Columns.Add("DepositForPackageIsRequired", New TypeDescription("Boolean"));
	
	For Each CurRow In RowsArray Do
		
		NewRow = PackageTable.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.Count = CurRow.CountBalance;
		NewRow.Sum = CurRow.SumBalance;
		NewRow.DocumentInflow = CurRow.DocumentInflow;
		NewRow.DepositForPackageIsRequired = CurRow.DepositForPackageIsRequired;
		
	EndDo;
	
	Query = New Query("
	|SELECT
	|	PackageTable.Partner                 AS Partner,
	|	PackageTable.Products            AS Products,
	|	PackageTable.Characteristic          AS Characteristic,
	|	PackageTable.Count              AS Count,
	|	PackageTable.DocumentInflow     AS DocumentInflow,
	|	PackageTable.DepositForPackageIsRequired AS DepositForPackageIsRequired
	|INTO
	|	TTTareTable
	|FROM
	|	&PackageTable AS PackageTable
	|;
	|SELECT
	|	MIN(TTTareTable.Partner)                                        AS Partner,
	|	MIN(TTTareTable.DocumentInflow.Counterparty)                 AS Counterparty,
	|	MIN(TTTareTable.DocumentInflow.Contract)                    AS Contract,
	|	MIN(TTTareTable.DocumentInflow.Organization)                AS Organization,
	|	MIN(TTTareTable.DocumentInflow.Department)              AS Department,
	|	MIN(TTTareTable.DocumentInflow.Terms)                 AS Terms,
	|	MIN(TTTareTable.DocumentInflow.LineOfBusiness)    AS LineOfBusiness,
	|	MIN(TTTareTable.DocumentInflow.BusinessOperation)      AS BusinessOperation,
	|	MIN(TTTareTable.DocumentInflow.Currency)                     AS Currency,
	|	MIN(CASE
	|				WHEN TTTareTable.DocumentInflow REFS Document.VendorInvoice 
	|					THEN TTTareTable.DocumentInflow.ARAPCurrency
	|				ELSE TTTareTable.DocumentInflow.Currency
	|			END)                                                        AS ARAPCurrency,
	|	MIN(TTTareTable.DocumentInflow.Terms.PaymentMethod)     AS PaymentMethod,
	|	MIN(CASE 
	|				WHEN NOT TTTareTable.DocumentInflow.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef) 
	|					THEN TTTareTable.DocumentInflow.Contract.ForeignCurrencyTransaction
	|				ELSE TTTareTable.DocumentInflow.Terms.ForeignCurrencyTransaction
	|			END)                                                        AS ForeignCurrencyTransaction,
	|	MIN(TTTareTable.DocumentInflow.VATTaxation)         AS VATTaxation,
	|	MIN(TTTareTable.DocumentInflow.PriceIncludesVAT)            AS PriceIncludesVAT,
	|	MIN(TTTareTable.DepositForPackageIsRequired)                        AS DepositForPackageIsRequired,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Warehouse) = 1 AND
	|			MAX(TTTareTable.DocumentInflow.Warehouse.IsFolder) = FALSE
	|		THEN
	|			MAX(TTTareTable.DocumentInflow.Warehouse)
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
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
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Counterparty) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCounterparty,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Organization) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCompany,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Terms) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesAgreement,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Contract) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesContract,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.LineOfBusiness) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInDirectionOfActivity,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.BusinessOperation) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesEconomicOperation,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Currency) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCurrency,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CASE
	|									WHEN TTTareTable.DocumentInflow REFS Document.VendorInvoice 
	|										THEN TTTareTable.DocumentInflow.ARAPCurrency
	|									ELSE TTTareTable.DocumentInflow.Currency
	|								END) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInCurrencyOfMutualSettlements,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.VATTaxation) > 1
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
	|						TTTareTable.DocumentInflow.CompanyBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentInflow.CompanyBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Organization) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentInflow.CompanyBankAccount)
	|		ELSE
	|			VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|	END AS CompanyBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentInflow.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentInflow.CounterpartyBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT TTTareTable.DocumentInflow.Counterparty) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentInflow.CounterpartyBankAccount)
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS CounterpartyBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentInflow.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentInflow.Shipper
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentInflow.Shipper)
	|		ELSE
	|			VALUE(Catalog.Counterparties.EmptyRef)
	|	END AS GoodsRecipient,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentInflow.ShipperBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentInflow.ShipperBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						TTTareTable.DocumentInflow.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						TTTareTable.DocumentInflow.Shipper
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(TTTareTable.DocumentInflow.ShipperBankAccount)
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS GoodsRecipientBankAccount
	|FROM
	|	TTTareTable AS TTTareTable
	|");
	
	Query.SetParameter("PackageTable", PackageTable);
	
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
		CommonClientServer.MessageToUser(ErrorText);
		
		Return Undefined;
		
	Else
		
		HeaderAttributes = New Structure();
		HeaderAttributes.Insert("Partner",                       SampleBankingDetails.Partner);
		HeaderAttributes.Insert("Counterparty",                    SampleBankingDetails.Counterparty);
		HeaderAttributes.Insert("Contract",                       SampleBankingDetails.Contract);
		HeaderAttributes.Insert("Organization",                   SampleBankingDetails.Organization);
		HeaderAttributes.Insert("Department",                 SampleBankingDetails.Department);
		HeaderAttributes.Insert("Warehouse",                         SampleBankingDetails.Warehouse);
		HeaderAttributes.Insert("Terms",                    SampleBankingDetails.Terms);
		HeaderAttributes.Insert("LineOfBusiness",       SampleBankingDetails.LineOfBusiness);
		HeaderAttributes.Insert("BusinessOperation",         PurchasesServer.GetRefundTransactionOnReceipt(SampleBankingDetails.BusinessOperation));
		HeaderAttributes.Insert("Currency",                        SampleBankingDetails.Currency);
		HeaderAttributes.Insert("ARAPCurrency",          SampleBankingDetails.ARAPCurrency);
		HeaderAttributes.Insert("PaymentMethod",                   SampleBankingDetails.PaymentMethod);
		HeaderAttributes.Insert("ForeignCurrencyTransaction",                 SampleBankingDetails.ForeignCurrencyTransaction);
		HeaderAttributes.Insert("VATTaxation",            SampleBankingDetails.VATTaxation);
		HeaderAttributes.Insert("PriceIncludesVAT",               SampleBankingDetails.PriceIncludesVAT);
		HeaderAttributes.Insert("GoodsRecipient",               SampleBankingDetails.GoodsRecipient);
		HeaderAttributes.Insert("GoodsRecipientBankAccount", SampleBankingDetails.GoodsRecipientBankAccount);
		HeaderAttributes.Insert("CompanyBankAccount",     SampleBankingDetails.CompanyBankAccount);
		HeaderAttributes.Insert("CounterpartyBankAccount",     SampleBankingDetails.CounterpartyBankAccount);
		HeaderAttributes.Insert("DepositForPackageIsRequired",       SampleBankingDetails.DepositForPackageIsRequired);
		
		ContainerAddressInTemporaryStorage = PutToTempStorage(PackageTable, UUID);
		Return New Structure(
						"HeaderAttributes,ContainerAddressInTemporaryStorage,FillInAcceptedContainer",
						HeaderAttributes,
						ContainerAddressInTemporaryStorage);
		
	EndIf;
	
EndFunction

&AtServer
Procedure SetPartnerSelection_()
	
	CommonClientServer.SetDynamicListFilterItem(ReceivedPackage,          "Partner", FilterPartner, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterPartner));
	CommonClientServer.SetDynamicListFilterItem(PackageReturnsDocuments, "Partner", FilterPartner, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterPartner));
	CommonClientServer.SetDynamicListFilterItem(PackageRedemptionDocuments,   "Partner", FilterPartner, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterPartner));
	
EndProcedure

&AtServer
Procedure SetSelectionByManager()
	
	CommonClientServer.SetDynamicListFilterItem(ReceivedPackage,          "DocumentInflow.Manager", FilterManager, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterManager));
	CommonClientServer.SetDynamicListFilterItem(PackageReturnsDocuments, "Manager", FilterManager, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterManager));
	CommonClientServer.SetDynamicListFilterItem(PackageRedemptionDocuments,   "Manager", FilterManager, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterManager));
	
EndProcedure

&AtServer
Procedure SetRequestTextAcceptedContainer()
	
	QueryText =
	"SELECT ALLOWED
	|	VALUETYPE(UNDEFINED) AS AvailableType
	|INTO AvailableRevenueTypes
	|
	|UNION ALL
	|
	|SELECT
	|	TYPE(Document.VendorInvoice) AS AvailableType
	|WHERE
	|	&AcquisitionIsAvailable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AccumulationRegisterReceivedReturnablePackagingBalance.Products AS Products,
	|	AccumulationRegisterReceivedReturnablePackagingBalance.Characteristic AS Characteristic,
	|	AccumulationRegisterReceivedReturnablePackagingBalance.Partner AS Partner,
	|	AccumulationRegisterReceivedReturnablePackagingBalance.DepositIsRequired AS DepositForPackageIsRequired,
	|	AccumulationRegisterReceivedReturnablePackagingBalance.DocumentInflow AS DocumentInflow,
	|	AccumulationRegisterReceivedReturnablePackagingBalance.DocumentInflow.ReusablePackagesReturnDate AS ReusablePackagesReturnDate,
	|	AccumulationRegisterReceivedReturnablePackagingBalance.CountBalance AS CountBalance,
	|	AccumulationRegisterReceivedReturnablePackagingBalance.SumBalance AS SumBalance,
	|	CASE
	|		WHEN AccumulationRegisterReceivedReturnablePackagingBalance.DocumentInflow.ReusablePackagesReturnDate <= ENDOFPERIOD(&ReturnDate, DAY)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Overdue
	|FROM
	|	AccumulationRegister.ReceivedReturnablePackaging.Balance(
	|			,
	|			VALUETYPE(DocumentInflow) IN
	|				(SELECT
	|					AvailableType
	|				FROM
	|					AvailableRevenueTypes)
	|		) AS AccumulationRegisterReceivedReturnablePackagingBalance
	|";
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ReceivedPackage);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.ReceivedPackage, ListProperties);
	
EndProcedure

#EndRegion
