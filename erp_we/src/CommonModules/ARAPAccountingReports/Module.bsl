#Region Public

#Region AddingCommandsToForms

// Adds the "customer account Statement" report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function StatementOfSettlementsWithCustomers_AddReportCommand(ReportsCommands) Export
	
	ReportCommand = Undefined;
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.CustomersARAPStatement) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomersARAPStatement.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomersARAPStatement.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.CustomersARAPAccounting) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomersARAPAccounting.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomersARAPAccounting.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	EndIf;
	Return ReportCommand;
	
EndFunction

// Adds the "Statement of payments between organizations" report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function StatementOfSettlementsBetweenOrganizations_AddReportCommand(ReportsCommands) Export
	
	ReportCommand = Undefined;
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.AccountsPayablesAndReceivablesByIntercompany) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.AccountsPayablesAndReceivablesByIntercompany.FullName();
			ReportCommand.Presentation = Metadata.Reports.AccountsPayablesAndReceivablesByIntercompany.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.IntercompanyARAP) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.IntercompanyARAP.FullName();
			ReportCommand.Presentation = Metadata.Reports.IntercompanyARAP.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	EndIf;
	Return ReportCommand;
	
EndFunction

// Adds the "statement of payments with partners" report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands) Export
	
	ReportTitle = ?(Constants.UsePartnersAsCounterparties.Get(), NStr("vi = 'Bảng kê hạch toán với đối tác';
																		|ru = 'Ведомость расчетов с контрагентами';
																		|en = 'Summary of counterparty AR/AP'; fa = 'Summary of counterparty AR/AP';
																		|it = 'Estratto conto con le controparti';
																		|pl = 'Zestawienie rozliczeń z kontrhentami';
																		|tr = 'Cari hesaplarla mutabakat tablosu'"), NStr("vi = 'Bảng kê hạch toán với bạn hàng';
																													|ru = 'Ведомость расчетов с партнерами';
																													|en = 'Summary of partners AR/AP'; fa = 'Summary of partners AR/AP';
																													|it = 'Estratto conto con i partner';
																													|pl = 'Zestawienie rozliczeń z partnerami';
																													|tr = 'İş ortakları ile mutabakat tablosu'"));
	
	ReportCommand = Undefined;
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.PartnersARAPAccountingStatement) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.PartnersARAPAccountingStatement.FullName();
			ReportCommand.Presentation = ReportTitle;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.PartnersARAPAccounting) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.PartnersARAPAccounting.FullName();
			ReportCommand.Presentation = ReportTitle;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	EndIf;
	Return ReportCommand;
	
EndFunction

// Adds the vendor billing Statement report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function SupplierBillingStatement_AddReportCommand(ReportsCommands) Export
	
	ReportCommand = Undefined;
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.VendorsARAPStatement) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorsARAPStatement.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorsARAPStatement.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.VendorsARAPAccounting) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorsARAPAccounting.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorsARAPAccounting.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			
		EndIf;
	EndIf;
	Return ReportCommand;
	
EndFunction

// Adds the "customer debt" report command in standard form to the list of commands.
// The report is grouped by partner.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function CustomerDebt_AddReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.CustomersAccountsReceivable) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomersAccountsReceivable.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomersAccountsReceivable.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.FunctionalOptions = "UseCustomerPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithClient");
			ReportCommand.VariantKey = "CustomersDebtContext";
			
			Return ReportCommand;
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.StatusOfCustomersARAP) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.StatusOfCustomersARAP.FullName();
			ReportCommand.Presentation = Metadata.Reports.StatusOfCustomersARAP.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.FunctionalOptions = "UseCustomerPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithClient");
			ReportCommand.VariantKey = "CustomersDebtContext";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;
	Return Undefined;
EndFunction

// Adds the "customer debt" report command to the list of commands. 
// The report is grouped by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function CustomerDebt_AddDocumentReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.CustomersAccountsReceivable) Then
		
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomersAccountsReceivable.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomersAccountsReceivable.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithClientOnDocuments");
			ReportCommand.VariantKey = "CustomerDebtOnObjectOfSettlement";
			
			Return ReportCommand;
		
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.StatusOfCustomersARAP) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.StatusOfCustomersARAP.FullName();
			ReportCommand.Presentation = Metadata.Reports.StatusOfCustomersARAP.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithClientOnDocuments");
			ReportCommand.VariantKey = "CustomerDebtOnObjectOfSettlement";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;

	Return Undefined;
EndFunction

// Adds the "Customer Settlement Card" report command to the list of commands.
// Grouping by partner/counterparty.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithClient_AddReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.CustomerARAPOpenItems24) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomerARAPOpenItems24.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomerARAPOpenItems24.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			ReportCommand.FunctionalOptions = "UseCustomerPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "Card");
			ReportCommand.VariantKey = "Card";
			
			Return ReportCommand;
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.CustomerARAPOpenItems) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomerARAPOpenItems.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomerARAPOpenItems.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			ReportCommand.FunctionalOptions = "UseCustomerPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "CustomerSettlementCard");
			ReportCommand.VariantKey = "CardOfSettlementsWithCustomersContext";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the "customer payment Card" report command to the list of commands.
// Grouping by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.CustomerARAPOpenItems24) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomerARAPOpenItems24.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomerARAPOpenItems24.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "Card");
			ReportCommand.VariantKey = "Card";
			
			Return ReportCommand;
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.CustomerARAPOpenItems) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CustomerARAPOpenItems.FullName();
			ReportCommand.Presentation = Metadata.Reports.CustomerARAPOpenItems.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "CardOfSettlementsWithClientOnDocuments");
			ReportCommand.VariantKey = "CardOfSettlementsWithClientsOnDocumentsContext";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the vendor Debt report command in standard format to the list of commands.
// The report is grouped by partner.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function IndebtednessToSuppliers_AddReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.VendorsAccountsPayable) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorsAccountsPayable.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorsAccountsPayable.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.FunctionalOptions = "UseVendorPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithSupplier");
			ReportCommand.VariantKey = "DebtToServiceProviders";
			
			Return ReportCommand;
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.StateOfVendorAccountsPayable) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.StateOfVendorAccountsPayable.FullName();
			ReportCommand.Presentation = Metadata.Reports.StateOfVendorAccountsPayable.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.FunctionalOptions = "UseVendorPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithSupplier");
			ReportCommand.VariantKey = "DebtToServiceProviders";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;

	Return Undefined;
EndFunction

// Adds the supplier Debt report command to the list of commands. 
// The report is grouped by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.VendorsAccountsPayable) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorsAccountsPayable.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorsAccountsPayable.Synonym;
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithSupplierAccordingToDocuments");
			ReportCommand.VariantKey = "IndebtednessToSuppliersForSettlementObject";
			
			Return ReportCommand;
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.StateOfVendorAccountsPayable) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.StateOfVendorAccountsPayable.FullName();
			ReportCommand.Presentation = Metadata.Reports.StateOfVendorAccountsPayable.Synonym;
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "StateOfSettlementsWithSupplierAccordingToDocuments");
			ReportCommand.VariantKey = "IndebtednessToSuppliersForSettlementObject";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;

	Return Undefined;
EndFunction

// Adds the "Supplier Settlement Card" report command to the list of commands.
// Grouping by partner/counterparty.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithSupplier_AddReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.VendorARAPOpenItems24) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorARAPOpenItems24.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorARAPOpenItems24.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			ReportCommand.FunctionalOptions = "UseVendorPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "Card");
			ReportCommand.VariantKey = "Card";
			
			Return ReportCommand;
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.VendorARAPOpenItems) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorARAPOpenItems.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorARAPOpenItems.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			ReportCommand.FunctionalOptions = "UseVendorPartnerDataContext";
			ReportCommand.AdditionalParameters.Insert("CommandName", "PaymentCardWithSupplier");
			ReportCommand.VariantKey = "PaymentCardWithSuppliersContext";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the "payment card with supplier" report command to the list of commands.
// Grouping by calculation object.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.VendorARAPOpenItems24) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorARAPOpenItems24.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorARAPOpenItems24.Synonym;
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "Card");
			ReportCommand.VariantKey = "Card";
			
			Return ReportCommand;
			
		EndIf;
	Else
		If AccessRight("View", Metadata.Reports.VendorARAPOpenItems) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.VendorARAPOpenItems.FullName();
			ReportCommand.Presentation = Metadata.Reports.VendorARAPOpenItems.Synonym;
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Important";
			ReportCommand.AdditionalParameters.Insert("CommandName", "PaymentCardWithSupplierBasedOnDocuments");
			ReportCommand.VariantKey = "PaymentCardWithSuppliersAccordingToDocumentsContext";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;
	
	Return Undefined;
EndFunction

#EndRegion

#Region FieldTemplatesForReports

