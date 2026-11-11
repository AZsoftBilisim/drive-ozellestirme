
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("CashRegister") And ValueIsFilled(FillingData.CashRegister) Then
			FillInDocumentAtCashRegister(FillingData.CashRegister);
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.GiftCertificateSale") Then
		
		If ValueIsFilled(FillingData.CashRegister) Then
			FillInDocumentAtCashRegister(FillingData.CashRegister);
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	EndIf;
	
	If Not ValueIsFilled(Counterparty) Then
		Counterparty = Catalogs.Counterparties.RetailCustomer;
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			FillOutGiftCertificates(Cancel);
			
			FillInCalculationObject();
			
		ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
			
			Cancel = True;
			
			ErrorText = NStr("vi = 'Phiếu tính tiền đã đánh. Không thể hủy bỏ kết chuyển';
							|ru = 'Чек ККМ пробит. Отмена проведения невозможна';
							|en = 'Receipt is issued. Posting cancellation is unavailable'; fa = 'Receipt is issued. Posting cancellation is unavailable';
							|it = 'Scontrino del registratore di cassa è stato emesso. Cancellazione impossibile';
							|pl = 'Wydrukowano paragon fiskalny. Anulowanie jest niemożliwe';
							|tr = 'Kasa fişi kesilmiştir. İptal mümkün değildir'");
			
			Common.MessageToUser(
				ErrorText,
				ThisObject);
				
			Return;
			
		EndIf;
		
	Else
		
		For Each TSRow In GiftCertificates Do
			TSRow.ARAPObject = Undefined;
		EndDo;
		
	EndIf;
	
	DocumentAmount = GiftCertificates.Total("Sum");
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "GiftCertificates,PaymentWithPaymentCards");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status           = Undefined;
	
	ReceivedInCash = 0;
	PaymentWithPaymentCards.Clear();
	
	RegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	FillPropertyValues(ThisObject, RegisterShiftState);
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "GiftCertificates,PaymentWithPaymentCards");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	If ItemAttributeValuesHaveChanged(ThisObject, CheckedAttributes) Then
		GiftCertificatesServer.FillCheckProcessing(ThisObject, Cancel);
	EndIf;
	RetailSales.CheckPaymentCompletionWithPaymentCards(ThisObject, Cancel);

EndProcedure

#EndRegion

#Region Private

Function SelectionOfGiftCertificatesToFillInDocument()
	
	ArrayOfGiftCertificates = GiftCertificates.UnloadColumn("GiftCertificate");
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GiftCertificates.Ref AS GiftCertificate,
	|	&Organization AS Organization,
	|	GiftCertificateKinds.GiftCardAccounting25
	|FROM
	|	Catalog.GiftCertificates AS GiftCertificates
	|		LEFT JOIN Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|		ON GiftCertificates.Owner = GiftCertificateKinds.Ref
	|WHERE
	|	GiftCertificates.Ref IN(&ArrayOfGiftCertificates)
	|	AND (NOT GiftCertificateKinds.GiftCardAccounting25
	|		AND ( FALSE
	|			OR &Organization <> GiftCertificates.Organization
	|		  )
	|		)";
	Query.SetParameter("ArrayOfGiftCertificates", ArrayOfGiftCertificates);
	Query.SetParameter("Organization", Organization);
	
	Return Query.Execute().Select();
	
EndFunction

