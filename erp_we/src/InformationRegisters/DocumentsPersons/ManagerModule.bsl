#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function returns an identity document that is valid on the specified date.
//
// Parameters:
//	Person			- CatalogRef.Counterparties, CatalogRef.Persons - the individual for whom you need to get the document.
//	Date			- Date - the date on which the document should be received.
//
// Returns:
//		String - submission of an identity document.
//
Function PersonalIdentityDocument(Person, Date = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("Person",	Person);
	Query.SetParameter("SliceDate",	Date);
	
	QueryText =
	"SELECT TOP 1
	|	DocumentsPersons.Presentation
	|FROM
	|	InformationRegister.DocumentsPersons AS DocumentsPersons
	|		INNER JOIN (SELECT
	|			MAX(DocumentsPersons.Period) AS Period,
	|			DocumentsPersons.Person AS Person
	|		FROM
	|			InformationRegister.DocumentsPersons AS DocumentsPersons
	|		WHERE
	|			DocumentsPersons.ThisIsAnIdentityDocument
	|			AND DocumentsPersons.Person = &Person
	|			AND DocumentsPersons.Period <= &SliceDate
	|		
	|		GROUP BY
	|			DocumentsPersons.Person) AS DocumentsSlice
	|		ON DocumentsPersons.Period = DocumentsSlice.Period
	|			AND DocumentsPersons.Person = DocumentsSlice.Person
	|			AND (DocumentsPersons.ThisIsAnIdentityDocument)";
	
	If Not ValueIsFilled(Date) Then
		QueryText = StrReplace(QueryText, "AND DocumentsPersons.Period <= &SliceDate", "");
	EndIf;
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Presentation;
	EndIf;
	
	Return "";
	
EndFunction

// The function checks whether the specified type of document is an identity document for this individual.
//
// Parameters:
//	Person			- CatalogRef.Counterparties, CatalogRef.Persons - the individual for whom you need to get the document.
//	DocumentKind	- CatalogRef.DocumentKindsOfPersons - type of identity document.
//	Date			- Date - the date on which the document should be received.
//
// Returns:
//		Boolean - whether the specified type of document is an identity document.
//
Function IsIdentityCard(Person, DocumentKind, Date) Export
	
	If Not ValueIsFilled(Person) Or DocumentKind.IsEmpty() Or Not ValueIsFilled(Date) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Person",		Person);
	Query.SetParameter("DocumentKind",	DocumentKind);
	Query.SetParameter("SliceDate",		Date);
	
	Query.Text =
	"SELECT
	|	DocumentsPersons.DocumentKind
	|FROM
	|	InformationRegister.DocumentsPersons AS DocumentsPersons
	|		INNER JOIN (SELECT
	|			MAX(DocumentsPersons.Period) AS Period,
	|			DocumentsPersons.Person AS Person
	|		FROM
	|			InformationRegister.DocumentsPersons AS DocumentsPersons
	|		WHERE
	|			DocumentsPersons.Person = &Person
	|			AND DocumentsPersons.Period < &SliceDate
	|			AND DocumentsPersons.ThisIsAnIdentityDocument
	|		
	|		GROUP BY
	|			DocumentsPersons.Person) AS DocumentsSlice
	|		ON DocumentsPersons.Person = DocumentsSlice.Person
	|			AND DocumentsPersons.Period = DocumentsSlice.Period
	|			AND (DocumentsPersons.DocumentKind = &DocumentKind)";
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Person ONLY Catalog.Persons)
	|	OR ValueAllowed(CAST(Person AS Catalog.Counterparties).Partner)";
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Function RecordPresentation(Record) Export
	
	If Record.DocumentKind.IsEmpty() Then
		Presentation = "";
	Else
		
		TextSeries				= NStr("vi = ', sê-ri: %1';
										|ru = ', серия: %1';
										|en = ', batch: %1'; fa = ', batch: %1';
										|it = ', serie: %1';
										|pl = ', seria: %1';
										|tr = ', parti: %1'");
		TextNumber				= NStr("vi = ', số %1';
										|ru = ', № %1';
										|en = ', No.%1'; fa = ', No.%1';
										|it = ', № %1';
										|pl = ', nr %1';
										|tr = ', № %1'");
		TextDateOfIssue			= NStr("vi = ', đã cấp: %1';
											|ru = ', выдан: %1';
											|en = ', issued: %1'; fa = ', issued: %1';
											|it = ', rilasciato: %1';
											|pl = ', wydany: %1';
											|tr = ', verildi: %1'");
		TextExpirationDate		= NStr("vi = ', có hiệu lực đến: %1';
										|ru = ', действует до: %1';
										|en = ', valid until: %1'; fa = ', valid until: %1';
										|it = ', scadenza: %1';
										|pl = ', ważny do: %1';
										|tr = ', kadar geçerlidir: %1'");
		TextDivisionCode	= NStr("vi = ', mã bộ phận %1';
									|ru = ', код подр. %1';
									|en = ', business unit code %1'; fa = ', business unit code %1';
									|it = ', codice reparto %1';
									|pl = ', kod dz. %1';
									|tr = ', alt bölüm kodu. %1'");
		
		Presentation = ""
			+ Record.DocumentKind
			+ ?(ValueIsFilled(Record.Series), StringFunctionsClientServer.SubstituteParametersToString(TextSeries, Record.Series), "")
			+ ?(ValueIsFilled(Record.Number), StringFunctionsClientServer.SubstituteParametersToString(TextNumber, Record.Number), "")
			+ ?(ValueIsFilled(Record.DateOfIssue1), StringFunctionsClientServer.SubstituteParametersToString(TextDateOfIssue, Format(Record.DateOfIssue1, NStr("vi = 'ДФ=''дд ММММ ""năm"" гггг''';
																																								|ru = 'ДФ=''дд ММММ гггг ""года""''';
																																								|en = 'DF=''MMMM dd yyyy'''; fa = 'DF=''MMMM dd yyyy''';
																																								|it = 'ДФ=''дд ММММ гггг ""a.""''';
																																								|pl = 'DF=''dd ММММ yyyy ""roku""''';
																																								|tr = 'DF=''dd MMMM yyyy ""yıl""'''"))), "")
			+ ?(ValueIsFilled(Record.ValidityPeriod), StringFunctionsClientServer.SubstituteParametersToString(TextExpirationDate, Format(Record.ValidityPeriod, NStr("vi = 'ДФ=''дд ММММ ""năm"" гггг''';
																																										|ru = 'ДФ=''дд ММММ гггг ""года""''';
																																										|en = 'DF=''MMMM dd yyyy'''; fa = 'DF=''MMMM dd yyyy''';
																																										|it = 'ДФ=''дд ММММ гггг ""a.""''';
																																										|pl = 'DF=''dd ММММ yyyy ""roku""''';
																																										|tr = 'DF=''dd MMMM yyyy ""yıl""'''"))), "")
			+ ?(ValueIsFilled(Record.IssuedBy), ", " + Record.IssuedBy, "");
			
		
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion

#EndIf