#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the composition of documents and business operations that are available for display in the workplace.
//
// Parameters:
//  FilterBusinessTransactions		 - ValueList - list of values of the enum type Link.Economic operations
//  FilterDocumentTypes				 - ValueList - list of values of the reference Link type.IDs of metadata objectsreferences
//  PurposeUseKey		 - String - key of the workplace for which the function is called.
// 
// Returns:
//   See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Function InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey) Export
	
	BusinessTransactionsAndDocuments = BusinessTransactionsAndDocuments();
	
	If PurposeUseKey = "ExpenseReports" Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	AvailableBusinessTransactionsAndDocuments = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	
	Return AvailableBusinessTransactionsAndDocuments;
	
EndFunction

#EndRegion

#Region Private

Function BusinessTransactionsAndDocuments()
	
	BusinessTransactionsAndDocuments = TMCommonUse.NewTableBusinessOperationsAndDocuments();
	
	// ExpenseReport
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.OtherExpensesOfAdvanceHolders;
	String.AddButtonCreate        = True;
	String.DocumentType                 = Type("DocumentRef.ExpenseReport");
	String.FullDocumentName           = "Document.ExpenseReport";
	String.StatusesAreUsed          = True;
	String.WorkplaceTitle       = NStr("vi = 'Giấy thanh toán tiền tạm ứng';
										|ru = 'Авансовые отчеты';
										|en = 'Expense reports'; fa = 'گزارش‌های هزینه';
										|it = 'Note spese';
										|pl = 'Raporty zaliczkowe';
										|tr = 'Gider raporları'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.JournalOfDocumentsExpenseReports";
	
	// VendorInvoice
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	String.AddButtonCreate        = True;
	String.DocumentType                 = Type("DocumentRef.VendorInvoice");
	String.FullDocumentName           = "Document.VendorInvoice";
	String.WorkplaceTitle       = NStr("vi = 'Giấy thanh toán tiền tạm ứng';
										|ru = 'Авансовые отчеты';
										|en = 'Expense reports'; fa = 'گزارش‌های هزینه';
										|it = 'Note spese';
										|pl = 'Raporty zaliczkowe';
										|tr = 'Gider raporları'");
	
	
	Return BusinessTransactionsAndDocuments;
	
EndFunction

Function CreateHyperlinkToDesign(Parameters) Export
	
	Result = Undefined;
	
	RowsArray = New Array;
	
	Organization = Parameters.Organization;
	AdvanceHolder = Parameters.AdvanceHolder;
	Department = Parameters.Department;
		
	ColorUnfilled = StyleColors.EmptyTableField;
	FilledColor = StyleColors.HyperlinkColor;
	
	HyperlinkTextForAdvances = NStr("vi = 'Ứng trước và mua hàng';
									|ru = 'Авансы и закупки';
									|en = 'Advances and purchases'; fa = 'Advances and purchases';
									|it = 'Anticipi e acquisti';
									|pl = 'Zaliczki i zakupy';
									|tr = 'Avanslar ve satın alma'");
	ThereAreAdvances = ThereAreAdvancesToDesign(Organization, AdvanceHolder, Department);
	HyperlinkForAdvances = New FormattedString(
		HyperlinkTextForAdvances,, ?(ThereAreAdvances, FilledColor, ColorUnfilled),, "PageOfTheOrderForRegistration");
	RowsArray.Add(HyperlinkForAdvances);
	
	If RowsArray.Count() > 0 Then
		Result = New FormattedString(RowsArray);
	EndIf;
	
	Return Result;
	
EndFunction

Function ThereAreAdvancesToDesign(Organization = Undefined, AdvanceHolder = Undefined, Department = Undefined)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.AdvanceHolderCash) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = RequestTextAdvancesForRegistration(Organization, AdvanceHolder, Department);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("AdvanceHolder", AdvanceHolder);
	Query.SetParameter("Department", Department);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function RequestTextAdvancesForRegistration(Organization = Undefined, AdvanceHolder = Undefined, Department = Undefined)
	
	QueryText = "
	|SELECT TOP 1 ALLOWED
	|	AdvanceHolderCash.AdvanceHolder AS AdvanceHolder
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(, &FilterCriterion) AS AdvanceHolderCash
	|WHERE
	|	AdvanceHolderCash.ToReportBalance <> 0
	|	OR AdvanceHolderCash.PurchaseAmountBalance <> 0
	|";
	
	FilterCriterion = "TRUE";
	
	If ValueIsFilled(Organization) Then
		FilterCriterion = FilterCriterion + "
		|AND Organization = &Organization";
	EndIf;
	
	If ValueIsFilled(AdvanceHolder) Then
		FilterCriterion = FilterCriterion + "
		|AND AdvanceHolder = &AdvanceHolder";
	EndIf;
	
	If ValueIsFilled(Department) Then
		FilterCriterion = FilterCriterion + "
		|AND Department = &Department";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	
	Return QueryText;
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	Result = Undefined;
	
	RowsArray = New Array;
	
	Organization = Parameters.Organization;
	AdvanceHolder = Parameters.AdvanceHolder;
	Department = Parameters.Department;
		
	ColorUnfilled = StyleColors.EmptyTableField;
	FilledColor = StyleColors.HyperlinkColor;
	
	HyperlinkTextAdvanceReports = NStr("vi = 'Giấy thanh toán tiền tạm ứng';
										|ru = 'Авансовые отчеты';
										|en = 'Expense reports'; fa = 'گزارش‌های هزینه';
										|it = 'Note spese';
										|pl = 'Raporty zaliczkowe';
										|tr = 'Gider raporları'");
	HyperlinkAdvanceReports = New FormattedString(
		HyperlinkTextAdvanceReports,, FilledColor,, "DataProcessor.JournalOfDocumentsExpenseReports.Form.DocumentsList");
	RowsArray.Add(HyperlinkAdvanceReports);
	RowsArray.Add("; ");
	
	HyperlinkTextProcurementDocuments = NStr("vi = 'Chứng từ mua hàng';
											|ru = 'Документы закупки';
											|en = 'Purchase documents'; fa = 'اسناد خرید';
											|it = 'Documenti d''acquisto';
											|pl = 'Dokumenty zakupu';
											|tr = 'Satın alma belgeleri'");
	ThereArePurchaseDocuments = ThereArePurchaseDocuments(Organization, AdvanceHolder, Department);
	HyperlinkProcurementDocuments = New FormattedString(
		HyperlinkTextProcurementDocuments,, ?(ThereArePurchaseDocuments, FilledColor, ColorUnfilled),, "DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList");
	RowsArray.Add(HyperlinkProcurementDocuments);
	RowsArray.Add("; ");
	
	If RowsArray.Count() > 0 Then
		Result = New FormattedString(RowsArray);
	EndIf;
	
	Return Result;
	
EndFunction

Function ThereArePurchaseDocuments(Organization, AdvanceHolder, Department)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.AdvanceHolderCash) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryTextPurchaseDocumentsAll(Organization, AdvanceHolder, Department);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("AdvanceHolder", AdvanceHolder);
	Query.SetParameter("Department", Department);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function QueryTextPurchaseDocumentsAll(Organization = Undefined, AdvanceHolder = Undefined, Department = Undefined)
	
	QueryText = "
	|SELECT TOP 1 ALLOWED
	|	AdvanceHolderCash.Recorder AS VendorInvoice
	|FROM
	|	AccumulationRegister.AdvanceHolderCash AS AdvanceHolderCash
	|WHERE
	|	AdvanceHolderCash.PurchaseAmount <> 0
	|	AND &FilterCriterion
	|	AND AdvanceHolderCash.Recorder REFS Document.VendorInvoice
	|";
	
	FilterCriterion = "TRUE";
	
	If ValueIsFilled(Organization) Then
		FilterCriterion = FilterCriterion + "
		|AND Organization = &Organization";
	EndIf;
	
	If ValueIsFilled(AdvanceHolder) Then
		FilterCriterion = FilterCriterion + "
		|AND AdvanceHolder = &AdvanceHolder";
	EndIf;
	
	If ValueIsFilled(Department) Then
		FilterCriterion = FilterCriterion + "
		|AND Department = &Department";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf