#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS OF INITIALIZATION AND COMPLETION OF SUPPLIER PRICE REGISTRATION

Procedure FillInDocumentBasedOnPartner(Basis)
	
	PartnerDetails_ = Common.ObjectAttributesValues(Basis, "Vendor, Competitor");
	If Not PartnerDetails_.Vendor And Not PartnerDetails_.Competitor Then
		Raise NStr("vi = 'Chỉ có thể nhập trên cơ sở ""Ghi nhận đơn giá nhà cung cấp"" đối với nhà cung cấp và đối thủ cạnh tranh!';
					|ru = 'Ввод на основании ""Регистрация цен поставщика"" возможен только для поставщика и конкурента!';
					|en = 'Generation from base document ""Vendor price registration"" basis is allowed only for vendors and competitors.'; fa = 'Generation from base document ""Vendor price registration"" basis is allowed only for vendors and competitors.';
					|it = 'Inserimento sulla base di ""Registrazione dei prezzi del fornitore"" è possibile solo per il fornitore e il concorrente!';
					|pl = 'Wpisanie na podstawie ""rejestracji cen dostawcy"" jest możliwe tylko dla dostawcy i konkurenta!';
					|tr = '""Tedarikçi Fiyat Kaydı"" temelinde giriş sadece tedarikçi ve rakip için mümkündür!'");
	EndIf;
	Partner = Basis;
	
EndProcedure

// Fills in the price registration of the supplier's nomenclature based on an agreement with a partner.
//
// Parameters:
//  Basis - link to the partner.
//
Procedure FillInDocumentBasedOnAgreementWithSupplier(Basis)
	
	Query = New Query("
		|SELECT
		|	TermsOfPurchases.Partner AS Partner,
		|	TermsOfPurchases.Ref  AS Terms
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
		|WHERE
		|	TermsOfPurchases.Ref = &Ref
		|");
		
	Query.SetParameter("Ref", Basis);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection);
	
EndProcedure

// Fills in the price registration in accordance with the selection
//
// Parameters:
// FillingData - Structure - Structure with selection values.
//
Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Terms") Then
		
		Terms = FillingData.Terms;
		FillInDocumentBasedOnAgreementWithSupplier(Terms);
		
	ElsIf FillingData.Property("Partner") Then
		
		FillInDocumentBasedOnPartner(FillingData.Partner);
		
	EndIf;
	
EndProcedure

// Initializes the setting of prices for the partner item.
//
Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();

EndProcedure

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Partners") Then
		FillInDocumentBasedOnPartner(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		FillInDocumentBasedOnAgreementWithSupplier(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.PurchaseOrder")
		Or FillInDataType = Type("DocumentRef.GoodsReceiptForStorage")
		Or FillInDataType = Type("DocumentRef.VendorInvoice") Then
		
		Documents.VendorPriceList.FillInPriceRegistrationForPurchaseDocument(FillingData, ThisObject);
		
	ElsIf FillInDataType = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		Documents.VendorPriceList.InformationOnReceiptOfGoods(FillingData, ThisObject);
	Else
		VendorPriceListLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	InitializeDocument();

EndProcedure

#EndRegion

// Parameters:
// 	Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	String = Table.Add();
	String.AccessValue = Partner;
	
EndProcedure

#EndIf
