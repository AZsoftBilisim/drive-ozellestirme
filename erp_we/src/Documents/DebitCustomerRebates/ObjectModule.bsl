//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.AccrualOfCustomerRebates") Then
		
		DocumentAccruals = FillingData; // DocumentRef.AccrualOfCustomerRebates
		
		PartyCountDetails = Common.ObjectAttributeValue(
			DocumentAccruals,
			"TermDocument.PartyCountDetails");
		
		If PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCustomer Then
			
			MessageTemplate = NStr("vi = 'Sử dụng tính toán chi tiết ""Theo khách hàng"". Không thể nhập chứng từ ""%1"".';
									|ru = 'Используется детализация расчета ""По клиенту"". Ввод документа ""%1"" не доступен.';
									|en = 'The ""By customer"" AR/AP item is used. Cannot register the ""%1"" document.'; fa = 'The ""By customer"" AR/AP item is used. Cannot register the ""%1"" document.';
									|it = 'Используется детализация расчета ""По клиенту"". Ввод документа ""%1"" не доступен.';
									|pl = 'The ""By customer"" AR/AP item is used. Cannot register the ""%1"" document.';
									|tr = '""Müşteriye göre"" hesaplama detayı kullanılır. ""%1"" belge girişi mevcut değildir.'");
			DocumentSynonym = Metadata().Synonym;
			
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DocumentSynonym);
			Raise ExceptionText;
			
		Else
			
			FillInAccordingToAccrualDocument(DocumentAccruals, StandardProcessing);
			
		EndIf;
		
	EndIf;
	
	InitializeDocument();
	
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
	
	DocumentAmount = DrillDownDebits.Total("Sum");
	
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

#Region InitializationAndFilling

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If GetFunctionalOption("UseApprovalOfCustomerRebatesWriteOffs") Then
		
		Status = Enums.RebatesDocumentStatuses.Draft;
		
	Else
		
		Status = Enums.RebatesDocumentStatuses.Approved;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InputOnBasis

// Parameters:
//  AccrualDocument - DocumentRef.AccrualOfCustomerRebates
//  StandardProcessing - Boolean - 
//
Procedure FillInAccordingToAccrualDocument(AccrualDocument, StandardProcessing)
	
	HeaderData_ = Documents.AccrualOfCustomerRebates.DataOfAccrualDocument(AccrualDocument);
	
	If HeaderData_ <> Undefined Then
		
		FillPropertyValues(ThisObject, HeaderData_);
		
		If HeaderData_.Sum = 0 Then
			
			ExceptionText = NStr("vi = 'Trong chứng từ tính toán không có khoản thưởng được tính có số tiền dương';
								|ru = 'По документу начислений нет начисленных бонусов с положительными суммами';
								|en = 'For the accrual document, there are no accrued rebates with positive amounts'; fa = 'For the accrual document, there are no accrued rebates with positive amounts';
								|it = 'По документу начислений нет начисленных бонусов с положительными суммами';
								|pl = 'For the accrual document, there are no accrued rebates with positive amounts';
								|tr = 'Tahakkuk belgesinde artı tutarlı olarak tahakkuk eden herhangi bir bonus mevcut değildir'");
			Raise ExceptionText;
			
		Else
			
			SamplingDetailedData = HeaderData_.Select();
			FillInTranscriptOfWriteOffsAccordingToAccrualDocument(SamplingDetailedData);
			
		EndIf;
		
	Else
		
		ExceptionText = NStr("vi = 'Không thể nhận dữ liệu chứng từ tính toán. Có thể là, chứng từ chưa được kết chuyển.';
							|ru = 'Не удалось получить данные документа начислений. Возможно, документ не проведен.';
							|en = 'Cannot get data of the accrual document. The document might not be posted.'; fa = 'Cannot get data of the accrual document. The document might not be posted.';
							|it = 'Не удалось получить данные документа начислений. Возможно, документ не проведен.';
							|pl = 'Cannot get data of the accrual document. The document might not be posted.';
							|tr = 'Tahakkuk belgesi verileri alınamadı. Belge kontrol edilmemiş olabilir.'");
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

Procedure FillInTranscriptOfWriteOffsAccordingToAccrualDocument(DataOfWriteOff)
	
	While DataOfWriteOff.Next() Do
		
		If DataOfWriteOff.Sum > 0 Then
			
			NewRow = DrillDownDebits.Add();
			FillPropertyValues(NewRow, DataOfWriteOff);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion
#EndRegion

#EndIf