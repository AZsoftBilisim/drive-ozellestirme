
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters,,
	                        "CloseOnChoice, CloseOnOwnerClose, ReadOnly");
	

	FillInPeriods();

	If Terms = Undefined Then
		If DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate)
			Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
			Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
			Or DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
			
		Else
			Terms = Catalogs.TermsOfSale.EmptyRef();
		EndIf;
	EndIf;
	
	CustomerAgreementsAreApplicable    = True;
	AgreementsWithSuppliersAreApplicable = True;
	If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
		CustomerAgreementsAreApplicable = Handler.CustomerAgreementsAreApplicable();
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
		CustomerAgreementsAreApplicable = Handler.CustomerAgreementsAreApplicable();
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		CustomerAgreementsAreApplicable = False;
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		AgreementsWithSuppliersAreApplicable = False;
	EndIf;
	TransferOption = "Variant1";
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		Items.InformationLabelSelections.Height = 1;
	EndIf;
	
	FillInDocumentTable();
	CreateInformationLabelSelections();
	GenerateInformationLabelNumberOfDocuments(ThisForm);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure FillInPeriods()
	
	If Not BasisDocuments.Count() = 0 Then
		
		If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableName = "Document.CustomerInvoice";

		ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableName = "Document.GoodsShipmentToCustomer";
			
		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
			
			TableName = "Document.VendorInvoice";
			
		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
			
			TableName = "Document.ReturnOfGoodsFromCustomer";
			
		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor Then
			
			TableName = "Document.ReturnOfGoodsToVendor";
			
		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
			  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
			Then
			
			TableName = "Document.GoodsReceiptForStorage";
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableName = "Document.TransferOfGoodsToBailee";
			
		ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
			TableName = "Document.ReceiptOfGoodsFromCustodian";
			
		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage
			  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
			  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
			Then
			
			TableName = "Document.GoodsShipmentFromStorage";
			
		Else
			
			Raise NStr("vi = 'Kiểu chứng từ cơ sở không xác định.';
						|ru = 'Не известный тип документа-основания.';
						|en = 'Unknown base document type.'; fa = 'Unknown base document type.';
						|it = 'Tipo di documento-causale sconosciuto.';
						|pl = 'Nieznany rodzaj dokumentu podstawy.';
						|tr = 'Bilinen bir temel belge türü değildir.'");
			
		EndIf;
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	MIN(DocumentTable.Date)  AS MinDate,
		|	MAX(DocumentTable.Date) AS MaxDate
		|FROM
		|	&DocumentTable AS DocumentTable
		|WHERE
		|	DocumentTable.Ref IN(&BasisDocuments)
		|
		|ORDER BY
		|	MinDate";
		
		Query.Text = StrReplace(Query.Text, "&DocumentTable", TableName);
		Query.SetParameter("BasisDocuments", BasisDocuments);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
		
			Period.StartDate    = AddMonth(Selection.MinDate, - 1);
			Period.EndDate = AddMonth(Selection.MaxDate, 1);
		
		EndDo;
		
	EndIf;
	
	If Period.StartDate = Date(1, 1, 1) And Period.EndDate = Date(1, 1, 1) Then
		Period.Variant = StandardPeriodVariant.Month;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText,  StandardProcessing)
	
	ClearMessages();
	
	If CloseForm
		Or Exit Then
		Return;
	EndIf;
	
	RowsSelected = Basis1.FindRows(New Structure("Selected", True)); 
	SelectedBases = New Array;
	For Each RowSelected In RowsSelected Do 
		SelectedBases.Add(RowSelected["Ref"]);
	EndDo;
	
	If Modified And Not MoveToDocument Then
		
		HasChanges = False;
		
		If SelectedBases.Count() <> BasisDocuments.Count() Then
			HasChanges = True;
		ElsIf SelectedBases.Count() = 0 Or BasisDocuments.Count() = 0 Then
			
			HasChanges = True;
			
		Else
			For Each SelectedBase In SelectedBases Do
				If BasisDocuments.FindByValue(SelectedBase) = Undefined Then
					HasChanges = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If HasChanges Then
			QueryText = NStr("vi = 'Thành phần chứng từ cơ sở đã thay đổi. Tiếp nhận thay đổi? ';
							|ru = 'Состав документов-оснований был изменен. Принять изменения?';
							|en = 'Content of base documents was changed. Accept changes?'; fa = 'Content of base documents was changed. Accept changes?';
							|it = 'La struttura dei documenti-causali è stata modificata. Accettare le modifiche?';
							|pl = 'Skład dokumentów-podstaw został zmieniony. Akceptować zmiany?';
							|tr = 'Temel belgelerin yapısı değiştirilmiştir. Değişiklikler kabul edilsin mi?'");
			HandlerNotifications = New CallbackDescription("QuestionAboutAcceptingChangesInResponse", ThisForm);
			ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.YesNoCancel);
			Cancel = True;
		EndIf;
		
	ElsIf MoveToDocument Then
		
		If SelectedBases.Count() > 1
			And Not DocumentsSelectedCorrectly(SelectedBases) Then
			
			MoveToDocument = False;
			Cancel = True;
			Return;
			
		EndIf;			
		
		If Not ClearanceIsConfirmed And TabularSectionIsNotEmpty Then
			If TransferOption = "Variant1" Then
				QueryText = NStr("vi = 'Phần bảng chứng từ sẽ bị xóa và điền lại. Tiếp tục?';
								|ru = 'Табличная часть документа будет очищена и перезаполнена. Продолжить?';
								|en = 'The table will be cleared and refilled. Do you want to continue?'; fa = 'The table will be cleared and refilled. Do you want to continue?';
								|it = 'La tabella del documento verrà cancellata e ricompilata. Continuare?';
								|pl = 'Część tabelaryczna dokumentu zostanie wyczyszczona i ponownie wypełniona. Kontynuować?';
								|tr = 'Belgenin tablo kısmı temizlenecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Phần bảng chứng từ sẽ được điền lại. Tiếp tục?';
								|ru = 'Табличная часть документа будет перезаполнена. Продолжить?';
								|en = 'Table of the document will be refilled. Continue?'; fa = 'Table of the document will be refilled. Continue?';
								|it = 'La sezione tabellare del documento verrà ricompilata. Continuare?';
								|pl = 'Część tabelaryczna dokumentu zostanie ponownie wypełniona. Kontynuować?';
								|tr = 'Belgenin tablo kısmı yeniden doldurulacaktır. Devam edilsin mi?'");
			EndIf;
			HandlerNotifications = New CallbackDescription("QuestionAboutClearingTablePartWhenAnswering", ThisForm);
			ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.YesNo);
			Cancel = True;
		Else
			
			MoveToDocument();
			Cancel = True;
			
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	FillInDocumentTable();
	
