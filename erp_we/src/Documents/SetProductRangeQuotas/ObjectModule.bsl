#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	If IsNew() Then
		InitializeDocument(FillingData);
	EndIf;
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible		 = Users.CurrentUser();
	ValidityStartDate	 = BegOfMonth(CurrentSessionDate());
	If ValueIsFilled(PlanningObject) Then
		If Documents.SetProductRangeQuotas.ThereIsPlan_(PlanningObject, ValidityStartDate, Ref) Then
			ValidityStartDate = Date(1,1,1);
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TotalQuota = ProductCategories.Total("Quota");
	
	If WriteMode = DocumentWriteMode.Posting Then
		ThereIsPlan = Documents.SetProductRangeQuotas.ThereIsPlan_(PlanningObject, ValidityStartDate, Ref);
		If ThereIsPlan Then
			Cancel = True;
			MessageText = NStr("vi = 'Đã lập chứng từ đặt hạn mức cho %1 đối với khuôn dạng được chọn.';
								|ru = 'На %1 для выбранного формата уже существует документ установки квот.';
								|en = 'Quota setting document already exists for the selected format on %1.'; fa = 'Quota setting document already exists for the selected format on %1.';
								|it = 'Al %1 per il formato selezionato esiste già un documento di impostazione delle quote.';
								|pl = 'Na %1 dla wybranego formatu już istnieje dokument ustawienia limitów ';
								|tr = 'Seçilen formatta ""%1"" için zaten bir kota yapılandırma belgesi mevcut.'")
								+ Chars.LF + NStr("vi = 'Có thể thiết lập hạn mức không nhiều hơn 1 lần mỗi tháng.';
													|ru = 'Установка квот может производиться не чаще 1 раза в месяц.';
													|en = 'Quotas can be set only once a month.'; fa = 'Quotas can be set only once a month.';
													|it = 'L''impostazione delle quote può essere effettuata non più di 1 volta al mese.';
													|pl = 'Ustawienia limitów można wykonywać nie częściej niż raz na miesiąc';
													|tr = 'Kotalar ayda bir defadan fazla yapılandırılamaz.'")
								+ Chars.LF + NStr("vi = 'Hãy chọn ngày hoặc khuôn dạng cửa hàng khác.';
													|ru = 'Выберите другую дату или формат магазинов.';
													|en = 'Select another date or retail format.'; fa = 'Select another date or retail format.';
													|it = 'Selezionate un''altra data oppure un formato dei negozi.';
													|pl = 'Wybierz inną datę lub format sklepów.';
													|tr = 'Farklı bir tarih veya mağaza formatı seçin.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									MessageText,
									Format(ValidityStartDate,"DLF=D"));
									
			CommonClientServer.MessageToUser(
			MessageText,
			,
			,
			,
			True);
		EndIf;
		
	EndIf;
	
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

// Initializes the document
//
Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible		 = Users.CurrentUser();
	ValidityStartDate	 = BegOfMonth(CurrentSessionDate());
	PlanningObject	 = SettingsValueCached.GetDefaultSchedulingObject(PlanningObject);
	
	If ValueIsFilled(PlanningObject) Then
		If Documents.SetProductRangeQuotas.ThereIsPlan_(PlanningObject, ValidityStartDate, Ref) Then
			ValidityStartDate = Date(1,1,1);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
