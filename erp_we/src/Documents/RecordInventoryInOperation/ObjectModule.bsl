#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut(FillingData);
	
	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
	
	ElsIf FillInDataType = Type("DocumentRef.PhysicalCountOfInventoryInOperation") Then
		
		FillInBasedOnInventory(FillingData);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("Goods.ExpenseItem");
	AttributesNotToCheck.Add("Goods.DimensionOfExpenses");
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, AttributesNotToCheck, Cancel);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RecordInventoryInOperation);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, AttributesNotToCheck);
		
	CheckParameters = InventoryInOperationServer.ParametersForCheckingAccountingForIndividuals();
	CheckParameters.PresentationOfTS = NStr("vi = 'Hàng hóa';
											|ru = 'Товары';
											|en = 'Goods'; fa = 'کالاها';
											|it = 'Merci';
											|pl = 'Goods';
											|tr = 'Ürünler'");
	InventoryInOperationServer.CheckAccountingForIndividuals(ThisObject, AttributesNotToCheck, Cancel, CheckParameters);
	
	InventoryInOperationServer.CheckTransferIntoOperation(ThisObject, AttributesNotToCheck, Cancel);

	PerformAFillInCheck(CheckedAttributes, AttributesNotToCheck, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ExecuteActionsBeforeWrite(Cancel, WriteMode);
	
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
	
	EmployeeResponsible = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocumentBeforeFillingItOut(FillingData)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EmployeeResponsible = Users.CurrentUser();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
			Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	EndIf;
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("DocumentBasis")
		And TypeOf(Basis.DocumentBasis) = Type("DocumentRef.PhysicalCountOfInventoryInOperation") Then
			
		FillInBasedOnInventory(Basis);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnInventory(Val FillingData)
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
		ArrayOfLineNumbers = Undefined;
		ReportErrors = True;
	EndIf;
	
	ActionCompleted = Documents.RecordInventoryInOperation.FillInBasedOnInventory(ThisObject, ArrayOfLineNumbers);
	
	If Not ActionCompleted And ReportErrors Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %1 không có các dòng cần ghi tăng';
						|ru = 'В документе %1 отсутствуют строки требующие оприходования';
						|en = 'There are no lines that require receipt in the %1 document'; fa = 'There are no lines that require receipt in the %1 document';
						|it = 'Nel documento %1 mancano le stringhe che richiedono l''accettazione';
						|pl = 'W dokumencie %1 brak wierszy wymagających rejestracji';
						|tr = '%1 belgesinde dikkate alınması gereken hiçbir satır yoktur'");
		ErrorText = StrTemplate(ErrorText, DocumentBasis);
		Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		
	EndIf; 
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure PerformAFillInCheck(CheckedAttributes, AttributesNotToCheck, Cancel)
	
	BeginningOfApplicationOfFSBU5 = LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019();
	
	If Date < BeginningOfApplicationOfFSBU5 Then
		MessageText = NStr("vi = 'Ngày chứng từ không được sớm hơn %1 (bắt đầu áp dụng chuẩn mực kế toán số 2)';
							|ru = 'Дата документа должна быть не раньше %1 (начало применения ФСБУ 5/2019)';
							|en = 'The document date must not be earlier than %1 (the start of the Russian GAAP (FSBU 5/2019) application)'; fa = 'The document date must not be earlier than %1 (the start of the Russian GAAP (FSBU 5/2019) application)';
							|it = 'La data del documento non deve essere precedente a %1 (avvio applicazione Standard Federali per le Aziende 5/2019)';
							|pl = 'Data dokumentu powinna być nie wcześniejsza niż %1 (rozpoczęcie zastosowania standardu FSBU 5/2019)';
							|tr = 'Belgenin tarihi %1''den daha erken olmamalıdır (FAS 5/2019''un başlangıcı)'");
		MessageText = StrTemplate(MessageText, Format(BeginningOfApplicationOfFSBU5, "DLF=D"));
		Common.MessageToUser(MessageText, Ref, "Date", "Object", Cancel);
	EndIf;
	
	CheckTablePart(Cancel);
	
EndProcedure

Procedure CheckTablePart(Cancel)
	
	DetailsOfCategories = InventoryInOperationServer.AttributesOfOperatingCategories(Goods);
	
	MessageTemplate = NStr("vi = 'Trong dòng %1 đã chọn thể loại sử dụng ""%2"", trong đó đã bật sử dụng kế toán dưới dạng nhóm TSCĐ. Không hỗ trợ ghi tăng tiêu chí sử dụng này.""';
							|ru = 'В строке %1 выбрана категория эксплуатации ""%2"", в которой включен учет в виде группового ОС. Оприходование с такой категорией эксплуатации не поддерживается.""';
							|en = 'In line %1, the ""%2"" operation category is selected. In this category, accounting as a group fixed asset is enabled. Receipt with such operation category is not supported.'; fa = 'In line %1, the ""%2"" operation category is selected. In this category, accounting as a group fixed asset is enabled. Receipt with such operation category is not supported.';
							|it = 'Nella riga %1 è selezionata una categoria di lavorazione ""%2"" nella quale è inclusa la contabilità in forma di cespite di gruppo. La ricezione con questa categoria di lavorazione non è supportata.""';
							|pl = 'W wierszu %1 jest wybrana kategoria eksploatacji ""%2"", w którym jest włączona ewidencja w postaci grupowego środka trwałego. Rejestracja z taką kategorią nie jest obsługiwana.""';
							|tr = '%1 satırında, bir grup SV olarak muhasebeyi içeren ""%2"" işlem kategorisi seçildi. Bu işlem kategorisi ile muhasebe desteklenmiyor."".'");
	
	For Each RowData In Goods Do
		
		If Not ValueIsFilled(RowData.OperationCategory) Then
			Continue;
		EndIf;

		CategoryProperties = DetailsOfCategories.Get(RowData.OperationCategory);
		If CategoryProperties <> Undefined 
			And CategoryProperties.AccountAsGroupFA Then
			
			MessageText = 
				StrTemplate(MessageTemplate, 
					Format(RowData.LineNumber, "NG=0;"),
					String(RowData.OperationCategory));
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowData.LineNumber, "OperationCategory");
			Common.MessageToUser(MessageText, Ref, Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Procedure ExecuteActionsBeforeWrite(Cancel, WriteMode)
	
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RecordInventoryInOperation));
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	InventoryInOperationServer.FillInAttributesByCategoryOfOperation(Goods);
	
	Catalogs.LotsOfInventoryInOperation.FillInBatches(ThisObject, WriteMode);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
