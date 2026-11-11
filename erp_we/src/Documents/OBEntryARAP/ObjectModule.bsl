#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	OBEntryLocalization.OBEntryARAPBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOfSettlementsProcessingOfTransactions(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.EnteringSettlementBalancesProcessingDeletions(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not RecordInOperationalAccounting And Not PostInFinancialAndTaxAccounting And Not RecordInMA Then
		MessageText = NStr("vi = 'Cần phải phản ánh hoạt động trong một trong số kế toán';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If RecordInOperationalAccounting
		And (BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.RecordCustomerBonusRebates) Then
		
		CheckBitDepthOfCalculationObjectNumbers(Cancel);
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerBonuses
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryVendorBonuses
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor
		Or Not RecordInOperationalAccounting Then
		
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.PaymentDate");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.APARDocumentDate");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.NumberOfARAPDocument");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.ARAPObjectSender");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.DocumentOfARAPAccounting");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.Sum");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.SumCompl");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.SumMan");
		
		CheckCompletionOfTabularPartSettlementsWithPartners(Cancel, BusinessOperation);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable Then
		
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.APARDocumentDate");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.NumberOfARAPDocument");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.ARAPObjectSender");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.DocumentOfARAPAccounting");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.Sum");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.SumCompl");
		NotCheckedAttributeArray.Add("PartnersARAPAccounting.SumMan");
		
		CheckCompletionOfTabularPartSettlementsWithPartners(Cancel, BusinessOperation);
		
	EndIf;
	
	CheckDatesOfPrimaryDocuments(Cancel);
	
	NotCheckedAttributeArray.Add("CompanyRecipient");

	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntryLocalization.EnteringSettlementBalancesProcessingFillChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	OBEntryLocalization.EnteringBalancesOfSettlementsProcessingFilling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	EmployeeResponsible = Users.CurrentUser();
	OBEntryLocalization.EnteringAccountBalancesWhenCopying(ThisObject, CopiedObject);
	
EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	OBEntryLocalization.EnteringAccountBalancesWhenRecording(ThisObject, Cancel);

EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return
	EndIf;
	
	OBEntryLocalization.EnteringSettlementBalancesBeforeDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(ThisObject, FillingData.CopyingValue);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckCompletionOfTabularPartSettlementsWithPartners(Cancel, BusinessOperation)

	ItIsNecessaryToCheckCompletionOfGiftCertificates = False;
	If BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor Then
		ColumnNameAmount = NStr("vi = 'Ứng trước';
								|ru = 'Аванс';
								|en = 'Prepayment'; fa = 'پیش‌پرداخت';
								|it = 'Аванс';
								|pl = 'Prepayment';
								|tr = 'Avans'");
	Else
		ColumnNameAmount = NStr("vi = 'Công nợ';
								|ru = 'Долг';
								|en = 'Debt'; fa = 'بدهی';
								|it = 'Долг';
								|pl = 'Debt';
								|tr = 'Borç'");
	EndIf;
	
	For Each TableRow In PartnersARAPAccounting Do
		
		If Not ValueIsFilled(TableRow.ARAPObjectSender) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền cột ""Đối tượng thanh toán"" trong dòng %1 của danh sách ""Thanh toán với đối tác""';
						|ru = 'Не заполнена колонка ""Объект расчетов"" в строке %1 списка ""Расчеты с партнерами""';
						|en = '""AR/AP object"" in line %1 of list ""Partners AR/AP"" is not filled in'; fa = '""AR/AP object"" in line %1 of list ""Partners AR/AP"" is not filled in';
						|it = 'La colonna ""Oggetto di calcoli"" non è compilata nella riga %1 dell''elenco ""Le regolazioni dei conti con i partner""';
						|pl = 'Nie wypełniono kolumny ""Объект расчетов"" w wierszu %1 listy ""Расчеты с партнерами""';
						|tr = '""İş ortaklarıyla mutabakatlar"" listesinin %1 satırındaki ""Alacak/Borç nesnesi"" sütunu doldurulmadı'"),
					TableRow.LineNumber);
			Common.MessageToUser(
				Text,
				ThisObject,
				"PartnersARAPAccounting[" + (TableRow.LineNumber - 1) + "].ARAPObjectSender",
				,
				Cancel);
		EndIf;
			
		If RecordInOperationalAccounting
			 And Not ValueIsFilled(TableRow.DocumentOfARAPAccounting) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Chưa điền cột ""Chứng từ hạch toán"" trong dòng %1 của danh sách ""Hạch toán với bạn hàng""';
							|ru = 'Не заполнена колонка ""Расчетный документ"" в строке %1 списка ""Расчеты с партнерами""';
							|en = '""AR/AP document"" in line %1 of list ""Partners AR/AP"" is not filled in'; fa = '""AR/AP document"" in line %1 of list ""Partners AR/AP"" is not filled in';
							|it = 'La colonna ""Documento di calcoli"" non è compilata nella riga %1 dell''elenco ""Le regolazioni dei conti con i partner""';
							|pl = 'Nie wypełniono kolumny ""Расчетный документ"" w wierszu %1 listy ""Расчеты с партнерами""';
							|tr = '""İş ortaklarıyla mutabakatlar"" listesinin %1 satırındaki ""Mutabakat belgesi"" sütunu doldurulmadı'"),
						TableRow.LineNumber);
			Common.MessageToUser(
				Text,
				ThisObject,
				"PartnersARAPAccounting[" + (TableRow.LineNumber - 1) + "].DocumentOfARAPAccounting",
				,
				Cancel);
		EndIf;
		
		If RecordInOperationalAccounting = True
			And BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
			And TypeOf(TableRow.ARAPObject) = Type("CatalogRef.GiftCertificates") Then
			ItIsNecessaryToCheckCompletionOfGiftCertificates = True;
		EndIf;
		
		If Not ValueIsFilled(TableRow.Sum) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền cột ""%1"" trong dòng %2 của danh sách ""Hạch toán với bạn hàng""';
						|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""Расчеты с партнерами""';
						|en = 'The ""%1"" column in line %2 of the ""Partners AR/AP"" list is required'; fa = 'The ""%1"" column in line %2 of the ""Partners AR/AP"" list is required';
						|it = 'Не заполнена колонка ""%1"" в строке %2 списка ""Расчеты с партнерами""';
						|pl = 'The ""%1"" column in line %2 of the ""Partners AR/AP"" list is required';
						|tr = '""İş ortaklarıyla mutabakatlar"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı'"),
					ColumnNameAmount,
					TableRow.LineNumber);
			Common.MessageToUser(
				Text,
				ThisObject,
				"PartnersARAPAccounting[" + (TableRow.LineNumber - 1) + "].Sum",
				,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(TableRow.SumCompl) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền cột ""%1 %2"" trong dòng %3 danh sách ""Hạch toán với bạn hàng""';
						|ru = 'Не заполнена колонка ""%1 %2"" в строке %3 списка ""Расчеты с партнерами""';
						|en = 'The ""%1 %2"" column in line %3 of the ""Partners AR/AP"" list is required'; fa = 'The ""%1 %2"" column in line %3 of the ""Partners AR/AP"" list is required';
						|it = 'Не заполнена колонка ""%1 %2"" в строке %3 списка ""Расчеты с партнерами""';
						|pl = 'The ""%1 %2"" column in line %3 of the ""Partners AR/AP"" list is required';
						|tr = '""İş ortaklarıyla mutabakatlar"" listesinin %3 satırındaki ""%1 %2"" sütunu doldurulmadı'"),
					ColumnNameAmount,
					NStr("vi = '(pháp quy)';
						|ru = '(регл.)';
						|en = '(local)'; fa = '(local)';
						|it = '(регл.)';
						|pl = '(local)';
						|tr = '(yerel)'"),
					TableRow.LineNumber);
			Common.MessageToUser(
				Text,
				ThisObject,
				"PartnersARAPAccounting[" + (TableRow.LineNumber - 1) + "].SumCompl",
				,
				Cancel);
		EndIf; 
		
		If Not ValueIsFilled(TableRow.SumMan) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền cột ""%1 %2"" trong dòng %3 danh sách ""Hạch toán với bạn hàng""';
						|ru = 'Не заполнена колонка ""%1 %2"" в строке %3 списка ""Расчеты с партнерами""';
						|en = 'The ""%1 %2"" column in line %3 of the ""Partners AR/AP"" list is required'; fa = 'The ""%1 %2"" column in line %3 of the ""Partners AR/AP"" list is required';
						|it = 'Не заполнена колонка ""%1 %2"" в строке %3 списка ""Расчеты с партнерами""';
						|pl = 'The ""%1 %2"" column in line %3 of the ""Partners AR/AP"" list is required';
						|tr = '""İş ortaklarıyla mutabakatlar"" listesinin %3 satırındaki ""%1 %2"" sütunu doldurulmadı'"),
					ColumnNameAmount,
					NStr("vi = '(quản trị)';
						|ru = '(упр.)';
						|en = '(mgmt)'; fa = '(mgmt)';
						|it = '(упр.)';
						|pl = '(mgmt)';
						|tr = '(yönetim)'"),
					TableRow.LineNumber);
			Common.MessageToUser(
				Text,
				ThisObject,
				"PartnersARAPAccounting[" + (TableRow.LineNumber - 1) + "].SumMan",
				,
				Cancel);
		EndIf;
		
	EndDo;
	
	If ItIsNecessaryToCheckCompletionOfGiftCertificates Then
		GiftCertificatesServer.FillCheckProcessing(ThisObject, Cancel);
	EndIf;
	
EndProcedure

Procedure CheckBitDepthOfCalculationObjectNumbers(Cancel)
	
	MessageTemplate = NStr("vi = 'Chiều dài số thứ tự đối tượng tính toán vượt quá chiều dài cho phép (%Length%) đối với đối tượng tính toán đã chọn tại dòng %LineNumber%.';
							|ru = 'Длина номера объекта расчетов превышает допустимую длину (%Length%) для выбранного объекта расчетов в строке %LineNumber%.';
							|en = 'Length of AR/AP object number exceeds the maximum length (%Length%) for the selected AR/AP object in line %LineNumber%.'; fa = 'Length of AR/AP object number exceeds the maximum length (%Length%) for the selected AR/AP object in line %LineNumber%.';
							|it = 'La lunghezza del numero dell''oggetto di calcoli supera la lunghezza consentita (%Length%) per l''oggetto di calcoli selezionato nella riga %LineNumber%.';
							|pl = 'Długość numeru obiektu rozliczeń przekracza dopuszczalną długość (%Length%) dla wybranego obiektu w wierszu %LineNumber%.';
							|tr = 'Alacak/Borç nesnesi numarasının uzunluğu, %LineNumber% satırında seçilen alacak/borç nesnesi için izin verilen uzunluğu (%Length%) aşıyor.'");
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor Then
		
		TabularSection    = PartnersARAPAccounting;
		TabularSectionName = "PartnersARAPAccounting";

	Else
		Return;
	EndIf;
	
	For Each TableRow In TabularSection Do
		If TableRow.ARAPObject <> Undefined Then
			ARAPObjectType = TypeOf(TableRow.ARAPObject);
			IsCatalog = Catalogs.AllRefsType().ContainsType(ARAPObjectType);
			IsDocument = Documents.AllRefsType().ContainsType(ARAPObjectType);
			NumberLength = 0;
			CalculationObjectMetadata = Metadata.FindByType(ARAPObjectType);
			If IsCatalog And CalculationObjectMetadata <> Undefined Then
				NumberLength = CalculationObjectMetadata.CodeLength;
			ElsIf IsDocument And CalculationObjectMetadata <> Undefined Then
				NumberLength = CalculationObjectMetadata.NumberLength;
			Else
				Return;
			EndIf;
			If (StrLen(TableRow.NumberOfARAPDocument) > NumberLength)
				And NumberLength > 0 Then
			MessageText = StrReplace(MessageTemplate, "%Length%", NumberLength);
			MessageText = StrReplace(MessageText, "%LineNumber%", TableRow.LineNumber);
			Common.MessageToUser(
				MessageText,
				ThisObject,
				CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "NumberOfARAPDocument"),
				,
				Cancel);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckDatesOfPrimaryDocuments(Cancel)
	
	Query = New Query;
	Query.SetParameter("DocumentsArray", PartnersARAPAccounting.UnloadColumn("DocumentOfARAPAccounting"));
	Query.Text = 
		"SELECT
		|	SourceDocument.Ref AS Ref,
		|	BEGINOFPERIOD(SourceDocument.Date, DAY) AS Date,
		|	SourceDocument.SourceDocumentType AS SourceDocumentType
		|FROM
		|	Document.SourceDocument AS SourceDocument
		|WHERE
		|	SourceDocument.Ref IN (&DocumentsArray)";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CalculationLinesForDocument = PartnersARAPAccounting.FindRows(New Structure("DocumentOfARAPAccounting", Selection.Ref));
		For Each TableRow In CalculationLinesForDocument Do
			If Date < Selection.Date Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Ngày chứng từ hạch toán lớn hơn ngày nhập dư đầu trong dòng %1 của danh sách ""Hạch toán với bạn hàng""';
							|ru = 'Дата расчетного документа больше даты ввода начальных остатков в строке %1 списка ""Расчеты с партнерами""';
							|en = 'The AR/AP document date is later than the date of opening balance entry in line %1 of the Partners AR/AP list'; fa = 'The AR/AP document date is later than the date of opening balance entry in line %1 of the Partners AR/AP list';
							|it = 'Дата расчетного документа больше даты ввода начальных остатков в строке %1 списка ""Расчеты с партнерами""';
							|pl = 'The AR/AP document date is later than the date of opening balance entry in line %1 of the Partners AR/AP list';
							|tr = 'Alacak/Borç belgesinin tarihi, ""İş ortaklarıyla mutabakatlar"" listesinin %1 satırındaki ilk bakiyelerin giriş tarihinden büyüktür'"),
						TableRow.LineNumber);
				Common.MessageToUser(
					Text,
					ThisObject,
					,
					"PartnersARAPAccounting[" + (TableRow.LineNumber - 1) + "].DocumentOfARAPAccounting",
					Cancel);
			EndIf;
			If (BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
					And (Selection.SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
						Or Selection.SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment)
				Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor
					And (Selection.SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor
						Or Selection.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment))
				And ValueIsFilled(TableRow.PaymentDate)
				And TableRow.PaymentDate < Selection.Date Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Ngày giảm nợ không thể trước ngày thanh toán.';
							|ru = 'Дата погашения не может быть раньше даты платежа.';
							|en = 'The repayment date cannot be earlier than the payment date.'; fa = 'The repayment date cannot be earlier than the payment date.';
							|it = 'Дата погашения не может быть раньше даты платежа.';
							|pl = 'The repayment date cannot be earlier than the payment date.';
							|tr = 'Vade tarihi ödeme tarihinden önce olamaz.'"),
						TableRow.LineNumber);
				Common.MessageToUser(
					Text,
					ThisObject,
					,
					"PartnersARAPAccounting[" + (TableRow.LineNumber - 1) + "].PaymentDate",
					Cancel);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
