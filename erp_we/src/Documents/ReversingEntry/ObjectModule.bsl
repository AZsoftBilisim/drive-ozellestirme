#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("Date") And ValueIsFilled(FillingData.Date) Then
			Date = FillingData.Date;
		EndIf;
		
		If FillingData.Property("ReplacementDocument") Then
			ReplacementDocument = FillingData.ReplacementDocument;
		EndIf;
		
		If FillingData.Property("ReversedDocument") Then
			ReversedDocument = FillingData.ReversedDocument;
		EndIf;
	Else
		ReversedDocument = FillingData;
	EndIf;
	
	If ValueIsFilled(ReversedDocument)
		And Metadata.DefinedTypes.CorrectedDocuments.Type.ContainsType(TypeOf(ReversedDocument)) Then
		
		If Not DocumentCorrection.RegistrationStornoIsAllowed(ReversedDocument) Then
			Raise NStr("vi = 'Không hỗ trợ đảo ngược chứng từ.';
						|ru = 'Сторнирование документа не поддерживается.';
						|en = 'Document reversing is not supported.'; fa = 'Document reversing is not supported.';
						|it = 'Lo storno del documento non è supportato.';
						|pl = 'Stornowanie dokumentu nie jest obsługiwane';
						|tr = 'Belge ters çevirme desteklenmiyor.'");
		EndIf;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	DocumentsRegistry.Organization AS Organization
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.Ref = &ReversedDocument
		|	AND DocumentsRegistry.AdditionalRecord = FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsRegistry.Ref AS Ref
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.ReversedDocument = &ReversedDocument
		|	AND DocumentsRegistry.Posted
		|";
		
		Query.SetParameter("ReversedDocument", ReversedDocument);
		QueryResults = Query.ExecuteBatch();
		
		Selection = QueryResults[0].Select();
		If Selection.Next() Then
			FillPropertyValues(ThisObject, Selection);
		Else
			Raise StrTemplate(NStr("vi = 'Theo chứng từ %1 không có dữ liệu trong danh sách chứng từ.';
									|ru = 'По документу %1 нет данных в реестре документов.';
									|en = 'The document registry contains no data for document %1.'; fa = 'The document registry contains no data for document %1.';
									|it = 'Per il documento %1 non esistono dati nel registro dei documenti.';
									|pl = 'Brak danych wg dokumentu%1 w rejestrze dokumentów.';
									|tr = '%1 belgesinde belge kayıt defterinde veri yok.'"), ReversedDocument);
		EndIf;
		
		Selection = QueryResults[1].Select();
		If Selection.Next() Then
			If TypeOf(Selection.Ref) = Type("DocumentRef.ReversingEntry") Then
				MessageText = NStr("vi = 'Đã nhập chứng từ ""Đảo ngược"" trên cơ sở.';
									|ru = 'На основании уже введен документ ""Сторно"".';
									|en = 'The ""Storno"" document is already entered using base document.'; fa = 'The ""Storno"" document is already entered using base document.';
									|it = 'Sulla base di questo documento è già stato inserito il documento ""Storno"".';
									|pl = 'Dla podstawy już wprowadzono dokument ""Storno""';
									|tr = 'Gerekçeye dayalı, ""İptal"" belgesi artık girildi.'");
			Else
				MessageText = NStr("vi = 'Trên cơ sở đã nhập chứng từ chỉnh sửa.
				                            |Cần nhập chứng từ ""Đảo ngược"" trên cơ sở chứng từ chỉnh sửa gần nhất.';
				                            |ru = 'На основании введен исправительный документ.
				                            |Документ ""Сторно"" необходимо вводить на основании последнего исправления.';
				                            |en = 'The correction document is entered using base document.
				                            |The ""Storno"" document must be entered based on the last correction.'; fa = 'The correction document is entered using base document.
				                            |The ""Storno"" document must be entered based on the last correction.';
				                            |it = 'Sulla base di questo documento è già stato inserito il documento di correzione.
				                            | Il documento ""Storno"" deve essere inserito sulla base dell''ultima correzione.';
				                            |pl = 'Dla podstawy wprowadzono już dokument korygujący.
				                            |Dokument ""Storno"" należy wprowadzić na podstawie ostatniej korekty.';
				                            |tr = 'Düzeltici belge esasında girilir.
				                            |""İptal"" belgesi son düzeltme esasında girilmelidir.'");
			EndIf;
			Raise MessageText;
		EndIf;
	EndIf;
	
	Author = Users.CurrentUser();
	
	ReversingEntryLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ReversedDocument) Then
		ErrorText = NStr("vi = 'Chưa điền ""Chứng từ được đảo ngược""';
						|ru = 'Не заполнен ""Сторнируемый документ""';
						|en = '""Reversed document"" cannot be blank'; fa = '""Reversed document"" cannot be blank';
						|it = '""Documento da stornare"" non è compilato';
						|pl = '""Stornowany dokument"" nie jest wypełniony';
						|tr = '""Tersine çevrilen belge"" doldurulmadı'");
		CommonClientServer.MessageToUser(ErrorText,, "Object.ReversedDocument", , Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	// CheckingChainOfCorrections
	TypesOfDocumentsToBeCorrected = New Array;
	TypesOfDocumentsToBeCorrected = Metadata.Documents.PurchaseAdjustment.Attributes.CorrectedDocument.Type.Types();
	CommonClientServer.SupplementArray(
		TypesOfDocumentsToBeCorrected, Metadata.Documents.SaleAdjustment.Attributes.CorrectedDocument.Type.Types(), True);
	
	If Not TypesOfDocumentsToBeCorrected.Find(TypeOf(ReversedDocument)) = Undefined Then
		
		// Define the verification parameters
		Attributes = New Structure("ReversedDocument, Date", ReversedDocument, Date);
		CorrectedDocument = Documents.ReversingEntry.CorrectedDocument(Attributes);
		CheckParameters = InformationRegisters.DocumentCorrections.DocumentCorrectionVerificationParameters();
		CheckParameters.Ref = Ref;
		CheckParameters.Date = Date;
		CheckParameters.CorrectedDocument = CorrectedDocument;
		
		// Checking for changes in the date or the document being corrected when re-checking
		ChangesDuringFollowUp = False;
		If WriteMode = DocumentWriteMode.Posting And Posted Then
			ChangesDuringFollowUp = DocumentCorrection.ParametersForCorrectingDocumentsHaveChanged(CheckParameters);
		EndIf;
		
		// Checking for the existence of documents in the chain with a longer date
		If ChangesDuringFollowUp Or WriteMode = DocumentWriteMode.UndoPosting
			Or (WriteMode = DocumentWriteMode.Posting And Not Posted) Then
			
			Patch = DocumentCorrection.CorrectionAfterDocumentDate(CheckParameters);
			If ValueIsFilled(Patch) Then
				ErrorText = NStr("vi = 'Có chỉnh sửa muộn hơn ngày của chứng từ hiện tại.
					|Đã cấm thay đổi chứng từ.';
					|ru = 'Есть исправление позднее даты текущего документа.
					|Изменение документа запрещено.';
					|en = 'There is a correction later than the current document date.
					|Cannot edit the document.'; fa = 'There is a correction later than the current document date.
					|Cannot edit the document.';
					|it = 'Есть исправление позднее даты текущего документа.
					|Изменение документа запрещено.';
					|pl = 'There is a correction later than the current document date.
					|Cannot edit the document.';
					|tr = 'Mevcut belgenin tarihinden daha sonra düzeltme mevcut.
					|Belgenin değiştirilmesi yasaktır.'");
				Common.MessageToUser(ErrorText,,,, Cancel);
			EndIf;
			
		EndIf;
		
		// Checking for up-to-date corrections of the original (corrected) document
		If Not Cancel And (ChangesDuringFollowUp Or (WriteMode = DocumentWriteMode.Posting And Not Posted)) Then
			ThereAreViolations = DocumentCorrection.AvailabilityOfCorrectionsAsOfDocumentDate(CorrectedDocument, ReversedDocument, Date);
			If ThereAreViolations Then
				ErrorText = NStr("vi = 'Đã nhập chỉnh sửa trên cơ sở chứng từ gốc.
					|Cấm thay đổi chứng từ.';
					|ru = 'На основании исходного документа введено исправление.
					|Изменение документа запрещено.';
					|en = 'A correction is registered based on the source document.
					|Cannot change the document.'; fa = 'A correction is registered based on the source document.
					|Cannot change the document.';
					|it = 'На основании исходного документа введено исправление.
					|Изменение документа запрещено.';
					|pl = 'A correction is registered based on the source document.
					|Cannot change the document.';
					|tr = 'Temel belge esas alınarak düzeltme yapılmıştır.
					|Belgenin değiştirilmesi yasaktır.'");
				Common.MessageToUser(ErrorText,,,, Cancel);
			EndIf;
		EndIf;
		
	EndIf;
	// End CheckingChainOfCorrections
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ReversingEntryLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReversingEntryLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Raise NStr("vi = 'Không cho phép sao chép chứng từ ""Đảo ngược"".';
				|ru = 'Копирование документа ""Сторно"" не предусмотрено.';
				|en = 'The ""Storno"" document cannot be copied.'; fa = 'The ""Storno"" document cannot be copied.';
				|it = 'Non è prevista la possibilità di copiare il documento ""Storno"".';
				|pl = 'Kopiowanie dokumentu ""Storno"" nie jest przewidziane.';
				|tr = '""İptal"" belgesinin kopyası tasarlanmadı.'")
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;

	If Not Cancel Then
		DocumentCorrection.CheckFillingOfStorno(ThisObject, Cancel, CheckedAttributes);
	EndIf;

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If Metadata.DefinedTypes.DeliveryReferenceOrder.Type.ContainsType(TypeOf(ReversedDocument)) Then
		GoodsDelivery.ReflectDeliveryState(ReversedDocument, Cancel);
	EndIf;
	
	ReversingEntryLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
		OtherAssetsLiabilitiesServer.CreateTaskForNonOperationalDocumentExecution(ThisObject);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Metadata.DefinedTypes.DeliveryReferenceOrder.Type.ContainsType(TypeOf(ReversedDocument)) Then
		GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	EndIf;
	
	ReversingEntryLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InventoryKinds

Procedure InitializeParametersForFillingInventoryTypesForConducting(WriteMode)
	
	ManagerOfDocument = Common.ObjectManagerByRef(ReversedDocument);
	DocumentMechanisms = DocumentsPosting.DocumentAccountingMechanisms(ManagerOfDocument);
	If DocumentMechanisms.Find("OperationalAccountingOfGoodsOfOrganizations") <> Undefined Then
		
		ObjectBeingReversed = ReversedDocument.GetObject();
		ObjectBeingReversed.InitializeParametersForFillingInventoryTypesForConducting(ThisObject, WriteMode);
		
		If AdditionalProperties.Property("ParametersForFillingInventoryTypes")
			And TypeOf(AdditionalProperties.ParametersForFillingInventoryTypes) = Type("Structure") Then
			AdditionalProperties.ParametersForFillingInventoryTypes.DocumentMakesBothArrivalAndExpenditure = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
