#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.LoanAndDepositInterestCharge.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	LoanAndDepositInterestChargeLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query(
	"SELECT
	|	*
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	PRESENTATION(ContractData.Ref) AS Contract,
	|	DocumentTable.Date AS AccrualDate,
	|	NOT (DocumentTable.DATE BETWEEN &StartDate AND &EndDate) AS DateNotInPeriod,
	|	ContractData.Organization <> &Organization AS OrganizationsDonTMatch
	|FROM
	|	DocumentTable AS DocumentTable
	|	LEFT JOIN Catalog.LoanAndDepositContracts AS ContractData
	|	ON DocumentTable.Contract = ContractData.Ref
	|WHERE
	|	NOT (DocumentTable.DATE BETWEEN &StartDate AND &EndDate)
	|	OR ContractData.Organization <> &Organization
	|ORDER BY
	|	DocumentTable.LineNumber
	|;
	|");
	
	Query.SetParameter("DocumentTable", Accruals.Unload());
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.DateNotInPeriod Then
			Text = StrTemplate(NStr("vi = 'Ngày trích %1 trong dòng %2 không được bao gồm trong thời gian trích được chỉ định.';
									|ru = 'Дата начисления %1 в строке %2 не входит в заданный период начисления.';
									|en = 'Accrual date %1 in line %2 does not belong to the specified accrual period.'; fa = 'Accrual date %1 in line %2 does not belong to the specified accrual period.';
									|it = 'La data di accredito %1 nella riga %2 non fa parte del periodo di accredito prestabilito.';
									|pl = 'Data naliczania %1 w wierszu %2 nie wchodzi do zadanego okresu naliczania.';
									|tr = '%2 satırındaki tahakkuk tarihi %1, belirtilen tahakkuk dönemi içine dahil değil.'"),
				Format(Selection.AccrualDate, "DLF=D"), Selection.LineNumber);
			TabField = "Date";
		ElsIf Selection.OrganizationsDonTMatch Then
			Text = StrTemplate(NStr("vi = 'Doanh nghiệp hợp đồng %1 trong dòng %2 không khớp với Doanh nghiệp %3 được chọn trong chứng từ.';
									|ru = 'Организация договора %1 в строке %2 не совпадает с организацией %3, выбранной в документе.';
									|en = 'Contract company %1 in line %2 does not match the %3 company selected in the document.'; fa = 'Contract company %1 in line %2 does not match the %3 company selected in the document.';
									|it = 'L''azienda del contratto %1 nella riga %2 non coincide con l''azienda %3, selezionata nel documento.';
									|pl = 'Firma kontraktu %1 w wierszu %2 nie odpowiada z firmą %3, wybraną w dokumencie.';
									|tr = '%2satırındaki %1 sözleşmeli iş yeri, belgede seçilen %3 iş yeri ile eşleşmiyor.'"),
				Selection.Contract, Selection.LineNumber, Organization);
			TabField = "Contract";
		EndIf;
		
		CommonClientServer.MessageToUser(
			Text,
			ThisObject,
			CommonClientServer.PathToTabularSection("Accruals", Selection.LineNumber, TabField),,
			Cancel);
	EndDo;
	
	ItemsAndDimensionsSelectionParameters = Documents.LoanAndDepositInterestCharge.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	LoanAndDepositInterestChargeLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	LoanAndDepositInterestChargeLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Accruals");
	
	ItemsAndDimensionsSelectionParameters = Documents.LoanAndDepositInterestCharge.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.LoanAndDepositInterestCharge.AccountingAccountSettings_(BusinessOperation));
	LoanAndDepositInterestChargeLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	LoanAndDepositInterestChargeLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	LoanAndDepositInterestChargeLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Accruals");
	Author = Users.CurrentUser();
	EmployeeResponsible = Undefined;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	AccrualPeriod = New StandardPeriod;
	AccrualPeriod.Variant = StandardPeriodVariant.ThisMonth;
	
	StartDate = AccrualPeriod.StartDate;
	EndDate = AccrualPeriod.EndDate;
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("Organization")
		Or Not ValueIsFilled(FillingData.Organization) Then
		Organization = Common.CommonSettingsStorageLoad("CurrentCompany", "");
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
