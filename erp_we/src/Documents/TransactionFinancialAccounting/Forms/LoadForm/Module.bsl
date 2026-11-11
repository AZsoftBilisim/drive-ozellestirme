
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DefaultCompany = Catalogs.Companies.DefaultCompany();
	If Parameters.Property("ChartOfAccounts") And ValueIsFilled(Parameters.ChartOfAccounts) Then
		ChartOfAccounts = Parameters.ChartOfAccounts;
		Items.ChartOfAccounts.Visible = False;
	Else 
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	ChartOfAccountsInternationalAccountingInCaseOfChangeServer();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChartOfAccountsInternationalAccountingInCaseOfChange(Item)
	ChartOfAccountsInternationalAccountingInCaseOfChangeServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportPostings(Command)
	
	Modified = False;
	If ImportPostingsServer() Then
		Structure = New Structure("AddressOfPostingsInTheStorage", AddressOfPostingsInTheStorage);
		NotifyChoice(Structure);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ImportPostingsServer()
	
	LineNumber = 2;
	LoadingListOfDocuments = Not ImportParameters.UploadingToDocument;
	LoadingFields = ImportParameters.Fields;
	LineFilled = LineFilled(SpreadsheetDocument, LineNumber);
	UploadedWithoutErrors = True;
	CurrencyExchangeRateCache = ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache();
	
	DocumentObject_ = Undefined;
	DocumentDate = Undefined;
	DocumentOrganization = Undefined;
	ChartOfAccountsDocument = Undefined;
	Postings = Undefined;
	If ImportParameters.UploadingToDocument Then
		DocumentDate = ImportParameters.DocumentDate;
		ChartOfAccountsDocument = ImportParameters.ChartOfAccounts;
		DocumentOrganization = ImportParameters.Organization;
		
		If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
			Postings = AccountingRegisters.International.CreateRecordSet().Unload();
		ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
			Postings = AccountingRegisters.InternationalWithoutCorrespondence.CreateRecordSet().Unload();
		Else
			Raise NStr("vi = 'Chưa xác định biểu ghi kế toán để kết nhập bút toán.';
						|ru = 'Не определен регистр бухгалтерии для загрузки проводок.';
						|en = 'Accounting register is not identified for the entry import.'; fa = 'Accounting register is not identified for the entry import.';
						|it = 'Registro di contabiità non definito per il download delle transazioni.';
						|pl = 'Nie określono rejestru księgowości dla importu wpisów księgowych.';
						|tr = 'Giriş yüklemek için muhasebe kaydı tanımlanmadı.'")
		EndIf;
		
	EndIf;
	
	// Prepare a set of records
	While LineFilled Do
		
		TransactionData = Undefined;
		Try
			// Let's read the data lines of the graph
			TransactionData = New Structure();
			For ColumnNumber = 1 To LoadingFields.Count() Do
				
				Field = LoadingFields[ColumnNumber-1];
				CellText = CellText(SpreadsheetDocument, LineNumber, ColumnNumber);
				
				If IsBlankString(CellText) And Field <> "PostingType" Then
					Continue;
				EndIf;
				
				If Field = "Period" Then
					Simple = TextToDate(CellText, LineNumber, Field);
				
				ElsIf Field = "Organization" Then
					Simple = FindFieldValue(
						Metadata.Catalogs.Companies.FullName(), CellText);
				
				ElsIf Field = "Account" Then
					
					AdditionalSelection = New Structure();
					If TransactionData.Property("ChartOfAccounts") And ValueIsFilled(TransactionData.ChartOfAccounts) Then
						AdditionalSelection.Insert("ChartOfAccounts", TransactionData.ChartOfAccounts);
					Else
						AdditionalSelection.Insert("ChartOfAccounts", ?(ValueIsFilled(ChartOfAccountsDocument), ChartOfAccountsDocument, ChartOfAccounts));
					EndIf;
					
					Simple = FindFieldValue(
						Metadata.ChartsOfAccounts.International.FullName(),CellText, AdditionalSelection);
					
				ElsIf Field = "ExtDimension1" Then
					Simple = FindValueOfExtdimension(TransactionData.Account,1, CellText);
					
				ElsIf Field = "ExtDimension2" Then
					Simple = FindValueOfExtdimension(TransactionData.Account,2, CellText);
					
				ElsIf Field = "ExtDimension3" Then
					Simple = FindValueOfExtdimension(TransactionData.Account,3, CellText);
					
				ElsIf Field = "AccountDr" Then
					
					AdditionalSelection = New Structure();
					If TransactionData.Property("ChartOfAccounts") And ValueIsFilled(TransactionData.ChartOfAccounts) Then
						AdditionalSelection.Insert("ChartOfAccounts", TransactionData.ChartOfAccounts);
					Else
						AdditionalSelection.Insert("ChartOfAccounts", ?(ValueIsFilled(ChartOfAccountsDocument), ChartOfAccountsDocument, ChartOfAccounts));
					EndIf;
					
					Simple = FindFieldValue(
						Metadata.ChartsOfAccounts.International.FullName(),CellText, AdditionalSelection);
					
				ElsIf Field = "ExtDimensionDr1" Then
					Simple = FindValueOfExtdimension(TransactionData.AccountDr,1, CellText);
					
				ElsIf Field = "ExtDimensionDr2" Then
					Simple = FindValueOfExtdimension(TransactionData.AccountDr,2, CellText);
					
				ElsIf Field = "ExtDimensionDr3" Then
					Simple = FindValueOfExtdimension(TransactionData.AccountDr,3, CellText);
					
				ElsIf Field = "AccountCr" Then
					
					AdditionalSelection = New Structure();
					If TransactionData.Property("ChartOfAccounts") And ValueIsFilled(TransactionData.ChartOfAccounts) Then
						AdditionalSelection.Insert("ChartOfAccounts", TransactionData.ChartOfAccounts);
					Else
						AdditionalSelection.Insert("ChartOfAccounts", ?(ValueIsFilled(ChartOfAccountsDocument), ChartOfAccountsDocument, ChartOfAccounts));
					EndIf;
					
					Simple = FindFieldValue(
						Metadata.ChartsOfAccounts.International.FullName(),CellText);
					
				ElsIf Field = "ExtDimensionCr1" Then
					Simple = FindValueOfExtdimension(TransactionData.AccountCr,1, CellText);
					
				ElsIf Field = "ExtDimensionCr2" Then
					Simple = FindValueOfExtdimension(TransactionData.AccountCr,2, CellText);
					
				ElsIf Field = "ExtDimensionCr3" Then
					Simple = FindValueOfExtdimension(TransactionData.AccountCr,3, CellText);
					
				ElsIf Field = "Currency" Or Field = "CurrencyDr" Or Field = "CurrencyCr" Then
					Simple = FindFieldValue(
						Metadata.Catalogs.Currencies.FullName(), CellText);
					
				ElsIf Field = "Department" Or Field = "DepartmentDr" Or Field = "DepartmentCr" Then
					Simple = FindFieldValue(
						Metadata.Catalogs.BusinessStructure.FullName(), CellText);
					
				ElsIf Field = "LineOfBusiness" Or Field = "LineOfBusinessDr" Or Field = "LineOfBusinessCr" Then
					Simple = FindFieldValue(
						Metadata.Catalogs.LinesOfBusiness.FullName(), CellText);
					
				ElsIf Field = "PostingType" Then
					If Not IsBlankString(CellText) Then
						Simple = Enums.PostingTypesFinancialAccounting[CellText];
					EndIf;
					
				ElsIf Field = "Content" Then
					Simple = CellText;
					
				ElsIf Field = "SumDr" Then
					
					Simple = TextToNumber(CellText, LineNumber, Field);
					TransactionData.Insert("Sum",Simple);
					FillInViewOfTransactionMovement(TransactionData, LineNumber, "Dr");
				
				ElsIf Field = "SumCr" Then
					
					Simple = TextToNumber(CellText, LineNumber, Field);
					TransactionData.Insert("Sum",Simple);
					FillInViewOfTransactionMovement(TransactionData, LineNumber, "Cr");
				
				ElsIf Field = "PresentationAmountDr" Then
					
					Simple = TextToNumber(CellText, LineNumber, Field);
					TransactionData.Insert("PresentationAmount",Simple);
					FillInViewOfTransactionMovement(TransactionData, LineNumber, "Dr");
				
				ElsIf Field = "PresentationAmountCr" Then
					
					Simple = TextToNumber(CellText, LineNumber, Field);
					TransactionData.Insert("PresentationAmount",Simple);
					FillInViewOfTransactionMovement(TransactionData, LineNumber, "Cr");
					
				Else
					
					Simple = TextToNumber(CellText, LineNumber, Field);
					
				EndIf;
				TransactionData.Insert(Field,Simple);
				
			EndDo;// by columns of the loading table
			
		Except
			TextTemplate1 = NStr("vi = 'Dòng số %1 cột ""%2"" - lỗi chuyển đổi giá trị ""%3""
								|Dòng chưa được kết nhập do nguyên nhân';
								|ru = 'Строка №%1 колонка ""%2"" - ошибка преобразования значения ""%3""
								|Строка не загружена по причине';
								|en = 'Row %1, column %2: conversion error for value ""%3"".
								|The row is not imported. Reason:'; fa = 'Row %1, column %2: conversion error for value ""%3"".
								|The row is not imported. Reason:';
								|it = 'Riga №%1 colonna ""%2""- errore di conversione del valore ""%3""
								| La riga non è stata caricata a causa';
								|pl = 'Wiersz nr%1 kolumna ""%2"" - błąd konwersji wartości ""%3""
								|Nie pobrano wiersza z powodu';
								|tr = 'Satır №%1 sütun ""%2"" - değer dönüştürme hatası ""%3""
								|Satır şu sebepten yüklenmedi'") + ": ";
			Text = StrTemplate(TextTemplate1, LineNumber, Field, CellText);
			Text = Text + Chars.LF + Chars.Tab + BriefErrorDescription(ErrorInfo());
			Common.MessageToUser(Text);
			UploadedWithoutErrors = False;
		EndTry;
		
		If ValueIsFilled(TransactionData) Then
			
			If LoadingListOfDocuments Then
				
				If (TransactionData.Property("Organization") And DocumentOrganization <> TransactionData.Organization) 
					Or (TransactionData.Property("ChartOfAccounts") And ChartOfAccountsDocument <> TransactionData.ChartOfAccounts)
					Or DocumentObject_ = Undefined Then
					
					If DocumentObject_ <> Undefined Then
						DocumentObject_.RegisterRecords.International.Write = True;
						DocumentObject_.RegisterRecords.InternationalWithoutCorrespondence.Write = True;
						If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
							DocumentObject_.RegisterRecords.International.Load(Postings);
						ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
							DocumentObject_.RegisterRecords.InternationalWithoutCorrespondence.Load(Postings);
						EndIf;
						DocumentObject_.Write();
					EndIf;
					
					DocumentDate = TransactionData.Period;
					If TransactionData.Property("Organization") Then
						DocumentOrganization = TransactionData.Organization;
					Else
						DocumentOrganization = DefaultCompany;
					EndIf;
					If TransactionData.Property("ChartOfAccounts") Then
						ChartOfAccountsDocument = TransactionData.ChartOfAccounts;
					Else
						ChartOfAccountsDocument = ChartOfAccounts;
					EndIf;
					
					DocumentObject_ = Documents.TransactionFinancialAccounting.CreateDocument();
					DocumentObject_.Date = DocumentDate;
					DocumentObject_.Organization = DocumentOrganization;
					DocumentObject_.ChartOfAccounts = ChartOfAccountsDocument;
					DocumentObject_.Write();
					
					If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
						Postings = DocumentObject_.RegisterRecords.International.Unload();
					ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
						Postings = DocumentObject_.RegisterRecords.InternationalWithoutCorrespondence.Unload();
					Else
						Raise NStr("vi = 'Chưa xác định biểu ghi kế toán để kết nhập bút toán.';
									|ru = 'Не определен регистр бухгалтерии для загрузки проводок.';
									|en = 'Accounting register is not identified for the entry import.'; fa = 'Accounting register is not identified for the entry import.';
									|it = 'Registro di contabiità non definito per il download delle transazioni.';
									|pl = 'Nie określono rejestru księgowości dla importu wpisów księgowych.';
									|tr = 'Giriş yüklemek için muhasebe kaydı tanımlanmadı.'");
					EndIf;
				EndIf;
				
				If Not DocumentObject_.EnterPeriodByRows And BegOfDay(DocumentDate) <> BegOfDay(TransactionData.Period) Then
					DocumentObject_.EnterPeriodByRows = True;
				EndIf;
				
			EndIf;
			
			NewEntry = Postings.Add();
			FillPropertyValues(NewEntry, TransactionData);
			If Not ValueIsFilled(NewEntry.Organization) Then
				NewEntry.Organization = ?(ValueIsFilled(DocumentOrganization), DocumentOrganization, DefaultCompany);
			EndIf;
			If Not ValueIsFilled(NewEntry.ChartOfAccounts) Then
				NewEntry.ChartOfAccounts = ?(ValueIsFilled(ChartOfAccountsDocument), ChartOfAccountsDocument, ChartOfAccounts);
			EndIf;
			If TransactionData.Property("AccountDr") Then
				FillExtdimension(NewEntry, TransactionData.AccountDr, "Dr");
			EndIf;
			If TransactionData.Property("AccountCr") Then
				FillExtdimension(NewEntry, TransactionData.AccountCr, "Cr");
			EndIf;
			If TransactionData.Property("Account") Then
				FillExtdimension(NewEntry, TransactionData.Account, "");
			EndIf;
			FillInAmounts(NewEntry, CurrencyExchangeRateCache, DocumentDate);
			NewEntry.Active = False;
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		
		Try
			LineFilled = LineFilled(SpreadsheetDocument, LineNumber);
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;// by rows of the loading table
	
	If LoadingListOfDocuments And DocumentObject_ <> Undefined Then
		DocumentObject_.RegisterRecords.International.Write = True;
		DocumentObject_.RegisterRecords.InternationalWithoutCorrespondence.Write = True;
		If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
			DocumentObject_.RegisterRecords.International.Load(Postings);
		ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
			DocumentObject_.RegisterRecords.InternationalWithoutCorrespondence.Load(Postings);
		EndIf;
		DocumentObject_.Write();
	EndIf;
	
	If ImportParameters.UploadingToDocument Then
		AddressOfPostingsInTheStorage = PutToTempStorage(Postings, UUID);
	EndIf;
	
	Return UploadedWithoutErrors;
	
EndFunction

&AtServer
Procedure FillInViewOfTransactionMovement(TransactionData, LineNumber, DrCr = "")
	
	If DrCr = "Dr" Then
		If TransactionData.Property("RecordType") And TransactionData.RecordType <> AccountingRecordType.Debit Then
			Raise StrTemplate(NStr("vi = 'Tại dòng %1 đồng thời điền số tiền nợ và có. Đã ngừng kết nhập.';
									|ru = 'В строке %1 одновременно заполнена суммы дебита и кредита. Загрузка прервана.';
									|en = 'In line %1 both debit and credit amounts are filled. Import is canceled.'; fa = 'In line %1 both debit and credit amounts are filled. Import is canceled.';
									|it = 'Nella riga %1sono compilati contemporaneamente gli importi di debito e credito. Download interrotto.';
									|pl = 'W wierszu %1 jednocześnie są wypełnione kwota wn i ma. Import został przerwany.';
									|tr = '%1 satır aynı anda borç ve alacak tutarlarını içerir. İndirme kesintiye uğradı.'"), LineNumber);
		Else
			TransactionData.Insert("RecordType", AccountingRecordType.Debit);
		EndIf;
	ElsIf DrCr = "Cr" Then
		If TransactionData.Property("RecordType") And TransactionData.RecordType <> AccountingRecordType.Credit Then
			Raise StrTemplate(NStr("vi = 'Tại dòng %1 đồng thời điền số tiền nợ và có. Đã ngừng kết nhập.';
									|ru = 'В строке %1 одновременно заполнена суммы дебита и кредита. Загрузка прервана.';
									|en = 'In line %1 both debit and credit amounts are filled. Import is canceled.'; fa = 'In line %1 both debit and credit amounts are filled. Import is canceled.';
									|it = 'Nella riga %1sono compilati contemporaneamente gli importi di debito e credito. Download interrotto.';
									|pl = 'W wierszu %1 jednocześnie są wypełnione kwota wn i ma. Import został przerwany.';
									|tr = '%1 satır aynı anda borç ve alacak tutarlarını içerir. İndirme kesintiye uğradı.'"), LineNumber);
		Else
			TransactionData.Insert("RecordType", AccountingRecordType.Credit);
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure InitializeParametersForUploadingTransactionsWithCorrespondence()
	
	ImportParameters = ImportParameters();
	If Parameters.Property("Organization") Then
		FillPropertyValues(ImportParameters, Parameters);
		ImportParameters.UploadingToDocument = True;
	EndIf;
	
	AccountingByDirectionsIsUsed = GetFunctionalOption("GenerateFinancialResult");
	OrganizationIsFilledIn = Not ImportParameters.UploadingToDocument And Not ValueIsFilled(DefaultCompany);
	
	LoadingFields = New Array;
		
	If ImportParameters.EnterPeriodByRows Then
		LoadingFields.Add("Period");
	EndIf;
	If OrganizationIsFilledIn Then
		LoadingFields.Add("Organization");
	EndIf;
	LoadingFields.Add("AccountDr");
	LoadingFields.Add("ExtDimensionDr1");
	LoadingFields.Add("ExtDimensionDr2");
	LoadingFields.Add("ExtDimensionDr3");
	LoadingFields.Add("AccountCr");
	LoadingFields.Add("ExtDimensionCr1");
	LoadingFields.Add("ExtDimensionCr2");
	LoadingFields.Add("ExtDimensionCr3");
	LoadingFields.Add("CurrencyDr");
	LoadingFields.Add("CurrencyAmountDr");
	LoadingFields.Add("CountDr");
	LoadingFields.Add("CurrencyCr");
	LoadingFields.Add("CurrencyAmountCr");
	LoadingFields.Add("CountCr");
	LoadingFields.Add("Sum");
	LoadingFields.Add("PresentationAmount");
	LoadingFields.Add("DepartmentDr");
	LoadingFields.Add("DepartmentCr");
	If AccountingByDirectionsIsUsed Then
		LoadingFields.Add("LineOfBusinessDr");
		LoadingFields.Add("LineOfBusinessCr");
	EndIf;
	LoadingFields.Add("PostingType");
	LoadingFields.Add("Content");
	
	ImportParameters.Insert("Fields",LoadingFields);
	
	// Initializing a tabular document
	SpreadsheetDocument.Clear();
	
	TemplateTemplate = Documents.TransactionFinancialAccounting.GetTemplate("ImportTemplateForEntriesWithCorrespondence");
	ColumnArea = TemplateTemplate.GetArea("Postings");
	SpreadsheetDocument.Join(ColumnArea);
	If Not AccountingByDirectionsIsUsed Then
		DirectionColumnNumber = "C21";
		DirectionColumn = SpreadsheetDocument.Area(DirectionColumnNumber);
		SpreadsheetDocument.DeleteArea(DirectionColumn,SpreadsheetDocumentShiftType.Horizontal);
		DirectionColumn = SpreadsheetDocument.Area(DirectionColumnNumber);
		SpreadsheetDocument.DeleteArea(DirectionColumn,SpreadsheetDocumentShiftType.Horizontal);
	EndIf;
	If Not OrganizationIsFilledIn Then
		OrganizationColumn = SpreadsheetDocument.Area("C2");
		SpreadsheetDocument.DeleteArea(OrganizationColumn,SpreadsheetDocumentShiftType.Horizontal);
	EndIf;
	If Not ImportParameters.EnterPeriodByRows Then
		ColumnPeriod = SpreadsheetDocument.Area("C1");
		SpreadsheetDocument.DeleteArea(ColumnPeriod,SpreadsheetDocumentShiftType.Horizontal);
	EndIf;
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

&AtServer
Procedure InitializeParametersForUploadingTransactionsWithoutCorrespondence()
	
	ImportParameters = ImportParameters();
	If Parameters.Property("Organization") Then
		FillPropertyValues(ImportParameters, Parameters);
		ImportParameters.UploadingToDocument = True;
	EndIf;
	
	AccountingByDirectionsIsUsed = GetFunctionalOption("GenerateFinancialResult");
	OrganizationIsFilledIn = Not ImportParameters.UploadingToDocument And Not ValueIsFilled(DefaultCompany);
	
	LoadingFields = New Array;
	If ImportParameters.EnterPeriodByRows Then
		LoadingFields.Add("Period");
	EndIf;
	If OrganizationIsFilledIn Then
		LoadingFields.Add("Organization");
	EndIf;
	LoadingFields.Add("Department");
	If AccountingByDirectionsIsUsed Then
		LoadingFields.Add("LineOfBusiness");
	EndIf;
	LoadingFields.Add("Account");
	LoadingFields.Add("ExtDimension1");
	LoadingFields.Add("ExtDimension2");
	LoadingFields.Add("ExtDimension3");
	LoadingFields.Add("Currency");
	LoadingFields.Add("CurrencyAmount");
	LoadingFields.Add("Count");
	LoadingFields.Add("SumDr");
	LoadingFields.Add("PresentationAmountDr");
	LoadingFields.Add("SumCr");
	LoadingFields.Add("PresentationAmountCr");
	LoadingFields.Add("PostingType");
	LoadingFields.Add("Content");
	
	ImportParameters.Insert("Fields",LoadingFields);
	
	// Initializing a tabular document
	SpreadsheetDocument.Clear();
	
	TemplateTemplate = Documents.TransactionFinancialAccounting.GetTemplate("ImportTemplateForEntriesWithoutCorrespondence");
	ColumnArea = TemplateTemplate.GetArea("Postings");
	SpreadsheetDocument.Join(ColumnArea);
	If Not AccountingByDirectionsIsUsed Then
		DirectionColumnNumber = "C4";
		DirectionColumn = SpreadsheetDocument.Area(DirectionColumnNumber);
		SpreadsheetDocument.DeleteArea(DirectionColumn,SpreadsheetDocumentShiftType.Horizontal);
	EndIf;
	If Not OrganizationIsFilledIn Then
		OrganizationColumn = SpreadsheetDocument.Area("C2");
		SpreadsheetDocument.DeleteArea(OrganizationColumn,SpreadsheetDocumentShiftType.Horizontal);
	EndIf;
	If Not ImportParameters.EnterPeriodByRows Then
		ColumnPeriod = SpreadsheetDocument.Area("C1");
		SpreadsheetDocument.DeleteArea(ColumnPeriod,SpreadsheetDocumentShiftType.Horizontal);
	EndIf;
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

&AtServer
Function ImportParameters()
	
	ImportParameters = New Structure();
	ImportParameters.Insert("UploadingToDocument", False);
	ImportParameters.Insert("DocumentDate");
	ImportParameters.Insert("ChartOfAccounts");
	ImportParameters.Insert("Organization");
	ImportParameters.Insert("EnterPeriodByRows", True);
	ImportParameters.Insert("Fields", New Array);
	
	Return ImportParameters;

EndFunction


#Region Other

&AtServer
Procedure ChartOfAccountsInternationalAccountingInCaseOfChangeServer()
	
	OptionForGeneratingTransactions = Undefined;
	If ValueIsFilled(ChartOfAccounts) Then
		OptionForGeneratingTransactions = Common.ObjectAttributeValue(ChartOfAccounts, "OptionForGeneratingTransactions");
	EndIf;
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		InitializeParametersForUploadingTransactionsWithoutCorrespondence();
		Items.DownloadButton.Enabled = True;
	ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		InitializeParametersForUploadingTransactionsWithCorrespondence();
		Items.DownloadButton.Enabled = True;
	Else
		SpreadsheetDocument.Clear();
		Items.DownloadButton.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Function TextToDate(Val StringValue, LineNumber, ColumnName, Separator = ".")
	
	Try
		Result = Date(StringValue)
	Except
		DateText__ = Left(TrimAll(StringValue),10);
		Pos = StrFind(DateText__," ");
		If Pos = 9 Then
			DateText__ = Left(TrimAll(StringValue),8);
		EndIf;
		Digits = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DateText__,Separator);
		Try
			Result = ?(StrLen(Digits[2]) = 2, "20"+Digits[2], Digits[2]) 
						+ Format(Digits[1], "ND=2; NLZ=;") 
						+ Format(Digits[0], "ND=2; NLZ=;");
			Result = Date(Result);
		Except
			ReportConversionError(LineNumber, ColumnName, StringValue);
		EndTry;
	EndTry;
	Return Result;
	
EndFunction

&AtServer
Function TextToNumber(StringValue, LineNumber, ColumnName)
	
	If IsBlankString(StringValue) Or StringValue = Undefined Then
		Return 0;
	EndIf;
	
	Try
		Result = Number(StrReplace(StringValue," ",""));
	Except
		ReportConversionError(LineNumber, ColumnName, StringValue);
	EndTry;
	Return Result;
	
EndFunction

&AtServer
Procedure FillExtdimension(AccountingEntry, Account, DrCr = "")
	
	If ValueIsFilled(Account) Then
		AccountProperties = FinancialAccountingServerCached.AccountProperties(Account);
		For Cnt = 1 To 3 Do
			AccountingEntry["ExtDimensionType" + DrCr + String(Cnt)] = AccountProperties["ExtDimensionType" + String(Cnt)];
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAmounts(AccountingEntry, RateCache, DocumentDate)
	
	If AccountingEntry.Sum <> 0 And AccountingEntry.PresentationAmount <> 0 Then
		Return;
	EndIf;
	
	DateOfCourse = AccountingEntry.Period;
	If Not ValueIsFilled(DateOfCourse) Then
		DateOfCourse = DocumentDate;
	EndIf;
	Currency = Undefined;
	CurrencyAmount = TransactionCurrencyAmount(AccountingEntry, Currency);
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(AccountingEntry.Organization);
	AccountingCurrencies = FinancialAccountingServerCached.AccountingCurrencies(AccountingEntry.ChartOfAccounts, AccountingEntry.Organization);
	FunctionalCurrencyRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(AccountingCurrencies.Functional, DateOfCourse, RateCache, CurrencyOfComplianceAccounting);
	CurrencyExchangeRate_  = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(AccountingCurrencies.Presentations, DateOfCourse, RateCache, CurrencyOfComplianceAccounting);
	
	If AccountingEntry.Sum = 0 And FunctionalCurrencyRate <> 0 Then
		If CurrencyAmount <> 0 Then
			CurrencyExchangeRate  = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(Currency, DateOfCourse, RateCache);
			AccountingEntry.Sum = CurrencyAmount * CurrencyExchangeRate / FunctionalCurrencyRate;
		ElsIf AccountingEntry.PresentationAmount <> 0 Then
			AccountingEntry.Sum = AccountingEntry.PresentationAmount * CurrencyExchangeRate_ / FunctionalCurrencyRate;
		EndIf;
	EndIf;
	
	If AccountingEntry.PresentationAmount = 0 And CurrencyExchangeRate_ <> 0 Then
		AccountingEntry.PresentationAmount = AccountingEntry.Sum * FunctionalCurrencyRate / CurrencyExchangeRate_;
	EndIf;
	
EndProcedure

&AtServer
Function TransactionCurrencyAmount(AccountingEntry, Currency)
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		If AccountingEntry.CurrencyAmountDr <> 0 Then
			Currency = AccountingEntry.CurrencyDr;
			Return AccountingEntry.CurrencyAmountDr;
		ElsIf AccountingEntry.CurrencyAmountCr <> 0 Then
			Currency = AccountingEntry.CurrencyCr;
			Return AccountingEntry.CurrencyAmountCr;
		EndIf;
	ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		If ValueIsFilled(AccountingEntry.CurrencyAmount) Then
			Currency = AccountingEntry.Currency;
			Return AccountingEntry.CurrencyAmount;
		EndIf;
	EndIf;
	
	Return 0;
	
EndFunction

&AtServer
Function FindValueOfExtdimension(Account, ExtDimensionNumber, ValueText)
	
	For Each ExtDimensionType In Account.ExtDimensionTypes[ExtDimensionNumber-1].ExtDimensionType.ValueType.Types() Do
		
		ObjectKind = Common.ObjectKindByType(ExtDimensionType);
		FullName = Metadata.FindByType(ExtDimensionType).FullName();
		ObjectName = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullName,".")[1];
		
		If ObjectKind = "Enum" Then
			TextOfEnumerationValue = StrReplace(Title(ValueText), " ", "");
			Simple = Enums[ObjectName][TextOfEnumerationValue];
		Else
			Simple = FindFieldValue(FullName, ValueText);;
		EndIf;
		
		If ValueIsFilled(Simple) Then
			Break;
		EndIf;
		
	EndDo;
	
	Return Simple;
	
EndFunction

&AtServer
Function FindFieldValue(FullObjectName,ValueText, AdditionalSelection = Undefined)
	
	MetadataObject = Metadata.FindByFullName(FullObjectName);
	
	ArrayOfRequestTexts = New Array;
	If MetadataObject.DescriptionLength <> 0 Then
		ArrayOfRequestTexts.Add(
			"SELECT
			|	1 AS Priority,
			|	Table.Ref
			|FROM
			|	&FullObjectName AS Table
			|WHERE
			|	Table.Description = &ValueText
			|	AND &AdditionalSelection
			|");
	EndIf;
	If MetadataObject.CodeLength <> 0 Then
		ArrayOfRequestTexts.Add(
			"SELECT
			|	2 AS Priority,
			|	Table.Ref
			|FROM
			|	&FullObjectName AS Table
			|WHERE
			|	Table.Code = &ValueText
			|	AND &AdditionalSelection
			|");
	EndIf;
	
	QueryText = 
		StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin())
		+ Chars.LF
		+ "ORDER BY Priority";
	
	
	Query = New Query;
	If AdditionalSelection <> Undefined Then
		ArrayAdditionalSelection = New Array;
		For Each KeyAndValue In AdditionalSelection Do
			ArrayAdditionalSelection.Add(StrTemplate("Table.%1 = &%1", KeyAndValue.Key));
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		TextAdditionalSelection = StrConcat(ArrayAdditionalSelection, Chars.LF + "And" + " ");
	Else
		TextAdditionalSelection = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "&AdditionalSelection", TextAdditionalSelection);
	
	Query.Text = QueryText;
	Query.SetParameter("ValueText", ValueText);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Common.ObjectManagerByFullName(FullObjectName).EmptyRef();
	
EndFunction

&AtServer
Function CellText(SpreadsheetDocument, LineNumber, ColumnNumber)
	
	StorageBinLocation = StrTemplate("R%1C%2", Format(LineNumber, "NZ=0; NG=0"), String(ColumnNumber));
	Return TrimAll(SpreadsheetDocument.Area(StorageBinLocation).Text);
	
EndFunction

&AtServer
Function LineFilled(SpreadsheetDocument, LineNumber)
	
	ResourceColumns = New Array;
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		ResourceColumns.Add("Sum");
		ResourceColumns.Add("PresentationAmount");
		ResourceColumns.Add("CountDr");
		ResourceColumns.Add("CountCr");
		ResourceColumns.Add("CurrencyAmountDr");
		ResourceColumns.Add("CurrencyAmountCr");
	Else
		ResourceColumns.Add("SumDr");
		ResourceColumns.Add("SumCr");
		ResourceColumns.Add("PresentationAmountDr");
		ResourceColumns.Add("PresentationAmountCr");
		ResourceColumns.Add("Currency");
		ResourceColumns.Add("CurrencyAmount");
		ResourceColumns.Add("Count");
	EndIf;
	
	For Each Column In ResourceColumns Do
		If Not IsBlankString(CellText(SpreadsheetDocument, LineNumber, ColumnNumber(Column))) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure ReportConversionError(LineNumber, ColumnName, StringValue)
	
	TextTemplate1 = NStr("vi = 'Dòng số %1 cột ""%2"" - lỗi chuyển đổi giá trị ""%3""
						|Giá trị ô chưa được kết nhập!';
						|ru = 'Строка №%1 колонка ""%2"" - ошибка преобразования значения ""%3""
						|Значение ячейки не загружено!';
						|en = 'Row No.%1 column ""%2"" - conversion error of value ""%3""
						|Cell value is not imported.'; fa = 'Row No.%1 column ""%2"" - conversion error of value ""%3""
						|Cell value is not imported.';
						|it = 'Riga №%1 colonna ""%2""- errore di conversione del valore ""%3""
						| Il valore della casella non è stato caricato!';
						|pl = 'Wiersz nr%1 kolumna ""%2"" - błąd konwersji wartości ""%3""
						|Nie pobrano wartości komórki!';
						|tr = 'Satır №%1 sütun ""%2"" - ""%3"" değeri dönüştürülürken hata
						|Hücre değeri yüklenmedi!'");
	Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, LineNumber, ColumnName, StringValue);
	Common.MessageToUser(Text);
	
EndProcedure

&AtServer
Function ColumnNumber(FieldName)
	
	Return ImportParameters.Fields.Find(FieldName) + 1;
	
EndFunction

#EndRegion

#EndRegion