Procedure FillOutGiftCertificates(Cancel)
	
	Selection = SelectionOfGiftCertificatesToFillInDocument();
	
	While Selection.Next() Do
		
		If Selection.GiftCardAccounting25 Then
			Continue;
		EndIf;

		DataToFill = New Map;
		DataToFill.Insert("Organization", Selection.Organization);
		
		Try
			// Before the 2.5 gift certificate is recorded, the associated payment object will be updated.
			Catalogs.GiftCertificates.FillInAttributesOfGiftCertificate(Selection.GiftCertificate, DataToFill);
		Except
			ErrorInfo = ErrorInfo();
			
			ErrorDescription = NStr("vi = 'Khi ghi lại phần tử danh mục ""Phiếu quà tặng"" %GiftCertificate%, đã xảy ra lỗi.
								|Mô tả bổ sung:
								|%AdditionalDetails%';
								|ru = 'При записи элемента справочника ""Подарочные сертификаты"" %GiftCertificate% произошла ошибка.
								|Дополнительное описание:
								|%AdditionalDetails%';
								|en = 'An error occurred when saving the %GiftCertificate% item of the Gift cards catalog.
								|Additional details:
								|%AdditionalDetails%'; fa = 'An error occurred when saving the %GiftCertificate% item of the Gift cards catalog.
								|Additional details:
								|%AdditionalDetails%';
								|it = 'Durante il blocco dell''elemento di anagrafica ""Buoni regalo"" %GiftCertificate%si è verificato un errore.
								|Descrizione aggiuntiva:
								|%AdditionalDetails%';
								|pl = 'Podczas zapisu elementu katalogu ""Certyfikaty podarunkowe"" %GiftCertificate% wystąpił błąd.
								|Opis dodatkowy:
								|%AdditionalDetails%';
								|tr = '""Hediye kuponları"" dizinine %GiftCertificate% öğesi kaydedilirken hata meydana geldi.
								| Ek açıklama:
								|%AdditionalDetails%'");
			
			ErrorDescription = StrReplace(
				ErrorDescription, 
				"%GiftCertificate%", 
				Selection.GiftCertificate);

			ErrorDescription = StrReplace(
				ErrorDescription, 
				"%AdditionalDetails%", 
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
				
			Common.MessageToUser(ErrorDescription,,,,Cancel);
			
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure FillInCalculationObject()
	
	If GiftCertificates.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	CAST(GiftCertificates.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate
	|INTO GiftCertificates
	|FROM
	|	&GiftCertificates AS GiftCertificates
	|INDEX BY
	|	GiftCertificate
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	ARAPObjects.Ref AS ARAPObject
	|FROM
	|	GiftCertificates AS GiftCertificates
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = GiftCertificates.GiftCertificate
	|			AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	GiftCertificates.GiftCertificate.Owner.GiftCardAccounting25";
	
	Query.SetParameter("GiftCertificates", GiftCertificates.Unload());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		IndexOf = Selection.LineNumber - 1;
		GiftCertificates[IndexOf].ARAPObject = Selection.ARAPObject;
	EndDo;
	
EndProcedure

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	Cashier = Users.CurrentUser();
	
	If Not ValueIsFilled(Counterparty) Then
		Counterparty = Catalogs.Counterparties.RetailCustomer;
	EndIf;
	
EndProcedure

Procedure FillInDocumentAtCashRegister(CashRegister)
	
	RegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	FillPropertyValues(ThisObject, RegisterShiftState,,"Cashier");
	
EndProcedure

#EndRegion

// Checks that the values of the transferred object details have changed relative to the values stored in the information database.
//
// Parameters:
// 		Object - DocumentObject, CatalogObject - the object being checked.
// 		ArrayOfVerifiedDetails - Array of String - Array of verified Bank details. 
//
// Returns:
// 		Boolean - True if the value of at least one of the props has changed, otherwise False.
//
Function ItemAttributeValuesHaveChanged(Object, ArrayOfVerifiedDetails)
	Var VerifiableTSDetails;
	
	If Object.IsNew() Then
		Return True;
	EndIf;
	
	AttributeValuesHaveChanged = False;
	
	// Getting Object metadata
	ObjectMetadata = Object.Ref.Metadata();
	
	// Creating a structure for storing the names of table parts and verifiable details in them.
	// 		Key - Name of the table part
	// 		Value - Array - Array of strings, details of this table part for verification.
	TabularSections = New Structure;
	VerifiedHeaderDetails = New Array;
	
	// Checking the details of the object and filling in the structure according to the details of the table parts.
	For Each Attribute In ArrayOfVerifiedDetails Do
		ComponentsOfAttribute = StrSplit(Attribute, ".");
		If ComponentsOfAttribute.Count() = 1 Then
		 	// If the object's details are specified, you need to check whether it is a tabular part
			If VerifiedHeaderDetails.Find(Attribute) = Undefined And Not TabularSections.Property(Attribute) Then
				If ObjectMetadata.TabularSections.Find(Attribute) = Undefined Then
					VerifiedHeaderDetails.Add(Attribute);
				Else	
					TabularSections.Insert(Attribute, New Array);
				EndIf;
			EndIf;
		Else
			TabularSectionName = ComponentsOfAttribute[0];
			AttributeName = ComponentsOfAttribute[1];
			// Saving the checked details of the tabular part to the structure
			If Not TabularSections.Property(TabularSectionName, VerifiableTSDetails) Then
				VerifiableTSDetails = New Array;
				TabularSections.Insert(TabularSectionName, VerifiableTSDetails);
			EndIf;
			VerifiableTSDetails.Add(AttributeName);
		EndIf;
	EndDo;
	
	QueryTextTemplate2 = "SELECT
							|&TextOfSelectionFields
							|FROM
							|	&FullObjectName AS ObjectData
							|WHERE
							|	ObjectData.Ref = &Ref";
	
	SampleFieldRequestTextTemplate = "ObjectData.%1 AS %1";
	SampleTSRequestTextTemplate = "ObjectData.%1.(
								|%2) AS %1";
	TemplateForQueryTextOfTSFieldOfSelection = "%1 AS %1";
	
	ArrayOfRequestTextsForAttributes = New Array;
	If VerifiedHeaderDetails.Count() Then
		For Each Attribute In VerifiedHeaderDetails Do
			ArrayOfRequestTextsForAttributes.Add(StrTemplate(SampleFieldRequestTextTemplate, Attribute));
		EndDo;
	EndIf;
	For Each TabularSection In TabularSections Do
		If TabularSection.Value.Count() Then
			// To correctly compare the rows of the table part, you need to add the standard "Row number" props
			StandardAttributeLineNumber = ObjectMetadata.TabularSections[TabularSection.Key].StandardAttributes.LineNumber; // StandardAttributeDescription 
			AttributeNameLineNumber = StandardAttributeLineNumber.Name;
			If TabularSection.Value.Find(AttributeNameLineNumber) = Undefined Then
				TabularSection.Value.Add(AttributeNameLineNumber);
			EndIf;
			ArrayOfQueryTextsForTSAttributes = New Array;
			For Each	Attribute In TabularSection.Value Do
				ArrayOfQueryTextsForTSAttributes.Add(StrTemplate(TemplateForQueryTextOfTSFieldOfSelection, Attribute));	
			EndDo;
			TextOfRequestForTSAttributes = StrConcat(ArrayOfQueryTextsForTSAttributes, ","+Chars.LF);
			QueryTextForTabularPart = StrTemplate(SampleTSRequestTextTemplate, TabularSection.Key, TextOfRequestForTSAttributes);
		Else
			// If a tabular part is specified for verification without specifying specific details, this means that the comparison will be carried out in the context of all the details.
			QueryTextForTabularPart = StrTemplate(SampleFieldRequestTextTemplate, TabularSection.Key);
		EndIf;	
		ArrayOfRequestTextsForAttributes.Add(QueryTextForTabularPart);
	EndDo;
	
	If ArrayOfRequestTextsForAttributes.Count() Then
		RequestTextForSelectionFields = StrConcat(ArrayOfRequestTextsForAttributes, ","+Chars.LF);
		QueryText = StrReplace(QueryTextTemplate2, "&TextOfSelectionFields", RequestTextForSelectionFields);
		QueryText = StrReplace(QueryText, "&FullObjectName", ObjectMetadata.FullName());

		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("FullObjectName", ObjectMetadata.FullName());
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			For Each	Attribute In VerifiedHeaderDetails Do
				If Selection[Attribute] <> Object[Attribute] Then
					AttributeValuesHaveChanged = True;
					Break;
				EndIf;
			EndDo;
			If Not AttributeValuesHaveChanged Then
				For Each TabularSection In TabularSections Do
					TSDataOnLink = Selection[TabularSection.Key].Unload();
					TSDataFromObject = Object[TabularSection.Key].Unload();
					ComparisonResult = TMCommonUse.CompareValueTables(TSDataOnLink, TSDataFromObject, False);
					If ComparisonResult.Count() Then
						AttributeValuesHaveChanged = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	Return AttributeValuesHaveChanged;
EndFunction

#EndRegion

#EndIf