EndProcedure

#EndRegion 

#Region EventHandlersOfTablePartOfImplementation

&AtClient
Procedure SalesOfGoodsAndServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If RowSelected <> Undefined Then
		ShowValue(, Basis1.FindByID(RowSelected).Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure SalesOfGoodsAndServicesSelectedOnChange(Item)
	
	CurrentData = Items.SalesOfGoodsAndServices.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OperationSign = ?(CurrentData.Selected,1,-1);
	DocumentsCount = DocumentsCount + 1*OperationSign;
	DocumentsForAmount     = DocumentsForAmount + CurrentData.DocumentAmount*OperationSign;
	
	DisplayInformationLabelNumberOfDocuments(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure Refresh(Command)
	
	FillInDocumentTable();
	
EndProcedure

&AtClient
Procedure DisableAll(Command)
	
	SetFlagsSelected(False);
	
EndProcedure

&AtClient
Procedure SelectAll_2(Command)
	
	SetFlagsSelected(True);
	
EndProcedure

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveToDocument = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInDocumentTable()
	
	TableOfDocumentBases = New ValueTable;
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	DocumentGrounds.SaleOfGoodsAndServices AS SaleOfGoodsAndServices
	|
	|INTO SelectedDocuments
	|FROM
	|	&DocumentGrounds AS DocumentGrounds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.CustomerInvoice"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Selected,
		|	CustomerInvoice.Number,
		|	CustomerInvoice.Date,
		|	CustomerInvoice.DocumentAmount,
		|	CustomerInvoice.Ref
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON CustomerInvoice.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE 
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE CustomerInvoice.Terms = &Terms
		|	END
		|	AND CustomerInvoice.Counterparty = &Counterparty
		|	AND CustomerInvoice.Organization = &Organization
		|	AND CustomerInvoice.Partner = &Partner
		|	AND CustomerInvoice.Currency = &Currency
		|	AND CustomerInvoice.VATTaxation = &VATTaxation
		|	AND CustomerInvoice.PriceIncludesVAT = &PriceIncludesVAT
		|	AND CustomerInvoice.BusinessOperation = &BusinessOperation
		|	AND CASE
		|			WHEN &ContractIsNotRequired
		|				THEN TRUE
		|			ELSE CustomerInvoice.Contract = &Contract
		|		END
		|	AND CustomerInvoice.Posted
		|	AND CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN CustomerInvoice.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN CustomerInvoice.Date >= &StartDate
		|			ELSE CustomerInvoice.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	CustomerInvoice.Date DESC";
		
		Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));

	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices",
			New TypeDescription("DocumentRef.GoodsShipmentToCustomer"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Selected,
		|	GoodsShipmentToCustomer.Number,
		|	GoodsShipmentToCustomer.Date,
		|	GoodsShipmentToCustomer.DocumentAmount,
		|	GoodsShipmentToCustomer.Ref
		|FROM
		|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON GoodsShipmentToCustomer.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE 
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE GoodsShipmentToCustomer.Terms = &Terms
		|	END
		|	AND GoodsShipmentToCustomer.Counterparty = &Counterparty
		|	AND GoodsShipmentToCustomer.Organization = &Organization
		|	AND GoodsShipmentToCustomer.Partner = &Partner
		|	AND GoodsShipmentToCustomer.Currency = &Currency
		|	AND GoodsShipmentToCustomer.VATTaxation = &VATTaxation
		|	AND GoodsShipmentToCustomer.Contract = &Contract
		|	AND GoodsShipmentToCustomer.Posted
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN GoodsShipmentToCustomer.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN GoodsShipmentToCustomer.Date >= &StartDate
		|			ELSE GoodsShipmentToCustomer.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	GoodsShipmentToCustomer.Date DESC";
		
		Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.VendorInvoice"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Selected,
		|	VendorInvoice.Number,
		|	VendorInvoice.Date,
		|	VendorInvoice.DocumentAmount,
		|	VendorInvoice.Ref
		|FROM
		|	Document.VendorInvoice AS VendorInvoice
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON VendorInvoice.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE 
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE VendorInvoice.Terms = &Terms
		|	END
		|	AND VendorInvoice.Counterparty = &Counterparty
		|	AND VendorInvoice.Organization = &Organization
		|	AND VendorInvoice.Partner = &Partner
		|	AND VendorInvoice.Currency = &Currency
		|	AND VendorInvoice.VATTaxation = &VATTaxation
		|	AND VendorInvoice.PriceIncludesVAT = &PriceIncludesVAT
		|	AND VendorInvoice.BusinessOperation = &BusinessOperation
		|	AND VendorInvoice.GoodsReceiptOption = &GoodsReceiptOption
		|	AND CASE
		|			WHEN &ContractIsNotRequired
		|				THEN TRUE
		|			ELSE VendorInvoice.Contract = &Contract
		|		END
		|	AND VendorInvoice.Posted
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN VendorInvoice.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN VendorInvoice.Date >= &StartDate
		|			ELSE VendorInvoice.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	VendorInvoice.Date DESC";
		
		Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.TransferOfGoodsToBailee"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Selected,
		|	GoodsHandover.Number,
		|	GoodsHandover.Date,
		|	GoodsHandover.DocumentAmount,
		|	GoodsHandover.Ref
		|FROM
		|	Document.TransferOfGoodsToBailee AS GoodsHandover
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON GoodsHandover.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE GoodsHandover.Terms = &Terms
		|	END
		|	AND GoodsHandover.Counterparty = &Counterparty
		|	AND GoodsHandover.Organization = &Organization
		|	AND GoodsHandover.Partner = &Partner
		|	AND GoodsHandover.Currency = &Currency
		|	AND GoodsHandover.BusinessOperation = &BusinessOperation
		|	AND CASE
		|		WHEN &ContractIsNotRequired
		|			THEN TRUE
		|		ELSE GoodsHandover.Contract = &Contract
		|	END
		|	AND GoodsHandover.Posted
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN GoodsHandover.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN GoodsHandover.Date >= &StartDate
		|			ELSE GoodsHandover.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	GoodsHandover.Date DESC";
		
		Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisRefundFromCommissionAgent(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.ReceiptOfGoodsFromCustodian"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Selected,
		|	ReceiptFromTheCustodian.Number,
		|	ReceiptFromTheCustodian.Date,
		|	ReceiptFromTheCustodian.DocumentAmount,
		|	ReceiptFromTheCustodian.Ref
		|FROM
		|	Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON ReceiptFromTheCustodian.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE ReceiptFromTheCustodian.Terms = &Terms
		|	END
		|	AND ReceiptFromTheCustodian.Counterparty = &Counterparty
		|	AND ReceiptFromTheCustodian.Organization = &Organization
		|	AND ReceiptFromTheCustodian.Partner = &Partner
		|	AND ReceiptFromTheCustodian.Currency = &Currency
		|	AND ReceiptFromTheCustodian.BusinessOperation = &BusinessOperation
		|	AND CASE
		|		WHEN &ContractIsNotRequired
		|			THEN TRUE
		|		ELSE ReceiptFromTheCustodian.Contract = &Contract
		|	END
		|	AND ReceiptFromTheCustodian.Posted
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN ReceiptFromTheCustodian.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN ReceiptFromTheCustodian.Date >= &StartDate
		|			ELSE ReceiptFromTheCustodian.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	ReceiptFromTheCustodian.Date DESC";
		
		Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
		  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.GoodsReceiptForStorage"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	GoodsReceiptForStorage.Ref         AS Ref,
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END                                   AS Selected,
		|	GoodsReceiptForStorage.Number          AS Number,
		|	GoodsReceiptForStorage.Date           AS Date,
		|	GoodsReceiptForStorage.DocumentAmount AS DocumentAmount
		|FROM
		|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON GoodsReceiptForStorage.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE GoodsReceiptForStorage.Terms = &Terms
		|	END
		|	AND GoodsReceiptForStorage.Counterparty            = &Counterparty
		|	AND GoodsReceiptForStorage.Organization           = &Organization
		|	AND GoodsReceiptForStorage.Partner               = &Partner
		|	AND GoodsReceiptForStorage.Currency                = &Currency
		|	AND GoodsReceiptForStorage.BusinessOperation = &BusinessOperation
		|	AND CASE
		|			WHEN &ContractIsNotRequired
		|				THEN TRUE
		|			ELSE GoodsReceiptForStorage.Contract = &Contract
		|		END
		|	AND GoodsReceiptForStorage.Posted
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN GoodsReceiptForStorage.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN GoodsReceiptForStorage.Date >= &StartDate
		|			ELSE GoodsReceiptForStorage.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	GoodsReceiptForStorage.Date DESC";
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.ReturnOfGoodsFromCustomer"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Selected,
		|	ReturnOfGoodsFromCustomer.Number,
		|	ReturnOfGoodsFromCustomer.Date,
		|	ReturnOfGoodsFromCustomer.DocumentAmount,
		|	ReturnOfGoodsFromCustomer.Ref
		|FROM
		|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON ReturnOfGoodsFromCustomer.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE 
		|		WHEN NOT &UseTermsOfPurchases
		|			THEN TRUE
		|		ELSE ReturnOfGoodsFromCustomer.Terms = &Terms
		|	END
		|	AND ReturnOfGoodsFromCustomer.Counterparty = &Counterparty
		|	AND ReturnOfGoodsFromCustomer.Organization = &Organization
		|	AND ReturnOfGoodsFromCustomer.Partner = &Partner
		|	AND ReturnOfGoodsFromCustomer.Currency = &Currency
		|	AND ReturnOfGoodsFromCustomer.VATTaxation = &VATTaxation
		|	AND ReturnOfGoodsFromCustomer.PriceIncludesVAT = &PriceIncludesVAT
		|	AND ReturnOfGoodsFromCustomer.BusinessOperation = &BusinessOperation
		|	AND CASE
		|			WHEN &ContractIsNotRequired
		|				THEN TRUE
		|			ELSE ReturnOfGoodsFromCustomer.Contract = &Contract
		|		END
		|	AND ReturnOfGoodsFromCustomer.Posted
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN ReturnOfGoodsFromCustomer.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN ReturnOfGoodsFromCustomer.Date >= &StartDate
		|			ELSE ReturnOfGoodsFromCustomer.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	ReturnOfGoodsFromCustomer.Date DESC";
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.ReturnOfGoodsToVendor"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Selected,
		|	ReturnOfGoodsToVendor.Number,
		|	ReturnOfGoodsToVendor.Date,
		|	ReturnOfGoodsToVendor.DocumentAmount,
		|	ReturnOfGoodsToVendor.Ref
		|FROM
		|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON ReturnOfGoodsToVendor.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	CASE 
		|		WHEN NOT &UseTermsOfPurchases
		|			THEN TRUE
		|		ELSE ReturnOfGoodsToVendor.Terms = &Terms
		|	END
		|	AND ReturnOfGoodsToVendor.Counterparty = &Counterparty
		|	AND ReturnOfGoodsToVendor.Organization = &Organization
		|	AND ReturnOfGoodsToVendor.Partner = &Partner
		|	AND ReturnOfGoodsToVendor.Currency = &Currency
		|	AND ReturnOfGoodsToVendor.VATTaxation = &VATTaxation
		|	AND ReturnOfGoodsToVendor.PriceIncludesVAT = &PriceIncludesVAT
		|	AND ReturnOfGoodsToVendor.BusinessOperation = &BusinessOperation
		|	AND CASE
		|			WHEN &ContractIsNotRequired
		|				THEN TRUE
		|			ELSE ReturnOfGoodsToVendor.Contract = &Contract
		|		END
		|	AND ReturnOfGoodsToVendor.Posted
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN ReturnOfGoodsToVendor.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN ReturnOfGoodsToVendor.Date >= &StartDate
		|			ELSE ReturnOfGoodsToVendor.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	ReturnOfGoodsToVendor.Date DESC";
		
	Else
		
		TableOfDocumentBases.Columns.Add("SaleOfGoodsAndServices", New TypeDescription("DocumentRef.GoodsShipmentFromStorage"));
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	GoodsShipmentFromStorage.Ref         AS Ref,
		|	CASE
		|		WHEN SelectedDocuments.SaleOfGoodsAndServices IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END                                   AS Selected,
		|	GoodsShipmentFromStorage.Number          AS Number,
		|	GoodsShipmentFromStorage.Date           AS Date,
		|	GoodsShipmentFromStorage.DocumentAmount AS DocumentAmount
		|FROM
		|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
		|		LEFT JOIN SelectedDocuments AS SelectedDocuments
		|		ON GoodsShipmentFromStorage.Ref = SelectedDocuments.SaleOfGoodsAndServices
		|WHERE
		|	GoodsShipmentFromStorage.Posted
		|	AND GoodsShipmentFromStorage.Partner               = &Partner
		|	AND GoodsShipmentFromStorage.Counterparty            = &Counterparty
		|	AND GoodsShipmentFromStorage.Organization           = &Organization
		|	AND GoodsShipmentFromStorage.BusinessOperation = &BusinessOperation
		|	AND GoodsShipmentFromStorage.Currency                = &Currency
		|	AND CASE
		|			WHEN NOT &UseTermsOfPurchases
		|				THEN TRUE
		|			ELSE GoodsShipmentFromStorage.Terms = &Terms
		|		END
		|	AND CASE
		|			WHEN &ContractIsNotRequired
		|				THEN TRUE
		|			ELSE GoodsShipmentFromStorage.Contract   = &Contract
		|		END
		|	AND CASE
		|			WHEN &StartDate = &DateEmpty
		|					AND &EndDate = &DateEmpty
		|				THEN TRUE
		|			WHEN &StartDate = &DateEmpty
		|				THEN GoodsShipmentFromStorage.Date <= &EndDate
		|			WHEN &EndDate = &DateEmpty
		|				THEN GoodsShipmentFromStorage.Date >= &StartDate
		|			ELSE GoodsShipmentFromStorage.Date BETWEEN &StartDate AND &EndDate
		|		END
		|
		|ORDER BY
		|	GoodsShipmentFromStorage.Date DESC";
		
	EndIf;
	
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("ContractIsNotRequired", ContractIsNotRequired);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("BasisDocuments", BasisDocuments);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
	Query.SetParameter("PriceIncludesVAT", PriceIncludesVAT);
	Query.SetParameter("StartDate", Period.StartDate);
	Query.SetParameter("EndDate", Period.EndDate);
	Query.SetParameter("UseTermsOfPurchases", GetFunctionalOption("UseTermsOfPurchases") And AgreementsWithSuppliersAreApplicable);
	Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales") And CustomerAgreementsAreApplicable);
	Query.SetParameter("DateEmpty", Date(1, 1, 1));

	For Each ListItem In BasisDocuments Do
		NewRow = TableOfDocumentBases.Add();
		NewRow.SaleOfGoodsAndServices = ListItem.Value;
	EndDo;
	Query.SetParameter("DocumentGrounds", TableOfDocumentBases);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Basis1.Clear();
		Items.SalesOfGoodsAndServicesSelectAll_2.Enabled   = False; 
		Items.SalesOfGoodsAndServicesDisableAll.Enabled = False;
	Else
		Basis1.Load(Result.Unload());
		Items.SalesOfGoodsAndServicesSelectAll_2.Enabled   = True;
		Items.SalesOfGoodsAndServicesDisableAll.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionAboutAcceptingChangesInResponse(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		MoveToDocument = True;
		Close();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure QuestionAboutClearingTablePartWhenAnswering(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		MoveToDocument();
		
	Else
		
		MoveToDocument = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveToDocument()
	
	ArrayOfSelectedDocuments = New Array;
	RowsSelected = Basis1.FindRows(New Structure("Selected", True));
	For Each RowSelected In RowsSelected Do
		ArrayOfSelectedDocuments.Add(RowSelected["Ref"]);
	EndDo;
	
	ClearanceIsConfirmed = True;
	CloseForm = True;
	NotifyChoice(ArrayOfSelectedDocuments);
	
EndProcedure 

&AtClient
Procedure SetFlagsSelected(Include)

	For Each TableRow In Basis1 Do
		TableRow.Selected = Include;
	EndDo;
	
	If Include Then
		GenerateInformationLabelNumberOfDocuments(ThisForm)
	Else
		DocumentsCount = 0;
		DocumentsForAmount     = 0;
		DisplayInformationLabelNumberOfDocuments(ThisForm);
	EndIf;

EndProcedure

&AtServer
Procedure CreateInformationLabelSelections()
	
	If Not TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		
		If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
			InformationLabelSelections = NStr("vi = 'Lọc theo: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%';
												|ru = 'Отбор по: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%';
												|en = 'Filter by: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%'; fa = 'Filter by: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%';
												|it = 'Filter by: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%';
												|pl = 'Filter by: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%';
												|tr = 'Filtre: %Organization%, %Partner%, %Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%'");
		Else
			InformationLabelSelections = NStr("vi = 'Lọc theo: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%, %PriceIncludesVAT%';
												|ru = 'Отбор по: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%, %PriceIncludesVAT%';
												|en = 'Filter by: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%, %PriceIncludesVAT%'; fa = 'Filter by: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%, %PriceIncludesVAT%';
												|it = 'Selezione per: %Organization%, %Partner%,%Counterparty% %Currency%, %Terms%, %VATTaxation%,%Contract%%BusinessOperation%, %PriceIncludesVAT%';
												|pl = 'Filtr wg: %Organization%, %Partner%,%Counterparty% %Currency%,%Terms%, %VATTaxation%,%Contract%%BusinessOperation%, %PriceIncludesVAT%';
												|tr = 'Filtre: %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%, %Contract%, %BusinessOperation%, %PriceIncludesVAT%'");
		EndIf;
		
	Else
		InformationLabelSelections = NStr("vi = 'Lọc theo: %Counterparty%%Contract%%Terms%';
											|ru = 'Отбор по: %Counterparty%%Contract%%Terms%';
											|en = 'Filter by: %Counterparty%%Contract%%Terms%'; fa = 'Filter by: %Counterparty%%Contract%%Terms%';
											|it = 'Selezione per: %Counterparty%%Contract%%Terms%';
											|pl = 'Filtr według: %Counterparty%%Contract%%Terms%';
											|tr = 'Filtre: %Counterparty%%Contract%%Terms%'");
	EndIf;
	
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%Organization%", Organization);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%Partner%", Partner);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%Counterparty%", ?(GetFunctionalOption("UsePartnersAsCounterparties"),""," " + Counterparty  + ", "));
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%Terms%", Terms);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%Currency%", Currency);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%VATTaxation%", VATTaxation);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%Contract%", ?(ContractIsNotRequired,""," " + Contract + ", "));
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%BusinessOperation%", BusinessOperation);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%PriceIncludesVAT%", ?(PriceIncludesVAT, NStr("vi = 'Giá gồm thuế GTGT';
																														|ru = 'Цена включает НДС';
																														|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
																														|it = 'Il prezzo include l''IVA';
																														|pl = 'Cena zawiera VAT';
																														|tr = 'KDV dahil fiyat'"), NStr("vi = 'Đơn giá không gồm thuế GTGT';
																																						|ru = 'Цена не включает НДС';
																																						|en = 'Price excludes VAT'; fa = 'Price excludes VAT';
																																						|it = 'Il prezzo non include l''IVA';
																																						|pl = 'Cena nie zawiera VAT';
																																						|tr = 'KDV hariç fiyat'")));
	
	If Right(InformationLabelSelections,2) = ", " Then
		InformationLabelSelections = Left(InformationLabelSelections, StrLen(InformationLabelSelections) - 2);
	EndIf;
	
	InformationLabelSelections = InformationLabelSelections + ".";
	
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateInformationLabelNumberOfDocuments(Form)

	Form.DocumentsCount = 0;
	Form.DocumentsForAmount     = 0;
	
	For Each TableRow In Form.Basis1 Do
		If TableRow.Selected Then
			Form.DocumentsCount = Form.DocumentsCount + 1;
			Form.DocumentsForAmount     = Form.DocumentsForAmount + TableRow.DocumentAmount;
		EndIf;
	EndDo;
	
	DisplayInformationLabelNumberOfDocuments(Form);

EndProcedure

&AtClientAtServerNoContext
Procedure DisplayInformationLabelNumberOfDocuments(Form)

	If Form.DocumentsCount <> 0 Then
		LabelText = NStr("vi = 'Đã chọn %DocumentsCount% chứng từ, với số tiền %DocumentsForAmount% %Currency%.';
						|ru = 'Подобрано документов - %DocumentsCount%, на сумму %DocumentsForAmount% %Currency%.';
						|en = 'Documents selected - %DocumentsCount%, in the amount of %DocumentsForAmount% %Currency%.'; fa = 'Documents selected - %DocumentsCount%, in the amount of %DocumentsForAmount% %Currency%.';
						|it = 'Selezionati documenti - %DocumentsCount%, per l''importo di %DocumentsForAmount% %Currency%.';
						|pl = 'Dobrano dokumentów - %DocumentsCount%, na wartość %DocumentsForAmount% %Currency%.';
						|tr = 'Seçilmiş belgeler - %DocumentsCount%, tutar %DocumentsForAmount% %Currency%.'");
		LabelText = StrReplace(LabelText,"%DocumentsCount%", Form.DocumentsCount);
		LabelText = StrReplace(LabelText,"%DocumentsForAmount%", Form.DocumentsForAmount);
		LabelText = StrReplace(LabelText,"%Currency%", Form.Currency);
	Else
		LabelText = NStr("vi = 'Đã chọn 0 chứng từ.';
						|ru = 'Подобрано 0 документов.';
						|en = '0 documents selected.'; fa = '0 documents selected.';
						|it = 'Selezionati 0 documenti.';
						|pl = 'Dobrano 0 dokumentów.';
						|tr = 'Seçili belge 0.'");
	EndIf;
	
	Form.InformationLabelNumberOfDocuments = LabelText;

EndProcedure

&AtServer
Function DocumentsSelectedCorrectly(SelectedBases)
	Result = DiscrepanciesServerLocalization.DocumentsSelectedCorrectly(SelectedBases,
		TypeOfBaseDocumentForNonConformanceCertificate);
	Return Result;
EndFunction

#EndRegion

