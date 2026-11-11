#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "AccountingStatement") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"AccountingStatement",
			NStr("vi = 'Chứng chỉ kế toán (kế toán quốc tế)';
				|ru = 'Бухгалтерская справка (международный учет)';
				|en = 'Accounting statement (financial accounting)'; fa = 'Accounting statement (financial accounting)';
				|it = 'Бухгалтерская справка (международный учет)';
				|pl = 'Accounting statement (financial accounting)';
				|tr = 'Muhasebe belgesi (uluslararası muhasebe)'"),
			PrintAccountingStatement(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
EndProcedure

Function PrintAccountingStatement(ObjectsArray, PrintObjects, PrintParameters) Export
	
	SetPrivilegedMode(True);
	
	TabDocument = New SpreadsheetDocument;
	// Setting the default Template parameters
	TabDocument.HeaderSize = 0;
	TabDocument.FooterSize  = 0;
	TabDocument.FitToPage             = True;
	TabDocument.PageOrientation      = PageOrientation.Landscape;
	TabDocument.PrintParametersKey     = "PRINT_OPTIONS_TransactionFinancialAccounting_AccountingStatement";
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = "
	|SELECT
	|	InternationalRegisteredRecordsWithExtDimension.Period,
	|	InternationalRegisteredRecordsWithExtDimension.LineNumber,
	|	InternationalRegisteredRecordsWithExtDimension.Organization,
	|	InternationalRegisteredRecordsWithExtDimension.ChartOfAccounts,
	|	InternationalRegisteredRecordsWithExtDimension.AccountDr,
	|	InternationalRegisteredRecordsWithExtDimension.DepartmentDr,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimensionDr1,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimensionDr2,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimensionDr3,
	|	InternationalRegisteredRecordsWithExtDimension.AccountCr,
	|	InternationalRegisteredRecordsWithExtDimension.DepartmentCr,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimensionCr1,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimensionCr2,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimensionCr3,
	|	InternationalRegisteredRecordsWithExtDimension.CurrencyDr,
	|	InternationalRegisteredRecordsWithExtDimension.CurrencyCr,
	|	InternationalRegisteredRecordsWithExtDimension.Sum,
	|	InternationalRegisteredRecordsWithExtDimension.CurrencyAmountDr,
	|	InternationalRegisteredRecordsWithExtDimension.CurrencyAmountCr,
	|	InternationalRegisteredRecordsWithExtDimension.CountDr,
	|	InternationalRegisteredRecordsWithExtDimension.CountCr,
	|	InternationalRegisteredRecordsWithExtDimension.Content,
	|	InternationalRegisteredRecordsWithExtDimension.Recorder
	|INTO TTInternationalWithCorrespondence
	|FROM
	|	AccountingRegister.International.RecordsWithExtDimensions(, , Recorder IN (&ObjectsArray), , ) AS InternationalRegisteredRecordsWithExtDimension
	|
	|INDEX BY
	|	InternationalRegisteredRecordsWithExtDimension.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternationalRegisteredRecordsWithExtDimension.Period,
	|	InternationalRegisteredRecordsWithExtDimension.RecordType,
	|	InternationalRegisteredRecordsWithExtDimension.LineNumber,
	|	InternationalRegisteredRecordsWithExtDimension.Organization,
	|	InternationalRegisteredRecordsWithExtDimension.ChartOfAccounts,
	|	InternationalRegisteredRecordsWithExtDimension.Account,
	|	InternationalRegisteredRecordsWithExtDimension.Department,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimension1,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimension2,
	|	InternationalRegisteredRecordsWithExtDimension.ExtDimension3,
	|	InternationalRegisteredRecordsWithExtDimension.Currency,
	|	InternationalRegisteredRecordsWithExtDimension.Sum,
	|	InternationalRegisteredRecordsWithExtDimension.CurrencyAmount,
	|	InternationalRegisteredRecordsWithExtDimension.Count,
	|	InternationalRegisteredRecordsWithExtDimension.Content,
	|	InternationalRegisteredRecordsWithExtDimension.Recorder
	|INTO TTInternationalWithoutCorrespondence
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.RecordsWithExtDimensions(, , Recorder IN (&ObjectsArray), , ) AS InternationalRegisteredRecordsWithExtDimension
	|
	|INDEX BY
	|	InternationalRegisteredRecordsWithExtDimension.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Date AS Date,
	|	&TransactionContent AS TransactionContent,
	|	International.Period AS Period,
	|	International.LineNumber AS LineNumber,
	|	International.Organization AS Organization,
	|	International.ChartOfAccounts AS ChartOfAccounts,
	|	International.ChartOfAccounts.AccountingInFunctionalCurrency AS AccountingInFunctionalCurrency,
	|	International.ChartOfAccounts.OptionForGeneratingTransactions AS OptionForGeneratingTransactions,
	|	International.Account AS Account,
	|	International.Account.Code AS AccountCode,
	|	International.Department AS Department,
	|	International.ExtDimension1 AS ExtDimension1,
	|	International.ExtDimension2 AS ExtDimension2,
	|	International.ExtDimension3 AS ExtDimension3,
	|	International.Currency AS Currency,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.Sum
	|		ELSE 0
	|	END AS SumDr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN 0
	|		ELSE International.Sum
	|	END AS SumCr,
	|	International.CurrencyAmount AS CurrencyAmount,
	|	International.Count AS Count,
	|	International.Content AS Content
	|FROM
	|	&DocumentType AS DocumentData
	|	INNER JOIN TTInternationalWithoutCorrespondence AS International
	|		ON DocumentData.Ref = International.Recorder
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	DocumentData.Date,
	|	DocumentData.Ref,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Date AS Date,
	|	&TransactionContent AS TransactionContent,
	|	International.Period AS Period,
	|	ISNULL(International.LineNumber, 1) AS LineNumber,
	|	International.Organization AS Organization,
	|	International.ChartOfAccounts AS ChartOfAccounts,
	|	International.ChartOfAccounts.AccountingInFunctionalCurrency AS AccountingInFunctionalCurrency,
	|	International.ChartOfAccounts.OptionForGeneratingTransactions AS OptionForGeneratingTransactions,
	|	International.AccountDr AS AccountDr,
	|	International.AccountDr.Code AS AccountCodeDr,
	|	International.DepartmentDr AS DepartmentDr,
	|	International.ExtDimensionDr1 AS ExtDimensionDr1,
	|	International.ExtDimensionDr2 AS ExtDimensionDr2,
	|	International.ExtDimensionDr3 AS ExtDimensionDr3,
	|	International.AccountCr AS AccountCr,
	|	International.AccountCr.Code AS AccountCodeCr,
	|	International.DepartmentCr AS DepartmentCr,
	|	International.ExtDimensionCr1 AS ExtDimensionCr1,
	|	International.ExtDimensionCr2 AS ExtDimensionCr2,
	|	International.ExtDimensionCr3 AS ExtDimensionCr3,
	|	International.CurrencyDr AS CurrencyDr,
	|	International.CurrencyCr AS CurrencyCr,
	|	International.Sum AS Sum,
	|	International.CurrencyAmountDr AS CurrencyAmountDr,
	|	International.CurrencyAmountCr AS CurrencyAmountCr,
	|	International.CountDr AS CountDr,
	|	International.CountCr AS CountCr,
	|	International.Content AS Content
	|FROM
	|	&DocumentType AS DocumentData
	|		LEFT JOIN TTInternationalWithCorrespondence AS International
	|		ON DocumentData.Ref = International.Recorder
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTInternationalWithoutCorrespondence AS International
	|		WHERE
	|			International.Recorder = DocumentData.Ref
	|		)
	|ORDER BY
	|	DocumentData.Date,
	|	DocumentData.Ref,
	|	LineNumber
	|";
	
	MetadataObject = Metadata.Documents.Find(PrintParameters.DocumentType);
	
	If MetadataObject.Attributes.Find("EmployeeResponsible") <> Undefined Then
		ResponsiblePersonSAttributes = "DocumentData.EmployeeResponsible";
	ElsIf MetadataObject.Attributes.Find("Author") <> Undefined Then
		ResponsiblePersonSAttributes = "DocumentData.Author";
	Else
		ResponsiblePersonSAttributes = """""";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&DocumentType", MetadataObject.FullName());
	Query.Text = StrReplace(Query.Text, "&EmployeeResponsible", ResponsiblePersonSAttributes);
	Query.Text = StrReplace(Query.Text, "&TransactionContent", "DocumentData." + PrintParameters.FieldContentOfOperation);
	
	Results = Query.ExecuteBatch();
	NumberOfResults = Results.Count();
	
	FirstDocument = True;
	
	For Number_Of_Result = 1 To 2 Do
		
		ReverseIndex = NumberOfResults - Number_Of_Result;
		Result = Results[ReverseIndex];
		
		If Result.IsEmpty() Then
			Continue;
		EndIf;
		
		Selection = Result.Select();
		While Selection.NextByFieldValue("Ref") Do
			
			While Selection.NextByFieldValue("Organization") Do
				
				While Selection.NextByFieldValue("ChartOfAccounts") Do
					
					If Not FirstDocument Then
						TabDocument.PutHorizontalPageBreak();
					EndIf;
					
					FirstDocument = False;
					
					// Let's remember the line number from which we started to output the Cur document.
					RowNumberStart = TabDocument.TableHeight + 1;
					
					// Setting the default Template parameters
					TabDocument.HeaderSize = 0;
					TabDocument.FooterSize  = 0;
					TabDocument.FitToPage             = True;
					TabDocument.PageOrientation      = PageOrientation.Landscape;
					
					GenerateAccountingCertificate(PrintParameters, TabDocument, Selection);
					
					// In the table document, we will set the name of the area in which 
					// the object was displayed. It is necessary for the possibility of printing individually.
					PrintManagement.SetDocumentPrintArea(TabDocument,
						RowNumberStart, PrintObjects, Selection.Ref);
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return TabDocument;
	
EndFunction

Procedure GenerateAccountingCertificate(PrintParameters, TabDocument, Selection)
	
	HasCorrespondence = Selection.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence;
	
	If HasCorrespondence Then
		Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintAccountingStatementFinancialAccounting.PF_MXL_AccountingStatementWithCorrespondence");
	Else
		Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintAccountingStatementFinancialAccounting.PF_MXL_AccountingStatementWithoutCorrespondence");
	EndIf;
	
	If Selection.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		FunctionalCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization);
	Else
		FunctionalCurrency = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
	
	// We get the Template areas for output to a tabular document.
	DocumentHeader   = Template.GetArea("Header");
	TableHeading = Template.GetArea("TableHeading");
	TableRow    = Template.GetArea("TableRow");
	TableFooter    = Template.GetArea("TableFooter");
	DocumentBasement  = Template.GetArea("Footer");
	
	// Display the document header.
	CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(Selection.Organization, Selection.Date);
	
	HeaderStructure_ = New Structure();
	HeaderStructure_.Insert("Organization",    PrintFormGeneration.OrganizationDescription(CompanyInformation));
	HeaderStructure_.Insert("DocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number, True, True));
	HeaderStructure_.Insert("DocumentDate",  Format(Selection.Date, "DLF=D"));
	HeaderStructure_.Insert("Content",     Selection.TransactionContent);
	
	DocumentHeader.Parameters.Fill(HeaderStructure_);
	TabDocument.Put(DocumentHeader);
	
	// Let's display the table header.
	TitleStructure = New Structure();
	TitleStructure.Insert("FunctionalCurrency", FunctionalCurrency);
	
	TableHeading.Parameters.Fill(TitleStructure);
	TabDocument.Put(TableHeading);
	
	// Print the lines of the document.
	While Selection.Next() Do
		
		TableRow.Parameters.Fill(Selection);
		
		StructureOfAnalytics = New Structure();
		StructureOfAnalytics.Insert("Date", Format(Selection.Period, "DLF=D;"));
		
		If HasCorrespondence Then
			StructureOfAnalytics.Insert("DimensionDr", DimensionPostings(Selection, "Dr"));
			StructureOfAnalytics.Insert("DimensionCr", DimensionPostings(Selection, "Cr"));
		Else
			StructureOfAnalytics.Insert("Dimension", DimensionPostings(Selection, ""));
		EndIf;
		
		TableRow.Parameters.Fill(StructureOfAnalytics);
		
		// Let's check if the row with the basement fits.
		RowWithBasement = New Array;
		RowWithBasement.Add(TableRow);
		RowWithBasement.Add(TableFooter);
		RowWithBasement.Add(DocumentBasement);
		
		If Not Common.SpreadsheetDocumentFitsPage(TabDocument, RowWithBasement) Then
			
			// Let's display the basement of the table.
			TabDocument.Put(TableFooter);
				
			// Display the page break.
			TabDocument.PutHorizontalPageBreak();

			// Let's display the table header.
			TabDocument.Put(TableHeading);
			
		EndIf;
		
		TabDocument.Put(TableRow);
		
	EndDo;
	
	// Let's display the basement of the table.
	TabDocument.Put(TableFooter);
	
	// We will display the document basement.
	
	TabDocument.Put(DocumentBasement);
	
EndProcedure

Function DimensionPostings(Selection, DrCr)
	
	Dimension = New Array();
	
	If ValueIsFilled(Selection["Department" + DrCr]) Then
		Dimension.Add(Selection["Department" + DrCr]);
	EndIf;
	
	For ExtDimensionNumber = 1 To 3 Do
		If ValueIsFilled(Selection["ExtDimension" + DrCr + ExtDimensionNumber]) Then
			Dimension.Add(Selection["ExtDimension" + DrCr + ExtDimensionNumber]);
		EndIf;
	EndDo;
	
	Return StrConcat(Dimension, Chars.LF);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
