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
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	Else
		FillInDefaultData();
	EndIf;

	PayrollStatementHRLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		If Content.Count()=0 Then
			Cancel = True;
			MessageText = NStr("ru = 'Не заполнена табличная часть ""Состав"".';
								|vi = 'The ""Content"" table is not filled in.';
								|en = 'The ""Content"" table is not filled in.'; fa = 'The ""Content"" table is not filled in.';
								|it = 'The ""Content"" table is not filled in.';
								|pl = 'The ""Content"" table is not filled in.';
								|tr = '""İçerik"" tablo kısmı doldurulmamış.'");
			Common.MessageToUser(MessageText, , , , Cancel);
			Return;
		EndIf;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SumByDocument = Content.Total("ToBePaid");
	
	FillInShortCompositionOfDocument();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PayrollStatementHRLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	PayrollStatementHRLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	UseApplications = GetFunctionalOption("UsePaymentRequests");

	If Not UseApplications Then
		AttributeToCheck = CheckedAttributes.Find("Department");
		If Not AttributeToCheck = Undefined Then
			CheckedAttributes.Delete(AttributeToCheck);
		EndIf;
	ElsIf Not ValueIsFilled(Department) Then
		ErrorText = NStr(
			"ru = 'Включено использование заявок на расходование денежных средств. Поле ""Подразделение"" обязательно для заполнения.';
			|vi = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|en = 'Payment requests are enabled. The ""Business unit"" field is required.'; fa = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|it = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|pl = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|tr = 'Nakit harcama talepleri kullanımı etkinleştirildi. ""Departman"" alanının doldurulması zorunludur.'");
		Common.MessageToUser(ErrorText, ThisObject, "Department", , Cancel);
	EndIf;

EndProcedure

#EndRegion

#Region Private

Procedure FillInShortCompositionOfDocument()
	
	Individuals = Content.UnloadColumn("Individual");
	BriefDocumentComposition = SalaryAndPersonnel.ShortListOfIndividuals(Individuals, Date);
	
EndProcedure

// The procedure fills in the main Attributes with default values.
//
Procedure FillInDefaultData()
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	PayrollStatementHR.Organization AS Organization,
	|	CASE
	|		WHEN BusinessStructure.DeletionMark
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE PayrollStatementHR.Department
	|	END AS Department,
	|	PayrollStatementHR.PaymentMethodHR AS PaymentMethodHR,
	|	PayrollStatementHR.KindOfPayment AS KindOfPayment,
	|	PayrollStatementHR.Bank AS Bank,
	|	PayrollStatementHR.Currency AS Currency,
	|	PayrollStatementHR.Director AS Director,
	|	PayrollStatementHR.JobTitleExecutive AS JobTitleExecutive
	|FROM
	|	Document.PayrollStatementHR AS PayrollStatementHR
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON PayrollStatementHR.Department = BusinessStructure.Ref
	|WHERE
	|	PayrollStatementHR.EmployeeResponsible = &EmployeeResponsible
	|	AND PayrollStatementHR.Posted
	|
	|ORDER BY
	|	PayrollStatementHR.Date DESC");
	
	Query.SetParameter("EmployeeResponsible", EmployeeResponsible);

	Selection = Query.Execute().Select();

	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.DefaultBaseCurrency();
		EndIf;
	Else
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		Department = SettingsValueCached.UserDivision(EmployeeResponsible);
		Currency = SettingsValueCached.DefaultBaseCurrency();
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount();
		Bank = Common.ObjectAttributeValue(BankAccount, "Owner");
		PaymentMethodHR = Enums.PaymentMethodsHR.EmployeeSBankAccount;
		KindOfPayment = Enums.SalaryPaymentKinds.Prepayment_;

		ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Organization, Date);
		Director = ResponsiblePersons.Director;
		JobTitleExecutive = ResponsiblePersons.DirectorJobTitle;
	EndIf;
	DateOfPayment = Date;
	
EndProcedure

#EndRegion

#EndIf
