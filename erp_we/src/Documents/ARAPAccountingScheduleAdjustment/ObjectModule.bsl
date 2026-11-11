
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

 Procedure OnCopy(CopiedObject)
	
	Author = Users.CurrentUser();
	Comment = "";
	DocumentBasis = Undefined;
	ARAPDocument = Undefined;
	FinRecordID = "";
	NewSchedule_.Clear();
	Currency = Catalogs.Currencies.EmptyRef();
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If Common.RefTypeValue(FillingData) Then
		
		If TypeOf(FillingData) = Type("DocumentRef.ARAPAccountingScheduleAdjustment") Then
			AttributesNames = "Organization,Counterparty,ARAPDocument, CompanyRecipient, BusinessOperation";
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
			FillPropertyValues(ThisObject, DetailsOfFoundation);
		ElsIf TypeOf(FillingData) = Type("DocumentRef.IntercompanyGoodsReturn")
			Or TypeOf(FillingData) = Type("DocumentRef.CustomerInvoiceIntercompany")
			Or TypeOf(FillingData) = Type("DocumentRef.CashVoucher") Then
			AttributesNames = "Organization,Counterparty,CompanyRecipient";
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
			FillPropertyValues(ThisObject, DetailsOfFoundation);
			ARAPDocument = FillingData;
		ElsIf TypeOf(FillingData) = Type("DocumentRef.CommissionReportIntercompany")
			Or TypeOf(FillingData) = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
			AttributesNames = "Organization,Counterparty,Consignee";
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
			FillPropertyValues(ThisObject, DetailsOfFoundation);
			CompanyRecipient = DetailsOfFoundation.Consignee;
			ARAPDocument = FillingData;
		ElsIf TypeOf(FillingData) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
			AttributesNames = "Organization,MaterialProvider";
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
			FillPropertyValues(ThisObject, DetailsOfFoundation);
			CompanyRecipient = DetailsOfFoundation.MaterialProvider;
			ARAPDocument = FillingData;
		ElsIf TypeOf(FillingData) = Type("DocumentRef.ElectronicTicketTransaction") Then
			AttributesNames = "Organization,CounterpartyCarrier";
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
			FillPropertyValues(ThisObject, DetailsOfFoundation);
			Counterparty = DetailsOfFoundation.CounterpartyCarrier;
			ARAPDocument = FillingData;
		ElsIf TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
			Or TypeOf(FillingData) = Type("DocumentRef.CustomerInvoice")
			Or TypeOf(FillingData) = Type("DocumentRef.SaleAdjustment") Then
			AttributesNames = "Organization,Counterparty,Contract,CustomerCounterparty";
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
			ConductARAPAccountingThroughEndCustomers = False;
			If ValueIsFilled(DetailsOfFoundation.Contract) Then
				ConductARAPAccountingThroughEndCustomers = Common.ObjectAttributeValue(DetailsOfFoundation.Contract, "ConductARAPAccountingThroughEndCustomers");
			EndIf;
			FillPropertyValues(ThisObject, DetailsOfFoundation);
			If ConductARAPAccountingThroughEndCustomers Then
				Counterparty = DetailsOfFoundation.CustomerCounterparty;
			EndIf;
			ARAPDocument = FillingData;
		ElsIf TypeOf(FillingData) = Type("DocumentRef.ARAPSettlement")
			Or TypeOf(FillingData) = Type("DocumentRef.ExpenseReport")
			Or TypeOf(FillingData) = Type("DocumentRef.ReversingEntry") Then
			ARAPDocument = FillingData;
		Else
			AttributesNames = "Organization,Counterparty";
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
			FillPropertyValues(ThisObject, DetailsOfFoundation);
			ARAPDocument = FillingData;
		EndIf;
		
		If Not (AdditionalProperties.Property("SelectARAPDocument")
			And AdditionalProperties.SelectARAPDocument) Then
			DocumentBasis = FillingData;
		EndIf;
		
		Query = New Query;
		Query.SetParameter("ARAPDocument", DocumentBasis);
		Query.SetParameter("ARAPDocumentOfAdjustment", ARAPDocument);
		Query.SetParameter("Ref", Ref);
		SelectionByPrimaryDocument = TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument");
		QueryTexts = New Array;
		QueryTexts.Add(Documents.ARAPAccountingScheduleAdjustment.QueryTextForFillingData(SelectionByPrimaryDocument));
		QueryTexts.Add(Documents.ARAPAccountingScheduleAdjustment.QueryTextOfDocumentsBasedOn());
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());;
		QueryResult = Query.ExecuteBatch();
		
		SamplingByHouseholdOfOperation = QueryResult[1].Select(QueryResultIteration.ByGroups);
		EnteredDocuments = QueryResult[2].Unload();
		ErrorsMessages = New Array;
		ARAPCurrencies = New Array;
		MessageTemplate = NStr("vi = 'Dựa trên chứng từ hiện tại đã nhập %1.';
								|ru = 'На основании текущего документа уже введена %1.';
								|en = '%1 is already entered based on the current document.'; fa = '%1 is already entered based on the current document.';
								|it = '%1 is already entered based on the current document.';
								|pl = '%1 is already entered based on the current document.';
								|tr = 'Mevcut belge temelinde %1 zaten girildi.'");
		While SamplingByHouseholdOfOperation.Next() Do
			
			// When entering based on the previous correction, it is necessary to fill in the same operation.
			If ValueIsFilled(BusinessOperation) 
				And BusinessOperation <> SamplingByHouseholdOfOperation.BusinessOperation Then
				Continue;
			EndIf;
			
			RowsOfEnteredAdjustments = EnteredDocuments.FindRows(New Structure("BusinessOperation", SamplingByHouseholdOfOperation.BusinessOperation));
			DocumentLine = Documents.ARAPAccountingScheduleAdjustment.LastAdjustment(RowsOfEnteredAdjustments);
			If DocumentLine <> Undefined
				And DocumentLine.Ref <> DocumentBasis Then
				ErrorsMessages.Add(
					New Structure("MessageText, Ref",
						StrTemplate(MessageTemplate, DocumentLine.Ref),
						DocumentLine.Ref));
				Continue;
			EndIf;
			
			BusinessOperation = SamplingByHouseholdOfOperation.BusinessOperation;
			
			Selection = SamplingByHouseholdOfOperation.Select();
			While Selection.Next() Do
				NewRow = NewSchedule_.Add();
				FillPropertyValues(NewRow, Selection);
				If ValueIsFilled(Selection.Currency) Then
					ARAPCurrencies.Add(Selection.Currency);
				EndIf;
				If Not ValueIsFilled(NewRow.Date) Then
					NewRow.Date = CurrentSessionDate();
				EndIf;
			EndDo;
			
			Break;
			
		EndDo;
		
		DocumentAmount = NewSchedule_.Total("Sum");
		ARAPCurrencies = CommonClientServer.CollapseArray(ARAPCurrencies);
		If ARAPCurrencies.Count() = 1 Then
			Currency = ARAPCurrencies[0];
		ElsIf ARAPCurrencies.Count() > 1 Then 
			DocumentAmount = 0;
		EndIf;
		
		If NewSchedule_.Count() = 0 Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập Điều chỉnh lịch biểu hạch toán trên cơ sở chứng từ %1.';
					|ru = 'Не требуется вводить Корректировку графика взаиморасчетов на основании документа %1.';
					|en = 'Generating AR/AP accounting schedule adjustment from the %1 base document is not required.'; fa = 'Generating AR/AP accounting schedule adjustment from the %1 base document is not required.';
					|it = 'Generating AR/AP accounting schedule adjustment from the %1 base document is not required.';
					|pl = 'Generating AR/AP accounting schedule adjustment from the %1 base document is not required.';
					|tr = '%1 belgesine dayalı olarak alacak/borç muhasebesi planlarının düzeltilmesinin girilmesine gerek yoktur.'"),
				DocumentBasis);
			For Each ErrorMessage In ErrorsMessages Do
				Common.MessageToUser(ErrorMessage.MessageText, ErrorMessage.Ref);
			EndDo;
			Raise Text;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(CompanyRecipient) Then
		CheckedAttributes.Delete(
			CheckedAttributes.Find(
				Metadata.Documents.ARAPAccountingScheduleAdjustment.Attributes.Counterparty.Name));
	Else
		CheckedAttributes.Delete(
			CheckedAttributes.Find(
				Metadata.Documents.ARAPAccountingScheduleAdjustment.Attributes.CompanyRecipient.Name));
	EndIf;
	
	Query = New Query;
	Query.SetParameter("LinkToCheckDates", ARAPDocument);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ARAPDocument", DocumentBasis);
	Query.SetParameter("ARAPDocumentOfAdjustment", ARAPDocument);
	
	// Checking for other adjustments
	Query.Text = Documents.ARAPAccountingScheduleAdjustment.QueryTextOfDocumentsBasedOn();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.BusinessOperation = BusinessOperation 
			And Selection.Ref <> Ref
			And Selection.DocumentBasis = DocumentBasis Then
			MessageText = StrTemplate(
				NStr("vi = 'Dựa trên cơ sở %1 đã nhập %2 %3.';
					|ru = 'На основании %1 уже введена %2 %3.';
					|en = '%2 %3 is already generated based on %1.'; fa = '%2 %3 is already generated based on %1.';
					|it = '%2 %3 is already generated based on %1.';
					|pl = '%2 %3 is already generated based on %1.';
					|tr = '%1 temelinde %2 %3 girildi.'"),
				DocumentBasis,
				BusinessOperation,
				Selection.Ref);
			Common.MessageToUser(MessageText, Selection.Ref,, "Object.BusinessOperation", Cancel);
		EndIf;
	EndDo;
	
	// Checking the immutability of the document amount by key fields
	KeyFields = "Partner, ARAPObject, Currency, Contract, LineOfBusiness";
	TableOfDiscrepancies = NewSchedule_.UnloadColumns(KeyFields);
	TableOfDiscrepancies.Columns.Add("Sum", New TypeDescription("Number"));
	SelectionByPrimaryDocument = TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument");
	Query.Text = Documents.ARAPAccountingScheduleAdjustment.QueryTextForFillingData(SelectionByPrimaryDocument);
	
	SamplingByHouseholdOfOperation = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SamplingByHouseholdOfOperation.Next() Do
		If SamplingByHouseholdOfOperation.BusinessOperation <> BusinessOperation Then
			Continue;
		EndIf;
		Selection = SamplingByHouseholdOfOperation.Select();
		While Selection.Next() Do
			FillPropertyValues(TableOfDiscrepancies.Add(), Selection);
		EndDo;
	EndDo;
	
	For Each RowOfOriginalTable In TableOfDiscrepancies Do
		RowOfOriginalTable.Sum = -RowOfOriginalTable.Sum;
	EndDo;
	For Each LineOfNewGraph In NewSchedule_ Do
		FillPropertyValues(TableOfDiscrepancies.Add(), LineOfNewGraph);
	EndDo;
	
	TableOfDiscrepancies.GroupBy(KeyFields, "Sum");
	
	For Each LineOfDiscrepancies In TableOfDiscrepancies Do
		If LineOfDiscrepancies.Sum = 0 Then
			Continue;
		EndIf;
		Sum = ?(LineOfDiscrepancies.Sum > 0, LineOfDiscrepancies.Sum, -LineOfDiscrepancies.Sum);
		FieldPattern = "%1: %2";
		FieldArray = New Array;
		TSAttributes = Metadata.Documents.ARAPAccountingScheduleAdjustment.TabularSections.NewSchedule_.Attributes;
		FieldsCount = 1;
		If Not GetFunctionalOption("UsePartnersAndCounterparties") Then
			FieldArray.Add(StrTemplate(FieldPattern, TSAttributes.Partner.Presentation(), LineOfDiscrepancies.Partner));
			FieldsCount = FieldsCount + 1;
		EndIf;
		FieldArray.Add(StrTemplate(FieldPattern, TSAttributes.ARAPObject.Presentation(), LineOfDiscrepancies.ARAPObject));
		If ValueIsFilled(LineOfDiscrepancies.Contract) Then
			FieldArray.Add(StrTemplate(FieldPattern, TSAttributes.Contract.Presentation(), LineOfDiscrepancies.Contract));
			FieldsCount = FieldsCount + 1;
		EndIf;
		If ValueIsFilled(LineOfDiscrepancies.LineOfBusiness) Then
			FieldArray.Add(StrTemplate(FieldPattern, TSAttributes.LineOfBusiness.Presentation(), LineOfDiscrepancies.LineOfBusiness));
			FieldsCount = FieldsCount + 1;
		EndIf;
		
		MessageTemplate = ?(FieldsCount = 1,
		                    NStr("vi = 'Số tiền theo trường chính:';
								|ru = 'Сумма по ключевому полю:';
								|en = 'Sum by key field:'; fa = 'Sum by key field:';
								|it = 'Sum by key field:';
								|pl = 'Sum by key field:';
								|tr = 'Anahtar alana göre tutar:'"),
		                    NStr("vi = 'Số tiền theo trường chính:';
								|ru = 'Сумма по ключевым полям:';
								|en = 'Sum by key fields:'; fa = 'Sum by key fields:';
								|it = 'Sum by key fields:';
								|pl = 'Sum by key fields:';
								|tr = 'Anahtar alanlara göre tutar:'"))
		                  + NStr("vi = '
		                               |%1
		                               |không tương ứng với lịch biểu ban đầu đối với %2 %3';
		                               |ru = '
		                               |%1
		                               |не соответствует исходному графику на %2 %3';
		                               |en = '
		                               |%1
		                               |does not match the original schedule by %2 %3'; fa = '
		                               |%1
		                               |does not match the original schedule by %2 %3';
		                               |it = '
		                               |%1
		                               |does not match the original schedule by %2 %3';
		                               |pl = '
		                               |%1
		                               |does not match the original schedule by %2 %3';
		                               |tr = '
		                               |%1
		                               |, %2 %3 orijinal programla eşleşmiyor'");
		MessageText = StrTemplate(
			MessageTemplate,
			StrConcat(FieldArray, "; "),
			Format(Sum, "NFD=2; NZ="),
			LineOfDiscrepancies.Currency);
		Common.MessageToUser(MessageText, ThisObject, "",, Cancel);
	EndDo;
	
	// Checking the date of the original document on the modified dates of the schedule
	KeyFields = "Partner, ARAPObject, Currency, Contract, LineOfBusiness, Date";
	ChangesTable = NewSchedule_.UnloadColumns(KeyFields);
	ChangesTable.Columns.Add("Sum", New TypeDescription("Number"));
	SamplingByHouseholdOfOperation.Reset();
	While SamplingByHouseholdOfOperation.Next() Do
		If SamplingByHouseholdOfOperation.BusinessOperation <> BusinessOperation Then
			Continue;
		EndIf;
		Selection = SamplingByHouseholdOfOperation.Select();
		While Selection.Next() Do
			FillPropertyValues(ChangesTable.Add(), Selection);
		EndDo;
	EndDo;
	For Each RowOfOriginalTable In ChangesTable Do
		RowOfOriginalTable.Sum = -RowOfOriginalTable.Sum;
	EndDo;
	For Each LineOfNewGraph In NewSchedule_ Do
		FillPropertyValues(ChangesTable.Add(), LineOfNewGraph);
	EndDo;
	
	ChangesTable.GroupBy(KeyFields, "Sum");
	
	Query.Text = "
		|SELECT
		|	BEGINOFPERIOD(DocumentsRegistry.IBDocumentDate, DAY) AS Date
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.Ref = &LinkToCheckDates
		|	AND NOT DocumentsRegistry.AdditionalRecord";
	
	Selection = Query.Execute().Select();
	If Selection.Next() And ValueIsFilled(Selection.Date) Then
		For Each ChangesRow In ChangesTable Do
			If ChangesRow.Sum > 0 Then
				RowFilter = New Structure(KeyFields);
				FillPropertyValues(RowFilter, ChangesRow);
				LinesOfNewGraph = NewSchedule_.FindRows(RowFilter);
				For Each LineOfNewGraph In LinesOfNewGraph Do
					If ValueIsFilled(LineOfNewGraph.Date)
						And BegOfDay(LineOfNewGraph.Date) < Selection.Date Then
						Common.MessageToUser(
							NStr("vi = 'Ngày mới không thể nhỏ hơn ngày chứng từ gốc.';
								|ru = 'Новая дата не может быть меньше даты исходного документа.';
								|en = 'New date cannot be earlier than the source document date.'; fa = 'New date cannot be earlier than the source document date.';
								|it = 'New date cannot be earlier than the source document date.';
								|pl = 'New date cannot be earlier than the source document date.';
								|tr = 'Yeni tarih, orijinal belgenin tarihinden daha önce olamaz.'"),
							ThisObject,
							CommonClientServer.PathToTabularSection("NewSchedule_", LineOfNewGraph.LineNumber, "Date"),,
							Cancel);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.Posting
		And Not ValueIsFilled(FinRecordID) Then
		FinRecordID = New UUID;
	EndIf;
	
	NewSchedule_.Sort("Date");
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

#EndRegion

#EndRegion

#EndIf