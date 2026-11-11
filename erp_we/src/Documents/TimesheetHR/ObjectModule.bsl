#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	// Skip the processing to ensure that the shape of the object is received when passing the "AutoTest" parameter.
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;

	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;

	EmployeeResponsible = Users.CurrentUser();

	If Not TypeOf(FillingData) = Type("Structure") Then
		FillInDefaultData();
	EndIf;

	TimesheetHRLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	If DataExchange.Load Then
		Return;
	EndIf;

	If WriteMode = DocumentWriteMode.Posting Then
		If DataOnTime.Count() = 0 Then
			Cancel = True;
			MessageText = NStr("ru = 'Не заполнена табличная часть ""Расписание"".';
								|vi = 'The ""Schedule"" table is not filled in.';
								|en = 'The ""Schedule"" table is not filled in.'; fa = 'The ""Schedule"" table is not filled in.';
								|it = 'The ""Schedule"" table is not filled in.';
								|pl = 'The ""Schedule"" table is not filled in.';
								|tr = '""Program"" tablo kısmı doldurulmamış.'");
			Common.MessageToUser(MessageText, , , , Cancel);
			Return;
		EndIf;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);	
	
	If WriteMode = DocumentWriteMode.UndoPosting
		And DocumentsPayrollAndHumanResourcesServer.DocumentDataIsUsedToCalculateBlockedPOData(Ref, False) Then
		
		DocumentsPayrollAndHumanResourcesServer.ReportErrorsCancellationOfEvent(Ref, Cancel);	
		
	ElsIf  WriteMode = DocumentWriteMode.Posting Then
		
		ListOfEmployees = DocumentsPayrollAndHumanResourcesServer.PayrollBlocked(Organization, 
													BegOfMonth(BeginningDateOfPeriod), DataOnTime.Unload(,"Employee"));	
		
		If ListOfEmployees.Count() > 0 Then
			DocumentsPayrollAndHumanResourcesServer.ReportAboutPostErrors(Ref, BeginningDateOfPeriod, ListOfEmployees, Cancel);	  
		EndIf;	
	EndIf;	

EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);

	TimesheetHRLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure OnCopy(CopiedObject)

	EmployeeResponsible = Users.CurrentUser();
	TimesheetHRLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Posting(Cancel, PostingMode)

	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);

EndProcedure

Procedure UndoPosting(Cancel)

	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);

EndProcedure

#EndRegion

#Region Private

Procedure FillInDefaultData()

	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	DocumentRef.Organization AS Organization,
	|	CASE
	|		WHEN BusinessStructure.DeletionMark
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE DocumentRef.Department
	|	END AS Department,
	|	DocumentRef.InputOption AS InputOption,
	|	DocumentRef.Approved_1 AS Approved_1
	|FROM
	|	Document.TimesheetHR AS DocumentRef
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON DocumentRef.Department = BusinessStructure.Ref
	|WHERE
	|	DocumentRef.EmployeeResponsible = &EmployeeResponsible
	|	AND DocumentRef.Posted
	|
	|ORDER BY
	|	DocumentRef.Date DESC");
	
	Query.SetParameter("EmployeeResponsible", EmployeeResponsible);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	Else
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		Department = SettingsValueCached.UserDivision(EmployeeResponsible);
	EndIf;
	BeginningDateOfPeriod = BegOfMonth(Common.CurrentUserDate(EmployeeResponsible));
	EndingDateOfPeriod = EndOfMonth(BeginningDateOfPeriod);
	
EndProcedure

#EndRegion

#EndIf