// Parameters:
// 	QueryText - String -
// 	ReportSettings - DataCompositionSettings - 
// 	CalculatedFields - DataCompositionSchemaCalculatedFields -
// 	TableName - String -
Procedure AddSelectionsOfSelectedFieldsToQuery(QueryText, ReportSettings, CalculatedFields, TableName) Export
	
	SelectionText_ = "";
	
	SelectedFieldsArray = New Array;
	FindSelectedFieldsRecursively(ReportSettings.Selection.Items, SelectedFieldsArray);
	
	For Each SelectedField In SelectedFieldsArray Do
		If CalculatedFields.Find(String(SelectedField.Field)) = Undefined
			And ReportSettings.SelectionAvailableFields.Items.Find(SelectedField.Field) <> Undefined
			And ReportSettings.SelectionAvailableFields.Items.Find(SelectedField.Field).Type.Types().Find(Type("Number")) <> Undefined Then
			If StrFind(String(SelectedField.Field),"UserFields") = 0 Then
				SelectionText_ = SelectionText_ + ?(SelectionText_ = "","", "OR") +"
					|	SUM("+TableName+"." + String(SelectedField.Field) + ") <> 0 ";
			EndIf;
		EndIf;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&SelectionOfSelectedFields", ?(SelectionText_ = "", "TRUE", SelectionText_));
	
EndProcedure

Procedure FindSelectedFieldsRecursively(ItemsCollection, ItemArray)

	For Each Item In ItemsCollection Do
		
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			If Item.Use Then
				ItemArray.Add(Item);
			EndIf;
		Else
			FindSelectedFieldsRecursively(Item.Items, ItemArray);
		EndIf;
		
	EndDo;

EndProcedure

// Returns:
// 	String
//
Function TemplateOfShippedField() Export
	Return
		"CASE
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoiceDebtIncrease)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN CalculationsByTerms.Debt
		|			WHEN 2
		|				THEN CalculationsByTerms.ARAPMan
		|			ELSE CalculationsByTerms.DebtLocal
		|		END
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN - (CalculationsByTerms.Debt + CalculationsByTerms.Prepayment)
		|			WHEN 2
		|				THEN - (CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan)
		|			ELSE - (CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal)
		|		END
		|	ELSE 0
		|END";
EndFunction

// Returns:
// 	String
//
Function TemplateOfCreditedField() Export
	Return
		"CASE
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsDebtDecrease)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN CalculationsByTerms.Debt + CalculationsByTerms.Prepayment
		|			WHEN 2
		|				THEN CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan
		|			ELSE CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal
		|		END
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentPrepaymentDecrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentDecrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsDebtIncrease)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN - (CalculationsByTerms.Debt + CalculationsByTerms.Prepayment)
		|			WHEN 2
		|				THEN - (CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan)
		|			ELSE - (CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal)
		|		END
		|	ELSE 0
		|END";
EndFunction

// Returns:
// 	String
//
Function TemplateForPaidField() Export
	Return
		"CASE
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.PaymentPrepaymentIncrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.PaymentDebtDecrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.RefundDecreasesDebt)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN CalculationsByTerms.Debt + CalculationsByTerms.Prepayment
		|			WHEN 2
		|				THEN CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan
		|			ELSE CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal
		|		END
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.RefundIncreasesDebt)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.RefundDecreasesPrepayment)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN - CalculationsByTerms.Debt - CalculationsByTerms.Prepayment
		|			WHEN 2
		|				THEN - CalculationsByTerms.ARAPMan - CalculationsByTerms.PrepaymentMan
		|			ELSE - CalculationsByTerms.DebtLocal - CalculationsByTerms.PrepaymentLocal
		|		END
		|	ELSE 0
		|END";
EndFunction

// Returns:
// 	String
//
Function TemplateForWriteOffRevaluationField() Export
	Return
		"CASE
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN CalculationsByTerms.Debt + CalculationsByTerms.Prepayment
		|			WHEN 2
		|				THEN CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan
		|			ELSE CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal
		|		END
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease)
		|		OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease)
		|		THEN CASE &ReportData
		|			WHEN 4
		|				THEN - (CalculationsByTerms.Debt + CalculationsByTerms.Prepayment)
		|			WHEN 2
		|				THEN - (CalculationsByTerms.ARAPMan + CalculationsByTerms.PrepaymentMan)
		|			ELSE - (CalculationsByTerms.DebtLocal + CalculationsByTerms.PrepaymentLocal)
		|		END
		|	ELSE 0
		|END";
EndFunction

#EndRegion

#EndRegion