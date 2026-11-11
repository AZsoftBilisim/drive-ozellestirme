#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		If SelectedForm = Undefined Then
			Raise NStr("vi = 'Có thể khởi động bộ xử lý chỉ từ biểu mẫu ""Hệ thống tài khoản"" bằng các nút ""Kết xuất"" hoặc ""Kết nhập"".
			|Hãy chuyển đến phần hành ""Kế toán tài chính quốc tế""-""Tùy chỉnh và danh mục""-""Hệ thống tài khoản"".';
			|ru = 'Запуск обработки возможен только из формы ""Плана счетов"" кнопками ""Выгрузить"" или ""Загрузить"".
			|Перейдите в раздел ""Международный финансовый учет""-""Настройки и справочники""-""Планы счетов"".';
			|en = 'To start the data processor, go to General ledger > Settings and catalogs > Charts of accounts
			| and click Export or Import.'; fa = 'To start the data processor, go to General ledger > Settings and catalogs > Charts of accounts
			| and click Export or Import.';
			|it = 'L''elaborazione può essere avviata solo dal modulo ""Piano di conti"" tramite i pulsanti ""Caricare"" o ""Scaricare"".
			|Andare alla sezione ""Contabilità finanziaria internazionale"" - ""Impostazioni e directory"" - ""Piani di conti"".';
			|pl = 'Uruchomienie przetwarzania jest możliwe tylko z formularza ""Planu kont"" za pomocą przycisków ""Prześlij"" lub ""Pobierz"".
			|Przejdź do sekcji ""Międzynarodowa ewidencja finansowa""-""Ustawienia i katalogi""-""Plany kont"".';
			|tr = 'İşlem başlatması sadece ""Hesap Planı"" formundan ""Yükle"" veya ""İndir"" butonları kullanılarak yapılabilir.
			|""Genel muhasebe"" - ""Ayarlar ve kataloglar"" - ""Hesap planları"" bölümüne git.'");
		EndIf;
	#EndIf
		
EndProcedure

#EndRegion

#Region Internal

#Region UploadingChartOfAccounts

// Returns the structure of the download reports
//
// Returns:
// 	Structure - verification parameters:
// 		* TableCreated - SpreadsheetDocument - List of created objects
// 		* Table_Updated - SpreadsheetDocument - List of updated objects
// 		* TableSkipped - SpreadsheetDocument - List of missing items
// 		* TotalUpdated - Number - Number of updated objects
// 		* TotalSkipped - Number - Number of missed objects
// 		* TotalCreated - Number - Number of objects created
//
Function ParametersOfDownloadReports() Export
	
	ReportsParameters = New Structure;
	
	ReportsParameters.Insert("TableCreated");
	ReportsParameters.Insert("Table_Updated");
	ReportsParameters.Insert("TableSkipped");
	ReportsParameters.Insert("TotalUpdated");
	ReportsParameters.Insert("TotalSkipped");
	ReportsParameters.Insert("TotalCreated");
	
	Return ReportsParameters;
	
EndFunction

// Returns parameters for loading the invoice plan
//
// Returns:
// 	Structure - verification parameters:
// 		* MappingTable - ValueTable - Table of cell mapping in the Template and file
// 		* ReportParameters - Structure - Structure with report parameters and results See ParametersOfDownloadReports
//                                   ()
// 		* UploadFromFile - Boolean - If true, then the download is from a file, otherwise from the skipped tables
// 		* BinaryData - BinaryData - The file being uploaded
// 		* Extension - String - extension of the downloaded file 
// 		* ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Chart of accounts to upload
//
Function ParametersForLoadingChartOfAccounts() Export
	
	ImportParameters = New Structure;
	
	ImportParameters.Insert("MappingTable");
	ImportParameters.Insert("ReportParameters");
	ImportParameters.Insert("UploadFromFile", False);
	ImportParameters.Insert("BinaryData", Undefined);
	ImportParameters.Insert("Extension", Undefined);
	ImportParameters.Insert("ChartOfAccounts", Catalogs.FinancialAccountingChartsOfAccounts.EmptyRef());
	
	Return ImportParameters;
	
EndFunction

// Loads the chart of accounts from a file or tabular document
//
// Parameters:
// 	 ImportParameters - Structure - See ParametersForLoadingChartOfAccounts()
//
// Returns:
//	Structure - Structure with report parameters and results See ParametersOfDownloadReports
//             ()
//
Function DownloadDataFromAFile(ImportParameters) Export
	
	ReportParameters = ImportParameters.ReportParameters;
	MappingTable = ImportParameters.MappingTable;
	UploadFromFile = ImportParameters.UploadFromFile;
	BinaryData = ImportParameters.BinaryData; // BinaryData
	Extension = ImportParameters.Extension;
	ChartOfAccounts = ImportParameters.ChartOfAccounts;
	
	MatchingAccountType = New Map;
	For Each ConfigurationLanguage In Metadata.Languages Do
		
		LanguageCode = ConfigurationLanguage.LanguageCode;
		
		MatchingAccountType.Insert(NStr("vi = 'Tài sản';
										|ru = 'Актив';
										|en = 'Asset'; fa = 'دارایی';
										|it = 'Актив';
										|pl = 'Asset';
										|tr = 'Varlık'", LanguageCode), AccountType.Active);
		MatchingAccountType.Insert(NStr("vi = 'Nguồn vốn';
										|ru = 'Пассив';
										|en = 'Liability'; fa = 'بدهی';
										|it = 'Пассив';
										|pl = 'Liability';
										|tr = 'Yükümlülük'", LanguageCode), AccountType.Passive);
		MatchingAccountType.Insert(NStr("vi = 'Tài sản/Nguồn vốn';
										|ru = 'Актив/Пассив';
										|en = 'Asset/Liability'; fa = 'دارایی/بدهی';
										|it = 'Актив/Пассив';
										|pl = 'Aktywa/Pasywa';
										|tr = 'Varlık/Yükümlülük'", LanguageCode), AccountType.ActivePassive);
		
	EndDo;
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.ChartOfAccountsExportImportWizard.Template");
	
	RegionHeader = Template.GetArea("Header|Data");
	OblString = Template.GetArea("String|Data");
	
	RegionHeaderSkipped = Template.GetArea("Header");
	OblLineSkipped = Template.GetArea("String");
	
	ReportParameters.Insert("OblString", OblString);
	ReportParameters.Insert("OblLineSkipped", OblLineSkipped);
	
	ImportedTemplateWithData = New SpreadsheetDocument;	
	If UploadFromFile Then
		
		TempFileName = GetTempFileName(Extension);
		BinaryData.Write(TempFileName);
		
		ImportedTemplateWithData.Read(TempFileName);
		
		ReportParameters.TotalUpdated = 0;
		ReportParameters.TotalSkipped = 0;
		ReportParameters.TotalCreated = 0;
		
		ReportParameters.TableCreated.Clear();
		ReportParameters.Table_Updated.Clear();
		ReportParameters.TableSkipped.Clear();
		
		ReportParameters.TableCreated.Put(RegionHeader);
		ReportParameters.Table_Updated.Put(RegionHeader);
		ReportParameters.TableSkipped.Put(RegionHeaderSkipped);
		
	Else
		
		ImportedTemplateWithData.Put(ReportParameters.TableSkipped);
		
		ReportParameters.TotalSkipped = 0;
		ReportParameters.TableSkipped.Clear();
		ReportParameters.TableSkipped.Put(RegionHeaderSkipped);
		
	EndIf;
	
	MatchingColumnNumberInFileAndAttributeName = CheckHeaderOfUploadFile(ImportedTemplateWithData, UploadFromFile);
	
	For LineNumber = 2 To ImportedTemplateWithData.TableHeight Do
		
		NumberOfColumnWithCode = MatchingColumnNumberInFileAndAttributeName["NumberOfColumnWithCode"];
		CellWithCodeOfChartOfAccounts = ImportedTemplateWithData.GetArea(LineNumber, NumberOfColumnWithCode, LineNumber, NumberOfColumnWithCode);
		Code = TrimAll(CellWithCodeOfChartOfAccounts.CurrentArea.Text);
		
		If ValueIsFilled(Code) Then
			
			NewRow = MappingTable.Add();
			
		Else
			
			Continue;
			
		EndIf;
		
		For Each ColumnNumberAndAttributes In MatchingColumnNumberInFileAndAttributeName Do
			
			If ColumnNumberAndAttributes.Key = "NumberOfColumnWithCode" Then
				
				Continue;
				
			EndIf;
			
			Cell = ImportedTemplateWithData.GetArea(LineNumber, ColumnNumberAndAttributes.Key, LineNumber, ColumnNumberAndAttributes.Key);
			CellText = TrimAll(Cell.CurrentArea.Text);
			
			If CellText = "" Then
				
				Continue;
				
			EndIf;
			
			If ColumnNumberAndAttributes.Value = "Kind" Then
				
				NewRow[ColumnNumberAndAttributes.Value] = MatchingAccountType[CellText];
				
			Else
				
				AttributeType = TypeOf(NewRow[ColumnNumberAndAttributes.Value]);
				If AttributeType = Type("Boolean") Then
					
					NewRow[ColumnNumberAndAttributes.Value] = Boolean(CellText);
				
				ElsIf AttributeType = Type("String")
					Or AttributeType = Type("Undefined") Then
					
					NewRow[ColumnNumberAndAttributes.Value] = CellText;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	VT.Code AS Code,
	|	VT.GroupCode AS GroupCode
	|INTO TT_VT
	|FROM
	|	&MappingTable AS VT
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_VT.Code AS Code,
	|	International.Ref AS Account
	|FROM
	|	TT_VT AS TT_VT
	|		INNER JOIN ChartOfAccounts.International AS International
	|		ON TT_VT.Code = International.Code
	|			AND (International.ChartOfAccounts = &ChartOfAccounts)
	|
	|UNION ALL
	|
	|SELECT
	|	TT_VT.GroupCode,
	|	InternationalParents.Ref
	|FROM
	|	TT_VT AS TT_VT
	|		INNER JOIN ChartOfAccounts.International AS InternationalParents
	|		ON TT_VT.GroupCode = InternationalParents.Code
	|			AND (InternationalParents.ChartOfAccounts = &ChartOfAccounts)";
	
	Query.SetParameter("MappingTable", MappingTable);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	
	VTElementsToUpdate = Query.Execute().Unload();
	
	For Each TableRow In MappingTable Do
		
		If TableRow.Processed Then
			
			Continue;
			
		EndIf;
		
		BeginTransaction();
		Try
			
			If TableRow.Code = TableRow.GroupCode Then
				
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể ghi lại phần tử có mã ""%1"", mã lớp trên và phần tử giống nhau';
																								|ru = 'Не удалось записать элемент с кодом ""%1"", одинаковые код родителя и элемента';
																								|en = 'Cannot save the item with code ""%1"", the parent code and the item code are identical'; fa = 'Cannot save the item with code ""%1"", the parent code and the item code are identical';
																								|it = 'Non è stato possibile salvare l''elemento con il codice ""%1"", i codici genitore ed elemento sono identici';
																								|pl = 'Nie udało się zapisać elementu z kodem ""%1"", jednakowe kody rodzica i elementu';
																								|tr = 'Aynı ebeveyn ve öğe kimliğine sahip ""%1"" kodlu öğe kaydedilemedi'"), TableRow.Code);
				Raise ExceptionText;
				
			EndIf;
			
			CreateAccount(TableRow, MappingTable, ReportParameters, VTElementsToUpdate, ChartOfAccounts);
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = BriefErrorDescription(ErrorInfo());
			
			If Not TableRow.Processed Then
				
				OblLineSkipped.Parameters.Fill(TableRow);
				OblLineSkipped.Parameters.ErrorDescription = ErrorText;
				
				TabDocSkipped = ReportParameters.TableSkipped; // SpreadsheetDocument
				TabDocSkipped.Put(OblLineSkipped);
				TabDocSkipped.Areas.String.Protection = False;
				ReportParameters.TotalSkipped = ReportParameters.TotalSkipped + 1;
				
				TableRow.Processed = True;
				
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể ghi lại lớp trên có mã %1';
																						|ru = 'Не удалось записать родителя с кодом %1';
																						|en = 'Cannot save the parent with code %1'; fa = 'Cannot save the parent with code %1';
																						|it = 'Non è stato possibile salvare il genitore con il codice %1';
																						|pl = 'Nie udało się zapisać rodzica i elementu %1';
																						|tr = '%1 koda sahip ebeveyn kaydedilemedi'"), TableRow.Code);
			FindAndCancelProcessingOfSubordinateObjects(MappingTable, ReportParameters, TableRow, ErrorText);
			
		EndTry;
		
	EndDo;
	
	Return ReportParameters;
	
EndFunction

#EndRegion

#Region Uploading_ChartOfAccounts

// Returns Parameters for uploading an invoice plan
//
// Returns:
// 	Structure - verification parameters:
// 		* ChartOfAccounts - SpreadsheetDocument - List of created objects
// 		* FileName - SpreadsheetDocument - List of updated objects
// 		* TableSkipped - SpreadsheetDocument - List of missing items
// 		* TotalUpdated - Number - Number of updated objects
// 		* TotalSkipped - Number - Number of missed objects
// 		* TotalCreated - Number - Number of objects created
//
Function ParametersForUploadingChartOfAccounts() Export
	
	ParametersForUploadingChartOfAccounts = New Structure;
	
	ParametersForUploadingChartOfAccounts.Insert("ChartOfAccounts");
	ParametersForUploadingChartOfAccounts.Insert("FileName");
	
	Return ParametersForUploadingChartOfAccounts;
	
EndFunction

// Generates a tabular document with chart of accounts data
//
// Parameters:
// 	 ExportingParameters - Structure - See ParametersForUploadingChartOfAccounts()
//
// Returns:
//	SpreadsheetDocument - tabular document with chart of accounts data
//
Function UploadAccountPlanData(ExportingParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	International.Ref AS Ref,
	|	ISNULL(InternationalGroup.Code, """") AS GroupCode,
	|	International.Parent AS Group,
	|	International.Code AS Code,
	|	International.Description AS Description,
	|	International.Order AS Order,
	|	CASE International.Type
	|		WHEN VALUE(AccountType.Active)
	|			THEN &AssetBalanceSheetName
	|		WHEN VALUE(AccountType.Passive)
	|			THEN &Liabilities
	|		WHEN VALUE(AccountType.ActivePassive)
	|			THEN &AssetLiability
	|	END AS Kind,
	|	International.AccountingByBusinessUnits AS AccountingByBusinessUnits,
	|	International.AccountingByLinesOfBusiness AS AccountingByLinesOfBusiness,
	|	International.OffBalance AS OffBalance,
	|	International.DescriptionInternational AS DescriptionInternational,
	|	International.RestrictUseInPostings AS RestrictUseInPostings,
	|	International.LongDesc AS LongDesc,
	|	International.Currency1 AS Currency1,
	|	International.Quantitative AS Quantitative
	|INTO TT_InternationalChartOfAccounts
	|FROM
	|	ChartOfAccounts.International AS International
	|		LEFT JOIN ChartOfAccounts.International AS InternationalGroup
	|		ON International.Parent = InternationalGroup.Ref
	|WHERE
	|	&SelectionAccordingToChartOfAccounts
	|
	|INDEX BY
	|	Ref
	|;
	|///////////////////////////////////////////
	|SELECT
	|	TT_InternationalChartOfAccounts.GroupCode AS GroupCode,
	|	TT_InternationalChartOfAccounts.Group AS Group,
	|	TT_InternationalChartOfAccounts.Code AS Code,
	|	TT_InternationalChartOfAccounts.Description AS Description,
	|	TT_InternationalChartOfAccounts.Order AS Order,
	|	TT_InternationalChartOfAccounts.Kind AS Kind,
	|	TT_InternationalChartOfAccounts.AccountingByBusinessUnits AS AccountingByBusinessUnits,
	|	TT_InternationalChartOfAccounts.AccountingByLinesOfBusiness AS AccountingByLinesOfBusiness,
	|	TT_InternationalChartOfAccounts.OffBalance AS OffBalance,
	|	TT_InternationalChartOfAccounts.DescriptionInternational AS DescriptionInternational,
	|	TT_InternationalChartOfAccounts.RestrictUseInPostings AS RestrictUseInPostings,
	|	TT_InternationalChartOfAccounts.LongDesc AS LongDesc,
	|	TT_InternationalChartOfAccounts.Currency1 AS Currency1,
	|	TT_InternationalChartOfAccounts.Quantitative AS Quantitative,
	|	ISNULL(InternationalExtdimensionDay1.ExtDimensionType.Description, """") AS ExtDimension1,
	|	ISNULL(InternationalExtdimensionDay1.TurnoversOnly, FALSE) AS ExtDimension1RevolutionsOnly,
	|	ISNULL(InternationalExtdimensionDay2.ExtDimensionType.Description, """") AS ExtDimension2,
	|	ISNULL(InternationalExtdimensionDay2.TurnoversOnly, FALSE) AS ExtDimension2RevolutionsOnly,
	|	ISNULL(InternationalExtdimensionDay3.ExtDimensionType.Description, """") AS ExtDimension3,
	|	ISNULL(InternationalExtdimensionDay3.TurnoversOnly, FALSE) AS ExtDimension3RevolutionsOnly
	|FROM
	|	TT_InternationalChartOfAccounts
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON TT_InternationalChartOfAccounts.Ref = InternationalExtdimensionDay1.Ref
	|		AND InternationalExtdimensionDay1.LineNumber = 1
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON TT_InternationalChartOfAccounts.Ref = InternationalExtdimensionDay2.Ref
	|		AND InternationalExtdimensionDay2.LineNumber = 2
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON TT_InternationalChartOfAccounts.Ref = InternationalExtdimensionDay3.Ref
	|		AND InternationalExtdimensionDay3.LineNumber = 3
	|
	|ORDER BY
	|	Code";
	
	Query.SetParameter("AssetBalanceSheetName", NStr("vi = 'Tài sản';
													|ru = 'Актив';
													|en = 'Asset'; fa = 'دارایی';
													|it = 'Attivo';
													|pl = 'Asset';
													|tr = 'Varlık'"));
	Query.SetParameter("Liabilities", NStr("vi = 'Nguồn vốn';
											|ru = 'Пассив';
											|en = 'Liability'; fa = 'بدهی';
											|it = 'Passività';
											|pl = 'Liability';
											|tr = 'Yükümlülük'"));
	Query.SetParameter("AssetLiability", NStr("vi = 'Tài sản/Nguồn vốn';
												|ru = 'Актив/Пассив';
												|en = 'Asset/Liability'; fa = 'دارایی/بدهی';
												|it = 'Attivo/passivo';
												|pl = 'Aktywa/Pasywa';
												|tr = 'Varlık/Yükümlülük'"));
	
	TextOfSelectionAccordingToChartOfAccounts = "TRUE";
	If GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
		
		TextOfSelectionAccordingToChartOfAccounts = "International.ChartOfAccounts = &ChartOfAccounts";
		Query.SetParameter("ChartOfAccounts", ExportingParameters.ChartOfAccounts)
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&SelectionAccordingToChartOfAccounts", TextOfSelectionAccordingToChartOfAccounts);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = PrintManagement.PrintFormTemplate("DataProcessor.ChartOfAccountsExportImportWizard.Template");
	
	RegionHeader = Template.GetArea("Header|Data");
	OblString = Template.GetArea("String|Data");
	
	SpreadsheetDocument.Put(RegionHeader);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		OblString.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(OblString);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Create a ledger account
// 
// Parameters:
//  InvoiceData - ValueTableRow - contains fields:
//  	* Kind - AccountType -
//  MappingTable - ValueTable - 
//  ReportParameters - Structure - 
//  VTElementsToUpdate - ValueTable - 
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - 
// 
// Returns:
//  ChartOfAccountsRef.International -  Create an invoice
Function CreateAccount(InvoiceData, MappingTable, ReportParameters, VTElementsToUpdate, ChartOfAccounts)
	
	FoundItems1 = VTElementsToUpdate.FindRows(New Structure("Code", InvoiceData.Code));
	If FoundItems1.Count() > 0 Then
		
		NewItem = FoundItems1[0].Account.GetObject();
		IsNew = False;
		
	Else
		
		NewItem = ChartsOfAccounts.International.CreateAccount();
		IsNew = True;
		
	EndIf;
	
	If ValueIsFilled(InvoiceData.GroupCode) Then
		
		FoundItems1 = VTElementsToUpdate.FindRows(New Structure("Code", InvoiceData.GroupCode));
		If FoundItems1.Count() > 0 Then
			
			NewItem.Parent = FoundItems1[0].Account;
			
		EndIf;
		
		If Not ValueIsFilled(NewItem.Parent) Then
			
			FoundRows = MappingTable.FindRows(New Structure("Code, Processed", InvoiceData.GroupCode, False));
			If FoundRows.Count() > 0 Then
				
				Try
					
					NewItem.Parent = CreateAccount(FoundRows[0], MappingTable, ReportParameters, VTElementsToUpdate, ChartOfAccounts);
					
				Except
					
					FoundRows[0].Processed = True;
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể ghi lại lớp trên có mã %1';
																								|ru = 'Не удалось записать родителя с кодом %1';
																								|en = 'Cannot save the parent with code %1'; fa = 'Cannot save the parent with code %1';
																								|it = 'Non è stato possibile salvare il genitore con il codice %1';
																								|pl = 'Nie udało się zapisać rodzica i elementu %1';
																								|tr = '%1 koda sahip ebeveyn kaydedilemedi'"), InvoiceData.GroupCode);
					FindAndCancelProcessingOfSubordinateObjects(MappingTable, ReportParameters, FoundRows[0], ErrorText);
					
					Raise ErrorText;
					
				EndTry;
				
			Else
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể ghi lại lớp trên có mã %1';
																							|ru = 'Не удалось записать родителя с кодом %1';
																							|en = 'Cannot save the parent with code %1'; fa = 'Cannot save the parent with code %1';
																							|it = 'Non è stato possibile salvare il genitore con il codice %1';
																							|pl = 'Nie udało się zapisać rodzica i elementu %1';
																							|tr = '%1 koda sahip ebeveyn kaydedilemedi'"), InvoiceData.GroupCode);
				Raise ErrorText;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NewItem.Code = InvoiceData.Code;
	NewItem.Currency1 = InvoiceData.Currency1;
	
	NewItem.Description = InvoiceData.Description;
	NewItem.Order = InvoiceData.Order;
	NewItem.AccountingByBusinessUnits = InvoiceData.AccountingByBusinessUnits;
	NewItem.AccountingByLinesOfBusiness = InvoiceData.AccountingByLinesOfBusiness;
	NewItem.OffBalance = InvoiceData.OffBalance;
	NewItem.DescriptionInternational = InvoiceData.DescriptionInternational;
	NewItem.RestrictUseInPostings = InvoiceData.RestrictUseInPostings;
	NewItem.LongDesc = InvoiceData.LongDesc;
	NewItem.Currency1 = InvoiceData.Currency1;
	NewItem.Quantitative = InvoiceData.Quantitative;
	NewItem.Type = InvoiceData.Kind;
	NewItem.ChartOfAccounts = ChartOfAccounts;
	
	If ValueIsFilled(InvoiceData.ExtDimension1) Then
		
		FindAndAddExtDimensionByName(NewItem, InvoiceData.ExtDimension1, InvoiceData.ExtDimension1RevolutionsOnly);
		
	EndIf;
	
	If ValueIsFilled(InvoiceData.ExtDimension2) Then
		
		FindAndAddExtDimensionByName(NewItem, InvoiceData.ExtDimension2, InvoiceData.ExtDimension2RevolutionsOnly);
		
	EndIf;
	
	If ValueIsFilled(InvoiceData.ExtDimension3) Then
		
		FindAndAddExtDimensionByName(NewItem, InvoiceData.ExtDimension3, InvoiceData.ExtDimension3RevolutionsOnly);
		
	EndIf;
	
	If ValueIsFilled(NewItem.Ref) Then
		
		Block = New DataLock;
		LockItem = Block.Add("ChartOfAccounts.International");
		LockItem.SetValue("Ref", NewItem.Ref);
		Block.Lock();
		
	EndIf;
	
	NewItem.Write();
	
	FoundItems1 = VTElementsToUpdate.FindRows(New Structure("Code", NewItem.Code));
	If FoundItems1.Count() = 0 Then
		
		NewRow = VTElementsToUpdate.Add();
		NewRow.Code = NewItem.Code;
		NewRow.Account = NewItem.Ref;
		
	EndIf;
	
	OblString = ReportParameters.OblString; // SpreadsheetDocument
	OblString.Parameters.Fill(InvoiceData);
	OblString.Parameters.Account = NewItem.Ref;
	
	If IsNew Then
		
		TabDocCreated = ReportParameters.TableCreated; // SpreadsheetDocument
		TabDocCreated.Put(OblString); 
		ReportParameters.TotalCreated = ReportParameters.TotalCreated + 1;
		
	Else
		
		TabDocUpdated = ReportParameters.Table_Updated; // SpreadsheetDocument
		TabDocUpdated.Put(OblString);
		ReportParameters.TotalUpdated = ReportParameters.TotalUpdated + 1;
		
	EndIf;
	
	InvoiceData.Processed = True;
	
	Return NewItem.Ref;
	
EndFunction

Procedure FindAndCancelProcessingOfSubordinateObjects(MappingTable, ReportParameters, InvoiceData, ErrorText)
	
	OblLineSkipped = ReportParameters.OblLineSkipped; // SpreadsheetDocument
	SubordinateRows = MappingTable.FindRows(New Structure("GroupCode", InvoiceData.Code));
	For Each SubordinateRow In SubordinateRows Do
		
		If Not SubordinateRow.Processed Then
			
			OblLineSkipped.Parameters.Fill(SubordinateRow);
			OblLineSkipped.Parameters.ErrorDescription = ErrorText;
			
			TabDocSkipped = ReportParameters.TableSkipped; // SpreadsheetDocument
			TabDocSkipped.Put(OblLineSkipped);
			TabDocSkipped.Areas.String.Protection = False;
			
			ReportParameters.TotalSkipped = ReportParameters.TotalSkipped + 1;
			SubordinateRow.Processed = True;
			
		EndIf;
		
		SubordinateLinesOfSubordinateLine = MappingTable.FindRows(New Structure("GroupCode", InvoiceData.Code));
		For Each SubordinateLineOfSubordinateLine In SubordinateLinesOfSubordinateLine Do
			
			If InvoiceData.Code = SubordinateLineOfSubordinateLine.GroupCode Then
				
				Continue;
				
			EndIf;
			
			FindAndCancelProcessingOfSubordinateObjects(MappingTable, ReportParameters, SubordinateLineOfSubordinateLine, ErrorText);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FindAndAddExtDimensionByName(NewItem, CCTName, ExtDimensionIsOnlyRevolutions)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FinancialExtraDimensionTypes.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.FinancialExtraDimensionTypes AS FinancialExtraDimensionTypes
	|WHERE
	|	FinancialExtraDimensionTypes.Description = &Description";
	
	Query.SetParameter("Description", CCTName);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		CCT = Selection.Ref;
		
	ElsIf Not Metadata.ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.GetPredefinedNames().Find(CCTName) = Undefined Then
		
		CCT = ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes[CCTName];
		
	Else
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể xác định khoản mục theo tên: ""%1""';
																					|ru = 'Не удалось определить субконто по имени: ""%1""';
																					|en = 'Cannot identify the extra dimension by the name: ""%1""'; fa = 'Cannot identify the extra dimension by the name: ""%1""';
																					|it = 'Non è stato possibile determinare il subconto con il nome: ""%1""';
																					|pl = 'Nie udało się określić subkonto według nazwy: ""%1""';
																					|tr = 'Bu isme sahip ekstra boyut tespit edilemedi: ""%1""'"), CCTName);
		Raise ErrorText;
		
	EndIf;
	
	FoundStringsOfExtDimensionTypes = NewItem.ExtDimensionTypes.FindRows(New Structure("ExtDimensionType", CCT));
	If FoundStringsOfExtDimensionTypes.Count() = 0 Then
		
		StringExtdimension = NewItem.ExtDimensionTypes.Add();
		StringExtdimension.ExtDimensionType = CCT;
		StringExtdimension.TurnoversOnly = ExtDimensionIsOnlyRevolutions;
		
	EndIf;
	
EndProcedure

Function CheckHeaderOfUploadFile(ImportedTemplateWithData, UploadFromFile)
	
	StructureColumnNamesOfTemplate = GetRelationshipBetweenAttributesAndTemplateHeaders();
	
	ErrorsArray = New Array;
	MatchingColumnNumberInFileAndAttributeName = New Map;
	
	For ColumnNumber = ?(UploadFromFile, 1, 2) To ImportedTemplateWithData.TableWidth Do
		
		ColumnHeaderFound = False;
		
		Text = TrimAll(ImportedTemplateWithData.GetArea(1, ColumnNumber, 1, ColumnNumber).CurrentArea.Text);
		If ValueIsFilled(Text) Then
			
			For Each KeyAndValue In StructureColumnNamesOfTemplate Do
				
				For Each ArrayElement In KeyAndValue.Value Do
					
					If ArrayElement = Text Then
						
						MatchingColumnNumberInFileAndAttributeName.Insert(ColumnNumber, KeyAndValue.Key);
						StructureColumnNamesOfTemplate.Delete(KeyAndValue.Key);
						ColumnHeaderFound = True;
						
						If KeyAndValue.Key = "Code" Then
							
							MatchingColumnNumberInFileAndAttributeName.Insert("NumberOfColumnWithCode", ColumnNumber);
							
						EndIf;
						
						Break;
						
					EndIf;
					
				EndDo; 
				
				If ColumnHeaderFound Then
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not ColumnHeaderFound Then
				
				ErrorText = NStr("vi = 'Không thể xác định trường trong cột số%1 - ""%2""';
								|ru = 'Не определено поле в колонке №%1 - ""%2""';
								|en = 'In column #%1, field is not determined - ""%2""'; fa = 'In column #%1, field is not determined - ""%2""';
								|it = 'Campo non determinato nella colonna N°%1 - ""%2""';
								|pl = 'Nie określono pola w kolumnie nr%1 - ""%2""';
								|tr = '№%1 - ""%2"" sütunda alan tespit edilemedi'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, ColumnNumber, Text);
				ErrorsArray.Add(ErrorText);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ErrorsArray.Count() > 0
		Or StructureColumnNamesOfTemplate.Count() > 0 Then
		
		For Each KeyAndValue In StructureColumnNamesOfTemplate Do
			
			ErrorText = NStr("vi = 'Không thể tìm thấy cột đối với mục tin ""%1""';
							|ru = 'Не найдена колонка для реквизита ""%1""';
							|en = 'Column for the ""%1"" attribute is not found'; fa = 'Column for the ""%1"" attribute is not found';
							|it = 'Non trovata la colonna per il requisito ""%1""';
							|pl = 'Nie znaleziono kolumny dla atrybutu ""%1""';
							|tr = '""%1"" öznitelik için sütun bulunamadı'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, KeyAndValue.Value[0]);
			ErrorsArray.Add(ErrorText);
			
		EndDo;
		
		Raise StrConcat(ErrorsArray, Chars.LF);
		
	EndIf;
	
	Return MatchingColumnNumberInFileAndAttributeName; 
	
EndFunction

Function GetRelationshipBetweenAttributesAndTemplateHeaders()
	
	MatchingColumnNumbersToAttributes = New Map;
	MatchingColumnNumbersToAttributes.Insert(1, "GroupCode");
	MatchingColumnNumbersToAttributes.Insert(2, "Code");
	MatchingColumnNumbersToAttributes.Insert(3, "Order");
	MatchingColumnNumbersToAttributes.Insert(4, "Description");
	MatchingColumnNumbersToAttributes.Insert(5, "DescriptionInternational");
	MatchingColumnNumbersToAttributes.Insert(6, "Kind");
	MatchingColumnNumbersToAttributes.Insert(7, "Currency1");
	MatchingColumnNumbersToAttributes.Insert(8, "Quantitative");
	MatchingColumnNumbersToAttributes.Insert(9, "AccountingByBusinessUnits");
	MatchingColumnNumbersToAttributes.Insert(10, "AccountingByLinesOfBusiness");
	MatchingColumnNumbersToAttributes.Insert(11, "OffBalance");
	MatchingColumnNumbersToAttributes.Insert(12, "ExtDimension1");
	MatchingColumnNumbersToAttributes.Insert(13, "ExtDimension1RevolutionsOnly");
	MatchingColumnNumbersToAttributes.Insert(14, "ExtDimension2");
	MatchingColumnNumbersToAttributes.Insert(15, "ExtDimension2RevolutionsOnly");
	MatchingColumnNumbersToAttributes.Insert(16, "ExtDimension3");
	MatchingColumnNumbersToAttributes.Insert(17, "ExtDimension3RevolutionsOnly");
	MatchingColumnNumbersToAttributes.Insert(18, "RestrictUseInPostings");
	MatchingColumnNumbersToAttributes.Insert(19, "LongDesc");
	
	ArrayOfLanguageCodes = New Array;
	For Each ConfigurationLanguage In Metadata.Languages Do
		
		ArrayOfLanguageCodes.Add(ConfigurationLanguage.LanguageCode);
	
	EndDo;
	
	StructureColumnNamesOfTemplate = New Structure();
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.ChartOfAccountsExportImportWizard.Template");
	RegionHeader = Template.GetArea("Header|Data");
	
	For ColumnNumber = 1 To RegionHeader.TableWidth Do
		
		AttributeName = MatchingColumnNumbersToAttributes[ColumnNumber];
		StructureColumnNamesOfTemplate.Insert(AttributeName, New Array);
		
		For Each LanguageCode In ArrayOfLanguageCodes Do
			
			TabDoc = RegionHeader.GetArea(1, ColumnNumber, 1, ColumnNumber);
			TabDoc.LanguageCode = LanguageCode;
			
			Text = TrimAll(TabDoc.CurrentArea.Text);
			If ValueIsFilled(Text) Then 
				
				StructureColumnNamesOfTemplate[AttributeName].Add(Text);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return StructureColumnNamesOfTemplate;
	
EndFunction

#EndRegion

#EndIf