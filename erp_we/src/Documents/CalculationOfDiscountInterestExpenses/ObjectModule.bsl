#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode <> DocumentWriteMode.UndoPosting And Not DeletionMark Then
		CheckDuplicateCurPeriodDocuments(Cancel);
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
	
	If Not (AdditionalProperties.Property("MonthEndTransactions") And AdditionalProperties.MonthEndTransactions) Then
		InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(BegOfMonth(Date),
			Ref,
			Organization,
			Catalogs.MonthEndClosingOperations.CalculationOfDiscountInterestExpenses);
	EndIf;
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckDuplicateCurPeriodDocuments(Cancel)
	
	Query = New Query(
	"SELECT TOP 1
	|	T.Ref AS Ref
	|FROM
	|	Document.CalculationOfDiscountInterestExpenses AS T
	|WHERE
	|	T.Posted
	|	AND T.Organization = &Organization
	|	AND T.Date BETWEEN &PeriodBeginning AND &PeriodEnd
	|	AND NOT T.Ref = &CurrentDocument");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CurrentDocument", Ref);
	Query.SetParameter("PeriodBeginning", BegOfMonth(Date));
	Query.SetParameter("PeriodEnd", EndOfMonth(Date));
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		ErrorText = NStr("vi = 'Đối với doanh nghiệp ""%1"" trong tháng hiện tại %2 đã tồn tại chứng tự tương tự,
		                   |hãy kết chuyển lại chứng từ hoặc đặt dấu xóa.';
		                   |ru = 'Для организации ""%1"" в текущем месяце %2 уже существует аналогичный документ,
		                   |перепроведите его или пометьте на удаление.';
		                   |en = 'For the company ""%1"", a similar document already exists in the current month %2, 
		                   |repost it or mark it for deletion.'; fa = 'For the company ""%1"", a similar document already exists in the current month %2, 
		                   |repost it or mark it for deletion.';
		                   |it = 'Для организации ""%1"" в текущем месяце %2 уже существует аналогичный документ,
		                   |перепроведите его или пометьте на удаление.';
		                   |pl = 'For the company ""%1"", a similar document already exists in the current month %2, 
		                   |repost it or mark it for deletion.';
		                   |tr = 'İçinde bulunulan %2 ayında ""%1"" iş yeri için benzer belge
		                   |zaten mevcut, lütfen tekrar kontrol et veya silinmek üzere işaretle.'");
		ErrorText = StrTemplate(ErrorText, Organization, Format(Date, "DF=MM.yyyy"));
		Common.MessageToUser(ErrorText, Selection.Ref, , , Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf