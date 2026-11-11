//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("DocumentRef.AccrualOfVendorRebates") Then
		
		DocumentAccruals = FillingData; // DocumentRef.AccrualOfVendorRebates
		FillInAccordingToAccrualDocument(DocumentAccruals, StandardProcessing);
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	DocumentsWithoutPeriod = TermsAndConditionsDocumentsWithBonusTypeBalances();
	DateEmpty = Date(1, 1, 1);
	
	FieldKind = "Column";
	ListName = NStr("vi = 'Diễn giải các khoản ghi giảm';
					|ru = 'Расшифровка списаний';
					|en = 'Drill down write-offs'; fa = 'جزئیات اسقاط‌ها';
					|it = 'Расшифровка списаний';
					|pl = 'Drill down write-offs';
					|tr = 'Kayıtların deşifresi'");
	NameOfBeginningOfPeriodField = NStr("vi = 'Đầu kỳ';
										|ru = 'Начало периода';
										|en = 'Period start'; fa = 'شروع دوره';
										|it = 'Начало периода';
										|pl = 'Początek okresu';
										|tr = 'Dönem başı'");
	NameOfEndOfPeriodField = NStr("vi = 'Kết thúc kỳ';
									|ru = 'Окончание периода';
									|en = 'Period end'; fa = 'پایان دوره';
									|it = 'Окончание периода';
									|pl = 'Koniec okresu';
									|tr = 'Dönem sonu'");
	
	For Each CurrentRow In DrillDownDebits Do
		
		LineNumber = CurrentRow.LineNumber;
		
		If DocumentsWithoutPeriod.Find(CurrentRow.TermDocument) = Undefined
		   And ValueIsFilled(CurrentRow.TermDocument) Then
			
			If CurrentRow.BeginOfPeriod = DateEmpty Then
				
				PathToField = CommonClientServer.PathToTabularSection(
					"DrillDownDebits", LineNumber, "BeginOfPeriod");
				MessageText = CommonClientServer.FillingErrorText(
					FieldKind,
					,
					NameOfBeginningOfPeriodField,
					LineNumber,
					ListName);
				Common.MessageToUser(MessageText, ThisObject, PathToField,, Cancel);
				
			EndIf;
			
			If CurrentRow.PeriodEnding = DateEmpty Then
				
				PathToField = CommonClientServer.PathToTabularSection(
					"DrillDownDebits", LineNumber, "PeriodEnding");
				MessageText = CommonClientServer.FillingErrorText(
					FieldKind,
					,
					NameOfEndOfPeriodField,
					LineNumber,
					ListName);
				Common.MessageToUser(MessageText, ThisObject, PathToField,, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi chứng từ trong nút phụ trao đổi';
							|ru = 'Запрещено изменение документа в подчиненном узле обмена';
							|en = 'Cannot change the document in a subordinate exchange node'; fa = 'Cannot change the document in a subordinate exchange node';
							|it = 'Запрещено изменение документа в подчиненном узле обмена';
							|pl = 'Cannot change the document in a subordinate exchange node';
							|tr = 'Bağımlı değişim düğümündeki belgenin değiştirilmesi yasaktır'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	BonusCurrencies = DrillDownDebits.UnloadColumn("Currency");
	BonusCurrencies = CommonClientServer.CollapseArray(BonusCurrencies); // Array of CatalogRef.Currencies
	
	MulticurrencyDocument = (BonusCurrencies.Count() > 1);
	
	If MulticurrencyDocument Then
		
		DocumentAmount = 0;
		Currency = Catalogs.Currencies.EmptyRef();
		
	Else
		
		DocumentAmount = DrillDownDebits.Total("Sum");
		If BonusCurrencies.Count() > 0 Then
			Currency = BonusCurrencies[0];
		Else
			Currency = Catalogs.Currencies.EmptyRef();
		EndIf;
		
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
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

#EndRegion

#Region Private

// Returns:
//  Array of DocumentRef.ConditionsOfVendorRebates
//
Function TermsAndConditionsDocumentsWithBonusTypeBalances()
	
	Column = "TermDocument";
	TermsDocuments = DrillDownDebits.Unload().UnloadColumn(Column);  // Array of DocumentRef.ConditionsOfVendorRebates
	
	Query = New Query;
	Query.SetParameter("TermsDocuments", TermsDocuments);
	Query.Text =
	"SELECT
	|	ConditionsOfVendorRebates.Ref AS TermDocument
	|FROM
	|	Document.ConditionsOfVendorRebates AS ConditionsOfVendorRebates
	|WHERE
	|	ConditionsOfVendorRebates.Ref IN (&TermsDocuments)
	|	AND ConditionsOfVendorRebates.BonusType = VALUE(Enum.VendorRebateTypes.Balance)";
	
	Return Query.Execute().Unload().UnloadColumn(Column);
	
EndFunction

#Region InitializationAndFilling

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If GetFunctionalOption("UseApprovalOfVendorRebateWriteOffs") Then
		
		Status = Enums.RebatesDocumentStatuses.Draft;
		
	Else
		
		Status = Enums.RebatesDocumentStatuses.Approved;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InputOnBasis

// Parameters:
//  DocumentAccruals - DocumentRef.AccrualOfVendorRebates
//  StandardProcessing - Boolean - 
//
Procedure FillInAccordingToAccrualDocument(DocumentAccruals, StandardProcessing)
	
	FillingData = Documents.AccrualOfVendorRebates.DataOfAccrualDocument(DocumentAccruals);
	
	HeaderData_ = FillingData.Header;
	RowsData = FillingData.RowsData;
	Counterparties = FillingData.Counterparties;
	
	HeaderData_.Next();
	BonusType = HeaderData_.BonusType;
	
	If Counterparties.Count() > 1
	   And BonusType = Enums.VendorRebateTypes.Purchases Then
		
		NotificationText2 = NStr("vi = 'Trong chứng từ tính toán đã chỉ ra một số đối tác. Không thể xác định đối tác để tạo chứng từ ghi giảm.';
								|ru = 'В документе начисления указаны несколько контрагентов. Невозможно определить контрагента для создания документа списания.';
								|en = 'The accrual document contains several counterparties. Cannot identify the counterparty for creating the write-off document.'; fa = 'The accrual document contains several counterparties. Cannot identify the counterparty for creating the write-off document.';
								|it = 'В документе начисления указаны несколько контрагентов. Невозможно определить контрагента для создания документа списания.';
								|pl = 'The accrual document contains several counterparties. Cannot identify the counterparty for creating the write-off document.';
								|tr = 'Tahakkuk belgesinde çeşitli cari hesaplar belirtilmiş. Mahsup belgesinin oluşturulması için bir cari hesap tanımlanamaz.'");
		Raise NotificationText2;
		
	Else
		
		FillPropertyValues(ThisObject, HeaderData_);
		
		If BonusType = Enums.VendorRebateTypes.Purchases
		   And Counterparties.Count() > 0 Then
			
			Counterparties.Next();
			Counterparty = Counterparties.Counterparty;
			
		EndIf;
		
		While RowsData.Next() Do
			
			NewRow = DrillDownDebits.Add();
			FillPropertyValues(NewRow, RowsData);
			NewRow.Currency = HeaderData_.Currency;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf