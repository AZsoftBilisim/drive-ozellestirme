#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.BankAccountCash);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashInCashRegistersCR);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashInTransit);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashAccountBalance);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.AcquiringContractARAP);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.BankAccountCash);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.CashInCashRegistersCR);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.CashInTransit);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.CashAccountBalance);
		
	EndIf;
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.BankAccountCash);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.CashInCashRegistersCR);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.CashInTransit);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.CashAccountBalance);
	EndIf;
		
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.BankAccountCash;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
		DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.CashInCashRegistersCR;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	RegisterMetadata = Metadata.AccumulationRegisters.CashInTransit;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.CashAccountBalance;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.AcquiringContractARAP;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of the account funds.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "BankAccountCash");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashInCashRegistersCR");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashInTransit");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashAccountBalance");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AcquiringContractARAP");
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableBankAccountCash", 
		AccumulationRegisters.BankAccountCash.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableCashInCashRegistersCR", 
		AccumulationRegisters.CashInCashRegistersCR.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableCashInTransit", 
		AccumulationRegisters.CashInTransit.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableCashAccountBalance", 
		AccumulationRegisters.CashAccountBalance.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

#EndRegion

#Region ObjectModule

// Checks the Contract in the header of the document and clears 
// if the entire payment has been distributed and there are different Contracts in the settlement objects, 
// if there is an unallocated part of the payment and the settlement procedure of the Contract of the sub-agreements of the contractors or sub-agreements of the invoices
//
// Parameters:
// 	Object - DocumentObject - The object being processed.
// 	Cancel - Boolean - Flag failure from the document handler before Writing.
// 
Procedure BeforeWrite(Object, Cancel) Export
	
	FillInHeaderBasedOnDecryptionData(Object);
	
	If Not Cancel Then
		CheckFillOutContract(Object);
	EndIf;
	
EndProcedure

#EndRegion

#Region ManagingInterfaceElements

// The procedure sets the visibility of form elements by an array of names.
//
// Parameters:
//	Items - FormAllItems - Collection of form elements
//	ArrayOfAllProps - Array - Array of names of details to set visibility for
//	ArrayOfVisibleProps - Array - Array of names of details that should be visible on the form.
//
Procedure SetVisibilityOfElementsByArray(Items, Val ArrayOfAllProps, Val ArrayOfVisibleProps) Export
	
	If TypeOf(ArrayOfVisibleProps) <> Type("Array") Then
		ArrayOfVisibleProps = New Array;
	EndIf;
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		AttributeName = StrReplace(ArrayElement, ".", "");
		
		// If the props are not in the array of visible props, remove the visibility of the form element.
		VisibilityOfProps = (ArrayOfVisibleProps.Find(ArrayElement) <> Undefined);
		If Items.Find(AttributeName) <> Undefined
		 And Items[AttributeName].Visible <> VisibilityOfProps Then
			Items[AttributeName].Visible = VisibilityOfProps;
		EndIf;
		
	EndDo;
	
EndProcedure // Set the visibility of the elements of the array()

// The procedure sets the visibility of form elements by an array of names.
//
// Parameters:
//	Items - FormAllItems - Collection of form elements
//	ArrayOfAllProps - Array - Array of names of details to set visibility for
//	ArrayOfVisibleProps - Array - Array of names of details that should be visible on the form
//	TSName - String - Name of the table part, the current row of which is displayed as separate details
//	ReplacementNameTS - String - Name of the substring for replacing the name of the details of the table part.
//
Procedure SetVisibilityOfElementsInExtendedArray(Items, Val ArrayOfAllProps, Val ArrayOfVisibleProps,
	Val TSName, Val ReplacementNameTS) Export
	
	If TypeOf(ArrayOfVisibleProps) <> Type("Array") Then
		ArrayOfVisibleProps = New Array;
	EndIf;
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		AttributeName = StrReplace(StrReplace(ArrayElement, TSName, ReplacementNameTS), ".", "");
		
		VisibilityOfProps = (ArrayOfVisibleProps.Find(ArrayElement) <> Undefined);
		If Items.Find(AttributeName) <> Undefined
			And Items[AttributeName].Visible <> VisibilityOfProps Then
			Items[AttributeName].Visible = VisibilityOfProps;
		EndIf;
	EndDo;
	
EndProcedure

// The procedure sets the availability of form elements by an array of names.
//
// Parameters:
//	Items - FormAllItems - collection of form elements.
//	ArrayOfAllProps - Array - Array of names of details that are set to be available.
//	ArrayOfVisibleProps - Array - Array of names of details that should be available on the form.
//
Procedure SetAvailabilityOfElementsByArray(Items, Val ArrayOfAllProps, Val ArrayOfVisibleProps) Export
	
	If TypeOf(ArrayOfVisibleProps) <> Type("Array") Then
		ArrayOfVisibleProps = New Array;
	EndIf;
	
	ArrayOfAllElements = NamesOfFormItems(Items, ArrayOfAllProps);
	ArrayOfVisibleElements = NamesOfFormItems(Items, ArrayOfVisibleProps);
	
	For Each AttributeName In ArrayOfAllElements Do
		
		// If the element is not in the array of visible elements, remove the visibility of the form element.
		AvailabilityOfProps = (ArrayOfVisibleElements.Find(AttributeName) <> Undefined);
		
		FormItem = Items[AttributeName]; // FormField
		
		If Items.Find(AttributeName) <> Undefined
			And FormItem.Enabled <> AvailabilityOfProps Then
				FormItem.Enabled = AvailabilityOfProps;
		EndIf;
	EndDo;
	
EndProcedure

// The procedure sets the visibility of the selection based on the settlement balances in the form.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//	Button - FormButton - Form button to open the selection.
//
Procedure SetVisibilityOfSelectionForRemainingCalculations(BusinessOperation, Button) Export
	
	OperationArray = New Array;
	OperationArray.Add(Enums.BusinessTransactions.RefundFromVendor);
	OperationArray.Add(Enums.BusinessTransactions.RefundToCustomer);
	OperationArray.Add(Enums.BusinessTransactions.PaymentToVendor);
	OperationArray.Add(Enums.BusinessTransactions.CustomsPayment);
	OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	OperationArray.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
	OperationArray.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	OperationArray.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
	
	Button.Visible = (OperationArray.Find(BusinessOperation) <> Undefined);
	
EndProcedure // Set the visibility of the collection of the settlement dates()

Procedure ManagingFormElementsWhenReadingCreatingOnServer(Form) Export

	ObjectName = "";
	If Form.Parameters.Property("Key") Then
		MetadataObject = Metadata.FindByType(TypeOf(Form.Parameters.Key));
		If MetadataObject <> Undefined Then
			ObjectName = MetadataObject.FullName();
		EndIf;
	EndIf;

	If Not ValueIsFilled(ObjectName) Then
		Raise NStr("vi = 'Không thể cài đặt trường biểu mẫu';
					|ru = 'Не удалось выполнить настройку полей формы';
					|en = 'Unable to configure form fields'; fa = 'Unable to configure form fields';
					|it = 'Non è stato possibile effettuare l''impostazione dei campi del modulo';
					|pl = 'Nie udało się skonfigurować pola formularza';
					|tr = 'Alan ayarlaması yapılamadı formlar'");
	EndIf;

	FormFieldSettings = InitializeFormFieldSettings();
	Manager = Common.ObjectManagerByFullName(ObjectName);
	Manager.FillInFormFieldSettings(FormFieldSettings);

	If Not CommonClientServer.HasAttributeOrObjectProperty(Form, "FieldSettings") Then
		Attributes = New Array;
		Attributes.Add(New FormAttribute("FieldSettings", New TypeDescription("ValueTable")));
		Attributes.Add(New FormAttribute("Fields", New TypeDescription(), "FieldSettings"));
		Attributes.Add(New FormAttribute("Condition", New TypeDescription("DataCompositionFilter"), "FieldSettings"));
		Attributes.Add(New FormAttribute("Properties", New TypeDescription(), "FieldSettings"));
		Form.ChangeAttributes(Attributes);
	EndIf;
	Form.ValueToFormAttribute(FormFieldSettings, "FieldSettings");

	If Not CommonClientServer.HasAttributeOrObjectProperty(Form, "FieldDependencies") Then
		Attributes = New Array;
		Attributes.Add(New FormAttribute("FieldDependencies", New TypeDescription("ValueTable")));
		Attributes.Add(New FormAttribute("AttributeName", New TypeDescription("String"), "FieldDependencies"));
		Attributes.Add(New FormAttribute("DependentFields", New TypeDescription(), "FieldDependencies"));
		Form.ChangeAttributes(Attributes);
	EndIf;
	DependenciesOfFormFields = DependenciesOfFormFields(FormFieldSettings);
	Form.ValueToFormAttribute(DependenciesOfFormFields, "FieldDependencies");

EndProcedure

Function DependenciesOfFormFields(FieldSettings) Export
	
	FieldDependencies = InitializeDependenciesOfFormFields();
	
	For Each SettingString In FieldSettings Do
		
		Attributes = New Array;
		FillInSelectionDetails(SettingString.Condition, Attributes);
		
		For Each Attribute In Attributes Do
			PosPoints = StrFind(Attribute, ".");
			If PosPoints = 0 Then
				AttributeName = Attribute;
			Else
				AttributeName = Mid(Attribute, PosPoints + 1);
			EndIf;
			TableRow = FieldDependencies.Find(AttributeName, "AttributeName");
			If TableRow = Undefined Then
				TableRow = FieldDependencies.Add();
				TableRow.AttributeName = AttributeName;
			EndIf;
			For Each Field In SettingString.Fields Do
				TableRow.DependentFields.Add(Field);
			EndDo;
		EndDo;
	EndDo;
	
	Return FieldDependencies;
	
EndFunction

// Adds details to the unverifiable array if the element properties do not allow checking the details
//
// Parameters:
//    ItemsProperties - Array - member property
//    NotCheckedAttributeArray - Array - unverified Bank details
Procedure DisableVerificationOfObjectDetails(ItemsProperties, NotCheckedAttributeArray) Export
	
	For Each ItemProperties In ItemsProperties Do
		If ValueIsFilled(ItemProperties.TagName)
			And (ItemProperties.Property = "Visible"
				Or ItemProperties.Property = "ReadOnly"
				Or ItemProperties.Property = "OnlyViewWithoutBlankMark"
				Or ItemProperties.Property = "MarkIncomplete"
				Or ItemProperties.Property = "AutoMarkIncomplete") Then
			
			If (ItemProperties.Property = "Visible"
				Or ItemProperties.Property = "MarkIncomplete"
				Or ItemProperties.Property = "AutoMarkIncomplete")
					And ItemProperties.Value = False
				Or ItemProperties.Property = "OnlyViewWithoutBlankMark"
					And ItemProperties.Value = True
				Or ItemProperties.Property = "ReadOnly"
					And ItemProperties.Value = True Then
					
				NotCheckedAttributeArray.Add(ItemProperties.TagName);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure ClearUnusedObjectDetails(Object, ItemsProperties, ExceptionAttributes = Undefined) Export
	
	Attributes = Object.Metadata().Attributes;
	TabularSections = Object.Metadata().TabularSections;
	
	For Each ItemProperties In ItemsProperties Do
		
		If ExceptionAttributes <> Undefined
			And ExceptionAttributes.Find(ItemProperties.TagName) <> Undefined Then
			Continue;
		EndIf;
		
		If ValueIsFilled(ItemProperties.TagName)
			And ItemProperties.Property = "Visible"
			And Not ItemProperties.Value Then
		
			If Attributes.Find(ItemProperties.TagName) <> Undefined
				And ValueIsFilled(Object[ItemProperties.TagName]) Then
				
				Object[ItemProperties.TagName] = Undefined;
				
			ElsIf TabularSections.Find(ItemProperties.TagName) <> Undefined
				And Object[ItemProperties.TagName].Count() Then
				
				Object[ItemProperties.TagName].Clear();
				
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Returns an empty table of form field settings
// 
// Returns:
//     ValueTable - table with columns:
//         * Fields - Array of String - Fields that the setting applies to.
//         * Condition - DataCompositionFilter - Determines whether the setting is valid.
//         * Properties - Structure - Field properties.
//
Function InitializeFormFieldSettings() Export
	
	FormFieldSettings = New ValueTable;
	FormFieldSettings.Columns.Add("Fields", New TypeDescription("Array"));
	FormFieldSettings.Columns.Add("Condition", New TypeDescription("DataCompositionFilter"));
	FormFieldSettings.Columns.Add("Properties", New TypeDescription("Structure"));
	
	Return FormFieldSettings;
	
EndFunction

// Initializes the table part to display as a single row or multiple rows
// 
// Parameters:
//     Form - ClientApplicationForm - shape.
//     TSName - String - The name is tabular for the part.
//     RadioButton - Number - Flag for cocking the switch.
//
Procedure InitializeTablePart(Form, TSName, RadioButton) Export
	
	Object = Form.Object;
	Items = Form.Items;
	
	If Object[TSName].Count() = 0 Then
		NewRow = Object[TSName].Add();
		FormItem = Items[TSName]; // FormTable
		FormItem.CurrentRow = NewRow.GetID();
		RadioButton = 0;
	ElsIf Object[TSName].Count() = 1 Then
		FormItem = Items[TSName]; // FormTable
		FormItem.CurrentRow = Object[TSName][0].GetID();
		RadioButton = 0;
	Else
		RadioButton = 1;
	EndIf;
	
EndProcedure

// Complements the settings data of settings for Bank accounts
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
// 
Procedure ElementSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	
	Item = Settings.Add();
	Item.Fields.Add("OtherBankDetails");
	Finances.NewFilter(Item.Condition, "More.SettlementBankUsed", True);
	Item.Properties.Insert("Width", 12);
	
	Item = Settings.Add();
	Item.Fields.Add("OtherBankDetails");
	Finances.NewFilter(Item.Condition, "More.SettlementBankUsed", False);
	Item.Properties.Insert("Width", 9);
	
	Item = Settings.Add();
	Item.Fields.Add("BankForSettlementsInGroup");
	Finances.NewFilter(Item.Condition, "TransferBankDetailsManualEdit", False);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("BankAccountForPayments");
	Item.Fields.Add("TransferBankBIC");
	Item.Fields.Add("BankNameForPaymentsInt");
	Finances.NewFilter(Item.Condition, "More.SettlementBankUsed", True);
	Item.Properties.Insert("Enabled");

	Item = Settings.Add();
	Item.Fields.Add("SelectBankForSettlementsGroup");
	Finances.NewFilter(Item.Condition, "More.SettlementBankUsed", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("BankBIC");
	Item.Fields.Add("BicOfBankAtLink");
	Finances.NewFilter(Item.Condition, "ForeignBank", False);
	Item.Properties.Insert("Title", NStr("vi = 'Mã ngân hàng';
										|ru = 'БИК';
										|en = 'Bank code'; fa = 'کد بانک';
										|it = 'BIC';
										|pl = 'Bank code';
										|tr = 'BIC'"));
	
	Item = Settings.Add();
	Item.Fields.Add("BankBIC");
	Item.Fields.Add("BicOfBankAtLink");
	Finances.NewFilter(Item.Condition, "ForeignBank", True);
	Item.Properties.Insert("Title", NStr("vi = 'Mã';
										|ru = 'Код';
										|en = 'Code'; fa = 'کد';
										|it = 'Codice';
										|pl = 'Code';
										|tr = 'Kod'"));
	
	Item = Settings.Add();
	Item.Fields.Add("TransferBankBIC");
	Item.Fields.Add("BicOfBankForPaymentsUsingLink");
	Finances.NewFilter(Item.Condition, "ForeignBank", False);
	Item.Properties.Insert("Title", NStr("vi = 'Mã ngân hàng';
										|ru = 'БИК';
										|en = 'Bank code'; fa = 'کد بانک';
										|it = 'BIC';
										|pl = 'Bank code';
										|tr = 'BIC'"));
	
	Item = Settings.Add();
	Item.Fields.Add("TransferBankBIC");
	Item.Fields.Add("BicOfBankForPaymentsUsingLink");
	Finances.NewFilter(Item.Condition, "ForeignBank", True);
	Item.Properties.Insert("Title", NStr("vi = 'Mã';
										|ru = 'Код';
										|en = 'Code'; fa = 'کد';
										|it = 'Codice';
										|pl = 'Code';
										|tr = 'Kod'"));
	
	Item = Settings.Add();
	Item.Fields.Add("BankCorrAccount");
	Item.Fields.Add("TransferBankCorrAccount");
	Finances.NewFilter(Item.Condition, "ForeignBank", False);
	Finances.NewFilter(Item.Condition, "More.CurrencyAccount", False);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("BankAccountForPayments");
	Finances.NewFilter(Item.Condition, "ForeignBank", False);
	Finances.NewFilter(Item.Condition, "More.CurrencyAccount", False);
	Item.Properties.Insert("Visible", False);
	
	MainCountry = Catalogs.WorldCountries.FindByCode("643");
	If ValueIsFilled(MainCountry) Then
		Item = Settings.Add();
		Item.Fields.Add("ThisIsAnIBAN");
		Finances.NewFilter(Item.Condition, "CountryOfBank", MainCountry);
		Item.Properties.Insert("Enabled", False);
	EndIf;
	
	Item = Settings.Add();
	Item.Fields.Add("BankCountryInternational");
	Item.Fields.Add("BankCountryInternationalByReference");
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("Visible", False);
	
	Item = Settings.Add();
	Item.Fields.Add("ThisIsAnIBAN");
	Item.Fields.Add("BankInternationalGroup");
	Item.Fields.Add("BankInternationalGroupByReference");
	Item.Fields.Add("GroupBankForSettlementsInternational");
	Item.Fields.Add("GroupBankForSettlementsInternationalLink");
	Finances.NewFilter(Item.Condition, "More.InternationalBankAccountDetails", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("BankInternationalGroup");
	Item.Fields.Add("BankInternationalGroupByReference");
	Item.Fields.Add("GroupBankForSettlementsInternational");
	Item.Fields.Add("GroupBankForSettlementsInternationalLink");
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("ShowTitle");
	
	Item = Settings.Add();
	Item.Fields.Add("BankGroup1");
	Item.Fields.Add("BankGroupByLink");
	Item.Fields.Add("SettlementBankGroup");
	Item.Fields.Add("BankGroupForPaymentsByLink");
	Finances.NewFilter(Item.Condition, "More.InternationalBankAccountDetails", False);
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("ShowTitle", False);
	
	Item = Settings.Add();
	Item.Fields.Add("BankGroup1");
	Item.Fields.Add("BankGroupByLink");
	Item.Fields.Add("SettlementBankGroup");
	Item.Fields.Add("BankGroupForPaymentsByLink");
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CorrespondentBankAccountForSettlementsInternational");
	Item.Fields.Add("CorrespondentBankAccountForSettlementsInternationalByReference");
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("Visible", False);
	
	Item = Settings.Add();
	Item.Fields.Add("CountryOfBankForSettlementsInternational");
	Item.Fields.Add("CountryOfBankForSettlementsInternationalByReference");
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("Visible", False);
	
EndProcedure

// Manages form elements in the "no split" mode"
// 
// Parameters:
//     Form - ClientApplicationForm - shape.
//
Procedure SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning(Form) Export
	
	Object = Form.Object; // DocumentObject
	Items = Form.Items;
	
	If Object.ARAPDetails.Count() Then
		
		CurRow = Object.ARAPDetails[0];
		
		DocumentType = TypeOf(Object.Ref);
		ListOfBusinessTransactionsSale = GetListOfBusinessSalesOperationsForDocument(DocumentType);
		ListOfBusinessTransactionsPurchases = GetListOfPurchasingBusinessOperationsForDocument(DocumentType);
		ListOfBusinessTransactionsForRefundOperations = GetListOfBusinessReturnTransactionsForDocument(DocumentType);
		
		ContractARAPObjectFilledIn = CurRow.Property("ARAPObject") And ValueIsFilled(CurRow.ARAPObject)
			Or CurRow.Property("LeaseContracts") And ValueIsFilled(CurRow.LeaseContracts)
			Or CurRow.Property("LoanDepositContract") And ValueIsFilled(CurRow.LoanDepositContract)
			Or ValueIsFilled(Object.Contract);
		
		PaymentCurrencyIsEqualToCurrencyOfLoanDeposit = True;
		If CurRow.Property("LoanDepositContract")
			And ValueIsFilled(CurRow.LoanDepositContract) Then
			
			ContractCurrency = Common.ObjectAttributeValue(
				CurRow.LoanDepositContract, "ARAPCurrency");
			PaymentCurrencyIsEqualToCurrencyOfLoanDeposit = (ContractCurrency = Object.Currency);
			
		EndIf;
		
		ItIsAllowedToWorkWithSubsidiaryPartners = False;
		VATRateOfContract = Undefined;
		TheCalculationObjectMatchesTheDocument = False;
		If CurRow.Property("ARAPObject") And ValueIsFilled(CurRow.ARAPObject) Then
			ARAPObject = Common.ObjectAttributeValue(CurRow.ARAPObject, "Object");
			TheCalculationObjectMatchesTheDocument = ARAPObject = Object.Ref;
			If TypeOf(ARAPObject) = Type("CatalogRef.CounterpartyContracts") Then
				ContractParameters = Common.ObjectAttributesValues(ARAPObject, "ItIsAllowedToWorkWithSubsidiaryPartners, VATRate");
				ItIsAllowedToWorkWithSubsidiaryPartners = ContractParameters.ItIsAllowedToWorkWithSubsidiaryPartners;
				VATRateOfContract = ContractParameters.VATRate;
			EndIf;
		EndIf;
		
		ObjectOfTaxationDoesNotCoincideWithDocument = CurRow.Property("ARAPObject") And ValueIsFilled(CurRow.ARAPObject)
			And Not Object.Ref = ARAPObject;
		
		HideVATTaxation = ObjectOfTaxationDoesNotCoincideWithDocument
			Or (ListOfBusinessTransactionsSale.Find(Object.BusinessOperation) = Undefined
				And ListOfBusinessTransactionsPurchases.Find(Object.BusinessOperation) = Undefined)
			Or Not ListOfBusinessTransactionsForRefundOperations.Find(Object.BusinessOperation) = Undefined;
		HideVATRefundTaxation = ObjectOfTaxationDoesNotCoincideWithDocument
			Or ListOfBusinessTransactionsForRefundOperations.Find(Object.BusinessOperation) = Undefined;
			
		PartnerAvailable = Not ContractARAPObjectFilledIn Or ItIsAllowedToWorkWithSubsidiaryPartners Or TheCalculationObjectMatchesTheDocument;
		CurrencyIsAvailable = Not ContractARAPObjectFilledIn
			Or ContractARAPObjectFilledIn And Not PaymentCurrencyIsEqualToCurrencyOfLoanDeposit
			Or TheCalculationObjectMatchesTheDocument And Not ValueIsFilled(Object.Contract);
		Items.DecryptionWithoutPartitioningPartner.ReadOnly = Not PartnerAvailable;
		Items.DecryptionWithoutSplittingTheCurrencyOfMutualSettlements.ReadOnly = Not CurrencyIsAvailable;
		Items.DecodingWithoutSplittingVATTaxation.Visible = Not HideVATTaxation;
		Items.DecryptionWithoutDivisionTaxationVATRefund.Visible = Not HideVATRefundTaxation;
		Items.DecryptionWithoutSplittingTheVATAmount.ReadOnly = CashClientServer.ThisIsZeroVATRATE(CurRow.VATRate);
		
	EndIf;
	
EndProcedure

// Set the registration of the settlement currency.
// 
// Parameters:
//  Form - ClientApplicationForm - shape. 
//
Procedure SetConditionalAppearanceOfSettlementCurrency(Form) Export
	
	Items = Form.Items;
	ConditionalAppearance = Form.ConditionalAppearance;
	
	//ARAPCurrency
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsARAPCurrency.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterAndGroup = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterAndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
		ItemFilter = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = True;
	
	AddTermsAndConditionsForContract(SelectionGroupOr);
	
	FilterAndGroup = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterAndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		FilterNotEmptyContract = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterNotEmptyContract.LeftValue = New DataCompositionField("Object.Contract");
		FilterNotEmptyContract.ComparisonType = DataCompositionComparisonType.Filled;
	
		ItemFilter = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
	
	SelectionCurrencyIsSame = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	SelectionCurrencyIsSame.LeftValue = New DataCompositionField("Object.ARAPDetails.LoanDepositContract.ARAPCurrency");
	SelectionCurrencyIsSame.ComparisonType = DataCompositionComparisonType.Equal;
	SelectionCurrencyIsSame.RightValue = New DataCompositionField("Object.Currency");
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Set the partner's registration.
// 
// Parameters:
//  Form - ClientApplicationForm - shape. 
//
Procedure SetPartnerConditionalAppearance(Form) Export
	
	Items = Form.Items;
	ConditionalAppearance = Form.ConditionalAppearance;
	
	//Partner
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsPartner.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterAndGroup = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterAndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
		ItemFilter = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = True;
	
		ItemFilter = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ItIsAllowedToWorkWithSubsidiaryPartners");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = True;
	
	AddTermsAndConditionsForContract(SelectionGroupOr);
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Set the registration of the VAT amount in the decryption of the payment.
// 
// Parameters:
//  Form - ClientApplicationForm - shape. 
//
Procedure SetConditionalAppearanceOfVATAmountOfPaymentDecryption(Form) Export
	
	Items = Form.Items;
	ConditionalAppearance = Form.ConditionalAppearance;
	
	Item = ConditionalAppearance.Items.Add();
	
	Fields = Item.Fields.Items;
	ItemField = Fields.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsVATAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	RatesWithoutVAT = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RatesWithoutVAT.Add(Catalogs.VATRates.EmptyRef());
	
	ItemFilter.RightValue = RatesWithoutVAT;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Adds general properties for setting the format of the currency exchange rate field on the payment document form
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
Procedure FillInConditionalAppearanceAccuracyOfCourse(Settings) Export
	
	BasicCourseAccuracy = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
	
	Item = Settings.Add();
	Item.Fields.Add("DecodingWithoutSplittingTheCourseNumeratorOfMutualSettlements");
	
	AndGroup = FinancialReportingServer.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	FinancialReportingServer.NewFilter(AndGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("More.ARAPCurrency"), , DataCompositionComparisonType.NotEqual);
	FinancialReportingServer.NewFilter(AndGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("Currency"), , DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("EditFormat", "NFD=8");
	
	Item = Settings.Add();
	Item.Fields.Add("DecodingWithoutSplittingTheCourseNumeratorOfMutualSettlements");
	
	OrGroup = FinancialReportingServer.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FinancialReportingServer.NewFilter(OrGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("More.ARAPCurrency"), , DataCompositionComparisonType.Equal);
	FinancialReportingServer.NewFilter(OrGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("Currency"), , DataCompositionComparisonType.Equal);
	
	Item.Properties.Insert("EditFormat", StrTemplate("NFD=%1", BasicCourseAccuracy));
	
EndProcedure

// Sets up the format for editing the course accuracy in the payment decryption column as a list
//
// Parameters:
//  Form - ClientApplicationForm - shape. 
//
Procedure SetDesignAccuracyOfCourse(Form) Export
	
	BasicCourseAccuracy = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
	
	CurrencyOfComplianceAccounting = Form.CurrencyOfComplianceAccounting;
	DocumentCurrency = Form.Object.Currency;
	If DocumentCurrency = CurrencyOfComplianceAccounting Then
		Form.Items.ARAPDetailsExchangeRateNumeratorOfMutualSettlements.EditFormat = StrTemplate("NFD=%1", BasicCourseAccuracy);
	Else
		AllSettlementCurrenciesAreEqualToLocalAccountingCurrency = True;
		For Each DecryptionString In Form.Object.ARAPDetails Do
			If ValueIsFilled(DecryptionString.ARAPCurrency)
				And DecryptionString.ARAPCurrency <> CurrencyOfComplianceAccounting Then
				AllSettlementCurrenciesAreEqualToLocalAccountingCurrency = False;
			EndIf;
		EndDo;
		If AllSettlementCurrenciesAreEqualToLocalAccountingCurrency Then
			Form.Items.ARAPDetailsExchangeRateNumeratorOfMutualSettlements.EditFormat = StrTemplate("NFD=%1", BasicCourseAccuracy);
		Else
			Form.Items.ARAPDetailsExchangeRateNumeratorOfMutualSettlements.EditFormat = "NFD=8";
		EndIf;
	EndIf;
	
EndProcedure

#Region VisibilityOfOperations

// The procedure sets the visibility of the payment card selection in the form.
//
// Parameters:
//	Field - FormField - Form field for selecting the payment form.
//
Procedure SetVisibilityOfPaymentByPaymentCard(Field) Export
	
	If Not GetFunctionalOption("UsePaymentByCards") Then
		
		ListItem = Field.ChoiceList.FindByValue(Enums.PaymentForms.PaymentCard);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
		
		ListItem = Field.ChoiceList.FindByValue("PaymentCard");
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of selecting a receipt operation from another sales register
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure SetVisibilityOfTransferOperationsBetweenCashRegisters(Field) Export
	
	If Not GetFunctionalOption("UseMultipleCashAccounts")
		And Not GetFunctionalOption("UseRetailSales") Then
		
		OperationArray = New Array;
		OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount);
		OperationArray.Add(Enums.BusinessTransactions.CashIssueToAnotherCashAccount);
		
		For Each BusinessOperation In OperationArray Do
			ListItem = Field.ChoiceList.FindByValue(BusinessOperation);
			If ListItem <> Undefined Then
				Field.ChoiceList.Delete(ListItem);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure sets visibility for selecting a transfer operation to another account
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure SetVisibilityOfTransferOperationsToAnotherAccount(Field) Export
	
	If Not GetFunctionalOption("UseMultipleBankAccounts") Then
		
		OperationArray = New Array;
		OperationArray.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount);
		OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromAnotherAccount);
		
		For Each BusinessOperation In OperationArray Do
			ListItem = Field.ChoiceList.FindByValue(BusinessOperation);
			If ListItem <> Undefined Then
				Field.ChoiceList.Delete(ListItem);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the selection of operations with cash registers in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure SetVisibilityOfOperationsWithCashRegisterCashRegisters(Field) Export
	
	If Not GetFunctionalOption("UseRetailSales") Then
		
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.CashIssueToCashRegister);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
		
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.CashReceiptFromCashRegister);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the selection of payment operations for DS to another organization in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfTransferOperationsBetweenOrganizations(Field) Export
	
	If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		
		OperationArray = New Array;
		OperationArray.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
		OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
		OperationArray.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
		OperationArray.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
		
		For Each BusinessOperation In OperationArray Do
			ListItem = Field.ChoiceList.FindByValue(BusinessOperation);
			If ListItem <> Undefined Then
				Field.ChoiceList.Delete(ListItem);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the selection operations of the internal transmission of the DS in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfInternalTransferOperations(Field) Export
	
	If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the choice of payment operations for DS under loan and Deposit agreements.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfTransactionsUnderLoanAndDepositAgreements(Field) Export
	
	If Not GetFunctionalOption("UseLoanAndDepositContracts") Then
		
		OperationArray = New Array;
		OperationArray.Add(Enums.BusinessTransactions.CashIssueAsLoanToCounterparty);
		OperationArray.Add(Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived);
		OperationArray.Add(Enums.BusinessTransactions.TransferToDeposits);
		OperationArray.Add(Enums.BusinessTransactions.RevaluationOfFinancialInstruments);
		OperationArray.Add(Enums.BusinessTransactions.CashReceiptUnderDeposits);
		OperationArray.Add(Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty);
		OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromLoansRepayment);
		
		For Each BusinessOperation In OperationArray Do
			ListItem = Field.ChoiceList.FindByValue(BusinessOperation);
			If ListItem <> Undefined Then
				Field.ChoiceList.Delete(ListItem);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the "currency Conversion" operation selection in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure SetVisibilityOfCurrencyConversionCashOperation(Field) Export
	
	If Not GetFunctionalOption("UseMultipleCurrencies")
		Or Not GetFunctionalOption("UseMultipleCashAccounts") Then
		
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.CurrencyConversion);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the "currency Conversion" operation selection in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure SetVisibilityOfCurrencyConversionNonCashOperation(Field) Export
	
	If Not GetFunctionalOption("UseMultipleCurrencies")
		Or Not GetFunctionalOption("UseMultipleBankAccounts") Then
		
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.CurrencyConversion);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the "currency Conversion" operation selection in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure SetVisibilityOfCurrencyConversionOperation(Field) Export
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.CurrencyConversion);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the selection operations salary in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure SetVisibilityOfSalaryOperation(Field) Export
	
	If GetFunctionalOption("BaseVersion") Then
		
		ArrayOfSalaryOperations = New Array;
		ArrayOfSalaryOperations.Add(Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
		ArrayOfSalaryOperations.Add(Enums.BusinessTransactions.SalaryPaymentByDistributor);
		ArrayOfSalaryOperations.Add(Enums.BusinessTransactions.SalaryPaymentToEmployee);
		ArrayOfSalaryOperations.Add(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
		ArrayOfSalaryOperations.Add(Enums.BusinessTransactions.SalaryPaymentToBankAccounts);
		ArrayOfSalaryOperations.Add(Enums.BusinessTransactions.SalaryPayment);
		ArrayOfSalaryOperations.Add(Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts);
		
		For Each Item In ArrayOfSalaryOperations Do
			ListItem = Field.ChoiceList.FindByValue(Item);
			If ListItem <> Undefined Then
				Field.ChoiceList.Delete(ListItem);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the selection of acquiring operations in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfAcquiringOperations(Field) Export
	
	If Not GetFunctionalOption("UsePaymentByCards") Then
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.RefundAcquiringPayment);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the selection of operations for issuing and repaying loans to employees in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfOperationsToLoansToEmployees(Field) Export
	
	LoanOperationsAreAvailable = Not GetFunctionalOption("TradeManagement");

	If Not LoanOperationsAreAvailable Then
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.CashIssueAsLoanToEmployee);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.LoanRepaymentByEmployee);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of the operation selection "Prochaetodermatidae" in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfOperationOtherCashFlow(Field) Export
	
	If Not GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")
		And Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.OtherCashReceipt);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of selecting the operation "other non-monetary funds" in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfOperationOtherCashDisbursement(Field) Export
	
	If Not GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")
		And Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.OtherCashIssue);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets visibility for selecting the "Payment to landlord" operation in the form.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfPaymentToLandlordOperation(Field) Export
	
	UseTheLease = False;
	UseTheLease = NonCurrentAssets.VNAManagementIsUsed();
	If Not UseTheLease Then
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.PaymentToLessor);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
		ListItem = Field.ChoiceList.FindByValue(Enums.BusinessTransactions.RefundFromLessor);
		If ListItem <> Undefined Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

// The procedure sets the header of the "payment Amount" column.
//
// Parameters:
//    Currency - CatalogRef.Currencies - The document currency
//    Items - FormAllItems - Collection of managed form elements
//    ElementsToChange - Array - Names of form elements to change the title
//
Procedure SetPaymentAmountHeader(Currency, Items, ElementsToChange = Undefined) Export
	
	FormItem = Items.ARAPDetailsSum; // FormField
	FormItem.Title = StrTemplate(NStr("vi = 'Số tiền (%1)';
										|ru = 'Сумма (%1)';
										|en = 'Amount (%1)'; fa = 'Amount (%1)';
										|it = 'Totale (%1)';
										|pl = 'Wartość (%1)';
										|tr = 'Tutar (%1)'"), String(Currency));
	
	If Items.Find("ARAPDetailsVATAmount") <> Undefined Then
		FormItem = Items.ARAPDetailsVATAmount; // FormField
		FormItem.Title = StrTemplate(NStr("vi = 'Số tiền thuế GTGT ( %1)';
											|ru = 'Сумма НДС (%1)';
											|en = 'VAT amount (%1)'; fa = 'VAT amount (%1)';
											|it = 'Importo IVA (%1)';
											|pl = 'Wartość podatku VAT (%1)';
											|tr = 'KDV tutarı (%1)'"), String(Currency));
	EndIf;
	
	If ElementsToChange <> Undefined And TypeOf(ElementsToChange) = Type("Array") Then
		For Each FormItem In ElementsToChange Do
			FormItem = Items[FormItem]; // FormField
			FormItem.Title = StrTemplate(NStr("vi = 'Số tiền (%1)';
												|ru = 'Сумма (%1)';
												|en = 'Amount (%1)'; fa = 'Amount (%1)';
												|it = 'Totale (%1)';
												|pl = 'Wartość (%1)';
												|tr = 'Tutar (%1)'"), String(Currency));
		EndDo;
	EndIf;
	
EndProcedure

// The procedure sets the selection parameters for the checkout.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	CashRegisterElement - FormField - Field for entering the sales register.
//
Procedure SetParametersForSelectingCashRegister(Object, CashRegisterElement) Export
	
	If ValueIsFilled(Object.Organization) Then

		If Not ValueIsFilled(Object.CashAccount) Or OrderSpecifiedInPaymentDecryption(Object) Then
			WeNeedSelectionByOrganization = True;
		ElsIf Object.Property("PaymentRequest")
			And ValueIsFilled(Object.PaymentRequest) Then
			WeNeedSelectionByOrganization = True;
		Else
			WeNeedSelectionByOrganization = False;
		EndIf;
		
		ParametersArray = New Array;
		If WeNeedSelectionByOrganization Then
			ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Object.Organization"));
		EndIf;
		CashRegisterElement.ChoiceParameterLinks = New FixedArray(ParametersArray);
	Else
		CashRegisterElement.ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;
	
	ParametersArray = New Array;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ParametersArray.Add(New ChoiceParameter("Filter.Owner",
			New FixedArray(Catalogs.Companies.ArrayOfInterconnectedOrganizations())));
	EndIf;
	
	CashRegisterElement.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

// The procedure sets the selection parameters for the Bank account.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	BankAccountElement - FormField - Field for entering a Bank account.
//
Procedure SetBankAccountSelectionParameters_(Object, BankAccountElement) Export
	
	VisibilityOfFilterByOrganization = True;
	IncludeBranchAccounts = True;
	OnlyCompaniesWithBranches = False;
	
	If ValueIsFilled(Object.Organization) Then
		BankAccountElement.ChoiceParameterLinks = New FixedArray(
			CommonClientServer.ValueInArray(New ChoiceParameterLink("Filter.Owner", "Object.Organization")));
	Else
		BankAccountElement.ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;
	
	If Object.Property("PaymentRequest")
		And ValueIsFilled(Object.PaymentRequest) Then
		VisibilityOfFilterByOrganization = False;
	EndIf;
	
	ParametersArray = New Array;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		OnlyCompaniesWithBranches = True;
		VisibilityOfFilterByOrganization = False;
		ParametersArray.Add(New ChoiceParameter("Filter.Owner", Catalogs.Companies.EmptyRef()));
		BankAccountElement.ChoiceParameterLinks = New FixedArray(New Array);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SalaryPayment
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee Then
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization)));
	EndIf;
	
	If ValueIsFilled(Object.BankAccount) Then
		
		If Common.ObjectAttributeValue(Object.BankAccount, "IsFolder") Then
		
			NewSelectionOption = New ChoiceParameter("Filter.Parent", Object.BankAccount);
			ParametersArray.Add(NewSelectionOption);
			Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		
		EndIf;
		
	EndIf;
	
	ParametersArray.Add(New ChoiceParameter("VisibilityOfFilterByOrganization", VisibilityOfFilterByOrganization));
	ParametersArray.Add(New ChoiceParameter("IncludeBranchAccounts", IncludeBranchAccounts));
	ParametersArray.Add(New ChoiceParameter("OnlyCompaniesWithBranches", OnlyCompaniesWithBranches));
	
	BankAccountElement.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure // Set the parameters of the Bank Account selection()

// This procedure sets the selection parameters for the recipient's Bank account.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	Item - FormField - Field for entering a Bank account.
//	CurrencySelection_2 - Boolean - indicates that the selection has been completed by currency.
//
Procedure SetParametersForSelectingRecipientSBankAccount(Object, Item, CurrencySelection_2 = True) Export
	
	ArrayOfParameterRelationships = New Array;
	ChoiceParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ArrayOfParameterRelationships.Add(New ChoiceParameterLink("Filter.CashCurrency", "Object.CurrencyOfConversion"));
	Else
		If CurrencySelection_2
			And (Not Object.Property("AmountPlanning")
			Or Object.Property("AmountPlanning") And Object.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InPaymentCurrency) Then
			ArrayOfParameterRelationships.Add(New ChoiceParameterLink("Filter.CashCurrency", "Object.Currency"));
		EndIf;
	EndIf;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
		
		If Object.Property("CompanyRecipient") And ValueIsFilled(Object.CompanyRecipient) Then
			ArrayOfParameterRelationships.Add(New ChoiceParameterLink("Filter.Owner", "Object.CompanyRecipient"));
		Else
			CompaniesList = New ValueList;
			OrganizationSelectionParameters = New Structure;
			OrganizationSelectionParameters.Insert("ModeForSelectingRelatedOrganizations", "JustNotInterconnected");
			OrganizationSelectionParameters.Insert("Organization", Object.Organization);
			OrganizationSelectionParameters.Insert("SearchString", Undefined);
			StandardProcessing = False;
			CompaniesServerCall.OrganizationsProcessingSelectionDataAcquisition(CompaniesList, OrganizationSelectionParameters, StandardProcessing);
			
			ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner", New FixedArray(CompaniesList.UnloadValues())));
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount Then
		ArrayOfParameterRelationships.Add(New ChoiceParameterLink("Filter.Owner", "Object.Organization"));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ArrayOfParameterRelationships.Add(New ChoiceParameterLink("Filter.Owner", "Object.Organization"));
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner",
			New FixedArray(Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization))));
	EndIf;
	
	Item.ChoiceParameterLinks = New FixedArray(ArrayOfParameterRelationships);
	Item.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure // Set the parameters for selecting the recipient's Bank account()

// The procedure sets the selection parameters for the partner.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	PartnerElement - FormField - Field for entering the partner.
//
Procedure SetPartnerSelectionParameters(Object, PartnerElement) Export
	
	ParametersArray = New Array;
	ArrayOfLinks = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
	Then
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or Object.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
		Or Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor Then
		
		ParametersArray.Add(New ChoiceParameter("Filter.OtherRelations", True));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue
		Or Object.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		And Object.Property("OperationWithSelfEmployedPerson")
		And Object.OperationWithSelfEmployedPerson
		And Object.Property("ListOfCounterparties_")
		And Object.ListOfCounterparties_ Then
		ArrayOfLinks.Add(New ChoiceParameterLink(
			"Counterparty", "Items.ARAPDetails.CurrentData.Counterparty", LinkedValueChangeMode.DontChange));
	Else
		ArrayOfLinks.Add(
			New ChoiceParameterLink("Counterparty", "Object.Counterparty", LinkedValueChangeMode.DontChange));
	EndIf;
	
	PartnerElement.ChoiceParameters = New FixedArray(ParametersArray);
	PartnerElement.ChoiceParameterLinks = New FixedArray(ArrayOfLinks);
	
EndProcedure // Set the Partner Selection parameter()

// The procedure sets the selection parameters for the counterparty's Bank account.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	Item - FormField - Field for entering the counterparty's bank account.
//
Procedure SetParametersForSelectingCounterpartySBankAccount(Object, Item) Export
	
	ParametersArray = New Array;
	
	If TypeOf(Object.Ref) = Type("DocumentRef.BankAccountIssue") Then
		
		ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
		Documents.BankAccountIssue.FillInNamesOfBusinessTransactionDetails(
			Object, ArrayOfAllProps, ArrayOfOperationDetails);
		
		If ArrayOfOperationDetails.Find("PaymentWithConversion") = Undefined
			Or Object.OperationWithSelfEmployedPerson Then
			ParametersArray.Add(New ChoiceParameterLink("Filter.CashCurrency", "Object.Currency"));
		EndIf;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
		Or Object.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Object.AdvanceHolder"));
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		
		If Object.TransferToEmployeeViaABank Then
			ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Object.Counterparty"));
		Else
			ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Object.AdvanceHolder"));
		EndIf;
		
	Else
		ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Object.Counterparty"));
	EndIf;
	
	ChoiceParametersArray = New Array;
	ChoiceParameter = New ChoiceParameter("Filter.Closed", False);
	ChoiceParametersArray.Add(ChoiceParameter);
	
	Item.ChoiceParameterLinks = New FixedArray(ParametersArray);
	Item.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

// The procedure sets the selection parameters for a request to spend money.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	ApplicationElement - FormField - Field for entering a request for spending money.
//
Procedure SetApplicationSelectionParameters(Object, ApplicationElement) Export
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
	ParametersArray.Add(New ChoiceParameterLink("Filter.Currency", "Object.Currency"));
	
	ChoiceParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then
		
		ParametersArray.Add(New ChoiceParameterLink("Filter.PayrollTransaction", "Object.BusinessOperation",
			LinkedValueChangeMode.DontChange));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor
		Or  Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee Then
		
		ChoiceParameter = New ChoiceParameter("Filter.PayrollTransaction",
			Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
		ChoiceParametersArray.Add(ChoiceParameter);
		
	Else
		ParametersArray.Add(New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation",
			LinkedValueChangeMode.DontChange));
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		
		If Object.Property("ListOfCounterparties_") Then
			
			ParametersArray.Add(New ChoiceParameterLink("ListOfCounterparties_", "Object.ListOfCounterparties_"));
			
			If Object.ListOfCounterparties_ Then
				ParametersArray.Add(
					New ChoiceParameterLink("Counterparty", "Items.ARAPDetails.CurrentData.Counterparty"));
			Else
				ParametersArray.Add(
					New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.DontChange));
			EndIf;
			
		Else
			ParametersArray.Add(
				New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.DontChange));
			ChoiceParametersArray.Add(New ChoiceParameter("ListOfCounterparties_", False));
		EndIf;
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		Or Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or Object.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or Object.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		Or Object.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits Then
		ParametersArray.Add(
			New ChoiceParameterLink("Counterparty", "Object.Counterparty", LinkedValueChangeMode.DontChange));
	EndIf;
	
	ListOfAccountablePersons = New Array;
	ListOfAccountablePersons.Add(Undefined);
	
	If Object.Property("PersonsList")
		And Object.PersonsList Then
		
		For Each TableRow In Object.PersonalAccountsOfStaff Do
			ListOfAccountablePersons.Add(TableRow.Individual);
		EndDo;
		
	ElsIf CommonClientServer.HasAttributeOrObjectProperty(Object, "AdvanceHolder") Then
		ListOfAccountablePersons.Add(Object.AdvanceHolder);
	EndIf;
	
	ChoiceParametersArray.Add(New ChoiceParameter("AdvanceHolder", ListOfAccountablePersons));
	
	ListOfPaymentForms = New Array;
	
	If TypeOf(Object.Ref) = Type("DocumentRef.BankAccountIssue") Then
		
		If GetFunctionalOption("RFPaymentsSupport") Then
			ListOfPaymentForms = CashClientServerLocalization.FormsOfPaymentForApplicationsForNonCashPayment();
		Else
			ListOfPaymentForms.Add(Enums.PaymentForms.BankAccountPayment);
		EndIf;
		
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.PaymentMethod", ListOfPaymentForms));
		ParametersArray.Add(
			New ChoiceParameterLink("BankAccountCashAccount", "Object.BankAccount", LinkedValueChangeMode.DontChange));
		
		If Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
			Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			ParametersArray.Add(
				New ChoiceParameterLink("BankAccountBeneficiary", "Object.BankAccountBeneficiary", LinkedValueChangeMode.DontChange));
		EndIf;
		
		ParametersArray.Add(New ChoiceParameterLink("Filter.OperationWithSelfEmployedPerson", "Object.OperationWithSelfEmployedPerson"));
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CashVoucher") Then
		
		ListOfPaymentForms.Add(Enums.PaymentForms.CashAccountPayment_);
		
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.PaymentMethod", ListOfPaymentForms));
		ParametersArray.Add(
			New ChoiceParameterLink("BankAccountCashAccount", "Object.CashAccount", LinkedValueChangeMode.DontChange));
		
		If Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
			Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			ParametersArray.Add(
				New ChoiceParameterLink("CashAccountRecipient", "Object.CashAccountRecipient", LinkedValueChangeMode.DontChange));
		EndIf;
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.PaymentCardTransaction") Then
		
		ListOfPaymentForms.Add(Enums.PaymentForms.PaymentCard);
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.PaymentMethod", ListOfPaymentForms));
		
	EndIf;
	
	ChoiceParametersArray.Add(New ChoiceParameter("OnlyBalance", Not Object.Posted));
	
	ApplicationElement.ChoiceParameterLinks = New FixedArray(ParametersArray);
	ApplicationElement.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		
		TypesOfApplications = New Array;
		
		If GetFunctionalOption("UsePaymentRequests") Then
			TypesOfApplications.Add("DocumentRef.PaymentRequest");
		EndIf;
		
		If GetFunctionalOption("UseApplicationsForBusinessTrip") Then
			TypesOfApplications.Add("DocumentRef.ApplicationForBusinessTrip");
		EndIf;
		
		If TypesOfApplications.Count() <> 0 Then
			ApplicationElement.TypeRestriction = New TypeDescription(StrConcat(TypesOfApplications, ","));
		EndIf;
		
	Else
		ApplicationElement.TypeRestriction = New TypeDescription("DocumentRef.PaymentRequest");
	EndIf;
	
EndProcedure

// The procedure sets the selection parameters and the relationship of the selection parameters for the "Issuance Document 
// " field of the "Receipt of non-cash funds" document.
// 
// Parameters:
//	Object - FormDataStructure - Current object
//	WriteOffElement - FormField - The "Issuance document" field for entering the write-off of funds, 
//	or an expenditure cash order.
//
Procedure SetParametersForDebitingFunds(Object, WriteOffElement) Export
	
	ParametersArray = New Array;
	
	ChoiceParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts Then
		
		OperationArray = New Array;
		OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentToBankAccounts);
		
		ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", New FixedArray(OperationArray));
		
		ParametersArray.Add(New ChoiceParameterLink("Filter.BankAccount", "Object.BankAccount"));
		ChoiceParametersArray.Add(ChoiceParameter);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram Then
		
		OperationArray = New Array;
		OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
		OperationArray.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder);
		
		ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", New FixedArray(OperationArray));
		
		ParametersArray.Add(New ChoiceParameterLink("Filter.BankAccount", "Object.BankAccount"));
		ChoiceParametersArray.Add(ChoiceParameter);
		
	Else
		
		ParametersArray.Add(New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.CurrencyOfConversion", "Object.Currency"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.AdvanceHolder", "Object.AdvanceHolder"));
	EndIf;
	
	ChoiceParameter = New ChoiceParameter("Filter.DeletionMark", False);
	ChoiceParametersArray.Add(ChoiceParameter);
	
	WriteOffElement.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	WriteOffElement.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

// The procedure sets the selection parameters for the cash flow item.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	ItemArticle - FormField - Field for entering the cash flow item.
//
Procedure SetParametersForSelectingCashFlowItems(Object, ItemArticle) Export
	
	ParametersArray = New Array;
	If Object.BusinessOperation = Enums.BusinessTransactions.SalaryPayment Then
		ParametersArray.Add(
			New ChoiceParameterLink("Filter.BusinessOperation", "Object.PayrollTransaction",
				LinkedValueChangeMode.DontChange));
	Else
		ParametersArray.Add(New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation"));
	EndIf;
	ItemArticle.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

// The procedure sets the selection parameters for the expense item
//
// Parameters:
//	Object - FormDataStructure - Current object
//	Item - FormField - Field for entering the expense item.
//
Procedure SetParametersForSelectingExpenseItem_(Object, Item) Export
	
	ChoiceParametersArray = New Array;
	
	If (TypeOf(Object["Ref"]) = Type("DocumentRef.BankAccountIssue")
			Or TypeOf(Object["Ref"]) = Type("DocumentRef.PaymentRequest"))
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		
		ChoiceParameter = New ChoiceParameter("AddItemsOfAssetsLiabilities", True);
		ChoiceParametersArray.Add(ChoiceParameter);
	Else
		
		ChoiceParameter = New ChoiceParameter("AddExpenseItems", True);
		ChoiceParametersArray.Add(ChoiceParameter);
		ChoiceParameter = New ChoiceParameter("AddItemsOfAssetsLiabilities", True);
		ChoiceParametersArray.Add(ChoiceParameter);
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

// The procedure sets the parameters for selecting a loan agreement(Deposit, loan)
// and clears the loan agreement (Deposit, loan) that does not correspond to the current business operation or organization.
//
// Parameters:
//	Object - FormDataStructure - Current object
//  PaymentDecryptionAgreementElement - FormField - Field for entering the loan agreement (Deposit)
//  ClearAgreements - Boolean - If true then clear in tab.the parts of the payment transcript of the loan agreement (Deposit) 
//								that do not correspond to the current business transaction.
//
Procedure SetParametersForSelectingLoanDepositAgreement(Object, PaymentDecryptionAgreementElement, ClearAgreements = True) Export
	
	ContractKind = Catalogs.LoanAndDepositContracts.NatureOfTransactionAgreement(Object.BusinessOperation);
	If ContractKind = Undefined Then// this is not a credit/deposit farm.operation
		Return;
	EndIf;
	
	// Let's define the selection parameters
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark",False));
	ParametersArray.Add(New ChoiceParameter("Filter.ContractKind", ContractKind));
	If Not Object.Counterparty.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", Object.Counterparty));
	EndIf;
	
	If ValueIsFilled(Object.Organization) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
	EndIf;
	
	// Let's set the selection parameters
	PaymentDecryptionAgreementElement.ChoiceParameters = New FixedArray(ParametersArray);
	
	// Let's define the relationship of the selection parameters
	ArrayOfLinks = New Array;
	ClearContract = LinkedValueChangeMode.Clear;
	If Not Object.Organization.IsEmpty() Then
		ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization", ClearContract));
	EndIf;
	If Not Object.Counterparty.IsEmpty() Then
		ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Counterparty","Object.Counterparty", ClearContract));
		Partners = Object.ARAPDetails.Unload().UnloadColumn("Partner");
		If Partners.Count() > 0 And ValueIsFilled(Partners[0]) Then
			ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Partner","Items.ARAPDetails.CurrentData.Partner", ClearContract));
		EndIf;
	EndIf;
	PaymentDecryptionAgreementElement.ChoiceParameterLinks = New FixedArray(ArrayOfLinks);

	// We will clear the contracts that do not correspond to the current business operation
	If ClearAgreements Then
		ArrayOfContracts = Object.ARAPDetails.Unload().UnloadColumn("LoanDepositContract");
		ContractDetails_1 = Common.ObjectsAttributesValues(ArrayOfContracts, "Organization,ContractKind");
		If ContractDetails_1.Count() > 0 Then
			For Each TableRow In Object.ARAPDetails Do
				If Not ValueIsFilled(TableRow.LoanDepositContract) Then
					Continue;
				EndIf;
				If ContractDetails_1[TableRow.LoanDepositContract].Organization <> Object.Organization
					Or ContractDetails_1[TableRow.LoanDepositContract].ContractKind <> ContractKind Then
					TableRow.LoanDepositContract = Undefined;
					TableRow.CashFlowItem = Undefined;
				EndIf;
			EndDo;
		EndIf;// there is something to clean up
	EndIf;// It is necessary to clear the loan (deposit) agreements
	
EndProcedure

// Sets the parameters for selecting and linking the selection parameters for the "Contract for connecting to the payment system" field.
// 
// Parameters:
//  Object - FormDataStructure - the document in which the parameters are being set.
//  Item - FormField - the field for which the parameters are being set.
//
Procedure SetParametersForChoosingAcquiringAgreement(Object, Item) Export

	ArrayOfLinks = New Array;
	
	If ValueIsFilled(Object.Organization) Then
	
		NewLink = New ChoiceParameterLink("Filter.Organization", "Object.Organization");
		ArrayOfLinks.Add(NewLink);
	
	EndIf;
	
	LinksOfChoice = New FixedArray(ArrayOfLinks);
	Item.ChoiceParameterLinks = LinksOfChoice;
	
	ParametersArray = New Array;
	
	NewParameter1 = New ChoiceParameter("Filter.DeletionMark", False);
	ParametersArray.Add(NewParameter1);
	
	NewParameter1 = New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid);
	ParametersArray.Add(NewParameter1);
	
	ChoiceParameters = New FixedArray(ParametersArray);
	Item.ChoiceParameters = ChoiceParameters;
	
EndProcedure

// The procedure sets the selection parameters for the VAT rate.
//
// Parameters:
//	Object - FormDataStructure - Cur current object
//	The Partner - Form field element is a field for entering a partner.
//
Procedure EstablishLinksBetweenVATRateSelectionParameters(Object, ElementVATRate) Export
	
	ArrayOfLinks = New Array;
	
	ArrayOfLinks.Add(New ChoiceParameterLink(
			"Organization", "Object.Organization", LinkedValueChangeMode.DontChange));
	
	ArrayOfLinks.Add(New ChoiceParameterLink(
			"VATTaxation", "Items.ARAPDetails.CurrentData.VATTaxation", LinkedValueChangeMode.DontChange));
	
	ElementVATRate.ChoiceParameterLinks = New FixedArray(ArrayOfLinks);
	
EndProcedure

// Procedure list for selecting the types of amounts for the current business transaction.
//
// Parameters:
//	List - ValueList - form element selection list
//  BusinessTransaction - EnumRef.BusinessTransactions - current business operation.
//
Procedure FillInListOfTypesOfAmountsOfLoansDeposits(List, BusinessTransaction) Export
	
	TypesOfAmounts = Enums.LoanAndDepositScheduleAmountTypes;
	List.Clear();
	List.Add(TypesOfAmounts.PrincipalDebt);
	List.Add(TypesOfAmounts.Interests);
	If BusinessTransaction = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived Then
		List.Add(TypesOfAmounts.Fee);
	EndIf;
	
EndProcedure

// Fills in the organization of the owner of the calculation object in the table part.
//
// Parameters:
//  TabularSection - TabularSection - The payment description must contain the "Order" and "Organization" fields"
//  Organization - CatalogRef.Companies - Organization of the document
//  BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//
Procedure FillInOrganizationInTableSection(TabularSection, Organization, BusinessOperation) Export
	
	Query = New Query("
	|SELECT
	|	ARAPObjects.Organization AS Organization,
	|	ARAPObjects.Ref AS ARAPObject
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Ref IN (&ArrayOfCalculationObjects_)");
	Query.SetParameter("ArrayOfCalculationObjects_", TabularSection.UnloadColumn("ARAPObject"));
	CompanyTable = Query.Execute().Unload();
	CompanyTable.Indexes.Add("ARAPObject");
	
	For Each TSRow In TabularSection Do
		TheStructureOfTheSearch = New Structure("ARAPObject", TSRow.ARAPObject);
		
		RowsOfOrganizations = CompanyTable.FindRows(TheStructureOfTheSearch);
		If RowsOfOrganizations.Count() = 1 Then
			TSRow.Organization = RowsOfOrganizations[0].Organization;
		Else
			TSRow.Organization = Organization;
		EndIf;
	EndDo;
	
EndProcedure

// Adds the selection parameters to the list of selection parameters according to the list of business operations.
// 
// Parameters:
//  ChoiceParameters - Array of ChoiceParameter - list of selection parameters.
//  BusinessTransactions - Array of EnumRef.BusinessTransactions - list of business operations.
//
Procedure AddListOfBusinessOperationsToSelectionParameters(ChoiceParameters, BusinessTransactions) Export

	If BusinessTransactions.Count() > 1 Then
			
		ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", BusinessTransactions);
		ChoiceParameters.Add(ChoiceParameter);
			
	ElsIf BusinessTransactions.Count() = 1 Then
			
		ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", BusinessTransactions[0]);
		ChoiceParameters.Add(ChoiceParameter);
			
	EndIf;

EndProcedure

// Fills in the "Counterparty" column in the "Payment decryption" tabular part of the document if the document does not use 
// a list of counterparties.
// 
// Parameters:
//  DocumentObject - DocumentObject.PaymentRequest,
//                   Document object.Write-off of non-cash funds - The document in which the filling is performed.
//  TabularSection - TabularSection - the tabular part of the document.
//
Procedure FillInCounterpartyOfPaymentDecryptionWithoutListOfCounterparties(DocumentObject, TabularSection) Export

	If Not DocumentObject.ListOfCounterparties_ Then
		
		For Each TableRow In TabularSection Do
			TableRow.Counterparty = DocumentObject.Counterparty;
		EndDo;
		
	EndIf;

EndProcedure

// Generates and displays a list of applications specified in the payment document
//
// Parameters:
//  Form - ClientApplicationForm - The Form of the payment document.
//  ManagerOfDocument - DocumentManager.CashVoucher, DocumentManager.BankAccountIssue -
//                      document manager.
//
Procedure DisplayInformationOnApplications(Form, ManagerOfDocument) Export

	Items = Form.Items;
	Object = Form.Object;
	
	Form.RequestList.Clear();
	
	ArrayOfOperationDetails = New Array;
	
	ManagerOfDocument.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("ARAPDetails.PaymentRequest") <> Undefined Then
	
		For Each CurRow In Object.ARAPDetails Do
			If ValueIsFilled(CurRow["PaymentRequest"])
				And Form.RequestList.FindByValue(CurRow["PaymentRequest"]) = Undefined Then
				Form.RequestList.Add(CurRow["PaymentRequest"]);
			EndIf;
		EndDo;
	
	EndIf;
	
	If ArrayOfOperationDetails.Find("PaymentRequest") <> Undefined
		And ValueIsFilled(Object.PaymentRequest)
		And Form.RequestList.FindByValue(Object.PaymentRequest) = Undefined Then
		Form.RequestList.Add(Object.PaymentRequest);
	EndIf;
	
	If Form.RequestList.Count() > 1 Then
		Form.TextApplicationHeader = NStr("vi = 'Tổng số trong giấy đề nghị';
											|ru = 'Всего заявок';
											|en = 'Total applications'; fa = 'Total applications';
											|it = 'Всего заявок';
											|pl = 'Razem wniosków';
											|tr = 'Toplam başvuru'") + ": " + Form.RequestList.Count();
		Items.PaymentByRequests.Title = NStr("vi = 'Thanh toán theo giấy đề nghị';
											|ru = 'Оплата по заявкам';
											|en = 'Payment by requests'; fa = 'پرداخت بر اساس درخواست‌ها';
											|it = 'Оплата по заявкам';
											|pl = 'Płatność na podstawie wniosków';
											|tr = 'Taleplere ilişkin ödeme'");
	ElsIf Form.RequestList.Count() = 1 Then
		Form.TextApplicationHeader = Form.RequestList[0].Value;
		Items.PaymentByRequests.Title = NStr("vi = 'Thanh toán theo giấy đề nghị';
											|ru = 'Оплата по заявке';
											|en = 'Payment under request'; fa = 'Payment under request';
											|it = 'Оплата по заявке';
											|pl = 'Płatność na podstawie wniosku';
											|tr = 'Talebe ilişkin ödeme'");
	Else
		Form.TextApplicationHeader = "";
		Items.PaymentByRequests.Title = NStr("vi = 'Thanh toán theo giấy đề nghị';
											|ru = 'Оплата по заявке';
											|en = 'Payment under request'; fa = 'Payment under request';
											|it = 'Оплата по заявке';
											|pl = 'Płatność na podstawie wniosku';
											|tr = 'Talebe ilişkin ödeme'");
	EndIf;

EndProcedure

// Fills in the "Partner" column in the tabular part of the "Payment decryption" document.
// 
// Parameters:
//  DocumentObject - DocumentObject.PaymentRequest,
//                   Document object.Write-off of non-cash funds - The document in which the filling is performed.
//  TabularSection - TabularSection - the tabular part of the document.
//
Procedure FillInPaymentTranscriptForm(DocumentObject, TabularSection) Export

	CounterpartiesTable = TabularSection.Unload(, "Counterparty");
	CounterpartiesTable.GroupBy("Counterparty");
	
	QueryResult = ResultOfRequestIsCounterpartySPartnersForOperation(
		CounterpartiesTable.UnloadColumn("Counterparty"), DocumentObject.BusinessOperation);
	
	SelectionOfPartners = QueryResult.Select();
	
	For Each TableRow In TabularSection Do
		
		If ValueIsFilled(TableRow.Counterparty)
			And Not ValueIsFilled(TableRow.Partner) Then
			
			Filter = New Structure;
			Filter.Insert("Counterparty", TableRow.Counterparty);
			
			If SelectionOfPartners.FindNext(Filter) Then
				TableRow.Partner = SelectionOfPartners.Partner;
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure

// Sets the selection parameters for the "Line of Business" field.
// 
// Parameters:
//  Object - FormDataStructure, ClientApplicationForm - the document in which the parameters are being set.
//  Item - FormField - the field for which the parameters are being set.
//
Procedure SetParametersForSelectingDirectionOfActivity(Object, Item) Export

	ChoiceParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or Object.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.VendorARAP", True));
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.CostAccounting", True));
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(ChoiceParametersArray);

EndProcedure

// Sets the selection parameters and the relationship of the selection parameters for the "Contract" field.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the document in which the parameters are set.
//  Item - FormField - the field for which the parameters are being set.
//
Procedure SetContractSelectionParameters(Form, Item) Export
	
	Object = Form.Object;
	BranchesOfOrganization = Form.BranchesOfOrganization;
	
	ParametersArray = New Array;
	ArrayOfLinks = New Array;
	
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ARAPCurrencies = Object.ARAPDetails.Unload(, "ARAPCurrency");
	
	If ARAPCurrencies.Count() > 0
		And ValueIsFilled(ARAPCurrencies[0].ARAPCurrency) Then
		ArrayOfLinks.Add(
			New ChoiceParameterLink("Filter.ARAPCurrency", "Items.ARAPDetails.CurrentData.ARAPCurrency"));
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		
		ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
		ParametersArray.Add(New ChoiceParameter("Filter.CompanyRecipient", Form.CompanyPayer));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		
		ArrayOfLinks.Add(New ChoiceParameterLink("Filter.CompanyRecipient", "Object.Organization"));
		ParametersArray.Add(New ChoiceParameter("Filter.Organization", Form.CompanyPayer));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		
		ArrayOfLinks.Add(New ChoiceParameterLink("Filter.CompanyRecipient", "Object.Organization"));
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "CompanyRecipient") Then
			ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Organization", "Object.CompanyRecipient"));
		Else
			ParametersArray.Add(New ChoiceParameter("Filter.Organization", Form.CompanyRecipient));
		EndIf;
			
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		
		ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "CompanyRecipient") Then
			ArrayOfLinks.Add(New ChoiceParameterLink("Filter.CompanyRecipient", "Object.CompanyRecipient"));
		Else
			ParametersArray.Add(New ChoiceParameter("Filter.CompanyRecipient", Form.CompanyRecipient));
		EndIf;
		
	Else
		
		CompaniesList = BranchesOfOrganization.UnloadValues();
		
		If CompaniesList.Count() > 0 Then
			CompaniesList.Add(Object.Organization);
			ParametersArray.Add(New ChoiceParameter("Filter.Organization", CompaniesList));
		Else
			ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "ListOfCounterparties_") Then
		
			If Object.ListOfCounterparties_ Then
				ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Counterparty", "Items.ARAPDetails.CurrentData.Counterparty"));
			Else
				ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty"));
			EndIf;
			
		Else
			ArrayOfLinks.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty"));
		EndIf;
		
		If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
			ParametersArray.Add(New ChoiceParameter("Filter.ContractType", ARAPAccountingClientServer.TypesOfContractsWithClient()));
		Else
			ParametersArray.Add(New ChoiceParameter("Filter.ContractType", ARAPAccountingClientServer.TypesOfContractsWithSupplier()));
		EndIf;
		
		
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(ParametersArray);
	Item.ChoiceParameterLinks = New FixedArray(ArrayOfLinks);
	
EndProcedure

// Removes payment Forms that are not available for selection from the default list.
// 
// Parameters:
//  Item - FormField - the "Payment Form" element.
//
Procedure ExcludeUnavailableFormsOfPayment(Item) Export

	AvailableFormsOfPayment = AvailableFormsOfPaymentToChooseFrom();
	
	DeleteList = New Array;
	
	For Each ChoiceItem In Item.ChoiceList Do
		
		If AvailableFormsOfPayment.Find(ChoiceItem.Value) = Undefined Then
			DeleteList.Add(ChoiceItem);
		EndIf;
		
	EndDo;
	
	For Each ItemToDelete In DeleteList Do
		Item.ChoiceList.Delete(ItemToDelete);
	EndDo;

EndProcedure

// Returns a list of payment Forms available for selection.
// 
// Parameters:
//  AnyFormOfPaymentIsUsed - Boolean - Any Form Of Payment Is Used
// 
// Returns:
//  Array of EnumRef.PaymentForms - Available Forms of payment to choose from.
Function AvailableFormsOfPaymentToChooseFrom(AnyFormOfPaymentIsUsed = True) Export

	PaymentForms = New Array;
	PaymentForms.Add(Enums.PaymentForms.CashAccountPayment_);
	PaymentForms.Add(Enums.PaymentForms.BankAccountPayment);
	
	If GetFunctionalOption("UsePaymentByCards") Then
		PaymentForms.Add(Enums.PaymentForms.PaymentCard);
	EndIf;
	
	PaymentForms.Add(Enums.PaymentForms.SettlementOfARAP);
	
	If GetFunctionalOption("UseLoyaltyPrograms") Then
		PaymentForms.Add(Enums.PaymentForms.BonusPoints);
	EndIf;
	
	If GetFunctionalOption("UseGiftCards") Then
		PaymentForms.Add(Enums.PaymentForms.GiftCertificate);
	EndIf;
	
	CashServerLocalization.AddAvailableFormsOfPayment(PaymentForms);
	
	If AnyFormOfPaymentIsUsed Then
		PaymentForms.Add(Enums.PaymentForms.EmptyRef());
	EndIf;
	
	Return PaymentForms;

EndFunction

#EndRegion

#Region DocumentFillingFunctions

// This function determines the partner corresponding to the selected counterparty.
//
// Returns a reference to the partner or Undefined if the partner specified for the counterparty does not meet the selection criteria.
//
// Parameters:
//    Counterparty - CatalogRef.Counterparties - counterparty to find a partner for
//    BusinessOperation - EnumRef.BusinessTransactions - optional restriction on a business transaction.
//
// Returns:
//    CatalogRef.Partners - Partner.
//
Function GetCounterpartyPartner(Counterparty, BusinessOperation = Undefined) Export
	
	QueryResult = ResultOfRequestIsCounterpartySPartnersForOperation(
		CommonClientServer.ValueInArray(Counterparty), BusinessOperation);
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		Partner = Selection.Partner;
	Else
		Partner = Undefined;
	EndIf;
	
	Return Partner;

EndFunction // Get a Partnerapontragenta()

// The procedure fills in the values of the "BIC" and "correspondent Account" fields.
//
// Parameters:
//    Bank - CatalogRef.BankClassifier - Bank
//    BIC - String - Bank branch ID
//    SWIFT - String - Swift Bank
//    CorrAccount - String - Bank's correspondent account.
//
Procedure FillInBeeKeeCorrAccount(Bank, BIC, SWIFT, CorrAccount) Export

	If Not ValueIsFilled(Bank) Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text = "
	|SELECT
	|	Code AS BIC,
	|	SWIFTBIC AS SWIFT,
	|	CorrAccount AS CorrAccount
	|FROM
	|	Catalog.BankClassifier AS Banks
	|WHERE
	|	Banks.Ref = &Ref
	|";
	Query.SetParameter("Ref", Bank);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	If Selection.Next() Then
		BIC = Selection.BIC;
		SWIFT = Selection.SWIFT;
		CorrAccount = Selection.CorrAccount;
	EndIf;

EndProcedure

// The procedure is received by the Bank at the specified BIC or correspondent account.
//
// Parameters:
//	Field - String - Name of the field where the value was selected.
//	Value - String - The value selected in the field.
//	Bank - CatalogRef.BankClassifier - Value of the field for specifying the Bank
//	BIC - String - Bank branch ID
//	CorrAccount - String - Bank's correspondent account.
//
// Returns:
//	ValueList - List of banks for interactive selection.
//
Function GetListOfBanksByBankingDetails(Field, Value, Bank, BIC, CorrAccount) Export

	ListOfBanks = New ValueList;
	
	// If the value is not selected, we will clear the bank value.
	If IsBlankString(Value) Then
	
		Bank = Catalogs.BankClassifier.EmptyRef();
		BIC = "";
		CorrAccount = "";
		
		Return ListOfBanks;
		
	EndIf;
		
	TableOfBanks = New ValueTable;
	Columns = TableOfBanks.Columns;
	Columns.Add("Ref");
	Columns.Add("Code");
	Columns.Add("CorrAccount");
	
	ThisIsBIC = False;
	ThisIsCorrespondentAccount = False;
	If StrFind(Field, "BIC") <> 0 Then
		ThisIsBIC = True;
	ElsIf StrFind(Field, "CorrAccount") <> 0 Then
		ThisIsCorrespondentAccount = True;
	EndIf;
	
	If (ThisIsBIC And StrLen(Value) = 9)
	 Or (ThisIsCorrespondentAccount And StrLen(Value) = 20)
	Then
		
		If ThisIsBIC Then
			FilterStructure1 = New Structure("Code", Value);
			
		ElsIf ThisIsCorrespondentAccount Then
			FilterStructure1 = New Structure("CorrAccount", Value);
			
		EndIf;
		
		Selection = Catalogs.BankClassifier.Select(,, FilterStructure1, "Code Asc");
		While Selection.Next() Do
			NewRow = TableOfBanks.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
				
	EndIf;
	
	If TableOfBanks.Count() = 1 Then
		BankData = TableOfBanks[0];
		
		Bank = BankData.Ref;
		BIC = BankData.Code;
		CorrAccount = BankData.CorrAccount;
		ListOfBanks.Add(Bank);
		
	ElsIf TableOfBanks.Count() > 1 Then
		ArrayOfBanks = TableOfBanks.UnloadColumn("Ref");
		ListOfBanks.LoadValues(ArrayOfBanks);
		
	EndIf;
	
	Return ListOfBanks;
	
EndFunction

// The function places the payment decryption in temporary storage and returns the address.
//
// Parameters:
//    ARAPDetails - TabularSection - Table part of the decryption
//    UUID - String - ID.
//
// Returns:
//    String - the address of the temporary storage.
//
Function PlacePaymentDecryptionInVault(Val ARAPDetails, UUID) Export

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		ARAPDetails.Unload(),
		UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction // Place a ciphercompayment in the vault()

// The procedure fills in the cashier, bank account, Contract for connection to the payment system and POS terminal, depending on the Form of payment of the document.
//
// Parameters:
//	PaymentMethod - EnumRef.PaymentForms - Actual form of payment for the application
//	FillingData - Structure - Data for filling out the document.
//	PaymentCurrency - CatalogRef.Currencies
//
Procedure FillInDetailsOfDocumentOnFormOfPayment(PaymentMethod, FillingData, PaymentCurrency = Undefined) Export
	
	If PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
		
		ParametersStructure = DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization = FillingData.Organization;
		ParametersStructure.PaymentMethod = PaymentMethod;
		ParametersStructure.CashAccount       = FillingData.CashAccount;
		ParametersStructure.Currency      = PaymentCurrency;

		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		If Not ValueIsFilled(CashAccount) Then
			CurrentCashAccount = Common.CommonSettingsStorageLoad("CurrentCashAccount", "");
			If ValueIsFilled(FillingData.Organization) Then
				If FillingData.Organization =
					Catalogs.CashAccounts.GetCheckoutDetails(CurrentCashAccount).Organization
				Then
					CashAccount = CurrentCashAccount;
				EndIf;
			Else
				CashAccount = CurrentCashAccount;
			EndIf;
		EndIf;
		
		If ValueIsFilled(CashAccount) Then
			FillingData.Insert("CashAccount", CashAccount);
			If Not ValueIsFilled(PaymentCurrency) Then
				Currency = Catalogs.CashAccounts.GetCheckoutDetails(CashAccount).Currency;
				FillingData.Insert("Currency", Currency);
			EndIf;
		EndIf;
		
	ElsIf PaymentMethod = Enums.PaymentForms.BankAccountPayment
		Or PaymentMethod = Enums.PaymentForms.InstantPayments Then
		
		ParametersStructure = ParametersForFillingOutOrganizationSBankAccount();
		ParametersStructure.Organization    = FillingData.Organization;
		ParametersStructure.Currency         = PaymentCurrency;
		
		BankAccount = GetOrganizationSDefaultBankAccount(ParametersStructure,
			FillingData.BankAccount, PaymentMethod);
		
		If Not ValueIsFilled(BankAccount) Then
			CurrentBankAccount = Common.CommonSettingsStorageLoad("CurrentBankAccount", "");
			If ValueIsFilled(FillingData.Organization) Then
				If FillingData.Organization =
					Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(CurrentBankAccount).Organization
				Then
					BankAccount = CurrentBankAccount;
				EndIf;
			Else
				BankAccount = CurrentBankAccount;
			EndIf;
		EndIf;
		
		If ValueIsFilled(BankAccount) Then
			FillingData.Insert("BankAccount", BankAccount);
			BankAccountDetails = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
			
			If (FillingData.Property("PaymentWithConversion")
				And Not FillingData.PaymentWithConversion)
				Or Not FillingData.Property("PaymentWithConversion") Then
				
				If Not ValueIsFilled(PaymentCurrency) Then
					Currency = BankAccountDetails.Currency;
					FillingData.Insert("Currency", Currency);
				EndIf;
				
				FillingData.Insert("PaymentWithConversion", DefinePaymentWithConversion(FillingData));
				
			EndIf;
				
			If Not BankAccountDetails.EnableCreatingCashIssueWithoutPaymentRequest
				And GetFunctionalOption("UsePaymentRequests") Then
				FillingData.Insert("PaymentByRequests", True);
			EndIf;
		EndIf;
		
	ElsIf PaymentMethod = Enums.PaymentForms.PaymentCard Then
		
		FilterParameters = Catalogs.AcquiringContracts.ParametersOfAcquisitionContractSelection();
		
		FilterParameters.Organization = FillingData.Organization;
		
		If CommonClientServer.HasAttributeOrObjectProperty(FillingData, "BankAccount") Then
			FilterParameters.BankAccount =
				?(FillingData.BankAccount <> Catalogs.CompaniesBankAccounts.EmptyRef(), FillingData.BankAccount, Undefined);
		EndIf;
		
		AcquiringContract = Catalogs.AcquiringContracts.ContractOfAcquiringByDefault(FilterParameters);
		
		If ValueIsFilled(AcquiringContract) Then
			AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract);
			FillingData.Insert("AcquiringContract", AcquiringContract);
			FillingData.Insert("Currency", AttributesValues.Currency);
			
			POSTerminal = Catalogs.POSTerminals.DefaultPOSTerminal(
				FillingData.Organization, FillingData.AcquiringContract);
			If ValueIsFilled(POSTerminal) Then
				FillingData.Insert("POSTerminal", POSTerminal);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure fills out a document based on requests for spending money.
//
// Parameters:
//	FillingData - Structure - fill-in data
//	TabularSection - TabularSection - tabular part of the document
//	PaymentMethod - EnumRef.PaymentForms - The actual form of payment (depends on the payment document you enter).
//	Document - DocumentRef.BankAccountIssue, DocumentRef.CashVoucher, DocumentRef.PaymentCardTransaction, Undefined - The document to be filled in.
//
Procedure FillOutDocumentOnApplicationsForSpendingMoney(FillingData, TabularSection, PaymentMethod, Document = Undefined) Export
	
	ReferencesArrray = New Array; AmountsPayable = Undefined;
	If TypeOf(FillingData) = Type("DocumentRef.PaymentRequest")
		Or TypeOf(FillingData) = Type("DocumentRef.ApplicationForBusinessTrip") Then
		ReferencesArrray.Add(FillingData);
		BankAccountCashAccount = Undefined;
		PaymentAmount = 0;
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		If TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PaymentRequest")
			Or TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ApplicationForBusinessTrip") Then
			ReferencesArrray.Add(FillingData.DocumentBasis);
		ElsIf TypeOf(FillingData.DocumentBasis) = Type("Array") Then
			ReferencesArrray = FillingData.DocumentBasis;
		EndIf;
		BankAccountCashAccount = FillingData.BankAccountCashAccount;
		PaymentAmount = FillingData.Sum;
		FillingData.Property("AmountsPayable", AmountsPayable);
	EndIf;
	
	RequestingBalances = New Query;
	RequestingBalances.TempTablesManager = New TempTablesManager;
	
	RequestingBalances.SetParameter("ReferencesArrray", ReferencesArrray);
	
	BankAccountsCashAccounts = New Array;
	If ValueIsFilled(BankAccountCashAccount) Then
		BankAccountsCashAccounts.Add(BankAccountCashAccount);
		BankAccountsCashAccounts.Add(Undefined);
		RequestingBalances.SetParameter("BankAccountsCashAccounts", BankAccountsCashAccounts);
		RequestingBalances.SetParameter("DonTLimitYourBankAccountToCheckout", False);
	Else
		RequestingBalances.SetParameter("BankAccountsCashAccounts", BankAccountsCashAccounts);
		RequestingBalances.SetParameter("DonTLimitYourBankAccountToCheckout", True);
	EndIf;
	
	RequestingBalances.SetParameter("Recorder", Document);
	
	RequestingBalances.Text = QueryTextForBalancesToBePaid();
	
	SetPrivilegedMode(True);
	RequestingBalances.Execute();
	SetPrivilegedMode(False);

	QueryText = "
	|SELECT
	|	Request.Organization AS Organization,
	|	CASE
	|		WHEN Request.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment) THEN
	|			Request.PayrollTransaction
	|		ELSE
	|			Request.BusinessOperation
	|	END AS BusinessOperation,
	|	Request.Currency AS Currency,
	|	Request.Currency AS RequestCurrency,
	|	Request.BankAccount AS BankAccount,
	|	Request.CashAccount AS CashAccount,
	|	Request.PaymentPurposes AS PaymentPurposes,
	|	Request.Counterparty AS Counterparty,
	|	CASE WHEN NOT Request.CounterpartyBankAccount.Closed THEN
	|		Request.CounterpartyBankAccount
	|	ELSE
	|		UNDEFINED
	|	END AS CounterpartyBankAccount,
	|	Request.CounterpartyBankAccount.CashCurrency AS CounterpartyBankAccountCurrency,
	|	Request.AdvanceHolder AS AdvanceHolder,
	|	CASE WHEN NOT Request.BankAccountBeneficiary.Closed THEN
	|		Request.BankAccountBeneficiary
	|	ELSE
	|		UNDEFINED
	|	END AS BankAccountBeneficiary,
	|	Request.BankAccountBeneficiary.CashCurrency AS BankAccountRecipientCurrency,
	|	Request.CashAccountRecipient AS CashAccountRecipient,
	|	Request.Department AS Department,
	|	CASE
	|		WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments)
	|			THEN VALUE(Enum.PaymentForms.BankAccountPayment)
	|		ELSE Request.PaymentMethodOfPaymentRequest
	|	END AS PaymentMethodOfPaymentRequest,
	|	Request.CashFlowItem AS CashFlowItem,
	|	Request.CurrencyOfConversion AS CurrencyOfConversion,
	|	Request.ConversionAmount AS ConversionAmount,
	|	Request.ConversionRate AS ConversionRate,
	|	Request.ConversionRateMultiplier AS ConversionRateMultiplier,
	|	Request.AmountPlanning AS AmountPlanning,
	|	Request.PaysheetNumber AS PaysheetNumber,
	|	Request.PaysheetDate AS PaysheetDate,
	|	Request.AssetAndLiabilityItem AS AssetAndLiabilityItem,
	|	Request.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Request.PaymentID AS PaymentID,
	|	Request.ExpenseReportDate AS ExpenseReportDate,
	|	Request.ContractWithSDOParticipant AS ContractWithSDOParticipant,
	|	Request.PaymentsAsPer275FZ AS PaymentsAsPer275FZ,
	|	Request.PaymentType275FZ AS PaymentType275FZ,
	|	Request.BankAccount.StateContract AS StateContract_,
	|	Request.TargetFundItem AS TargetFundItem,
	|	Request.TransferOfTaxesAndContributions AS TransferOfTaxesAndContributions,
	|	Request.TaxType AS TaxType,
	|	Request.PaysheetPersonalIncomeTax AS PaysheetPersonalIncomeTax,
	|	Request.RegistrationWithTaxAuthority AS RegistrationWithTaxAuthority,
	|	Request.KindOfFundsTransferToBudget AS KindOfFundsTransferToBudget,
	|	Request.RNCPSRNCMTCode AS RNCPSRNCMTCode,
	|	Request.BasisIndicator AS BasisIndicator,
	|	Request.PeriodIndicator AS PeriodIndicator,
	|	Request.NumberIndicator AS NumberIndicator,
	|	Request.DateIndicator AS DateIndicator,
	|	Request.TypeIndicator AS TypeIndicator,
	|	Request.AuthorStatus AS AuthorStatus,
	|	Request.BCCode AS BCCode,
	|	Request.IncomeKindCode AS IncomeKindCode,
	|	Request.PaymentCode AS PaymentCode,
	|	Request.AcquiringContract AS AcquiringContract,
	|	Request.RecordCommission AS RecordCommission,
	|	Request.FeeAmount AS FeeAmount,
	|	Request.ExpenseItem AS ExpenseItem,
	|	Request.DimensionOfExpenses AS DimensionOfExpenses,
	|	Request.Department AS ExpensesBusinessUnit,
	|	Request.GLAccountSettings AS GLAccountSettings,
	|	Request.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment) AS ThisIsSalaryPayment,
	|	CASE
	|		WHEN Request.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
	|		THEN
	|			Request.AdvanceHolder.Description
	|		ELSE
	|			CASE
	|				WHEN Request.Counterparty.DescriptionFull <> """" THEN
	|					Request.Counterparty.DescriptionFull
	|				ELSE
	|					Request.Counterparty.Description
	|			END
	|	END AS Issue,
	|	TRUE AS PaymentByRequests,
	|	Request.TINOfPayer AS TINOfPayer,
	|	Request.PayerCRTR AS PayerCRTR,
	|	Request.PayerSName AS PayerSName,
	|	Request.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Request.LineOfBusiness AS LineOfBusiness,
	|	Request.Contract AS Contract,
	|	Request.Ref AS PaymentRequest,
	|	Request.DocumentBasis AS DocumentBasisOfApplication,
	|	Request.DocumentBasis.FPSPaymentID AS FPSPaymentID,
	|	CASE
	|		WHEN Request.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment) THEN
	|			3
	|	END AS RankingInPriorityOfPayment,
	|	Request.TransferFeeType AS TransferFeeType,
	|	Request.InformationToPaymentRecipient AS InformationToPaymentRecipient,
	|	Request.ConditionOfConversionTransaction AS ConditionOfConversionTransaction,
	|	Request.BankAccountForFeeWriteOff AS BankAccountForFeeWriteOff,
	|	Request.VATTaxation AS VATTaxation,
	|	Request.TransferToEmployeeViaABank AS TransferToEmployeeViaABank,
	|	Request.PersonsList AS PersonsList,
	|	Request.PaymentWithConversion AS PaymentWithConversion,
	|	Request.ListOfCounterparties_ AS ListOfCounterparties_,
	|	Request.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson
	|
	|FROM
	|	Document.PaymentRequest AS Request
	|	
	|WHERE
	|	Request.Ref IN (&ReferencesArrray)
	|
	|UNION ALL
	|
	|SELECT
	|	Request.Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AS BusinessOperation,
	|	Request.Currency AS Currency,
	|	Request.Currency AS RequestCurrency,
	|	Request.BankAccount AS BankAccount,
	|	Request.CashAccount AS CashAccount,
	|	"""" AS PaymentPurposes,
	|	UNDEFINED AS Counterparty,
	|	Request.PersonalAccount AS CounterpartyBankAccount,
	|	Request.PersonalAccount.CashCurrency AS CounterpartyBankAccountCurrency,
	|	Request.Employee AS AdvanceHolder,
	|	UNDEFINED AS BankAccountBeneficiary,
	|	UNDEFINED AS BankAccountRecipientCurrency,
	|	UNDEFINED AS CashAccountRecipient,
	|	Request.Department AS Department,
	|	Request.PaymentMethodOfPaymentRequest AS PaymentMethodOfPaymentRequest,
	|	Request.CashFlowItem AS CashFlowItem,
	|	UNDEFINED AS CurrencyOfConversion,
	|	UNDEFINED AS ConversionAmount,
	|	UNDEFINED AS ConversionRate,
	|	UNDEFINED AS ConversionRateMultiplier,
	|	UNDEFINED AS AmountPlanning,
	|	UNDEFINED AS PaysheetNumber,
	|	UNDEFINED AS PaysheetDate,
	|	UNDEFINED AS AssetAndLiabilityItem,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS PaymentID,
	|	UNDEFINED AS ExpenseReportDate,
	|	FALSE         AS ContractWithSDOParticipant,
	|	FALSE         AS PaymentsAsPer275FZ,
	|	UNDEFINED AS PaymentType275FZ,
	|	UNDEFINED AS StateContract_,
	|	UNDEFINED AS TargetFundItem,
	|	FALSE         AS TransferOfTaxesAndContributions,
	|	UNDEFINED AS TaxType,
	|	UNDEFINED AS PaysheetPersonalIncomeTax,
	|	UNDEFINED AS RegistrationWithTaxAuthority,
	|	UNDEFINED AS KindOfFundsTransferToBudget,
	|	UNDEFINED AS RNCPSRNCMTCode,
	|	UNDEFINED AS BasisIndicator,
	|	UNDEFINED AS PeriodIndicator,
	|	UNDEFINED AS NumberIndicator,
	|	UNDEFINED AS DateIndicator,
	|	UNDEFINED AS TypeIndicator,
	|	UNDEFINED AS AuthorStatus,
	|	UNDEFINED AS BCCode,
	|	UNDEFINED AS IncomeKindCode,
	|	UNDEFINED AS PaymentCode,
	|	UNDEFINED AS AcquiringContract,
	|	UNDEFINED AS RecordCommission,
	|	UNDEFINED AS FeeAmount,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS ExpensesBusinessUnit,
	|	UNDEFINED AS GLAccountSettings,
	|	FALSE AS ThisIsSalaryPayment,
	|	Request.Employee.Description AS Issue,
	|	TRUE AS PaymentByRequests,
	|	UNDEFINED AS TINOfPayer,
	|	UNDEFINED AS PayerCRTR,
	|	""""         AS PayerSName,
	|	UNDEFINED AS FinancialAccountingGroup,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS Contract,
	|	Request.Ref AS PaymentRequest,
	|	UNDEFINED AS DocumentBasisOfApplication,
	|	UNDEFINED AS FPSPaymentID,
	|	UNDEFINED AS RankingInPriorityOfPayment,
	|	UNDEFINED AS TransferFeeType,
	|	""""         AS InformationToPaymentRecipient,
	|	UNDEFINED AS ConditionOfConversionTransaction,
	|	UNDEFINED AS BankAccountForFeeWriteOff,
	|	UNDEFINED AS VATTaxation,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE
	|
	|FROM
	|	Document.ApplicationForBusinessTrip AS Request
	|	
	|WHERE
	|	Request.Ref IN (&ReferencesArrray)
	|;
	|
	|//////////////////////////////////////////////
	|SELECT
	|	ISNULL(Cash.SumBalance, 0) AS Sum
	|FROM
	|	CashBalance AS Cash
	|";
	
	Query = New Query;
	Query.TempTablesManager = RequestingBalances.TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult[0].Select();
	If Selection.Next() Then
		FillPropertyValues(FillingData, Selection);
	Else
		Return;
	EndIf;
	
	If ValueIsFilled(Selection.PaymentMethodOfPaymentRequest)
		And PaymentMethod <> Selection.PaymentMethodOfPaymentRequest Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hình thức thanh toán ""%1"" của chứng từ đầu vào khác với hình thức thanh toán ""%2"" của ứng dụng.';
				|ru = 'Форма оплаты ""%1"" вводимого документа отличается от формы оплаты ""%2"" заявки.';
				|en = 'The ""%1"" payment form of the entered document differs from the ""%2"" payment form of the request.'; fa = 'The ""%1"" payment form of the entered document differs from the ""%2"" payment form of the request.';
				|it = 'Forma di pagamento ""%1"" del documento da inserire differisce dalla forma di pagamento ""%2"" della domanda.';
				|pl = 'Forma płatności ""%1"" wprowadzanego dokumentu różni się od formy płatności ""%2"" zlecenia.';
				|tr = '""%1"" girilen belgenin ödeme formu ""%2"" başvurunun ödeme formundan farklı.'"),
			PaymentMethod,
			Selection.PaymentMethodOfPaymentRequest);
		Raise Text;
	EndIf;
	
	If PaymentMethod = Enums.PaymentForms.PaymentCard
		And Selection.BusinessOperation <> Enums.BusinessTransactions.RefundToCustomer Then
		Text = NStr("vi = 'Hoạt động đã chọn không tương ứng với hoạt động hoàn trả của khách hàng được cung cấp khoản thanh toán.';
					|ru = 'Выбранная операция не соответствует операции возврата оплаты клиенту, для которой предусмотрен эквайринговый платеж.';
					|en = 'Selected operation does not correspond to the refund to customer transaction, acquiring payment for which is provided.'; fa = 'Selected operation does not correspond to the refund to customer transaction, acquiring payment for which is provided.';
					|it = 'L''operazione selezionata non è conforme all''operazione di restituzione del pagamento al cliente, per il quale viene fornito un pagamento di acquisizione.';
					|pl = 'Wybrana operacja nie odpowiada operacji zwrotu płatności klientowi, dla której jest przewidziana płatność acquiringowa.';
					|tr = 'Seçilen işlem, PoS ödemesinin sağlandığı müşteriye ödemeyi iade etme işlemine karşılık gelmiyor.'");
		Raise Text;
	EndIf;
	If ValueIsFilled(Selection.GLAccountSettings) Then
		FillingData.GLAccountSettings = GLAccountSettingsServer.CopyOfAccountSettings(Selection.GLAccountSettings);
	EndIf;
	If ValueIsFilled(BankAccountCashAccount) Then
		If PaymentMethod = Enums.PaymentForms.BankAccountPayment
			Or PaymentMethod = Enums.PaymentForms.InstantPayments Then
			FillingData.Insert("BankAccount", BankAccountCashAccount);
		ElsIf PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
			FillingData.Insert("CashAccount", BankAccountCashAccount);
		EndIf;
	EndIf;
	
	
	If FillingData.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ParametersStructure = ParametersForFillingOutOrganizationSBankAccount();
		ParametersStructure.Organization = FillingData.Organization;
		ParametersStructure.Currency = FillingData.CurrencyOfConversion;
		BankAccountBeneficiary =
			Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
		FillingData.Insert("BankAccountBeneficiary", BankAccountBeneficiary);
		CashAccountRecipient = Catalogs.CashAccounts.GetCheckoutByDefault(
			FillingData.Organization,
			FillingData.CurrencyOfConversion);
		FillingData.Insert("CashAccountRecipient", CashAccountRecipient);
	EndIf;
	
	If FillingData.AmountPlanning <> Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
		FillingData.PaymentWithConversion = DefinePaymentWithConversion(FillingData);
	EndIf;
	
	If FillingData.PaymentWithConversion Then
		
		If ValueIsFilled(FillingData.CounterpartyBankAccount)
			And FillingData.Currency <> FillingData.CounterpartyBankAccountCurrency Then
			FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
		EndIf;
		
		If ValueIsFilled(FillingData.BankAccountBeneficiary)
			And FillingData.Currency <> FillingData.BankAccountRecipientCurrency Then
			FillingData.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(PaymentAmount) Then
		FillingData.Insert("DocumentAmount", PaymentAmount);
	Else
		FillingData.Insert("DocumentAmount", QueryResult[1].Unload()[0].Sum);
	EndIf;
	
	If Selection.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or Selection.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		
		SetPrivilegedMode(True);
		DocumentOfTheIndividual = PersonsTM.GetIndividualSDefaultDocument(Selection.AdvanceHolder).Presentation;
		SetPrivilegedMode(False);
		FillingData.Insert("ByDocument", DocumentOfTheIndividual);
	EndIf;
	
	If FillingData.PersonsList
		And GetFunctionalOption("UseCashDepositToListEmployees") Then
		BalancesToBeWrittenOff = BalancesDebitedToEmployeesPersonalAccounts(ReferencesArrray);
		FillingData.Insert("PersonalAccountsOfStaff", BalancesToBeWrittenOff);
	EndIf;
	
	If Selection.AmountPlanning = Enums.MethodsOfPlanningRequestPayment.InARAPCurrency Then
		FillInDetailsOfDocumentOnFormOfPayment(PaymentMethod, FillingData);
	Else
		FillInDetailsOfDocumentOnFormOfPayment(PaymentMethod, FillingData, Selection.Currency);
	EndIf;
	
	If FillingData.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		And FillingData.ConversionRate <> 0
		And FillingData.ConversionAmount = 0 Then
		FillingData.Insert("ConversionAmount", FillingData.DocumentAmount / FillingData.ConversionRate);
	EndIf;
	

	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Selection.RequestCurrency, FillingData.Currency, CurrentSessionDate(), Selection.Organization);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DecryptionOfDocument.Partner,
	|	DecryptionOfDocument.Counterparty,
	|	Request.Organization AS Organization,
	|	ISNULL(DecryptionOfDocument.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	ISNULL(DecryptionOfDocument.Sum, Request.DocumentAmount) AS Sum,
	|	CASE
	|		WHEN Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency) THEN
	|			DecryptionOfDocument.AmountARAP
	|		ELSE
	|			0
	|	END AS AmountARAP,
	|	DecryptionOfDocument.ARAPCurrency,
	|	DecryptionOfDocument.ExpenseItem,
	|	DecryptionOfDocument.DimensionOfExpenses,
	|	DecryptionOfDocument.AssetsLiabilitiesDimension,
	|	ISNULL(DecryptionOfDocument.CashFlowItem, Request.CashFlowItem) AS CashFlowItem,
	|	DecryptionOfDocument.TargetFundItem,
	|	DecryptionOfDocument.LoanDepositContract,
	|	DecryptionOfDocument.LoanAndDepositAmountType,
	|	DecryptionOfDocument.LeaseContracts,
	|	DecryptionOfDocument.TypeOfLeasePayment,
	|	DecryptionOfDocument.EmployeeLoanAgreement,
	|	DecryptionOfDocument.Department,
	|	DecryptionOfDocument.LineOfBusiness,
	|	DecryptionOfDocument.Statement,
	|	&ExtdimensionFields,
	|	DecryptionOfDocument.VATRate,
	|	DecryptionOfDocument.VATAmount AS VATAmount,
	|	Request.Ref AS PaymentRequest,
	|	Request.AmountPlanning AS AmountPlanning,
	|	Request.Currency AS Currency,
	|	DecryptionOfDocument.MaturityDate AS MaturityDate
	|INTO TTARAPDetails
	|FROM
	|	Document.PaymentRequest AS Request
	|	
	|	LEFT JOIN
	|		Document.PaymentRequest.ARAPDetails AS DecryptionOfDocument
	|	ON
	|		DecryptionOfDocument.Ref = Request.Ref
	|	
	|WHERE
	|	Request.Ref IN(&ReferencesArrray)
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED,
	|	VALUE(Catalog.Counterparties.EmptyRef),
	|	VALUE(Catalog.Companies.EmptyRef),
	|	VALUE(Catalog.ARAPObjects.EmptyRef),
	|	ISNULL(ARAPDetails.Sum, Request.DocumentAmount) AS Sum,
	|	0 AS AmountARAP,
	|	Request.Currency,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	ARAPDetails.CashFlowItem,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	&FieldsUndefined,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT),
	|	0,
	|	Request.Ref AS PaymentRequest,
	|	UNDEFINED AS AmountPlanning,
	|	Request.Currency AS Currency,
	|	DATETIME(1, 1, 1) AS MaturityDate
	|FROM
	|	Document.ApplicationForBusinessTrip AS Request
	|	LEFT JOIN
	|		Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS ARAPDetails
	|	ON
	|		ARAPDetails.Ref = Request.Ref
	|WHERE
	|	Request.Ref IN(&ReferencesArrray)
	|	
	|UNION ALL
	|
	|SELECT
	|	DecryptionOfDocument.Partner,
	|	DecryptionOfDocument.Counterparty,
	|	DecryptionOfDocument.Ref.Organization,
	|	CASE
	|		WHEN DecryptionOfDocument.ARAPObject.Object = DecryptionOfDocument.Ref
	|			THEN VALUE(Catalog.ARAPObjects.EmptyRef)
	|		ELSE DecryptionOfDocument.ARAPObject
	|	END,
	|	-DecryptionOfDocument.Sum,
	|	CASE
	|		WHEN DecryptionOfDocument.PaymentRequest.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency) THEN
	|			-DecryptionOfDocument.AmountARAP
	|		ELSE
	|			0
	|	END AS AmountARAP,
	|	DecryptionOfDocument.ARAPCurrency,
	|	DecryptionOfDocument.ExpenseItem,
	|	DecryptionOfDocument.DimensionOfExpenses,
	|	DecryptionOfDocument.AssetsLiabilitiesDimension,
	|	DecryptionOfDocument.CashFlowItem,
	|	DecryptionOfDocument.TargetFundItem,
	|	DecryptionOfDocument.LoanDepositContract,
	|	DecryptionOfDocument.LoanAndDepositAmountType,
	|	DecryptionOfDocument.LeaseContracts,
	|	DecryptionOfDocument.TypeOfLeasePayment,
	|	DecryptionOfDocument.EmployeeLoanAgreement,
	|	DecryptionOfDocument.Department,
	|	DecryptionOfDocument.LineOfBusiness,
	|	DecryptionOfDocument.Statement,
	|	&ExtdimensionFields,
	|	DecryptionOfDocument.VATRate,
	|	-DecryptionOfDocument.VATAmount,
	|	DecryptionOfDocument.PaymentRequest,
	|	DecryptionOfDocument.PaymentRequest.AmountPlanning,
	|	DecryptionOfDocument.PaymentRequest.Currency,
	|	DATETIME(1, 1, 1) AS MaturityDate
	|FROM
	|	Document.BankAccountIssue.ARAPDetails AS DecryptionOfDocument
	|	
	|	INNER JOIN
	|		AccumulationRegister.CashToBePaid AS Cash
	|	ON
	|		Cash.Recorder = DecryptionOfDocument.Ref
	|		AND Cash.PaymentRequest = DecryptionOfDocument.PaymentRequest
	|		
	|WHERE
	|	Cash.PaymentRequest IN(&ReferencesArrray)
	|
	|UNION ALL
	|
	|SELECT
	|	DecryptionOfDocument.Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef),
	|	DecryptionOfDocument.Ref.Organization,
	|	CASE
	|		WHEN DecryptionOfDocument.ARAPObject.Object = DecryptionOfDocument.Ref
	|			THEN VALUE(Catalog.ARAPObjects.EmptyRef)
	|		ELSE DecryptionOfDocument.ARAPObject
	|	END,
	|	-DecryptionOfDocument.Sum,
	|	CASE
	|		WHEN DecryptionOfDocument.PaymentRequest.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency) THEN
	|			-DecryptionOfDocument.AmountARAP
	|		ELSE
	|			0
	|	END AS AmountARAP,
	|	DecryptionOfDocument.ARAPCurrency,
	|	DecryptionOfDocument.ExpenseItem,
	|	DecryptionOfDocument.DimensionOfExpenses,
	|	DecryptionOfDocument.AssetsLiabilitiesDimension,
	|	DecryptionOfDocument.CashFlowItem,
	|	UNDEFINED,
	|	DecryptionOfDocument.LoanDepositContract,
	|	DecryptionOfDocument.LoanAndDepositAmountType,
	|	DecryptionOfDocument.LeaseContracts,
	|	DecryptionOfDocument.TypeOfLeasePayment,
	|	DecryptionOfDocument.EmployeeLoanAgreement,
	|	DecryptionOfDocument.Department,
	|	DecryptionOfDocument.LineOfBusiness,
	|	DecryptionOfDocument.Ref.Statement,
	|	&ExtdimensionFields,
	|	DecryptionOfDocument.VATRate,
	|	-DecryptionOfDocument.VATAmount,
	|	DecryptionOfDocument.PaymentRequest,
	|	DecryptionOfDocument.PaymentRequest.AmountPlanning,
	|	DecryptionOfDocument.PaymentRequest.Currency,
	|	DATETIME(1, 1, 1) AS MaturityDate
	|FROM
	|	Document.CashVoucher.ARAPDetails AS DecryptionOfDocument
	|	
	|	INNER JOIN
	|		AccumulationRegister.CashToBePaid AS Cash
	|	ON
	|		Cash.Recorder = DecryptionOfDocument.Ref
	|		AND Cash.PaymentRequest = DecryptionOfDocument.PaymentRequest
	|WHERE
	|	Cash.PaymentRequest IN(&ReferencesArrray)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractCourse.Period AS Period,
	|	ContractCourse.Contract AS Contract,
	|	ContractCourse.CourseNumerator AS CourseNumerator,
	|	ContractCourse.CourseDenominator AS CourseDenominator
	|INTO ContractTTCourses
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&CurrentDate) AS ContractCourse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ARAPObjects.Ref AS ARAPObject,
	|	CASE
	|		WHEN ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable)) 
	|					= VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|			THEN VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		ELSE ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable))
	|	END                                                                  AS ContractRateOption,
	|	ARAPObjects.ARAPObjectType                                     AS ARAPObjectType,
	|	ISNULL(DocumentCourses.RateARAPCurrencyNumerator, 0)         AS RateARAPCurrencyNumerator,
	|	ISNULL(DocumentCourses.RateARAPCurrencyDenominator, 0)       AS RateARAPCurrencyDenominator,
	|	ISNULL(DocumentCourses.RateManagementAccountingCurrencyNumerator, 0)   AS RateManagementAccountingCurrencyNumerator,
	|	ISNULL(DocumentCourses.RateManagementAccountingCurrencyDenominator, 0) AS RateManagementAccountingCurrencyDenominator,
	|	ISNULL(DocumentCourses.RateDocumentCurrencyNumerator, 0)              AS RateDocumentCurrencyNumerator,
	|	ISNULL(DocumentCourses.RateDocumentCurrencyDenominator, 0)            AS RateDocumentCurrencyDenominator,
	|	ISNULL(DocumentCourses.DocumentCurrency, 0)                           AS DocumentCurrency,
	|	ARAPObjects.ARAPCurrency                                   AS ARAPCurrency,
	|	ARAPObjects.Organization.LocalAccountingCurrency             AS LocalAccountingCurrency,
	|	ARAPObjects.Date                                                   AS Date,
	|	ISNULL(ContractRates.Period, DATETIME(1, 1, 1))                    AS ContractCoursePeriod,
	|	ISNULL(ContractRates.CourseNumerator, 0)                              AS ExchangeRateNumeratorOfContractCurrency,
	|	ISNULL(ContractRates.CourseDenominator, 0)                            AS ExchangeRateDenominatorOfContractCurrency
	|INTO CalculationObjectData
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN InformationRegister.DocumentCurrenciesAndRates AS DocumentCourses
	|		ON ARAPObjects.Object = DocumentCourses.Document
	|		LEFT JOIN ContractTTCourses AS ContractRates
	|		ON ARAPObjects.Contract = ContractRates.Contract
	|WHERE
	|	ARAPObjects.Ref IN (SELECT T.ARAPObject FROM TTARAPDetails AS T)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationObjectData.DocumentCurrency                AS Currency,
	|	CalculationObjectData.ARAPObject                 AS ARAPObject,
	|	CalculationObjectData.LocalAccountingCurrency AS BaseCurrency,
	|	CalculationObjectData.Date                           AS DateOfCourse,
	|	CalculationObjectData.RateDocumentCurrencyNumerator   AS CourseNumerator,
	|	CalculationObjectData.RateDocumentCurrencyDenominator AS CourseDenominator
	|INTO TTCoursesArePre
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|	AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|	AND (CalculationObjectData.DocumentCurrency IN (SELECT T.Currency FROM TTARAPDetails AS T)
	|		OR CalculationObjectData.DocumentCurrency = &Currency)
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationObjectData.ARAPCurrency                AS Currency,
	|	CalculationObjectData.ARAPObject                      AS ARAPObject,
	|	CalculationObjectData.LocalAccountingCurrency      AS BaseCurrency,
	|	CalculationObjectData.Date                                AS DateOfCourse,
	|	CalculationObjectData.RateARAPCurrencyNumerator   AS CourseNumerator,
	|	CalculationObjectData.RateARAPCurrencyDenominator AS CourseDenominator
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|	AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|	AND (CalculationObjectData.ARAPCurrency IN(SELECT T.Currency FROM TTARAPDetails AS T)
	|		OR CalculationObjectData.ARAPCurrency = &Currency)
	|
	|UNION ALL
	|
	|SELECT
	|	&CurrencyOfMan                                                      AS Currency,
	|	CalculationObjectData.ARAPObject                            AS ARAPObject,
	|	CalculationObjectData.LocalAccountingCurrency            AS BaseCurrency,
	|	CalculationObjectData.Date                                      AS DateOfCourse,
	|	CalculationObjectData.RateManagementAccountingCurrencyNumerator   AS CourseNumerator,
	|	CalculationObjectData.RateManagementAccountingCurrencyDenominator AS CourseDenominator
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|	AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|	AND (&CurrencyOfMan IN (SELECT T.Currency FROM TTARAPDetails AS T)
	|		OR &CurrencyOfMan = &Currency)
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationObjectData.ARAPCurrency           AS Currency,
	|	CalculationObjectData.ARAPObject                 AS ARAPObject,
	|	CalculationObjectData.LocalAccountingCurrency AS BaseCurrency,
	|	CalculationObjectData.ContractCoursePeriod            AS DateOfCourse,
	|	CalculationObjectData.ExchangeRateNumeratorOfContractCurrency    AS CourseNumerator,
	|	CalculationObjectData.ExchangeRateDenominatorOfContractCurrency  AS CourseDenominator
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|	AND (CalculationObjectData.ARAPCurrency IN(SELECT T.Currency FROM TTARAPDetails AS T)
	|		OR CalculationObjectData.ARAPCurrency = &Currency)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTCoursesArePre.Currency          AS Currency,
	|	TTCoursesArePre.ARAPObject  AS ARAPObject,
	|	TTCoursesArePre.BaseCurrency   AS BaseCurrency,
	|	TTCoursesArePre.DateOfCourse       AS DateOfCourse,
	|	TTCoursesArePre.CourseNumerator   AS CourseNumerator,
	|	TTCoursesArePre.CourseDenominator AS CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	TTCoursesArePre AS TTCoursesArePre
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RelativeExchangeRatesSliceLast.Currency          AS Currency,
	|	TTARAPDetails.ARAPObject                  AS ARAPObject,
	|	RelativeExchangeRatesSliceLast.BaseCurrency   AS BaseCurrency,
	|	RelativeExchangeRatesSliceLast.Period          AS DateOfCourse,
	|	RelativeExchangeRatesSliceLast.CourseNumerator   AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&CurrentDate,
	|			BaseCurrency = &BaseCurrency
	|				AND (Currency IN (SELECT T.Currency FROM TTARAPDetails AS T)
	|					OR Currency = &Currency)) AS RelativeExchangeRatesSliceLast
	|		INNER JOIN TTARAPDetails AS TTARAPDetails
	|		ON (TRUE)
	|WHERE 
	|	NOT (RelativeExchangeRatesSliceLast.Currency, TTARAPDetails.ARAPObject)
	|		IN (SELECT T.Currency, T.ARAPObject FROM TTCoursesArePre AS T)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ARAPDetails.Partner,
	|	ARAPDetails.Counterparty,
	|	ARAPDetails.Organization,
	|	ARAPDetails.ARAPObject,
	|	CASE
	|		WHEN ARAPDetails.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency) THEN
	|			SUM(ARAPDetails.AmountARAP) * CurrencyExchangeRate.CourseNumerator * CurrencyConversionRate_2.CourseDenominator 
	|				/ (CurrencyExchangeRate.CourseDenominator * CurrencyConversionRate_2.CourseNumerator)
	|		ELSE
	|			SUM(ARAPDetails.Sum) * CurrencyExchangeRate.CourseNumerator * CurrencyConversionRate_2.CourseDenominator 
	|				/ (CurrencyExchangeRate.CourseDenominator * CurrencyConversionRate_2.CourseNumerator)
	|	END AS Sum,
	|	SUM(ARAPDetails.AmountARAP) AS AmountARAP,
	|	ARAPDetails.ARAPCurrency,
	|	ARAPDetails.ExpenseItem,
	|	ARAPDetails.DimensionOfExpenses,
	|	ARAPDetails.AssetsLiabilitiesDimension,
	|	ARAPDetails.CashFlowItem,
	|	ARAPDetails.TargetFundItem,
	|	ARAPDetails.LoanDepositContract,
	|	ARAPDetails.LoanAndDepositAmountType,
	|	ARAPDetails.LeaseContracts,
	|	ARAPDetails.TypeOfLeasePayment,
	|	ARAPDetails.EmployeeLoanAgreement,
	|	ARAPDetails.Department,
	|	ARAPDetails.LineOfBusiness,
	|	ARAPDetails.Statement,
	|	&ExtdimensionData_,
	|	ARAPDetails.VATRate,
	|	CASE
	|		WHEN ARAPDetails.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency) THEN
	|			(SUM(ARAPDetails.AmountARAP) * CurrencyExchangeRate.CourseNumerator * CurrencyConversionRate_2.CourseDenominator 
	|				/ (CurrencyExchangeRate.CourseDenominator * CurrencyConversionRate_2.CourseNumerator) *
	|					(ARAPDetails.VATRate.Rate1 / 100) / ((ARAPDetails.VATRate.Rate1 / 100) + 1))
	|	ELSE
	|		SUM(ARAPDetails.VATAmount) * CurrencyExchangeRate.CourseNumerator * CurrencyConversionRate_2.CourseDenominator 
	|				/ (CurrencyExchangeRate.CourseDenominator * CurrencyConversionRate_2.CourseNumerator)
	|	END AS VATAmount,
	|	ARAPDetails.PaymentRequest,
	|	SUM(CASE
	|			WHEN ARAPDetails.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency) 
	|				THEN ARAPDetails.AmountARAP
	|			ELSE ARAPDetails.Sum
	|	END) AS PaymentAmount,
	|	CurrencyExchangeRate.CourseNumerator * CurrencyConversionRate_2.CourseDenominator 
	|		/ (CurrencyExchangeRate.CourseDenominator * CurrencyConversionRate_2.CourseNumerator) AS ConversionFactor_,
	|	ARAPDetails.MaturityDate AS MaturityDate
	|
	|FROM TTARAPDetails AS ARAPDetails
	|		
	|		LEFT JOIN
	|			ExchangeRates AS CurrencyExchangeRate
	|		ON
	|			ARAPDetails.Currency = CurrencyExchangeRate.Currency
	|			AND ARAPDetails.ARAPObject = CurrencyExchangeRate.ARAPObject 
	|
	|		LEFT JOIN
	|			ExchangeRates AS CurrencyConversionRate_2
	|		ON
	|			&Currency = CurrencyConversionRate_2.Currency
	|			AND ARAPDetails.ARAPObject = CurrencyConversionRate_2.ARAPObject 
	|
	|GROUP BY
	|	ARAPDetails.Partner,
	|	ARAPDetails.Counterparty,
	|	ARAPDetails.Organization,
	|	ARAPDetails.ARAPObject,
	|	ARAPDetails.ARAPCurrency,
	|	ARAPDetails.ExpenseItem,
	|	ARAPDetails.DimensionOfExpenses,
	|	ARAPDetails.AssetsLiabilitiesDimension,
	|	ARAPDetails.CashFlowItem,
	|	ARAPDetails.TargetFundItem,
	|	ARAPDetails.LoanDepositContract,
	|	ARAPDetails.LoanAndDepositAmountType,
	|	ARAPDetails.LeaseContracts,
	|	ARAPDetails.TypeOfLeasePayment,
	|	ARAPDetails.EmployeeLoanAgreement,
	|	ARAPDetails.Department,
	|	ARAPDetails.LineOfBusiness,
	|	ARAPDetails.Statement,
	|	&ExtdimensionGrouping,
	|	ARAPDetails.VATRate,
	|	ARAPDetails.PaymentRequest,
	|	ARAPDetails.AmountPlanning,
	|	CurrencyExchangeRate.CourseNumerator,
	|	CurrencyExchangeRate.CourseDenominator,
	|	CurrencyConversionRate_2.CourseDenominator,
	|	CurrencyConversionRate_2.CourseNumerator,
	|	ARAPDetails.MaturityDate
	|
	|HAVING
	|	CASE
	|		WHEN ARAPDetails.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency)
	|			THEN SUM(ARAPDetails.AmountARAP) * CurrencyExchangeRate.CourseNumerator * CurrencyConversionRate_2.CourseDenominator 
	|				/ (CurrencyExchangeRate.CourseDenominator * CurrencyConversionRate_2.CourseNumerator)
	|		ELSE SUM(ARAPDetails.Sum)
	|	END > 0
	|	
	|ORDER BY
	|	ARAPDetails.PaymentRequest
	|";
	If FillingData.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		And LocalAccntingServer.TypesOfTaxesWithAccountSettings().Find(FillingData.TaxType) <> Undefined
		Or FillingData.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		
		Query.Text = StrReplace(Query.Text, "&ExtdimensionGrouping",
		"	ARAPDetails.GLAccountSettings");
		
		Query.Text = StrReplace(Query.Text, "&ExtdimensionData_",
		"	ARAPDetails.GLAccountSettings AS GLAccountSettings");
	Else
		Query.Text = StrReplace(Query.Text, "&ExtdimensionGrouping", "FALSE");
		
		Query.Text = StrReplace(Query.Text, "&ExtdimensionData_",
		"	MIN(ARAPDetails.GLAccountSettings) AS GLAccountSettings");
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&ExtdimensionFields",
		"DecryptionOfDocument.GLAccountSettings AS GLAccountSettings");
	
	Query.Text = StrReplace(Query.Text, "&FieldsUndefined", "UNDEFINED AS GLAccountSettings");
	Query.SetParameter("Currency", FillingData.Currency);
	Query.SetParameter("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	TabularSection.Clear();
	
	// The amount in the currency of the application is converted into the amount in the currency of the Document
	// , taking into account possible different rates on the date of shipment or the rates of The Contract
	PaymentAmountOfDecryptionLines = 0;
	DocumentAmount = 0;
	While Selection.Next() Do
		If (PaymentAmountOfDecryptionLines + Selection.PaymentAmount) > FillingData.DocumentAmount Then
			DocumentAmount = DocumentAmount + (FillingData.DocumentAmount - PaymentAmountOfDecryptionLines) * Selection.ConversionFactor_;
			Break;
		EndIf;
		PaymentAmountOfDecryptionLines = PaymentAmountOfDecryptionLines + Selection.PaymentAmount;
		DocumentAmount = DocumentAmount + Selection.Sum;
	EndDo;
	
	RowsToProcess = New Array;
	
	Selection.Reset();
	While Selection.Next() Do
		If AmountsPayable <> Undefined Then
			ApplicationAmount = AmountsPayable.Get(Selection.PaymentRequest)
				* Selection.ConversionFactor_;
			Sum = Min(Selection.Sum, ApplicationAmount, DocumentAmount);
		Else
			Sum = Min(Selection.Sum, DocumentAmount);
		EndIf;
		RecalculateVAT = (Sum <> Selection.Sum);
		DocumentAmount = DocumentAmount - Sum;
		If Sum > 0 Then
			NewRow = TabularSection.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Sum = Sum;
			
			If RecalculateVAT Then
				RowsToProcess.Add(NewRow);
			EndIf;
			If ValueIsFilled(Selection.GLAccountSettings) Then
				NewRow.GLAccountSettings = GLAccountSettingsServer.CopyOfAccountSettings(Selection.GLAccountSettings);
			EndIf;
			If (Constants.UsePayroll.Get()

			//++ WE 
				Or GetFunctionalOption("PayrollAndHumanResourcesWE")
			//-- WE 

				Or False) 
				And FillingData.Property("BusinessOperation")
				And FillingData.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount Then
				
				If TabularSection.Count() Then
					FillingData.Insert("Statement", Selection.Statement);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", VATConversionParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection,
		CachedValues);
	
	If FillingData.DocumentAmount <> TabularSection.Total("AmountARAP") Then
		For Each TSRow In TabularSection Do
			TSRow.AmountARAP = 0;
		EndDo;
	EndIf;
	
	If TabularSection.Count() Then
		FillingData.Insert("DocumentAmount", TabularSection.Total("Sum"));
	EndIf;
	
	If FillingData.ListOfCounterparties_ Then
	
		Query = New Query;
		Query.Text = 
			"SELECT DISTINCT
			|	CounterpartyBankAccounts.Counterparty AS Counterparty,
			|	CounterpartyBankAccounts.CounterpartyBankAccount AS CounterpartyBankAccount
			|FROM
			|	Document.PaymentRequest AS PaymentRequest
			|		INNER JOIN Document.PaymentRequest.BankAccountsOfCounterpartyList AS CounterpartyBankAccounts
			|		ON PaymentRequest.Ref = CounterpartyBankAccounts.Ref
			|WHERE
			|	PaymentRequest.Ref IN(&ReferencesArrray)";
		
		Query.SetParameter("ReferencesArrray", ReferencesArrray);
		
		FillingData.Insert("BankAccountsOfCounterpartyList", Query.Execute().Unload());
		
	EndIf;
	
EndProcedure

// Fills in the table with the remaining funds to be paid for requests
//
// Parameters:
//    SelectionData_ - Structure - contains the values of the selection of applications
//    TabularSection - FormDataCollection - a table to fill in.
//
Procedure FillInBalancesOfApplicationsForSpendingMoney(SelectionData_, TabularSection) Export
	
	Result = RequestForBalancesOfRequestsForSpendingFunds(SelectionData_);
	
	TabularSection.Clear();
	
	Selection = Result.Select();
	While Selection.Next() Do
		NewRow = TabularSection.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.RequestPresentation =
			StrTemplate(" %1 " + NStr("vi = 'ngày  %2';
										|ru = 'от %2';
										|en = 'dated %2'; fa = 'dated %2';
										|it = 'da %2';
										|pl = 'od %2';
										|tr = '%2 tarihli'"), Selection.RequestNumber, Format(Selection.RequestDate, "DLF=D"));
	EndDo;
	
EndProcedure

// The procedure fills out a document based on an order to transfer funds.
//
// Parameters:
//	DocumentBasis - DocumentRef.CashTransferReferenceOrder - The document - base
//	DocumentObject - DocumentObject - Current document
//	FillingData - Structure - fill-in data
//	ARAPDetails - TabularSection - Table part "payment Decryption" of the document.
//
Procedure FillInDocumentOnOrderForTransferOfFunds(
	Val DocumentBasis,
	DocumentObject,
	FillingData,
	ARAPDetails = Undefined
	) Export
	
	// Fill in the data of the document header.
	QueryText = "
	|SELECT
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Ref AS CashTransferReferenceOrder,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Status AS Status,
	|
	|	CASE WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
	|		VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
	|		) THEN
	|		DocumentData.CashAccountRecipient
	|	ELSE
	|		DocumentData.CashAccount
	|	END AS CashAccount,
	|
	|	CASE WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount),
	|		VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
	|		) THEN
	|		DocumentData.CashAccountRecipient
	|	ELSE
	|		UNDEFINED
	|	END AS CashAccountRecipient,
	|
	|	CASE WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashDepositToBankAccount),
	|		VALUE(Enum.BusinessTransactions.CashCollectionToBank)
	|		) THEN
	|		DocumentData.BankAccountBeneficiary
	|	ELSE
	|		DocumentData.BankAccount
	|	END AS BankAccount,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount) THEN
	|		DocumentData.BankAccountBeneficiary
	|	ELSE
	|		UNDEFINED
	|	END AS BankAccountBeneficiary,
	|
	|	DocumentData.PaymentPurposes AS PaymentPurposes,
	|	Cash.SumBalance AS DocumentAmount
	|FROM
	|	Document.CashTransferReferenceOrder AS DocumentData
	|
	|	LEFT JOIN
	|		AccumulationRegister.CashToBePaid.Balance(,
	|			PaymentRequest = &Ref
	|		) AS Cash
	|	ON
	|		TRUE
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation IN (&OperationArray)
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	OperationArray = New Array;
	If TypeOf(DocumentObject) = Type("DocumentObject.CashAccountReceiptNote") Then
		OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromBank);
		OperationArray.Add(Enums.BusinessTransactions.WithdrawalFromBankAccount);
		PresentationOfDocument = NStr("vi = 'Phiếu thu 01-TT';
										|ru = 'Приходный кассовый ордер';
										|en = 'Incoming payment — Cash account'; fa = 'دریافت — صندوق';
										|it = 'Reversale di incasso';
										|pl = 'Asygnata kasowa przychodowa';
										|tr = 'Gelen ödeme - kasa hesabı'");
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.CashVoucher") Then
		OperationArray.Add(Enums.BusinessTransactions.CashDepositToBankAccount);
		OperationArray.Add(Enums.BusinessTransactions.CashCollectionToBank);
		OperationArray.Add(Enums.BusinessTransactions.CashIssueToAnotherCashAccount);
		PresentationOfDocument = NStr("vi = 'Phiếu chi';
										|ru = 'Расходный кассовый ордер';
										|en = 'Outgoing payment — Cash account'; fa = 'پرداخت خروجی — صندوق';
										|it = 'Mandato di pagamento';
										|pl = 'Asygnata kasowa rozchodowa';
										|tr = 'Giden ödeme - kasa hesabı'");
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.BankAccountIssue") Then
		OperationArray.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount);
		OperationArray.Add(Enums.BusinessTransactions.WithdrawalFromBankAccount);
		PresentationOfDocument = NStr("vi = 'Chi tiền từ tài khoản ngân hàng';
										|ru = 'Списание безналичных ДС';
										|en = 'Outgoing payment — Bank account'; fa = 'پرداخت خروجی — حساب بانکی';
										|it = 'Addebito di fondi monetari non in contanti';
										|pl = 'Rozchód bezgotówkowych środków pieniężnych';
										|tr = 'Giden ödeme — banka hesabı'");
		
	EndIf;
	Query.SetParameter("OperationArray", OperationArray);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập %1 trên cơ sở chứng từ %2';
				|ru = 'Не требуется вводить %1 на основании документа %2';
				|en = 'It is not required to generate %1 based on document %2'; fa = 'It is not required to generate %1 based on document %2';
				|it = 'Non è richiesto l''inserimento di %1 nella causale del documento %2';
				|pl = 'Nie trzeba wprowadzać %1 na podstawie dokumentu %2';
				|tr = '%2 belgesine göre %1 girmeye gerek yok'"),
			PresentationOfDocument,
			DocumentBasis);
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
	
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		
		If TypeOf(DocumentObject) = Type("DocumentObject.CashAccountReceiptNote")
			And Selection.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
			FillingData.Insert("BusinessOperation", Enums.BusinessTransactions.CashCollectionFromBank);
		EndIf;
		
		If Selection.Status <> Enums.CashTransferOrderStatuses.AmountDue Then
			Text = NStr("vi = 'Lệnh chuyển tiền chưa được xác nhận thanh toán';
						|ru = 'Распоряжение на перемещение денежных средств не утверждено к оплате';
						|en = 'Cash transfer order is not confirmed for payment'; fa = 'Cash transfer order is not confirmed for payment';
						|it = 'Ordine di pagamento in contanti non approvato per il pagamento';
						|pl = 'Zamówienie na przemieszczenie środków pieniężnych-gotówki nie zatwierdzono do płatności';
						|tr = 'Ödenecek nakit transferi talimatı onaylanmadı'");
			Raise Text;
		EndIf;
	
	EndIf;
	
EndProcedure // Fill out the document of the distribution of the money transfer()

// The procedure fills in the DDS article in the header of the business transaction document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	FillingData - Structure - fill-in data
//	BusinessOperation - EnumRef.BusinessTransactions - Household. operation.
//
Procedure FillInCashFlowItem(DocumentObject, FillingData, BusinessOperation) Export
	
	If TypeOf(FillingData) = Type("Structure")  And FillingData.Property("CashFlowItem") Then
		CashFlowItem = FillingData.CashFlowItem;
	Else
		CashFlowItem = DocumentObject.CashFlowItem;
	EndIf;
	
	If Not ValueIsFilled(CashFlowItem) Then
		
		If TypeOf(FillingData) = Type("Structure") And FillingData.Property("BusinessOperation") Then
			
			If FillingData.BusinessOperation = Enums.BusinessTransactions.SalaryPayment 
				And FillingData.Property("PayrollTransaction") Then
				
				FillingData.Insert("CashFlowItem",
					SettingsValueCached.GetCashFlowItem(FillingData.PayrollTransaction));
			Else
					
				FillingData.Insert("CashFlowItem",
					SettingsValueCached.GetCashFlowItem(FillingData.BusinessOperation));
			EndIf;
		Else
			DocumentObject.CashFlowItem =
				SettingsValueCached.GetCashFlowItem(BusinessOperation);
		EndIf;
	EndIf;
	
EndProcedure

// The function generates the text of the line" including VAT " of the payment.
//
// Parameters:
//    Organization - CatalogRef.Companies - Organization of the document
//    DocumentCurrency - CatalogRef.Currencies - The document currency
//    ARAPDetails - TabularSection - Table part payment Description
//    AddTextIncluding - Boolean - Add the string "including" to the payment text.
//
// Returns:
//    String - The text of the VAT amount of the payment.
//
Function TextAmountOfVATPayment(Organization, DocumentCurrency, ARAPDetails, AddTextIncluding) Export
	
	If TypeOf(ARAPDetails) = Type("ValueTable") Then
		VATTable = ARAPDetails.Copy(, "VATRate, VATAmount");
	Else
		VATTable = ARAPDetails.Unload(, "VATRate, VATAmount");
	EndIf;
	VATTable.GroupBy("VATRate", "VATAmount");
	
		CurrencyPresentation = TrimAll(DocumentCurrency);
	
	TextPurposeOfVATPayment = "";
	For Each TableRow In VATTable Do
		If TableRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT
			Or Not ValueIsFilled(TableRow.VATRate) Then
			Continue;
		EndIf;
		TextPurposeOfVATPayment = TextPurposeOfVATPayment
			+ ?(IsBlankString(TextPurposeOfVATPayment), "", ", ")
			+ NStr("vi = 'Thuế GTGT';
					|ru = 'НДС';
					|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
					|it = 'IVA';
					|pl = 'VAT';
					|tr = 'KDV'") + " (" + TableRow.VATRate + ") "
			+ Format(TableRow.VATAmount, "NFD=2; NDS=-; NZ=0-00; NG=") + " " + CurrencyPresentation;
	EndDo;
	If Not ValueIsFilled(TextPurposeOfVATPayment) Then
		TextPurposeOfVATPayment = NStr("vi = 'Không thuế (GTGT)';
										|ru = 'Без налога (НДС)';
										|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
										|it = 'senza imposta (IVA)';
										|pl = 'bez podatku (VAT)';
										|tr = 'Vergisiz (KDV)'");
	Else
		If AddTextIncluding Then
			TextPurposeOfVATPayment = NStr("vi = 'trong đó';
											|ru = 'В т.ч.';
											|en = 'Including'; fa = 'شامل';
											|it = 'Incl.';
											|pl = 'W tym';
											|tr = 'Tablo bölümünde'") + " " + TextPurposeOfVATPayment;
		EndIf;
	EndIf;
	
	Return TextPurposeOfVATPayment;
	
EndFunction

// The procedure fills in the document based on the loan agreement (Deposit).
//
// Parameters:
//	LoanDepositContract - CatalogRef.LoanAndDepositContracts - Agreement-basis
//	FillingData - Structure - fill-in data
//	ARAPDetails - TabularSection - tabular part of the document
//  ThisIsAdmission - Boolean - type of cash flow.
//
Procedure FillInUnderLoanDepositAgreement(Val LoanDepositContract, FillingData, ARAPDetails, ThisIsAdmission) Export
	
	FillingData = Catalogs.LoanAndDepositContracts.DataForFillingInDDSDocument(LoanDepositContract, ThisIsAdmission);
	ARAPDetails.Load(FillingData.ARAPDetails);
	FillingData.Insert("DocumentAmount", ARAPDetails.Total("Sum"));
	
EndProcedure

// Clears the organization's Bank account if it belongs to another organization.
// Fills in by default if the Bank account is not filled in.
//
// Parameters:
//	Organization - CatalogRef.Companies - Organization of the document
//	BankAccount - CatalogRef.CompaniesBankAccounts - Verifiable Bank account
//	PaymentMethod - EnumRef.PaymentForms - Document payment form
//	LineOfBusiness - CatalogRef.LinesOfBusiness - direction of activity.
//	ForeignCurrencyTransaction - Boolean - Indicates payment in a currency.
//
Procedure CheckFillInOrganizationSBankAccountByOwner(Val Organization, BankAccount,
	PaymentMethod = Undefined, LineOfBusiness = Undefined, ForeignCurrencyTransaction = Undefined) Export
	
	AccountHolder = Undefined;
	If ValueIsFilled(BankAccount) Then
		AccountHolder = Common.ObjectAttributeValue(BankAccount, "Owner");
	EndIf;
	
	If Not ValueIsFilled(Organization) Or Organization <> AccountHolder Then
		BankAccount = Undefined;
	EndIf;
	
	ParametersStructure = ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersStructure.LineOfBusiness = LineOfBusiness;
	If ForeignCurrencyTransaction <> Undefined Then
		ParametersStructure.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
		ParametersStructure.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	BankAccount = GetOrganizationSDefaultBankAccount(ParametersStructure, BankAccount, PaymentMethod);
	
EndProcedure

// Clears the organization's cash register if it belongs to another organization.
// Fills in by default if the sales register is empty.
//
// Parameters:
//	Organization - CatalogRef.Companies - Organization of the document
//	CashAccount - CatalogRef.CashAccounts - Verified sales register
//	PaymentMethod - EnumRef.PaymentForms - Document payment form
//	LineOfBusiness - CatalogRef.LinesOfBusiness - Direction of activity
//	Individual - CatalogRef.Persons - A natural person
//
Procedure CheckOrganizationSSalesRegisterByOwner(Val Organization, CashAccount, PaymentMethod = Undefined, LineOfBusiness = Undefined, Individual = Undefined) Export
	
	CheckoutOwner = Undefined;
	If ValueIsFilled(CashAccount) Then
		CheckoutOwner = Common.ObjectAttributeValue(CashAccount, "Owner");
	EndIf;
	
	If Not ValueIsFilled(Organization) Or Organization <> CheckoutOwner Then
		CashAccount = Undefined;
	EndIf;
	
	ParametersStructure = DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization 			= Organization;
	ParametersStructure.PaymentMethod 			= PaymentMethod;
	ParametersStructure.CashAccount 					= CashAccount;
	ParametersStructure.LineOfBusiness = LineOfBusiness;
	ParametersStructure.Individual 			= Individual;
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
EndProcedure

// Returns the payment currency for the document
//
// Parameters:
//  PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
//  BankAccount - CatalogRef.CompaniesBankAccounts - The document's Bank account.
//  CashAccount - CatalogRef.CashAccounts - Document sales register.
//
// Returns:
//  CatalogRef.Currencies - Payment currency.
Function GetPaymentCurrency(PaymentMethod = Undefined, BankAccount = Undefined, CashAccount = Undefined) Export
	
	If (PaymentMethod = Enums.PaymentForms.BankAccountPayment 
		Or PaymentMethod = Enums.PaymentForms.InstantPayments
		Or Not ValueIsFilled(PaymentMethod))
		And ValueIsFilled(BankAccount) Then
		CurrencyOfPayment = Common.ObjectAttributeValue(BankAccount, "CashCurrency");
	ElsIf (PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Or Not ValueIsFilled(PaymentMethod))
		And ValueIsFilled(CashAccount) Then
		CurrencyOfPayment = Common.ObjectAttributeValue(CashAccount, "CashCurrency");
	Else
		CurrencyOfPayment = Catalogs.Currencies.EmptyRef();
	EndIf;
	
	Return CurrencyOfPayment;
	
EndFunction

// Creates payment documents, or generates fill-in data for creating a single payment document.
//
// Parameters:
//    GraphLines - Array - The keys of the records of the schedule of payments
//    DocumentType - String - Type of documents to create. If omitted, it will be detected automatically.
//    Group_ - Boolean - Indicates whether the graph lines should be grouped.
//
// Returns:
//    Structure:
//        Open helpform-Boolean-Indicates whether the document creation assistant form needs to be opened
//        Document creation-Structure - data for filling in a single document
//        Long operation-Structure - a Long operation for creating multiple documents
//        Adressstrokgrafika-String-the Address of the temporary storage that contains the paid lines of the schedule.
//
Function PayChartLines(GraphLines, DocumentType, Group_ = True) Export
	
	Result = CashServerLocalization.PayChartLines(GraphLines, DocumentType);
	
	If Result <> Undefined Then
		Return Result;
	EndIf;

	Result = New Structure;
	
	DocumentsToCreate = DocumentsToCreate(GraphLines, DocumentType, Group_);
	
	If DocumentsToCreate.Count() = 1 Then
		Result.Insert("OpenAssistantForm", False);
		Result.Insert("DocumentToCreate", DocumentsToCreate[0]);
	Else
		JobDescription = NStr("vi = 'Lập chứng từ thanh toán';
								|ru = 'Формирование платежных документов';
								|en = 'Generate payment documents'; fa = 'Generate payment documents';
								|it = 'Creazione dei documenti di pagamento';
								|pl = 'Tworzenie dokumentów płatniczych';
								|tr = 'Ödeme belgelerinin oluşturulması'");
		MethodToExecute = "CashServer.CreatePayments";
		ParametersStructure = New Structure;
		ParametersStructure.Insert("DocumentsToCreate", DocumentsToCreate);
		UUID = New UUID;
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParametersStructure, ExecutionParameters);
		Result.Insert("TimeConsumingOperation", TimeConsumingOperation);
		Result.Insert("OpenAssistantForm", True);
	EndIf;
	
	Return Result;
	
EndFunction

// Generates data for creating documents based on payment schedule lines
//
// Parameters:
//    GraphLines - Array - The keys of the records of the schedule of payments
//    DocumentType - String - Type of documents to create. If omitted, it will be detected automatically.
//    Group_ - Boolean - Indicates whether the graph lines should be grouped.
//
// Returns:
//    Array - Structures with the fields "Document type" and "Filling data".
//
Function DocumentsToCreate(GraphLines, DocumentType, Group_ = True) Export
	
	DocumentsToCreate = New Array;
	PaymentTable_1 = InformationRegisters.ScheduleOfPayments.CreateRecordSet().UnloadColumns();
	
	For Each PlotLine In GraphLines Do
		NewRow = PaymentTable_1.Add();
		FillPropertyValues(NewRow, PlotLine);
	EndDo;
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	PaymentTable_1.PaymentObject AS PaymentObject
	|INTO PaymentTable_1
	|FROM
	|	&PaymentTable_1 AS PaymentTable_1
	|";
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(Query.Text);
	
	OperatorPaymentTable = QuerySchema.QueryBatch[0].Operators[0]; // QuerySchemaSelectOperator
	For Each Column In PaymentTable_1.Columns Do
		OperatorPaymentTable.SelectedFields.Add("PaymentTable_1." + Column.Name);
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	Query.SetParameter("PaymentTable_1", PaymentTable_1);
	Query.Execute();
	
	QueryParts = New Array;
	QueryParts.Add("
	|SELECT
	|	ScheduleOfPayments.PaymentObject AS PaymentObject,
	|	ScheduleOfPayments.PaymentObject AS SalesOrder,
	|	ScheduleOfPayments.PaymentObject AS PurchaseOrder,
	|	ScheduleOfPayments.PaymentObject AS PaymentPurpose,
	|	ScheduleOfPayments.PaymentObject AS LoanDepositContract,
	|	ScheduleOfPayments.PaymentObject AS LeaseContracts,
	|	CASE
	|		WHEN ScheduleOfPayments.PaymentObject REFS Catalog.CounterpartyContracts
	|			OR ScheduleOfPayments.PaymentObject REFS Catalog.IntercompanyContracts THEN
	|			ScheduleOfPayments.PaymentObject
	|		ELSE UNDEFINED
	|	END AS Contract,
	|	CASE
	|		WHEN ScheduleOfPayments.PaymentObject REFS Catalog.LoanAndDepositContracts THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Catalog.LoanAndDepositContracts).Partner
	|		WHEN ScheduleOfPayments.PaymentObject REFS Catalog.LeaseContract THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Catalog.LeaseContract).Partner
	|	END AS Partner,
	|	ScheduleOfPayments.BankAccountCashAccount AS BankAccountCashAccount,
	|	ScheduleOfPayments.BankAccountCashAccount AS BankAccount,
	|	ScheduleOfPayments.BankAccountCashAccount AS CashAccount,
	|	ScheduleOfPayments.PaymentDate AS PaymentDate,
	|	ScheduleOfPayments.PayerBeneficiary AS PayerBeneficiary,
	|	ScheduleOfPayments.ReceiptIssue AS ReceiptIssue,
	|	ScheduleOfPayments.AmountType AS AmountType,
	|	ScheduleOfPayments.AmountType AS LoanAndDepositAmountType,
	|	ScheduleOfPayments.AmountType AS TypeOfLeasePayment,
	|	ScheduleOfPayments.Organization AS Organization,
	|	ScheduleOfPayments.Department AS Department,
	|	ScheduleOfPayments.Currency AS Currency,
	|	ScheduleOfPayments.CashFlowItem AS CashFlowItem,
	|	ISNULL(CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).PayrollTransaction, VALUE(Enum.BusinessTransactions.EmptyRef)) AS PayrollTransaction,
	|	ISNULL(ScheduleOfPayments.BankAccountCashAccount.CashCurrency, ScheduleOfPayments.Currency) AS CashCurrency,
	|	ISNULL(ScheduleOfPayments.BankAccountCashAccount.CashCurrency, ScheduleOfPayments.Currency) AS DocumentCurrency,
	|	
	|	CASE
	|		WHEN ScheduleOfPayments.PaymentObject REFS Document.PaymentRequest THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).CounterpartyBankAccount
	|		WHEN ScheduleOfPayments.PaymentObject REFS Catalog.LoanAndDepositContracts THEN
	|			CASE ScheduleOfPayments.AmountType
	|				WHEN VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) THEN
	|					CAST(ScheduleOfPayments.PaymentObject AS Catalog.LoanAndDepositContracts).CounterpartyBankAccount
	|				WHEN VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests) THEN
	|					CAST(ScheduleOfPayments.PaymentObject AS Catalog.LoanAndDepositContracts).InterestBankAccount
	|				WHEN VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee) THEN
	|					CAST(ScheduleOfPayments.PaymentObject AS Catalog.LoanAndDepositContracts).BankAccountOfFee
	|			END
	|		WHEN ScheduleOfPayments.PaymentObject REFS Document.VendorInvoice
	|		THEN CAST(ScheduleOfPayments.PaymentObject AS Document.VendorInvoice).CounterpartyBankAccount
	|		WHEN ScheduleOfPayments.PaymentObject REFS Document.VendorInvoiceServicesAndAssets
	|		THEN CAST(ScheduleOfPayments.PaymentObject AS Document.VendorInvoiceServicesAndAssets).CounterpartyBankAccount
	|		WHEN ScheduleOfPayments.PaymentObject REFS Catalog.LeaseContract THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Catalog.LeaseContract).CounterpartyBankAccount
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS CounterpartyBankAccount,
	|	
	|	ScheduleOfPayments.Sum AS AmountToPay,
	|	ScheduleOfPayments.Sum AS Sum,
	|	
	|	CASE
	|		WHEN ScheduleOfPayments.PaymentObject REFS Document.PaymentRequest THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).PersonsList
	|		ELSE
	|			FALSE
	|	END AS PersonsList,
	|	
	|	CASE
	|		WHEN ScheduleOfPayments.PaymentObject REFS Document.PaymentRequest THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).TransferToEmployeeViaABank
	|		ELSE
	|			FALSE
	|	END AS TransferToEmployeeViaABank,
	|	CASE
	|		WHEN ISNULL(CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).TransferToEmployeeViaABank, FALSE) THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).Counterparty
	|		ELSE
	|			VALUE(Catalog.Counterparties.EmptyRef)
	|	END AS RecipientBank,
	|	CASE
	|		WHEN ISNULL(CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).TransferToEmployeeViaABank, FALSE) THEN
	|			CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).CounterpartyBankAccount
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS AccountRecipient,
	|
	|	ScheduleOfPayments.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN ScheduleOfPayments.PaymentMethod = VALUE(Enum.PaymentForms.EmptyRef) THEN
	|			VALUE(Enum.PaymentForms.BankAccountPayment)
	|		ELSE
	|			ScheduleOfPayments.PaymentMethod
	|	END AS PaymentMethod,
	|	CASE
	|		WHEN ScheduleOfPayments.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions),
	|			VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount),
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount),
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount),
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
	|			VALUE(Enum.BusinessTransactions.CashCollectionFromBank),
	|			VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount),
	|			VALUE(Enum.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment),
	|			VALUE(Enum.BusinessTransactions.CurrencyConversion),
	|			VALUE(Enum.BusinessTransactions.SalaryPayment)
	|			) THEN
	|			FALSE
	|		WHEN ScheduleOfPayments.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|			VALUE(Enum.BusinessTransactions.CustomsPayment),
	|			VALUE(Enum.BusinessTransactions.OtherCashIssue),
	|			VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
	|			) AND ISNULL(CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).TransferOfTaxesAndContributions, FALSE) THEN
	|			FALSE
	|		WHEN ScheduleOfPayments.PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments) THEN
	|			FALSE
	|		WHEN ScheduleOfPayments.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor) 
	|			AND ISNULL(CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).ListOfCounterparties_, FALSE) THEN
	|			FALSE
	|		WHEN ScheduleOfPayments.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|			AND ScheduleOfPayments.PaymentObject REFS Document.PaymentRequest
	|			AND CAST(ScheduleOfPayments.PaymentObject AS Document.PaymentRequest).PersonsList THEN
	|			FALSE
	|		ELSE
	|			&Group_
	|	END AS Grouped
	|
	|INTO PaymentTableComplete
	|FROM
	|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
	|	
	|	INNER JOIN
	|		PaymentTable_1 AS PaymentTable_1
	|	ON
	|		PaymentTable_1.PaymentObject = ScheduleOfPayments.PaymentObject
	|		AND (PaymentTable_1.BankAccountCashAccount = ScheduleOfPayments.BankAccountCashAccount
	|			OR ScheduleOfPayments.BankAccountCashAccount = UNDEFINED AND PaymentTable_1.BankAccountCashAccount = UNDEFINED)
	|		AND PaymentTable_1.PaymentDate = ScheduleOfPayments.PaymentDate
	|		AND PaymentTable_1.ReceiptIssue = ScheduleOfPayments.ReceiptIssue
	|		AND PaymentTable_1.PayerBeneficiary = ScheduleOfPayments.PayerBeneficiary
	|		AND PaymentTable_1.Organization = ScheduleOfPayments.Organization
	|		AND PaymentTable_1.Currency = ScheduleOfPayments.Currency
	|		AND PaymentTable_1.AmountType = ScheduleOfPayments.AmountType
	|;
	|////////////////////////////////////
	|
	|SELECT
	|	*
	|FROM
	|	PaymentTableComplete
	|WHERE
	|	PaymentTableComplete.PayrollTransaction <> VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
	|	AND NOT PaymentTableComplete.PersonsList
	|;
	|////////////////////////////////////
	|
	|SELECT
	|	PaymentTable_1.Organization,
	|	PaymentTable_1.Department,
	|	PaymentTable_1.BankAccountCashAccount,
	|	PaymentTable_1.PayerBeneficiary,
	|	PaymentTable_1.CounterpartyBankAccount,
	|	PaymentTable_1.BusinessOperation,
	|	PaymentTable_1.ReceiptIssue,
	|	PaymentTable_1.PaymentMethod,
	|	PaymentTable_1.Currency,
	|	PaymentTable_1.Grouped,
	|	SUM(PaymentTable_1.AmountToPay) AS AmountToPay
	|	
	|FROM
	|	PaymentTableComplete AS PaymentTable_1
	|WHERE
	|	PaymentTable_1.Grouped
	|	AND PaymentTable_1.PayrollTransaction <> VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
	|
	|GROUP BY
	|	PaymentTable_1.Organization,
	|	PaymentTable_1.Department,
	|	PaymentTable_1.BankAccountCashAccount,
	|	PaymentTable_1.PayerBeneficiary,
	|	PaymentTable_1.CounterpartyBankAccount,
	|	PaymentTable_1.BusinessOperation,
	|	PaymentTable_1.ReceiptIssue,
	|	PaymentTable_1.PaymentMethod,
	|	PaymentTable_1.Currency,
	|	PaymentTable_1.Grouped
	|;
	|////////////////////////////////////
	|");
	
	UsePayroll = GetFunctionalOption("UsePayrollTM");

	QueryParts.Add("
	|SELECT
	|	PaymentTable_1.PaymentObject                                                  AS PaymentRequest,
	|	CASE
	|		WHEN PaymentTable_1.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment) THEN
	|			PaymentTable_1.PayrollTransaction
	|		ELSE
	|			PaymentTable_1.BusinessOperation
	|	END AS BusinessOperation,
	|	
	|	PaymentTable_1.Organization                                                   AS Organization,
	|	PaymentTable_1.Department                                                 AS Department,
	|	CASE
	|		WHEN PaymentTable_1.BankAccountCashAccount <> UNDEFINED THEN
	|			PaymentTable_1.BankAccountCashAccount
	|		ELSE
	|			CAST(PaymentTable_1.PaymentObject AS Document.PaymentRequest).BankAccount
	|	END AS BankAccount,
	|	PersonalAccounts.Individual                                                 AS AdvanceHolder,
	|	CASE
	|		WHEN PaymentTable_1.TransferToEmployeeViaABank
	|			THEN PaymentTable_1.AccountRecipient
	|		ELSE PersonalAccounts.PersonalAccount
	|	END                                                                       AS CounterpartyBankAccount,
	|	UNDEFINED                                                                AS Statement,
	|	PersonalAccounts.Ref.PaysheetNumber                         AS PaysheetNumber,
	|	PersonalAccounts.Ref.PaysheetDate                          AS PaysheetDate,
	|	CASE
	|		WHEN PaymentTable_1.CashFlowItem = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			PersonalAccounts.CashFlowItem
	|		ELSE
	|			PaymentTable_1.CashFlowItem
	|	END                                                                       AS CashFlowItem,
	|	TRUE                                                                      AS PaymentByRequests,
	|	CAST(PaymentTable_1.PaymentObject AS Document.PaymentRequest).PaymentPurposes AS PaymentPurposes,
	|	CAST(PaymentTable_1.PaymentObject AS Document.PaymentRequest).IncomeKindCode AS IncomeKindCode,
	|	CAST(PaymentTable_1.PaymentObject AS Document.PaymentRequest).PaymentCode AS PaymentCode,
	|	CASE WHEN PaymentTable_1.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment)
	|			OR (PaymentTable_1.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|				AND PaymentTable_1.PersonsList
	|				AND PaymentTable_1.TransferToEmployeeViaABank) THEN
	|		3
	|	ELSE
	|		5
	|	END AS RankingInPriorityOfPayment,
	|	CAST(PaymentTable_1.PaymentObject
	|		AS Document.PaymentRequest).ExpenseReportDate  AS ExpenseReportDate,
	|	PersonalAccounts.Sum                                                          AS Sum,
	|	PersonalAccounts.Sum                                                          AS DocumentAmount,
	|	SUM(PaymentTable_1.AmountToPay)                                           AS AmountToPay,
	|	PaymentTable_1.TransferToEmployeeViaABank                               AS TransferToEmployeeViaABank,
	|	PaymentTable_1.RecipientBank                                                AS Counterparty
	|FROM
	|	PaymentTableComplete AS PaymentTable_1
	|		
	|		INNER JOIN Document.PaymentRequest.PersonalAccountsOfStaff AS PersonalAccounts
	|		ON PersonalAccounts.Ref = PaymentTable_1.PaymentObject
	|			LEFT JOIN Document.BankAccountIssue.ARAPDetails AS WriteOffs
	|			ON WriteOffs.Ref.AdvanceHolder = PersonalAccounts.Individual
	|				AND WriteOffs.Ref.CounterpartyBankAccount = PersonalAccounts.PersonalAccount
	|				AND WriteOffs.PaymentRequest = PaymentTable_1.PaymentObject
	|				AND WriteOffs.Ref.Posted
	|WHERE
	|	(PaymentTable_1.PayrollTransaction = VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
	|		AND NOT &UsePayroll
	|	OR PaymentTable_1.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|		AND PaymentTable_1.PersonsList)
	|	AND WriteOffs.Ref IS NULL
	|
	|GROUP BY
	|	PaymentTable_1.PaymentObject,
	|	PaymentTable_1.Organization,
	|	PaymentTable_1.Department,
	|	PaymentTable_1.BankAccountCashAccount,
	|	CASE
	|		WHEN PaymentTable_1.CashFlowItem = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			PersonalAccounts.CashFlowItem
	|		ELSE
	|			PaymentTable_1.CashFlowItem
	|	END,
	|	PersonalAccounts.Ref,
	|	PersonalAccounts.Individual,
	|	CASE
	|		WHEN PaymentTable_1.TransferToEmployeeViaABank
	|			THEN PaymentTable_1.AccountRecipient
	|		ELSE PersonalAccounts.PersonalAccount
	|	END,
	|	PersonalAccounts.Sum,
	|	CASE
	|		WHEN PaymentTable_1.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment) THEN
	|			PaymentTable_1.PayrollTransaction
	|		ELSE
	|			PaymentTable_1.BusinessOperation
	|	END,
	|	CASE WHEN PaymentTable_1.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment)
	|			OR (PaymentTable_1.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|				AND PaymentTable_1.PersonsList
	|				AND PaymentTable_1.TransferToEmployeeViaABank) THEN
	|		3
	|	ELSE
	|		5
	|	END,
	|	PaymentTable_1.TransferToEmployeeViaABank,
	|	PaymentTable_1.RecipientBank
	|TOTALS BY
	|	PaymentRequest
	|");
	
	Query.Text = StrConcat(QueryParts);
	Query.SetParameter("UsePayroll", UsePayroll);
	Query.SetParameter("Group_", Group_);
	
	Result = Query.ExecuteBatch();
	
	PaymentTable_1 = Result[1].Unload();
	StringSelection = Result[1].Select();
	SelectingDimensions = Result[2].Select();
	SelectingPayoutsFromList = Result[3].Select(QueryResultIteration.ByGroups);
	
	SelectingPayments = New Structure;
	For Each Column In Result[2].Columns Do
		SelectingPayments.Insert(Column.Name);
	EndDo;
	SelectingPayments.Delete("AmountToPay");
	
	DescriptionOfBankAccountType = New TypeDescription("CatalogRef.CompaniesBankAccounts");
	DescriptionOfCashRegisterType = New TypeDescription("CatalogRef.CashAccounts");
	
	While SelectingDimensions.Next() Do
		FillPropertyValues(SelectingPayments, SelectingDimensions);
		
		SelectedPayments = PaymentTable_1.FindRows(SelectingPayments);
		
		If Not SelectedPayments.Count() Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(DocumentType) Then
			DocumentType = DetermineTypeOfDocumentToCreate(SelectingDimensions);
		EndIf;
		
		FillingData = Undefined;
		
		If TypeOf(SelectedPayments[0].PaymentObject) = Type("DocumentRef.CashTransferReferenceOrder")
			Or TypeOf(SelectedPayments[0].PaymentObject) = Type("DocumentRef.PaymentRequest")
			Or TypeOf(SelectedPayments[0].PaymentObject) = Type("DocumentRef.ApplicationForBusinessTrip") Then
			
			ReferencesArrray = New Array; AmountsPayable = New Map;
			For Each PaymentLine_1 In SelectedPayments Do
				ReferencesArrray.Add(PaymentLine_1.PaymentObject);
				RecordedAmount = AmountsPayable.Get(PaymentLine_1.PaymentObject);
				If RecordedAmount = Undefined Then
					AmountsPayable.Insert(PaymentLine_1.PaymentObject, PaymentLine_1.AmountToPay);
				Else
					AmountsPayable.Insert(PaymentLine_1.PaymentObject, PaymentLine_1.AmountToPay + RecordedAmount);
				EndIf;
			EndDo;
			
			FillingData = New Structure;
			FillingData.Insert("DocumentBasis", ReferencesArrray);
			FillingData.Insert("BankAccountCashAccount", SelectingDimensions.BankAccountCashAccount);
			FillingData.Insert("PayerBeneficiary", SelectingDimensions.PayerBeneficiary);
			FillingData.Insert("BusinessOperation", SelectingDimensions.BusinessOperation);
			FillingData.Insert("Sum", SelectingDimensions.AmountToPay);
			FillingData.Insert("Currency", SelectingDimensions.Currency);
			FillingData.Insert("MultipleSpendingRequests", ReferencesArrray.Count() > 1);
			FillingData.Insert("AmountsPayable", AmountsPayable);
		Else
			
			FillingData = New Structure;
			FillingData.Insert("BankAccount", DescriptionOfBankAccountType.AdjustValue(SelectingDimensions.BankAccountCashAccount));
			FillingData.Insert("CashAccount", DescriptionOfCashRegisterType.AdjustValue(SelectingDimensions.BankAccountCashAccount));
			FillingData.Insert("Counterparty", SelectingDimensions.PayerBeneficiary);
			FillingData.Insert("Organization", SelectingDimensions.Organization);
			FillingData.Insert("Currency", SelectingDimensions.Currency);
			
			If ValueIsFilled(SelectingDimensions.CounterpartyBankAccount) Then
				FillingData.Insert("CounterpartyBankAccount", SelectingDimensions.CounterpartyBankAccount);
			EndIf;
			
			If SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany
				Or SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany
				Or False Then
				If DocumentType = "CashAccountReceiptNote" Or DocumentType = "BankAccountReceiptNote" Then
					FillingData.Insert("BusinessOperation", Enums.BusinessTransactions.CashReceiptFromOtherCompany);
				Else
					FillingData.Insert("BusinessOperation", Enums.BusinessTransactions.CashPaymentToAnotherCompany);
				EndIf;
			ElsIf SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
				Or SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
				Or SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
				Or SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
				Or SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
				Or SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
				Or SelectingDimensions.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
				
				FillingData.Insert("BusinessOperation", SelectingDimensions.BusinessOperation);
			EndIf;
			FillingData.Insert("Basis", Common.ValueTableToArray(PaymentTable_1.Copy(SelectedPayments)));
		EndIf;
		
		DocumentToCreate = New Structure;
		DocumentToCreate.Insert("DocumentType", DocumentType);
		DocumentToCreate.Insert("FillingData", FillingData);
		DocumentsToCreate.Add(DocumentToCreate);
	EndDo;
	
	SelectingPayments = New Structure;
	For Each Column In Result[1].Columns Do
		SelectingPayments.Insert(Column.Name);
	EndDo;
	
	While StringSelection.FindNext(New Structure("Grouped", False)) Do
		
		FillingData = Undefined;
		
		If TypeOf(StringSelection.PaymentObject) = Type("DocumentRef.CashTransferReferenceOrder")
			Or TypeOf(StringSelection.PaymentObject) = Type("DocumentRef.PaymentRequest")
			Or TypeOf(StringSelection.PaymentObject) = Type("DocumentRef.ApplicationForBusinessTrip") Then
			
			ReferencesArrray = New Array;
			ReferencesArrray.Add(StringSelection.PaymentObject);
			
			FillingData = New Structure;
			FillingData.Insert("DocumentBasis", ReferencesArrray);
			FillingData.Insert("BankAccountCashAccount", StringSelection.BankAccountCashAccount);
			FillingData.Insert("PayerBeneficiary", StringSelection.PayerBeneficiary);
			FillingData.Insert("BusinessOperation", StringSelection.BusinessOperation);
			FillingData.Insert("Sum", StringSelection.AmountToPay);
			FillingData.Insert("Currency", StringSelection.Currency);
			FillingData.Insert("MultipleSpendingRequests", False);
			FillingData.Insert("AmountType", StringSelection.AmountType);
			
		Else
			
			If StringSelection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount
				Or StringSelection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherAccount
				Or StringSelection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
				Or StringSelection.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank
				Or StringSelection.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
				Or StringSelection.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
				
				FillingData = New Structure;
				FillingData.Insert("Organization", StringSelection.Organization);
				FillingData.Insert("BusinessOperation", StringSelection.BusinessOperation);
				FillingData.Insert("Currency", StringSelection.Currency);
				FillingData.Insert("DocumentAmount", StringSelection.AmountToPay);
				
				FillingData.Insert("SenderBankAccount", DescriptionOfBankAccountType.AdjustValue(StringSelection.PaymentObject));
				FillingData.Insert("CashAccountIssuer", DescriptionOfCashRegisterType.AdjustValue(StringSelection.PaymentObject));
				If StringSelection.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment Then
					FillingData.Insert("Counterparty", StringSelection.PayerBeneficiary);
					FillingData.Insert("AcquiringContract", StringSelection.PaymentObject);
				Else
					FillingData.Insert("Counterparty", StringSelection.PaymentObject);
				EndIf;
				If StringSelection.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank Then
					FillingData.Insert("BankAccount", DescriptionOfBankAccountType.AdjustValue(StringSelection.PaymentObject));
				Else
					FillingData.Insert("BankAccount", DescriptionOfBankAccountType.AdjustValue(StringSelection.BankAccount));
				EndIf;
				FillingData.Insert("CashAccount", StringSelection.CashAccount);
				
			Else
				FillingData = New Structure;
				FillingData.Insert("BankAccount", DescriptionOfBankAccountType.AdjustValue(StringSelection.BankAccountCashAccount));
				FillingData.Insert("CashAccount", DescriptionOfCashRegisterType.AdjustValue(StringSelection.BankAccountCashAccount));
				FillingData.Insert("Counterparty", StringSelection.PayerBeneficiary);
				FillingData.Insert("Organization", StringSelection.Organization);
				FillingData.Insert("Currency", StringSelection.Currency);
				
				FillPropertyValues(SelectingPayments, StringSelection);
				SelectedPayments = PaymentTable_1.FindRows(SelectingPayments);
				
				FillingData.Insert("Basis",
					Common.ValueTableToArray(PaymentTable_1.Copy(SelectedPayments)));
			EndIf;
		EndIf;
		
		DocumentToCreate = New Structure;
		DocumentToCreate.Insert("DocumentType", DocumentType);
		DocumentToCreate.Insert("FillingData", FillingData);
		DocumentsToCreate.Add(DocumentToCreate);
	EndDo;
	
	While SelectingPayoutsFromList.Next() Do
		
		AmountToPay = SelectingPayoutsFromList.AmountToPay;
		Selection = SelectingPayoutsFromList.Select();
		While Selection.Next() Do
			
			If Selection.Sum <= AmountToPay Then
				
				If (Selection.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
					Or (Selection.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
					And Not UsePayroll))
					And Selection.TransferToEmployeeViaABank Then
					
					FillingData = SelectingPayoutsFromList.PaymentRequest;
					
					DocumentToCreate = New Structure;
					DocumentToCreate.Insert("DocumentType", DocumentType);
					DocumentToCreate.Insert("FillingData", FillingData);
					DocumentsToCreate.Add(DocumentToCreate);
					
					Break;
					
				Else
					
					FillingData = New Structure;
					For Each Column In Result[3].Columns Do
						FillingData.Insert(Column.Name);
					EndDo;
					FillPropertyValues(FillingData, Selection);
					
					ReferencesArrray = New Array;
					ReferencesArrray.Add(Selection.PaymentRequest);
					FillingData.Insert("DocumentBasis", ReferencesArrray);
					FillingData.Insert("BankAccountCashAccount", Selection.BankAccount);
					
					DocumentToCreate = New Structure;
					DocumentToCreate.Insert("DocumentType", DocumentType);
					DocumentToCreate.Insert("FillingData", FillingData);
					DocumentsToCreate.Add(DocumentToCreate);
					
				EndIf;
				
				AmountToPay = AmountToPay - Selection.Sum;
			Else
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return DocumentsToCreate;
	
EndFunction

// Creates payment documents
//
// Parameters:
//    Parameters - Structure - Contains an array of prepared data for filling in documents
//    ResultAddress - String - Address of the temporary storage where the array of links to the created documents will be placed.
//
Procedure CreatePayments(Parameters, ResultAddress) Export
	
	DocumentsToCreate = Parameters.DocumentsToCreate;
	DocumentsCount = DocumentsToCreate.Count();
	Indus = 1;
	
	CreatedDocuments = New Array;
	For Each DocumentData In DocumentsToCreate Do
		
		NewDocument = Documents[DocumentData.DocumentType].CreateDocument();
		NewDocument.Date = CurrentSessionDate();
		NewDocument.Fill(DocumentData.FillingData);
		
		Post = False;
		
		NewDocument.AdditionalProperties.Insert("EDIWithBanks", True);
		If NewDocument.CheckFilling() Then
			If Not (NewDocument.AdditionalProperties.Property("FillingErrors")
				And NewDocument.AdditionalProperties.FillingErrors <> "") Then
				Post = True;
			EndIf;
		EndIf;
		
		Try
			NewDocument.Write(DocumentWriteMode.Write);
		Except
			ErrorText = NStr("vi = 'Không thể ghi chứng từ.';
							|ru = 'Не удалось записать документ.';
							|en = 'Cannot save the document.'; fa = 'Cannot save the document.';
							|it = 'Non è stato possibile registrare il documento.';
							|pl = 'Nie udało się zapisać dokumentu.';
							|tr = 'Belge kaydedilemedi.'");
			WriteLogEvent(
				ErrorText,
				EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		If Post Then
			Try
				NewDocument.Write(DocumentWriteMode.Posting);
			Except
				ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ.';
								|ru = 'Не удалось провести документ.';
								|en = 'Cannot post the document.'; fa = 'Cannot post the document.';
								|it = 'Non è possibile registrare il documento.';
								|pl = 'Nie udało się zaksięgować dokument.';
								|tr = 'Belge kaydedilemedi.'");
				WriteLogEvent(
					ErrorText,
					EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		
		If NewDocument.Ref <> Undefined Then
			CreatedDocuments.Add(NewDocument.Ref);
		EndIf;
		
		Progress = Round(Indus / DocumentsCount * 100);
		TimeConsumingOperations.ReportProgress(Progress);
		
		Indus = Indus + 1;
	EndDo;
	
	PutToTempStorage(CreatedDocuments, ResultAddress);
	
	TemporaryStorageKey = "PaymentDocumentGenerationWizard";
	If Parameters.Property("TemporaryStorageKey") Then
		TemporaryStorageKey = Parameters.TemporaryStorageKey;
	EndIf;
	
	Owner = Users.AuthorizedUser();
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Owner, ResultAddress, TemporaryStorageKey);
	SetPrivilegedMode(False);
	
EndProcedure

// Deletes payment documents
//
// Parameters:
//    RemovalLinks - Array - Links to deleted documents
//    ResultAddress - String - Address of the temporary storage where errors will be placed if they exist.
//
Procedure DeletePayments(RemovalLinks, ResultAddress) Export
	
	DocumentsToDelete = New Array;
	CalculationObjectsToDelete = New Array;
	ArrayOfMarkedForDeletion = New Array;
	ErrorList = Undefined;
	ObjectsPreventingDeletion = New ValueTable;
	
	SetPrivilegedMode(True);
	
	For Each LinkToDelete In RemovalLinks Do
		DocumentObject = LinkToDelete.GetObject();
		If DocumentObject = Undefined Then
			Continue;
		EndIf;
		Try
			DocumentObject.Lock();
		Except
			CommonClientServer.AddUserError(
				ErrorList, "Object.CreatedDocuments", ErrorDescription(), Undefined);
			Continue;
		EndTry;
		DocumentsToDelete.Add(LinkToDelete);
		DocumentObject.SetDeletionMark(True);
		
	EndDo;
	
	ListOfLinks = FindByRef(DocumentsToDelete);
	MessageRow = NStr("vi = 'Có các tham chiếu đến đối tượng %1 trong %2. chứng từ sẽ không bị xóa.';
						|ru = 'Имеются ссылки на объект %1 в %2. Документ не будет удален.';
						|en = 'There are references to the %1 object in %2. Document will not be deleted.'; fa = 'There are references to the %1 object in %2. Document will not be deleted.';
						|it = 'Ci sono link all''oggetto %1 in %2. Il documento non verrà cancellato.';
						|pl = 'Istnieją odnośniki do obiektu %1 w %2. Dokument nie będzie usunięty.';
						|tr = '%2''de %1 nesnesine bağlantı mevcut. Belge silinmeyecek.'");
	
	ExcludingObjects = MarkedObjectsDeletionInternal.ExceptionsOfSearchForRefsAllowingDeletion();
	
	For Each Ref In ListOfLinks Do
		If TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.JobsForAllocatingCustomersARAP")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.JobsForAllocatingVendorsARAP")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.JobsForMonthEndClosing")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.DocumentsRegistry")
			Or TypeOf(Ref[1]) = Type("CatalogRef.ARAPObjects")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.DeleteAuxiliarySettlementInformation")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.JobsForARAPAllocating")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.JobsOfBackdateAdditionalDocumentPosting")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.DocumentsWithCounterpartyCheckErrors")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.ScheduleOfPayments")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.JobsForPostingInBudgeting")
			Or TypeOf(Ref[1]) = Type("InformationRegisterRecordKey.SourceDocumentsData")
			Or TypeOf(Ref[0]) = TypeOf(Ref[1])
			Or ExcludingObjects.Find(Ref[1].Metadata()) <> Undefined
			Then
				Continue;
		EndIf;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(MessageRow, TrimAll(Ref[0]), TrimAll(Ref[1]));
		CommonClientServer.AddUserError(
			ErrorList, "Object.CreatedDocuments", ErrorText, Undefined);
		IndexOf = DocumentsToDelete.Find(Ref[0]);
		If IndexOf <> Undefined Then
			DocumentsToDelete.Delete(IndexOf);
		EndIf;
		ArrayOfMarkedForDeletion.Add(Ref[0]);
	EndDo;
	
	Try
		DeleteObjects(DocumentsToDelete, False);
	Except
		CommonClientServer.AddUserError(
			ErrorList, "Object.CreatedDocuments", ErrorDescription(), Undefined);
	EndTry;
	
	For Each LinkToDelete In ArrayOfMarkedForDeletion Do
		DocumentObject = LinkToDelete.GetObject();
		DocumentObject.SetDeletionMark(True);
	EndDo;
	
	SetPrivilegedMode(False);
	
	PutToTempStorage(ErrorList, ResultAddress);
	
EndProcedure

Procedure FillInHeaderBasedOnDecryptionData(Object) Export
	
	OurPartners = TMCommonUse.DeleteDuplicateElementsFromArray(
		Object.ARAPDetails.UnloadColumn("Partner"));
	If OurPartners.Count() = 1 Then
		Object.Partner = OurPartners[0];
	Else
		Object.Partner = Common.ObjectAttributeValue(Object.Counterparty, "Partner");
	EndIf;
	
	ClearVATTaxation(Object);
	
EndProcedure

// Defines the payment schedule lines to be paid
//
// Parameters:
//    PaymentObjects - Array, DocumentRef - Paid items
//
// Returns:
//    Array - Keys of register entries Payment schedule
//
Function ScheduleLinesForPayment(Val PaymentObjects) Export
	
	Result = New Array;
	
	If TypeOf(PaymentObjects) <> Type("Array") Then
		PaymentObject = PaymentObjects;
		PaymentObjects = New Array;
		PaymentObjects.Add(PaymentObject);
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	RegisterData.PaymentObject AS PaymentObject,
	|	RegisterData.BankAccountCashAccount AS BankAccountCashAccount,
	|	RegisterData.PaymentDate AS PaymentDate,
	|	RegisterData.PayerBeneficiary AS PayerBeneficiary,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.AmountType AS AmountType,
	|	RegisterData.ReceiptIssue AS ReceiptIssue,
	|	RegisterData.Currency AS Currency
	|FROM
	|	InformationRegister.ScheduleOfPayments AS RegisterData
	|WHERE
	|	RegisterData.PaymentObject IN (&PaymentObjects)
	|	AND RegisterData.PaymentDate <= &CurrentDate
	|;
	|
	|SELECT TOP 1
	|	RegisterData.PaymentObject AS PaymentObject,
	|	RegisterData.BankAccountCashAccount AS BankAccountCashAccount,
	|	RegisterData.PaymentDate AS PaymentDate,
	|	RegisterData.PayerBeneficiary AS PayerBeneficiary,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.AmountType AS AmountType,
	|	RegisterData.ReceiptIssue AS ReceiptIssue,
	|	RegisterData.Currency AS Currency
	|FROM
	|	InformationRegister.ScheduleOfPayments AS RegisterData
	|WHERE
	|	RegisterData.PaymentObject IN (&PaymentObjects)
	|	AND RegisterData.PaymentDate > &CurrentDate
	|ORDER BY
	|	PaymentDate
	|";
	
	Query.SetParameter("PaymentObjects", PaymentObjects);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	QueryResult = Query.ExecuteBatch();
	If QueryResult[0].IsEmpty() Then
		SampleIndex = 1;
	Else
		SampleIndex = 0;
	EndIf;
	
	Selection = QueryResult[SampleIndex].Select();
	While Selection.Next() Do
		
		KeyStructure1 = New Structure;
		For Each Column In QueryResult[SampleIndex].Columns Do
			KeyStructure1.Insert(Column.Name);
		EndDo;
		FillPropertyValues(KeyStructure1, Selection);
		
		RecordKey = InformationRegisters.ScheduleOfPayments.CreateRecordKey(KeyStructure1);
		Result.Add(RecordKey);
	EndDo;
	
	Return Result;
	
EndFunction

// Forms the data structure for filling out the payment refund document based on the order to the client
//
// Parameters:
//	SalesOrder - DocumentRef.SalesOrder
//	DocumentObjectToFillIn_ - DocumentObject - filling document
//	PaymentMethod - EnumRef.PaymentForms - form of payment by customer's order
//
// Returns:
//	Structure - data structure for filling out the document
//
Function GenerateFillInDataForReturningPaymentFromCustomerSOrder(SalesOrder, DocumentObjectToFillIn_, PaymentMethod = Undefined) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	CASE
		|		WHEN SalesOrder.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|			THEN ISNULL(CompaniesBankAccounts.Owner, VALUE(Catalog.Companies.EmptyRef))
		|		WHEN SalesOrder.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
		|			THEN ISNULL(CashAccounts.Owner, VALUE(Catalog.Companies.EmptyRef))
		|		ELSE SalesOrder.Organization
		|	END AS Organization,
		|	SalesOrder.CashAccount AS CashAccount,
		|	CASE
		|		WHEN SalesOrder.BankAccount = VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|			THEN SalesOrder.Contract.BankAccount
		|		ELSE SalesOrder.BankAccount
		|	END AS BankAccount,
		|	CASE
		|		WHEN SalesOrder.CounterpartyBankAccount = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|			THEN SalesOrder.Contract.CounterpartyBankAccount
		|		ELSE SalesOrder.CounterpartyBankAccount
		|	END AS CounterpartyBankAccount,
		|	SalesOrder.PaymentMethod AS PaymentMethodOfPaymentRequest,
		|	CASE
		|		WHEN &PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS PaymentMethodCash,
		|	CASE
		|		WHEN &PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment) 
		|			OR &PaymentMethod = VALUE(Enum.PaymentForms.InstantPayments)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS PaymentMethodBankAccount,
		|	SalesOrder.Currency AS ARAPCurrency,
		|	SalesOrder.Counterparty AS Counterparty,
		|	SalesOrder.Contract AS Contract,
		|	SalesOrder.Partner AS Partner,
		|	SalesOrder.Ref AS DocumentBasis,
		|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
		|	CASE
		|		WHEN SalesOrder.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|			THEN ISNULL(CompaniesBankAccounts.CashCurrency, VALUE(Catalog.Currencies.EmptyRef))
		|		WHEN SalesOrder.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
		|			THEN SalesOrder.CashAccount.CashCurrency
		|		ELSE ISNULL(SalesOrder.Contract.BankAccount.CashCurrency, SalesOrder.Currency)
		|	END AS Currency,
		|	SalesOrder.Department AS Department,
		|	ISNULL(CounterpartyContracts.PaymentsAsPer275FZ, FALSE) AS PaymentsAsPer275FZ,
		|	ISNULL(CounterpartyContracts.ForeignAssigneeInApprovedSDOList, FALSE) AS ForeignAssigneeInApprovedSDOList,
		|	ISNULL(CounterpartyContracts.ContractWithSDOParticipant, FALSE) AS ContractWithSDOParticipant,
		|	ISNULL(CounterpartyContracts.PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation, FALSE) AS PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation,
		|	SalesOrder.Currency AS DocumentCurrency,
		|	SalesOrder.Priority AS Priority,
		|	CASE
		|		WHEN SalesOrder.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|			THEN SalesOrder.LineOfBusiness
		|		WHEN SalesOrder.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|			THEN CounterpartyContracts.LineOfBusiness
		|		WHEN SalesOrder.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
		|			THEN CashAccounts.LineOfBusiness
		|		ELSE CompaniesBankAccounts.LineOfBusiness
		|	END AS LineOfBusiness,
		|	CASE
		|		WHEN SalesOrder.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
		|				AND ISNULL(CashAccounts.EnableCreatingCashIssueWithoutPaymentRequest, FALSE) = FALSE
		|			THEN TRUE
		|		WHEN SalesOrder.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|				AND ISNULL(CompaniesBankAccounts.EnableCreatingCashIssueWithoutPaymentRequest, FALSE) = FALSE
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS PaymentByRequests
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
		|		ON SalesOrder.BankAccount = CompaniesBankAccounts.Ref
		|		LEFT JOIN Catalog.CashAccounts AS CashAccounts
		|		ON SalesOrder.CashAccount = CashAccounts.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|		ON SalesOrder.Contract = CounterpartyContracts.Ref
		|WHERE
		|	SalesOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|	AND SalesOrder.Ref = &Ref";
	
	Query.SetParameter("Ref", SalesOrder);
	Query.SetParameter("PaymentMethod", PaymentMethod);
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		ObjectMetadata = DocumentObjectToFillIn_.Metadata();
		Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập chứng từ %1 trên cơ sở chứng từ %2';
					|ru = 'Не требуется вводить документ %1 на основании документа %2';
					|en = 'It is not required to enter document %1 based on document %2'; fa = 'It is not required to enter document %1 based on document %2';
					|it = 'Non è richiesto inserire il documento %1 in base al documento %2';
					|pl = 'Nie trzeba wprowadzać dokumentu %1 na podstawie dokumentu %2';
					|tr = '%2 belgesine göre %1 belgesini girmeye gerek yok'"),
				ObjectMetadata.ObjectPresentation,
				SalesOrder);
		
		Raise Text;
		
	EndIf;

	FillingData = New Structure;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectingDetailedRecords = QueryResult.Select();
	SetPrivilegedMode(False);
	
	SelectingDetailedRecords.Next();
	
	FillPropertyValues(FillingData, SelectingDetailedRecords);
	
	If PaymentMethod = Undefined Then
		PaymentMethod = FillingData.PaymentMethodOfPaymentRequest;
	EndIf;
	
	FillInDetailsOfDocumentOnFormOfPayment(PaymentMethod, FillingData);
	
	If Not ValueIsFilled(PaymentMethod) Then
		
		FillingData.PaymentMethodCash = True;
		FillingData.PaymentMethodBankAccount = True;
		
	EndIf;
	
	If Not ValueIsFilled(FillingData.CounterpartyBankAccount) Then
		FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency,
			FillingData.BankAccount);
	EndIf;
		
	AccountAttributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(
			FillingData.CounterpartyBankAccount);
	FillingData.Insert("PaymentPurposes", AccountAttributes.PurposeText);
	
	FillingData.Insert("RequiredPaymentDate", CurrentSessionDate());	
	
	Return FillingData;
	
EndFunction

// Fills in the tabular part of the transcript of the payment documents for the customer's order
//
// Parameters:
//	FillingData - Structure - structure of the main data of the Customer Order document 
//	TabularPartDecryptionOfPayment - TabularSection - tabular part of the payment document
//
Procedure FillInTranscriptOfPaymentOnClientSOrder(FillingData, TabularPartDecryptionOfPayment) Export
	
	DataParameters = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
	DataParameters.SalesOrder     = FillingData.DocumentBasis;
	DataParameters.Contract          = FillingData.Contract;
	DataParameters.DocumentCurrency  = FillingData.Currency;
	DataParameters.Partner          = FillingData.Partner;
	DataParameters.PaymentPurpose = FillingData.DocumentBasis;
	
	ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(DataParameters,
																	TabularPartDecryptionOfPayment,
																	0,
																	FillingData.Organization,
																	FillingData.BusinessOperation);
	
EndProcedure

// Forms the data structure for filling out the payment refund document based on the receipt of non-cash funds
//
// Parameters:
//	DocumentInflow - DocumentRef.BankAccountReceiptNote
//
// Returns:
//	Structure - data structure for filling out the document
//
Function GenerateFillInDataForRefundOfPaymentFromReceiptOfNonCashFunds(DocumentInflow) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BankAccountReceiptNote.Organization AS Organization,
		|	BankAccountReceiptNote.BankAccount AS BankAccount,
		|	BankAccountReceiptNote.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	VALUE(Enum.PaymentForms.BankAccountPayment) AS PaymentMethodOfPaymentRequest,
		|	FALSE AS PaymentMethodCash,
		|	TRUE AS PaymentMethodBankAccount,
		|	BankAccountReceiptNote.Counterparty AS Counterparty,
		|	BankAccountReceiptNote.Contract AS Contract,
		|	BankAccountReceiptNote.Partner AS Partner,
		|	BankAccountReceiptNote.Ref AS DocumentBasis,
		|	BankAccountReceiptNote.DocumentAmount AS DocumentAmount,
		|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
		|	ISNULL(CounterpartyContracts.PaymentsAsPer275FZ, FALSE) AS PaymentsAsPer275FZ,
		|	ISNULL(CounterpartyContracts.ForeignAssigneeInApprovedSDOList, FALSE) AS ForeignAssigneeInApprovedSDOList,
		|	ISNULL(CounterpartyContracts.ContractWithSDOParticipant, FALSE) AS ContractWithSDOParticipant,
		|	ISNULL(CounterpartyContracts.PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation, FALSE) AS PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation,
		|	BankAccountReceiptNote.Currency AS Currency,
		|	BankAccountReceiptNote.Currency AS ARAPCurrency,
		|	BankAccountReceiptNote.BusinessOperation AS EconomicOperationOfFoundationDocument,
		|	CASE
		|		WHEN BankAccountReceiptNote.SenderBankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|			THEN BankAccountReceiptNote.SenderBankAccount.Owner
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS CompanyRecipient,
		|	BankAccountReceiptNote.SenderBankAccount AS BankAccountBeneficiary,
		|	BankAccountReceiptNote.Department AS Department,
		|	BankAccountReceiptNote.AcquiringContract AS AcquiringContract
		|FROM
		|	Document.BankAccountReceiptNote AS BankAccountReceiptNote
		|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|		ON BankAccountReceiptNote.Contract = CounterpartyContracts.Ref
		|WHERE
		|	BankAccountReceiptNote.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentInflow);
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectingDetailedRecords = QueryResult.Select();
	SetPrivilegedMode(False);
	
	SelectingDetailedRecords.Next();
	
	FillPropertyValues(FillingData, SelectingDetailedRecords);
	
	If FillingData.EconomicOperationOfFoundationDocument = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment Then
		FillingData.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment;		
	ElsIf FillingData.EconomicOperationOfFoundationDocument = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		FillingData.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany;
	EndIf;	
	
	FillInDetailsOfDocumentOnFormOfPayment(FillingData.PaymentMethodOfPaymentRequest, FillingData, FillingData.ARAPCurrency);
	
	AccountAttributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(
						FillingData.CounterpartyBankAccount);
	FillingData.Insert("PaymentPurposes", AccountAttributes.PurposeText);
	
	FillingData.Insert("RequiredPaymentDate", CurrentSessionDate());
	
	Return FillingData;
	
EndFunction

// Fills in the tabular part of the transcript of the payment documents according to the payment documents
//
// Parameters:
//	DocumentPayments - DocumentRef.BankAccountReceiptNote, DocumentRef.CashAccountReceiptNote - The document Foundation
//	BusinessOperation - EnumRef.BusinessTransactions - payment document operation
//	TabularPartDecryptionOfPayment - TabularSection - tabular part of the payment document
//
Procedure FillInPaymentTranscriptForPaymentDocument(DocumentPayments, BusinessOperation, TabularPartDecryptionOfPayment) Export
	
	AttributeOfPaymentDecryption = Common.ObjectAttributeValue(DocumentPayments, "ARAPDetails");
	DecryptionTable = AttributeOfPaymentDecryption.Unload();
	
	CFItem = SettingsValueCached.GetCashFlowItem(BusinessOperation);
	DecryptionTable.FillValues(CFItem, "CashFlowItem");
	
	TabularPartDecryptionOfPayment.Load(DecryptionTable);
	
EndProcedure

// Forms the data structure for filling out the payment refund document based on the cash receipt order
//
// Parameters:
//	DocumentInflow - DocumentRef.CashAccountReceiptNote
//
// Returns:
//	Structure - data structure for filling out the document
//
Function GenerateFillInDataForReturningPaymentFromIncomingCashOrder(DocumentInflow) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	CashAccountReceiptNote.Organization AS Organization,
		|	CashAccountReceiptNote.CashAccount AS CashAccount,
		|	VALUE(Enum.PaymentForms.CashAccountPayment_) AS PaymentMethodOfPaymentRequest,
		|	TRUE AS PaymentMethodCash,
		|	FALSE AS PaymentMethodBankAccount,
		|	CashAccountReceiptNote.Counterparty AS Counterparty,
		|	CashAccountReceiptNote.Contract AS Contract,
		|	CashAccountReceiptNote.Partner AS Partner,
		|	CashAccountReceiptNote.Ref AS DocumentBasis,
		|	CashAccountReceiptNote.DocumentAmount AS DocumentAmount,
		|	CashAccountReceiptNote.Currency AS ARAPCurrency,
		|	CashAccountReceiptNote.Currency AS DocumentCurrency,
		|	CashAccounts.CashCurrency AS Currency,
		|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
		|	CashAccountReceiptNote.BusinessOperation AS EconomicOperationOfFoundationDocument,
		|	ISNULL(CounterpartyContracts.PaymentsAsPer275FZ, FALSE) AS PaymentsAsPer275FZ,
		|	ISNULL(CounterpartyContracts.ForeignAssigneeInApprovedSDOList, FALSE) AS ForeignAssigneeInApprovedSDOList,
		|	ISNULL(CounterpartyContracts.ContractWithSDOParticipant, FALSE) AS ContractWithSDOParticipant,
		|	ISNULL(CounterpartyContracts.PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation, FALSE) AS PaymentOfExpensesAccordingToTariffsThatAreASubjectToStateRegulation,
		|	CashAccountReceiptNote.BankAccount AS BankAccount,
		|	CashAccountReceiptNote.Department AS Department,
		|	CashAccountReceiptNote.CashAccountIssuer AS CashAccountRecipient,
		|	CASE
		|		WHEN NOT CashAccounts.EnableCreatingCashIssueWithoutPaymentRequest
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS PaymentByRequests
		|FROM
		|	Document.CashAccountReceiptNote AS CashAccountReceiptNote
		|		INNER JOIN Catalog.CashAccounts AS CashAccounts
		|		ON CashAccountReceiptNote.CashAccount = CashAccounts.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|		ON CashAccountReceiptNote.Contract = CounterpartyContracts.Ref
		|WHERE
		|	CashAccountReceiptNote.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentInflow);
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;	
	
	SelectingDetailedRecords = QueryResult.Select();
	SetPrivilegedMode(False);
	
	SelectingDetailedRecords.Next();
	
	FillPropertyValues(FillingData, SelectingDetailedRecords);
	
	If FillingData.EconomicOperationOfFoundationDocument = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		FillingData.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany;
	EndIf;
		
	FillInDetailsOfDocumentOnFormOfPayment(FillingData.PaymentMethodOfPaymentRequest, FillingData, FillingData.ARAPCurrency);
	
	FillingData.Insert("CounterpartyBankAccount");
	
	If ValueIsFilled(FillingData.Currency) Then
		FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
	Else
		FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty);
	EndIf;
	
	AccountAttributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(
						FillingData.CounterpartyBankAccount);
	FillingData.Insert("PaymentPurposes", AccountAttributes.PurposeText);
	
	FillingData.Insert("RequiredPaymentDate", CurrentSessionDate());	
	
	Return FillingData;
	
EndFunction

// Returns the filling data for the refund of the payment according to the "Acquiring operation" document.
// 
// Parameters:
//  DocumentBasis - DocumentRef.PaymentCardTransaction - The document from which the filling data is being fetched.
// 
// Returns:
//  Structure - Filling Data For The Refund Of The Acquiring Transaction Payment:
// * Organization - CatalogRef.Companies - Organization of the document.
// * BusinessOperation - EnumRef.BusinessTransactions - business transaction of return of payment to the client.
// * PaymentMethodOfPaymentRequest - EnumRef.PaymentForms - the Form of payment of the application.
// * PaymentMethodCash - Boolean - indicates cash payment.
// * PaymentMethodBankAccount - Boolean - indicates a non-cash payment.
// * MethodOfPaymentPaymentCard - Boolean - indicates payment by credit card.
// * Counterparty - CatalogRef.Counterparties - Contractor.
// * AcquiringContract - CatalogRef.AcquiringContracts - Contract for connection to the payment system.
// * DocumentAmount - Number - the amount of the document.
// * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// * Currency - CatalogRef.Currencies - the currency of the document.
// * Department - CatalogRef.BusinessStructure - unit.
// * DocumentBasis - DocumentRef.PaymentCardTransaction - document Foundation.
// * Contract - CatalogRef.CounterpartyContracts - the Contract of the counterparty.
// * Partner - CatalogRef.Partners - Partner.
// * LineOfBusiness - CatalogRef.LinesOfBusiness - direction of activity.
// * VATTaxation - EnumRef.VATTaxationTypes - taxation according to the document.
// * CounterpartyBankAccount - CatalogRef.CounterpartyBankAccounts - Counterparty's Bank account.
// * PaymentPurposes - String - the text of the payment purpose.
// * RequiredPaymentDate - Date - payment date.
//
Function FillingDataForRefundOfAcquiringTransactionPayment(DocumentBasis) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PaymentCardTransaction.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.PaymentCard) AS PaymentMethodOfPaymentRequest,
		|	FALSE AS PaymentMethodCash,
		|	FALSE AS PaymentMethodBankAccount,
		|	TRUE AS MethodOfPaymentPaymentCard,
		|	PaymentCardTransaction.Counterparty AS Counterparty,
		|	PaymentCardTransaction.AcquiringContract AS AcquiringContract,
		|	PaymentCardTransaction.POSTerminal AS POSTerminal,
		|	PaymentCardTransaction.DocumentAmount AS DocumentAmount,
		|	PaymentCardTransaction.Currency AS ARAPCurrency,
		|	PaymentCardTransaction.Currency AS Currency,
		|	PaymentCardTransaction.Department AS Department,
		|	PaymentCardTransaction.Ref AS DocumentBasis,
		|	PaymentCardTransaction.Contract AS Contract,
		|	PaymentCardTransaction.Partner AS Partner,
		|	PaymentCardTransaction.LineOfBusiness AS LineOfBusiness,
		|	PaymentCardTransaction.VATTaxation AS VATTaxation,
		|	PaymentCardTransaction.FPSPaymentID AS FPSPaymentID
		|FROM
		|	Document.PaymentCardTransaction AS PaymentCardTransaction
		|WHERE
		|	PaymentCardTransaction.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
		|	AND PaymentCardTransaction.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionDetailRecords = QueryResult.Select();
	SelectionDetailRecords.Next();
	
	FillPropertyValues(FillingData, SelectionDetailRecords);
	
	FillingData.Insert("CounterpartyBankAccount");
	
	If ValueIsFilled(FillingData.Currency) Then
		FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty,
			FillingData.Currency);
	Else
		FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			FillingData.Counterparty);
	EndIf;
	
	AccountAttributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(
						FillingData.CounterpartyBankAccount);
	FillingData.Insert("PaymentPurposes", AccountAttributes.PurposeText);
	
	FillingData.Insert("RequiredPaymentDate", CurrentSessionDate());
	
	Return FillingData;
	
EndFunction

// Gets the cashier from the last ACW or ICO.
// 
// Parameters:
//  Date - Date
//  Organization - CatalogRef.Companies - selection by organization for ACW and ICO documents
//  CashAccount - CatalogRef.CashAccounts - selection by cash account for ACW and ICO documents
// 
// Returns:
//  CatalogRef.Persons - Cashier Of The Last ACW Or ICO
Function CashierOfLastACWOrICO(Date, Organization, CashAccount) Export
	
	Cashier = Catalogs.Persons.EmptyRef();
	
	ListOfDocumentTypes = New Array;
	ListOfDocumentTypes.Add(Common.MetadataObjectID("Document.CashAccountReceiptNote"));
	ListOfDocumentTypes.Add(Common.MetadataObjectID("Document.CashVoucher"));
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	CASE
		|		WHEN DocumentsRegistry.Ref REFS Document.CashAccountReceiptNote
		|			THEN CAST(DocumentsRegistry.Ref AS Document.CashAccountReceiptNote).Cashier
		|		ELSE CAST(DocumentsRegistry.Ref AS Document.CashVoucher).Cashier
		|	END AS Cashier
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.RefType IN(&RefType)
		|	AND DocumentsRegistry.Organization = &Organization
		|	AND DocumentsRegistry.IBDocumentDate >= DATEADD(&Date, MONTH, -3)
		|	AND DocumentsRegistry.IBDocumentDate <= &Date
		|	AND DocumentsRegistry.StorageLocation.Key = &CashAccount
		|
		|ORDER BY
		|	DocumentsRegistry.IBDocumentDate DESC";
	
	Query.SetParameter("RefType", ListOfDocumentTypes);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CashAccount", CashAccount);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Cashier = Selection.Cashier;
	EndIf;
	
	Return Cashier;
	
EndFunction

// Returns the organization's current bank account from the general settings.
//
// Returns:
//   CatalogRef.CompaniesBankAccounts - The organization's current bank account or an empty link
//
Function OrganizationSCurrentBankAccount() Export

	Result = Common.CommonSettingsStorageLoad("CurrentBankAccount", ""); // CatalogRef.CompaniesBankAccounts
	
	If Result = Undefined Then
		Return Catalogs.CompaniesBankAccounts.EmptyRef();
	ElsIf ValueIsFilled(Result)
		And Common.ObjectAttributeValue(Result, "IsFolder") Then
		Return Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	Return Result;

EndFunction

// Receives the organization's bank account according to the following rules:
// If the bank account passed as a parameter is already full, returns it.
// If the payment Form passed as a parameter does not provide for filling out a bank account, it returns an empty
// link to the bank account.
// If the bank account defined by the passed parameters is the only one in the information database, it returns it.
// If there is more than one bank account in the database, it returns an empty link to the bank account.
//
// Parameters:
//   ParametersOfAccount - See ParametersForFillingOutOrganizationSBankAccount.
//   BankAccount - CatalogRef.CompaniesBankAccounts - Bank account that need to be filled.
//   PaymentMethod - EnumRef.PaymentForms - The Form of payment, which determines the need to obtain a bank account.
//
// Returns:
//   CatalogRef.CompaniesBankAccounts - the default bank account of the organization.
//
Function GetOrganizationSDefaultBankAccount(ParametersOfAccount = Undefined, BankAccount = Undefined,
	PaymentMethod = Undefined) Export
	
	If ValueIsFilled(BankAccount) Then
		Return BankAccount;
	ElsIf Not ValueIsFilled(PaymentMethod)
		Or PaymentMethod = Enums.PaymentForms.BankAccountPayment
		Or PaymentMethod = Enums.PaymentForms.InstantPayments Then
		
		If ParametersOfAccount = Undefined Then
			ParametersOfAccount = ParametersForFillingOutOrganizationSBankAccount();
		EndIf;
		
		Return SettingsValueCached.OrganizationSDefaultBankAccount(ParametersOfAccount);
	Else
		Return Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
EndFunction

// Receives the bank account of the counterparty according to the following rules:
// If the bank account passed as a parameter is already filled in, returns it.
// If the payment Form passed as a parameter does not provide for filling out a bank account or the
// Counterparty is not specified in the account parameters, it returns an empty link to the bank account.
// If the bank account defined by the passed parameters is the only one in the information database, it returns it.
// If there is more than one bank account in the database, it returns an empty link to the bank account.
//
// Parameters:
//  ParametersOfAccount - See ParametersForFillingInCounterpartySBankAccount.
//  BankAccount - CatalogRef.CounterpartyBankAccounts - Bank account that need to be filled.
//  PaymentMethod - EnumRef.PaymentForms - The Form of payment, which determines the need to obtain a bank account.
//
// Returns:
//  CatalogRef.CounterpartyBankAccounts - counterparty's default bank account.
//
Function GetDefaultCounterpartyBankAccount(ParametersOfAccount, BankAccount = Undefined,
	PaymentMethod = Undefined) Export
	
	If ValueIsFilled(BankAccount) Then
		Return BankAccount;
	ElsIf ValueIsFilled(ParametersOfAccount.Counterparty)
		And (Not ValueIsFilled(PaymentMethod)
		Or PaymentMethod = Enums.PaymentForms.BankAccountPayment
		Or PaymentMethod = Enums.PaymentForms.InstantPayments) Then
		
		Return SettingsValueCached.DefaultCounterpartyBankAccount(ParametersOfAccount);
	Else
		Return Catalogs.CounterpartyBankAccounts.EmptyRef();
	EndIf;
	
EndFunction

#EndRegion

#Region EDIWithBanks

// Checks whether a business operation belongs to a set of salary operations.
//
// Parameters:
//    BusinessOperation - EnumRef.BusinessTransactions - Household. operation.
//
// Returns:
//    Boolean - A sign of belonging.
//
Function SalaryOperation(BusinessOperation) Export
	
	OperationArray = New Array();
	OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
	OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentByDistributor);
	OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentToEmployee);
	OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
	OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentToBankAccounts);
	OperationArray.Add(Enums.BusinessTransactions.SalaryPayment);
	OperationArray.Add(Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram);
	OperationArray.Add(Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts);
	
	If OperationArray.Find(BusinessOperation) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Selects a fixed part of the payment purpose without service characters, words less than 2 characters, or numbers.
//
// Parameters:
//    TimeLine - String - The string being converted.
//
// Returns:
//    String - Formatted destination string.
//
Function FormatPaymentPurpose(Val TimeLine) Export
	
	InvalidChars = "0123456789""/\[]:;|=?*<>.,-_(){}+-=№@";
	
	For Position = 1 To StrLen(InvalidChars) Do
		TimeLine = StrReplace(TimeLine, Mid(InvalidChars, Position, 1), " ");
	EndDo;
	
	WordArray = DecomposeDestinationStringIntoArrayOfWords(TimeLine);
	
	ResultRow = StrConcat(WordArray, " ");
	
	Return TrimAll(ResultRow);
	
EndFunction

// The data structure of an operation from an extract when reading from a file.
// 
// Returns:
//  Structure - LongDesc:
//   * Number - String - document number
//   * Date - Date - Document date
//   * Sum - Number - The amount of the document
//   * DateOfTransaction - Date - date of the operation
//   * PaymentDirection - String - "1" - debiting from the current account, "2" - receipt to the current account
//   * Id - String - unique identifier of the operation
//   * Payer - String - name of the payer
//   * PayerTIN - String - Payer's INN
//   * PayerAccount - String - payer's account number
//   * PayerCountry - String - payer's country
//   * PayerSWIFTBank - String - SWIFT of the payer's bank
//   * PayerBank_ - String - name of the payer's bank
//   * Recipient - String - name of the recipient
//   * BeneficiaryTIN - String - The INN of the recipient
//   * BeneficiaryAccount - String - recipient's account number
//   * RecipientCountry - String - recipient's country
//   * RecipientSWIFTBank - String - SWIFT of the recipient's bank
//   * RecipientBank_ - String - name of the recipient's bank
//   * PaymentPurposes - String - purpose of payment.
Function LoadedOperationData() Export
	
	Return New Structure(
		"Number,
		|Date,
		|Sum,
		|DateOfTransaction,
		|PaymentDirection,
		|Id,
		|Payer,
		|PayerTIN,
		|PayerAccount,
		|PayerCountry,
		|PayerSWIFTBank,
		|PayerBank_,
		|Recipient,
		|BeneficiaryTIN,
		|BeneficiaryAccount,
		|RecipientCountry,
		|RecipientSWIFTBank,
		|RecipientBank_,
		|PaymentPurposes");
	
EndFunction

// Header structure template that is used when reading extract data from a file
// 
// Returns:
// 	Structure - LongDesc:
// * Sender - String - the bank from which the statement was received
// * CreationDate - Date - date and time of file formation
// * StartDate - Date - start date of the statement period
// * EndDate - Date - date of the end of the discharge period.
Function StatementTitle() Export
	
	Return New Structure("Sender, CreationDate, StartDate, EndDate");
	
EndFunction

#EndRegion

#Region DocumentFillingChecks

// The function generates a request for the table part "payment Decryption".
//
// Parameters:
//	ARAPDetails - TabularSection - tabular part of the document
//	Organization - CatalogRef.Companies - Organization of the document
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//	ARAPObject - CatalogRef.ARAPObjects - the object of the calculations of the owner of the decryption of the payment.
//
// Returns:
//	Query - request for the tabular part.
//
Function RequestForTablePartPaymentDecryption(ARAPDetails, Organization, BusinessOperation = Undefined, ARAPObject = Undefined) Export
	
	Query = New Query("SELECT ALLOWED
	|	*
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT ALLOWED
	|	DocumentTable.LineNumber AS LineNumber,
	|
	|	CASE WHEN DocumentTable.ProformaInvoice <> VALUE(Document.CustomerCommercialInvoice.EmptyRef)
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|		AND &UseCustomerCommercialInvoices
	|	THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS CheckingInvoiceForPayment
	|
	|FROM
	|	DocumentTable AS DocumentTable
	|
	|WHERE
	|	DocumentTable.ARAPObject.Organization NOT IN(&Organization)
	|	AND &FIlter_By_Type
	|
	|ORDER BY
	|	DocumentTable.LineNumber
	|;
	|");
	
	DocumentTable = ARAPDetails.Unload();
	If DocumentTable.Columns.Find("ProformaInvoice") = Undefined Then
		DocumentTable.Columns.Add("ProformaInvoice", New TypeDescription("DocumentRef.CustomerCommercialInvoice"));
	EndIf;
	ColumnOrderFromDocument = DocumentTable.Columns.Find("ARAPObject");
	ColumnOrderFromDocument.Name = "OrderFromDocument";
	ArrayOfTypesToAdd = New Array;
	ArrayOfTypesToAdd.Add(Type("DocumentRef.CommissionReportIntercompany"));
	ArrayOfTypesToAdd.Add(Type("DocumentRef.CustomerInvoiceIntercompany"));
	ArrayOfTypesToAdd.Add(Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany"));
	DocumentTable.Columns.Add("ARAPObject", New TypeDescription(ColumnOrderFromDocument.ValueType, ArrayOfTypesToAdd));
	DocumentTable.LoadColumn(DocumentTable.UnloadColumn(ColumnOrderFromDocument), "ARAPObject");
	
	Query.SetParameter("DocumentTable", DocumentTable);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("UseCustomerCommercialInvoices", GetFunctionalOption("UseCustomerCommercialInvoices"));
	
	If ARAPObject <> Undefined Then
		Query.Text = StrReplace(Query.Text,"&FIlter_By_Type","DocumentTable.ARAPObject <> &ARAPObject");
		Query.SetParameter("ARAPObject", ARAPObject);
	Else
		Query.Text = StrReplace(Query.Text,"&FIlter_By_Type","TRUE");
	EndIf;
	
	AvailableCompanies = New Array;
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		RequestForAvailableOrganizations = New Query(
		"SELECT ALLOWED DISTINCT
		|	Companies.ParentCompany AS Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref = &Organization
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	BranchOffices_.Ref
		|FROM
		|	Catalog.Companies AS BranchOffices_
		|WHERE
		|	BranchOffices_.TransactionsUsingParentCompanyAreAllowed
		|	AND TRUE IN (SELECT TOP 1
		|				TRUE
		|			FROM
		|				Catalog.Companies AS ParentOrganizations
		|			WHERE
		|				ParentOrganizations.Ref IN (&Organization)
		|				AND BranchOffices_.ParentCompany = ParentOrganizations.ParentCompany
		|	)");
		RequestForAvailableOrganizations.SetParameter("Organization", Organization);
		
		AvailableCompanies = RequestForAvailableOrganizations.Execute().Unload().UnloadColumn("Ref");
		
	EndIf;
	
	AvailableCompanies.Add(Organization);
	
	Query.SetParameter("Organization", AvailableCompanies);
	
	Return Query;
	
EndFunction // Request for a different part of the payment decryption()

// The procedure checks whether the table part "payment Decryption"is filled in.
//
// Parameters:
//	DocumentObject - DocumentObject - Document
//	DocumentAmount - Number - Total amount of the document
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//	Cancel - Boolean - Flag for refusing to continue working
//	FlagEDIWithBanks - Boolean - Whether to use it when exchanging with banks
//	FillingErrors - String - A string that accumulates validation errors.
//
Procedure CheckCompletionOfPaymentDecryption(
	DocumentObject,
	DocumentAmount,
	BusinessOperation,
	Cancel,
	FlagEDIWithBanks = False,
	FillingErrors = ""
	) Export
	
	ArrayOfUncheckedOperations = New Array;
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.CashIssueToAnotherCashAccount);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.CashDepositToBankAccount);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
	If Not Constants.UsePayroll.Get() Then
		ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.TransferOfTaxesAndContributions);
		ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.SalaryPayment);
		ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
		ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.SalaryPaymentToBankAccounts);
		ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
		ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.SalaryPaymentByDistributor);
		ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.SalaryPaymentToEmployee);
	EndIf;
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	If ArrayOfUncheckedOperations.Find(BusinessOperation) <> Undefined Then
		Return;
	EndIf;
	
	// Let's check the correspondence of the amounts of the document and the tabular part.
	If DocumentObject.ARAPDetails.Count() > 0
		And DocumentAmount <> DocumentObject.ARAPDetails.Total("Sum")
	Then
		Text = NStr("vi = 'Số tiền theo dòng trong phần bảng phải bằng số tiền trong chứng từ';
					|ru = 'Сумма по строкам в табличной части должна равняться сумме документа';
					|en = 'Total amount in the table rows must be equal to the document amount'; fa = 'Total amount in the table rows must be equal to the document amount';
					|it = 'L''importo per righe della parte tabulare deve essere pari all''importo del documento';
					|pl = 'Wartość w wierszach w części tabelarycznej powinna być równa kwocie dokumentu';
					|tr = 'Tablo bölümündeki satırların toplamı belgenin toplamına eşit olmalıdır'");
		If FlagEDIWithBanks Then
			AddFillInError(FillingErrors, Text);
		Else
			CommonClientServer.MessageToUser(
				Text, DocumentObject, "ARAPDetails[0].Sum",, Cancel);
		EndIf;
	EndIf;
	
	// Let's check the correspondence of the organization in the header of the document and in the tabular part.
	Query = RequestForTablePartPaymentDecryption(
		DocumentObject.ARAPDetails,
		DocumentObject.Organization,
		BusinessOperation,
		ARAPObjectsServer.GetCalculationObjectFromLink(DocumentObject.Ref));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
	
		If Selection.CheckingInvoiceForPayment Then
			TextDocument_ = NStr("vi = 'yêu cầu thanh toán';
								|ru = 'счете на оплату';
								|en = 'commercial invoice'; fa = 'commercial invoice';
								|it = 'Alla fattura in pagamento';
								|pl = 'rachunku do zapłaty';
								|tr = 'ticari fatura'");
			FieldName = "ProformaInvoice";
		Else
			TextDocument_ = NStr("vi = 'đối tượng tính toán';
								|ru = 'объекте расчетов';
								|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
								|it = 'oggetto di regolamenti';
								|pl = 'obiekcie rozliczeń';
								|tr = 'alacak/borç nesnesi'");
			FieldName = "ARAPObject";
		EndIf;
		
		If TypeOf(DocumentObject) = Type("DocumentObject.ReturnOfGoodsFromCustomer")
			Or TypeOf(DocumentObject) = Type("DocumentObject.ReturnOfGoodsToVendor") Then
			Field = "ReducedDebtByLine";
			DataKey = Undefined;
		Else
			Field = "ARAPDetails[" + (Selection.LineNumber - 1) + "]." + FieldName;
			DataKey = DocumentObject;
		EndIf;
		
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Doanh nghiệp trong %1 ở dòng %2 trong danh sách ""Diễn giải thanh toán"" không tương ứng với doanh nghiệp trong chứng từ %3';
				|ru = 'Организация в %1 в строке %2 списка ""Расшифровка платежа"" не соответствует организации документа %3';
				|en = 'Company in %1 in line %2 of the ""Payment details"" list does not match the company mentioned in document %3 '; fa = 'Company in %1 in line %2 of the ""Payment details"" list does not match the company mentioned in document %3 ';
				|it = 'L''azienda in %1 nella riga %2 dell''elenco ""decrittografia del pagamento"" non coincide con l''azienda del documento %3';
				|pl = 'Firma w %1 w wierszu %2 listy ""Szczegóły płatności"" nie odpowiada firmie dokumentu %3';
				|tr = '""Ödeme bilgileri"" listesinin %2 satırındaki %1 içerisindeki iş yeri, %3 belgesindeki iş yeri ile eşleşmiyor'"),
			TextDocument_,
			Selection.LineNumber,
			DocumentObject.Organization);
		If FlagEDIWithBanks Then
			AddFillInError(FillingErrors, Text);
		Else
			CommonClientServer.MessageToUser(
				Text,
				DataKey,
				Field,
				,
				Cancel);
		EndIf;
	EndDo;
	
EndProcedure // Check the completion of the payment cipher()

// Procedure for checking the application for spending money specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckRequestForSpendingMoney(
	DocumentObject,
	Cancel
	) Export
	
	ArrayOfUncheckedOperations = New Array;
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.CashIssueToAnotherCashAccount);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.CashDepositToBankAccount);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.CashCollectionFromBank);
	ArrayOfUncheckedOperations.Add(Enums.BusinessTransactions.CashCollectionToBank);
	
	If GetFunctionalOption("UsePaymentRequests")
		And ArrayOfUncheckedOperations.Find(DocumentObject.BusinessOperation) = Undefined Then
		
		If Not TypeOf(DocumentObject) = Type("DocumentObject.PaymentCardTransaction") Then
			
			If Not DocumentObject.PaymentByRequests Then
				Return;
			EndIf;
		
			ArrayOfRequests = DocumentObject.ARAPDetails.UnloadColumn("PaymentRequest");
			
			If Not ArrayOfRequests.Count() Then
				Return;
			EndIf;
			
			Query = New Query("
			|SELECT
			|	PRESENTATION(DocumentData.Ref) AS Request,
			|	
			|	CASE WHEN DocumentData.Organization <> &Organization THEN
			|		1
			|	ELSE
			|		0
			|	END AS ThereAreDifferencesInOrganization,
			|	
			|	CASE WHEN DocumentData.Status <> VALUE(Enum.StatusesOfPaymentRequests.AmountDue) THEN
			|		1
			|	ELSE
			|		0
			|	END AS ApplicationNotApprovedForPayment
			|	
			|FROM
			|	Document.PaymentRequest AS DocumentData
			|WHERE
			|	DocumentData.Ref IN (&ArrayOfRequests)
			|");
		
			Query.SetParameter("ArrayOfRequests", ArrayOfRequests);
			Query.SetParameter("Organization", DocumentObject.Organization);
			Query.SetParameter("PaymentDocumentLink", DocumentObject.Ref);
			
			If TypeOf(DocumentObject) = Type("DocumentObject.CashVoucher") Then
				BankAccountCashAccount = DocumentObject.CashAccount;
			ElsIf TypeOf(DocumentObject) = Type("DocumentObject.BankAccountIssue") Then
				BankAccountCashAccount = DocumentObject.BankAccount;
			EndIf;
			
			Query.SetParameter("BankAccountCashAccount", BankAccountCashAccount);
			
			CheckTable = Query.Execute().Unload();
			
			For Each CheckString In CheckTable Do
				
				If CheckString.ThereAreDifferencesInOrganization Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Doanh nghiệp trong chứng từ %1 không tương ứng với doanh nghiệp trong %2';
							|ru = 'Организация документа %1 не соответствует организации в %2';
							|en = 'Company mentioned in the document %1 does not match the company in %2'; fa = 'Company mentioned in the document %1 does not match the company in %2';
							|it = 'L''azienda del documento %1 non coincide con l''azienda in %2';
							|pl = 'Firma dokumentu %1 nie odpowiada firmie w %2';
							|tr = '%1 belgesinin iş yeri, %2 belgesindeki iş yeri ile eşleşmiyor'"),
						DocumentObject.Organization,
						CheckString.Request);
						
					CommonClientServer.MessageToUser(
						ErrorText,
						DocumentObject,
						"",
						,
						Cancel);
				EndIf;
				
				If CheckString.ApplicationNotApprovedForPayment Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 chưa xác nhận thanh toán';
							|ru = '%1 не утверждена к оплате';
							|en = '%1 is not confirmed for payment'; fa = '%1 is not confirmed for payment';
							|it = '%1 non confermato per il pagamento';
							|pl = '%1 nie zatwierdzona do płatności';
							|tr = '%1 ödeme için onaylanmadı'"),
						CheckString.Request);
						
					CommonClientServer.MessageToUser(
						ErrorText,
						DocumentObject,
						"",
						,
						Cancel);
				EndIf;
				
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure // Check for the use of funds()

// Wyborgerseite Of Vibroinsulators - Sample
// Procedure for checking the transfer order specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckOrderForTransferOfFunds(
	DocumentObject,
	Cancel
	) Export
	
	ArrayOfOperationsToCheck = New Array;
	ArrayOfOperationsToCheck.Add(Enums.BusinessTransactions.CashReceiptFromBank);
	ArrayOfOperationsToCheck.Add(Enums.BusinessTransactions.CashDepositToBankAccount);
	ArrayOfOperationsToCheck.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount);
	
	If GetFunctionalOption("UsePaymentRequests")
	   And ArrayOfOperationsToCheck.Find(DocumentObject.BusinessOperation) <> Undefined
	   And ValueIsFilled(DocumentObject.CashTransferReferenceOrder)
	Then
	
		Attributes = Documents.CashTransferReferenceOrder.DocumentAttributes(DocumentObject.CashTransferReferenceOrder);
		If Attributes.Organization <> DocumentObject.Organization Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Doanh nghiệp trong lệnh không tương ứng với doanh nghiệp trong chứng từ %1';
					|ru = 'Организация в распоряжении не соответствует организации документа %1';
					|en = 'Company in the reference does not correspond to the company mentioned in document %1'; fa = 'Company in the reference does not correspond to the company mentioned in document %1';
					|it = 'L''azienda dell''ordine non coincide con l''azienda del documento %1';
					|pl = 'Firma w zamówieniu nie odpowiada firmie dokumentu %1';
					|tr = 'Mevcut iş yeri, %1 belgesinin iş yeri ile eşleşmiyor'"),
				DocumentObject.Organization);
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"CashTransferReferenceOrder",
				,
				Cancel);
			
		EndIf;
		
		If Attributes.Department <> DocumentObject.Department Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bộ phận không khớp với bộ phận chứng từ %1';
					|ru = 'Подразделение в распоряжении не соответствует подразделению документа %1';
					|en = 'The business unit in the reference does not match the business unit in the %1 document'; fa = 'The business unit in the reference does not match the business unit in the %1 document';
					|it = 'Il reparto dell''ordine non coincide con il reparto del documento %1';
					|pl = 'Dział w zamówieniu nie odpowiada działowi dokumentu %1';
					|tr = 'Mevcut departman, %1 belgesindeki departman ile eşleşmiyor '"),
				DocumentObject.Department);
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"CashTransferReferenceOrder",
				,
				Cancel);
			
		EndIf;
		
		If Attributes.Status <> Enums.CashTransferOrderStatuses.AmountDue Then
			
			Text = NStr("vi = 'Lệnh chuyển tiền chưa được xác nhận thanh toán';
						|ru = 'Распоряжение на перемещение денежных средств не утверждено к оплате';
						|en = 'Cash transfer order is not confirmed for payment'; fa = 'Cash transfer order is not confirmed for payment';
						|it = 'Ordine di pagamento in contanti non approvato per il pagamento';
						|pl = 'Zamówienie na przemieszczenie środków pieniężnych-gotówki nie zatwierdzono do płatności';
						|tr = 'Ödenecek nakit transferi talimatı onaylanmadı'");
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"CashTransferReferenceOrder",
				,
				Cancel);
			
		EndIf;
		
		If Attributes.Currency <> DocumentObject.Currency Then
			
			Text = NStr("vi = 'Tiền tệ hạch toán không tương ứng với tiền tệ trong chứng từ';
						|ru = 'Валюта распоряжения не соответствует валюте документа';
						|en = 'Reference currency does not correspond to the document currency'; fa = 'Reference currency does not correspond to the document currency';
						|it = 'La valuta dell''ordine non coincide con la valuta del documento';
						|pl = 'Waluta zamówienia nie odpowiada walucie dokumentu';
						|tr = 'Mevcut para birimi belge para birimi ile eşleşmiyor'");
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"CashTransferReferenceOrder",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure // Check the distribution and relocation of monetary funds()

// The procedure checks the recipient's cash register specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckRecipientSCashRegister(DocumentObject, Cancel) Export
	
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.CashIssueToAnotherCashAccount);
	Array.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
	Array.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	Array.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	Array.Add(Enums.BusinessTransactions.CurrencyConversion);
	
	If Array.Find(DocumentObject.BusinessOperation) <> Undefined
		And ValueIsFilled(DocumentObject.CashAccountRecipient)
		And ValueIsFilled(DocumentObject.Organization) Then
		
		If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromBank
			And ValueIsFilled(DocumentObject.CashAccount)
			And DocumentObject.CashAccount = DocumentObject.CashAccountRecipient Then
			
			Text = NStr("vi = 'Một quỹ tiền mặt không thể là người gửi và người nhận đồng thời';
						|ru = 'Одна и та же касса не может являться отправителем и получателем одновременно';
						|en = 'The same cash account cannot be both withdrawing and receiving'; fa = 'The same cash account cannot be both withdrawing and receiving';
						|it = 'La stessa cassa non può risultare come mittente e destinatario allo stesso tempo';
						|pl = 'Jedna i ta sama kasa nie może być nadawcą i odbiorcą jednocześnie';
						|tr = 'Aynı kasa aynı anda gönderen ve alıcı olamaz.'");
			Common.MessageToUser(
				Text,
				DocumentObject,
				"CashAccountRecipient",
				,
				Cancel);
		Else
			
			CashRegisterAttributes = Common.ObjectAttributesValues(DocumentObject.CashAccountRecipient, "Owner, CashCurrency");
			
			If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashPaymentToAnotherCompany
				And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.RefundToAnotherCompany
				And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And DocumentObject.Organization <> CashRegisterAttributes.Owner Then
				
				Text = ?(DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion,
						NStr("vi = 'Doanh nghiệp trên tài khoản trích không tương ứng với doanh nghiệp trên chứng từ.';
							|ru = 'Организация счета зачисления не соответствует организации документа.';
							|en = 'The company mentioned in the receiving account does not match the company mentioned in the document.'; fa = 'The company mentioned in the receiving account does not match the company mentioned in the document.';
							|it = 'Организация счета зачисления не соответствует организации документа.';
							|pl = 'The company mentioned in the receiving account does not match the company mentioned in the document.';
							|tr = 'Tahakkuk hesabının iş yeri, belgenin iş yeri ile uyumlu değildir.'"),
						NStr("vi = 'Doanh nghiệp theo tài khoản người nhận không tương ứng với doanh nghiệp trên chứng từ.';
							|ru = 'Организация счета получателя не соответствует организации документа.';
							|en = 'The company mentioned in the beneficiary account does not match the company mentioned in the document.'; fa = 'The company mentioned in the beneficiary account does not match the company mentioned in the document.';
							|it = 'Организация счета получателя не соответствует организации документа.';
							|pl = 'The company mentioned in the beneficiary account does not match the company mentioned in the document.';
							|tr = 'Alıcı hesabı iş yeri, belge iş yeri ile eşleşmiyor.'"));

				Common.MessageToUser(
					Text,
					DocumentObject,
					"CashAccountRecipient",
					,
					Cancel);
			EndIf;
			
			If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CurrencyConversion
				And DocumentObject.Currency <> CashRegisterAttributes.CashCurrency Then
				Text = NStr("vi = 'Tiền tệ quỹ tiền mặt người nhận không tương ứng với tiền tệ trong chứng từ';
							|ru = 'Валюта кассы получателя не соответствует валюте документа';
							|en = 'Receiving cash account currency does not correspond to the document currency'; fa = 'Receiving cash account currency does not correspond to the document currency';
							|it = 'La valuta della cassa del destinatario non coincide con la valuta del documento';
							|pl = 'Waluta kasy odbiorcy nie odpowiada walucie dokumentu';
							|tr = 'Alıcının kasasının para birimi ile belgenin para birimi aynı değil'");
				Common.MessageToUser(
					Text,
					DocumentObject,
					"CashAccountRecipient",
					,
					Cancel);
			EndIf;
			
			If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount
				And ValueIsFilled(DocumentObject.CashAccount) And TypeOf(DocumentObject.CashAccountRecipient) <> Type("CatalogRef.CashRegisters") Then
				
				Query = New Query("
					|SELECT
					|	RecipientOfCashTransfer.PaymentBeneficiary AS CashAccountRecipient
					|FROM
					|	Catalog.CashAccounts.RecipientOfCashTransfer AS RecipientOfCashTransfer
					|WHERE
					|	RecipientOfCashTransfer.Ref = &CashAccount");
				Query.SetParameter("CashAccount", DocumentObject.CashAccount);
				
				QueryResult = Query.Execute();
				If Not QueryResult.IsEmpty()
					And QueryResult.Unload().Find(DocumentObject.CashAccountRecipient) = Undefined Then
					
					Text = NStr("vi = 'Quỹ tiền mặt người nhận không hợp lệ để điều chuyển tiền mặt từ quỹ tiền mặt chứng từ';
								|ru = 'Касса получатель недоступна для перемещения денежных средств из кассы документа';
								|en = 'Receiving cash account is not available for moving cash from the document cash account'; fa = 'Receiving cash account is not available for moving cash from the document cash account';
								|it = 'La cassa del destinatario non è accessibile per il trasferimento di fondi dalla cassa del documento';
								|pl = 'Kasa odbiorca jest niedostępna do przemieszczenia środków pieniężnych-gotówki z kasy dokumentu';
								|tr = 'Alıcı kasa, belgenin kasasından para transferi için erişilebilir değil'");
					Common.MessageToUser(
						Text,
						DocumentObject,
						"CashAccountRecipient",
						,
						Cancel);
				EndIf;
			
			EndIf;
			
			// Checking the interconnectedness of the recipient's cash register organization with the sender's cash register organization by organizational structure.
			If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(DocumentObject.Organization, CashRegisterAttributes.Owner) Then
				
				Text = NStr("vi = 'Doanh nghiệp quỹ tiền mặt nơi nhận phải ràng buộc với doanh nghiệp quỹ tiền mặt nơi gửi theo cơ cấu tổ chức.';
							|ru = 'Организация кассы получателя должна быть взаимосвязана с организацией кассы отправителя по организационной структуре.';
							|en = 'Receiving cash account company and withdrawing cash account company should be interdependent in respect of the company structure.'; fa = 'Receiving cash account company and withdrawing cash account company should be interdependent in respect of the company structure.';
							|it = 'L''azienda della cassa del destinatario deve essere interconnessa con l''azienda della cassa del mittente in base alla struttura aziendale.';
							|pl = 'Firma kasy odbiorcy powinna być wzajemnie powiązana z firmą kasy nadawcy według struktury organizacyjnej.';
							|tr = 'Alıcı kasa iş yeri, iş yeri yapısına göre gönderici kasa iş yeri ile bağlantılı olmalıdır.'");
				
				Common.MessageToUser(
					Text,
					DocumentObject,
					"CashAccountRecipient",
					,
					Cancel);
					
			ElsIf DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(DocumentObject.Organization, CashRegisterAttributes.Owner) Then
				
				Text = NStr("vi = 'Doanh nghiệp quỹ tiền mặt nơi nhận không ràng buộc với doanh nghiệp quỹ tiền mặt nơi gửi theo cơ cấu tổ chức.';
							|ru = 'Организация кассы получателя не должна быть взаимосвязана с организацией кассы отправителя по организационной структуре.';
							|en = 'Receiving cash account company and withdrawing cash account company should not be interdependent in respect of the company structure.'; fa = 'Receiving cash account company and withdrawing cash account company should not be interdependent in respect of the company structure.';
							|it = 'L''azienda della cassa del destinatario non deve essere interconnessa con l''azienda della cassa del mittente in base alla struttura aziendale.';
							|pl = 'Firma kasy odbiorcy nie powinna być wzajemnie powiązana z firmą kasy nadawcy według struktury organizacyjnej.';
							|tr = 'Alıcı kasa iş yeri, iş yeri yapısına göre gönderici kasa iş yeri ile bağlantılı olmamalıdır.'");
				
				Common.MessageToUser(
					Text,
					DocumentObject,
					"CashAccountRecipient",
					,
					Cancel);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure // Check the recipient's account()

// The procedure checks the sender's cash register specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckSenderSCashier(DocumentObject, Cancel) Export
	
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount);
	Array.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	Array.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
	Array.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	
	If Array.Find(DocumentObject.BusinessOperation) <> Undefined
		And ValueIsFilled(DocumentObject.CashAccountIssuer)
		And ValueIsFilled(DocumentObject.Organization) Then
		
		If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromBank
			And ValueIsFilled(DocumentObject.CashAccount)
			And DocumentObject.CashAccount = DocumentObject.CashAccountIssuer Then
			
			Text = NStr("vi = 'Một quỹ tiền mặt không thể là người gửi và người nhận đồng thời';
						|ru = 'Одна и та же касса не может являться отправителем и получателем одновременно';
						|en = 'The same cash account cannot be both withdrawing and receiving'; fa = 'The same cash account cannot be both withdrawing and receiving';
						|it = 'La stessa cassa non può risultare come mittente e destinatario allo stesso tempo';
						|pl = 'Jedna i ta sama kasa nie może być nadawcą i odbiorcą jednocześnie';
						|tr = 'Aynı kasa aynı anda gönderen ve alıcı olamaz.'");
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"CashAccountRecipient",
				,
				Cancel);
		Else
			
			CashRegisterAttributes = Common.ObjectAttributesValues(DocumentObject.CashAccountIssuer, "Owner, CashCurrency");
			
			If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromOtherCompany
				And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.RefundFromAnotherCompany
				And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And DocumentObject.Organization <> CashRegisterAttributes.Owner Then
				
					Text = NStr("vi = 'Doanh nghiệp của quỹ tiền mặt gửi không tương ứng với doanh nghiệp trên chứng từ';
								|ru = 'Организация кассы отправителя не соответствует организации документа';
								|en = 'The company mentioned in the withdrawing cash account does not correspond to the company mentioned in the document'; fa = 'The company mentioned in the withdrawing cash account does not correspond to the company mentioned in the document';
								|it = 'L''azienda della cassa del mittente non coincide con l''azienda del documento';
								|pl = 'Firma kasy nadawcy nie odpowiada firmie dokumentu';
								|tr = 'Gönderenin kasasının iş yeri belgenin iş yeri ile eşleşmiyor'");
					CommonClientServer.MessageToUser(
						Text,
						DocumentObject,
						"CashAccountIssuer",
						,
						Cancel);
			ElsIf (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany)
				And DocumentObject.Organization = CashRegisterAttributes.Owner Then
				
					Text = NStr("vi = 'Doanh nghiệp của quỹ tiền mặt gửi phải khác so với doanh nghiệp trên chứng từ';
								|ru = 'Организация кассы отправителя должна отличаться от организации документа';
								|en = 'The company mentioned in the withdrawing cash account should differ from the company mentioned in the document'; fa = 'The company mentioned in the withdrawing cash account should differ from the company mentioned in the document';
								|it = 'L''azienda della cassa del mittente deve differire dall''azienda del documento';
								|pl = 'Firma kasy nadawcy powina różnić się od firmy dokumentu';
								|tr = 'Göndericinin kasasının iş yeri, belgenin iş yerinden farklı olmalı'");
					CommonClientServer.MessageToUser(
						Text,
						DocumentObject,
						"CashAccountIssuer",
						,
						Cancel);
			EndIf;
			
			If DocumentObject.Currency <> CashRegisterAttributes.CashCurrency Then
				Text = NStr("vi = 'Tiền tệ của quỹ tiền mặt gửi không tương ứng với tiền tệ chứng từ';
							|ru = 'Валюта кассы отправителя не соответствует валюте документа';
							|en = 'Withdrawing cash account currency does not correspond to the document currency'; fa = 'Withdrawing cash account currency does not correspond to the document currency';
							|it = 'La valuta della cassa del mittente non coincide con la valuta del documento';
							|pl = 'Waluta kasy nadawcy nie odpowiada walucie dokumentu';
							|tr = 'Gönderenin kasasının para birimi ile belgenin para birimi aynı değil'");
				CommonClientServer.MessageToUser(
					Text,
					DocumentObject,
					"CashAccountIssuer",
					,
					Cancel);
			EndIf;
			
			// Checking the interconnectedness of the recipient's cash register organization with the sender's cash register organization by organizational structure.
			If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(DocumentObject.Organization, CashRegisterAttributes.Owner) Then
				
				Text = NStr("vi = 'Doanh nghiệp quỹ tiền mặt nơi nhận phải ràng buộc với doanh nghiệp quỹ tiền mặt nơi gửi theo cơ cấu tổ chức.';
							|ru = 'Организация кассы получателя должна быть взаимосвязана с организацией кассы отправителя по организационной структуре.';
							|en = 'Receiving cash account company and withdrawing cash account company should be interdependent in respect of the company structure.'; fa = 'Receiving cash account company and withdrawing cash account company should be interdependent in respect of the company structure.';
							|it = 'L''azienda della cassa del destinatario deve essere interconnessa con l''azienda della cassa del mittente in base alla struttura aziendale.';
							|pl = 'Firma kasy odbiorcy powinna być wzajemnie powiązana z firmą kasy nadawcy według struktury organizacyjnej.';
							|tr = 'Alıcı kasa iş yeri, iş yeri yapısına göre gönderici kasa iş yeri ile bağlantılı olmalıdır.'");
				
				CommonClientServer.MessageToUser(
					Text,
					DocumentObject,
					"CashAccountIssuer",
					,
					Cancel);
					
			ElsIf DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(DocumentObject.Organization, CashRegisterAttributes.Owner) Then
				
				Text = NStr("vi = 'Doanh nghiệp quỹ tiền mặt nơi nhận không ràng buộc với doanh nghiệp quỹ tiền mặt nơi gửi theo cơ cấu tổ chức.';
							|ru = 'Организация кассы получателя не должна быть взаимосвязана с организацией кассы отправителя по организационной структуре.';
							|en = 'Receiving cash account company and withdrawing cash account company should not be interdependent in respect of the company structure.'; fa = 'Receiving cash account company and withdrawing cash account company should not be interdependent in respect of the company structure.';
							|it = 'L''azienda della cassa del destinatario non deve essere interconnessa con l''azienda della cassa del mittente in base alla struttura aziendale.';
							|pl = 'Firma kasy odbiorcy nie powinna być wzajemnie powiązana z firmą kasy nadawcy według struktury organizacyjnej.';
							|tr = 'Alıcı kasa iş yeri, iş yeri yapısına göre gönderici kasa iş yeri ile bağlantılı olmamalıdır.'");
				
				CommonClientServer.MessageToUser(
					Text,
					DocumentObject,
					"CashAccountIssuer",
					,
					Cancel);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure // Check the Sender's box()

// The procedure checks the cash register of the CMC specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckCashRegister(DocumentObject, Cancel) Export
	
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.CashIssueToCashRegister);
	Array.Add(Enums.BusinessTransactions.CashReceiptFromCashRegister);
	
	If Array.Find(DocumentObject.BusinessOperation) <> Undefined
	   And ValueIsFilled(DocumentObject.CashRegister)
	   And ValueIsFilled(DocumentObject.Organization)
	Then
		
		CashRegisterDetails = Catalogs.CashRegisters.CashRegisterDetails(DocumentObject.CashRegister);
		If DocumentObject.Organization <> CashRegisterDetails.Organization Then
			Text = NStr("vi = 'Doanh nghiệp quầy thu ngân không tương ứng với doanh nghiệp trong chứng từ';
						|ru = 'Организация кассы ККМ не соответствует организации документа';
						|en = 'Cash register company does not match the company mentioned in the document'; fa = 'Cash register company does not match the company mentioned in the document';
						|it = 'L''azienda del registratore di cassa non coincide con l''azienda del documento';
						|pl = 'Firma kasy nie odpowiada firmie dokumentu';
						|tr = 'Yazar kasa iş yeri belgenin iş yeri ile eşleşmiyor'");
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"CashRegister",
				,
				Cancel);
		EndIf;
		If DocumentObject.Currency <> CashRegisterDetails.Currency Then
			Text = NStr("vi = 'Tiền tệ của quầy thu ngân không tương ứng với tiền tệ trong chứng từ';
						|ru = 'Валюта кассы ККМ не соответствует валюте документа';
						|en = 'Cash register currency does not correspond to the document currency'; fa = 'Cash register currency does not correspond to the document currency';
						|it = 'La valuta del registratore di cassa non coincide con la valuta del documento';
						|pl = 'Waluta kasy nie odpowiada walucie dokumentu';
						|tr = 'Yazar kasa para birimi, belge para birimiyle eşleşmiyor'");
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"CashRegister",
				,
				Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure // Check the Cash register()

// The procedure checks the recipient's Bank account specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - Flag for refusing to continue working
//	FlagEDIWithBanks - Boolean - Whether to use it when exchanging with banks
//	FillingErrors - String - A string that accumulates validation errors.
//
Procedure CheckRecipientSBankAccount(DocumentObject, Cancel, FlagEDIWithBanks = False, FillingErrors = "") Export
	
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount);
	Array.Add(Enums.BusinessTransactions.CashDepositToBankAccount);
	Array.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	
	If Array.Find(DocumentObject.BusinessOperation) <> Undefined
	   And ValueIsFilled(DocumentObject.BankAccountBeneficiary)
	   And ValueIsFilled(DocumentObject.Organization)
	Then
		
		If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashDepositToBankAccount
		   And ValueIsFilled(DocumentObject.BankAccount)
		   And DocumentObject.BankAccount = DocumentObject.BankAccountBeneficiary Then
		   
			Text = NStr("vi = 'Một tài khoản ngân hàng không thể là người gửi và người nhận đồng thời';
						|ru = 'Один и тот же банковский счет не может являться отправителем и получателем одновременно';
						|en = 'The same bank account cannot be both a payer and a beneficiary'; fa = 'The same bank account cannot be both a payer and a beneficiary';
						|it = 'Lo stesso conto bancario non può essere mittente e destinatario contemporaneamente';
						|pl = 'Jeden i ten sam rachunek bankowy nie może być nadawcą i odbiorcą jednocześnie';
						|tr = 'Aynı banka hesabı aynı anda gönderici ve alıcı olamaz'");
			If FlagEDIWithBanks Then
				AddFillInError(FillingErrors, Text);
			Else
				CommonClientServer.MessageToUser(
					Text,
					DocumentObject,
					"BankAccountBeneficiary",
					,
					Cancel);
			EndIf;
		Else
			
			AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(DocumentObject.BankAccountBeneficiary);
			
			If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashPaymentToAnotherCompany
				And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.RefundToAnotherCompany
				And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
			 And DocumentObject.Organization <> AccountAttributes.Organization Then
				Text = NStr("vi = 'Doanh nghiệp theo tài khoản người nhận không tương ứng với doanh nghiệp trên chứng từ';
							|ru = 'Организация счета получателя не соответствует организации документа';
							|en = 'The company mentioned in the beneficiary account does not match the company mentioned in the document'; fa = 'The company mentioned in the beneficiary account does not match the company mentioned in the document';
							|it = 'L''azienda del conto del destinatario non coincide con l''azienda del documento';
							|pl = 'Firma w rachunku odbiorcy nie odpowiada firmie w dokumencie';
							|tr = 'Alıcı hesabı iş yeri, belge iş yeri ile eşleşmiyor'");
				If FlagEDIWithBanks Then
					AddFillInError(FillingErrors, Text);
				Else
					CommonClientServer.MessageToUser(
						Text,
						DocumentObject,
						"BankAccountBeneficiary",
						,
						Cancel);
				EndIf;
			EndIf;
			
			If DocumentObject.Currency <> AccountAttributes.Currency Then
				Text = NStr("vi = 'Tiền tệ trong tài khoản của người nhận không tương ứng với tiền tệ trong chứng từ';
							|ru = 'Валюта счета получателя не соответствует валюте документа';
							|en = 'Beneficiary account currency does not match the document currency'; fa = 'Beneficiary account currency does not match the document currency';
							|it = 'La valuta del conto del destinatario non coincide con la valuta del documento';
							|pl = 'Waluta rachunku odbiorcy nie odpowiada walucie w dokumencie';
							|tr = 'Alıcının hesabının para birimi, belgenin para birimiyle eşleşmiyor'");
				If FlagEDIWithBanks Then
					AddFillInError(FillingErrors, Text);
				Else
					CommonClientServer.MessageToUser(
						Text,
						DocumentObject,
						"BankAccountBeneficiary",
						,
						Cancel);
				EndIf;
			EndIf;
			
			// Checking the interconnectedness of the organization of the recipient's account with the organization of the sender's cash register according to the organizational structure.
			If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(DocumentObject.Organization, AccountAttributes.Organization) Then
				
				Text = NStr("vi = 'Doanh nghiệp tài khoản người thụ hưởng phải ràng buộc với doanh nghiệp tài khoản người gửi theo cơ cấu tổ chức.';
							|ru = 'Организация счета получателя должна быть взаимосвязана с организацией счета отправителя по организационной структуре.';
							|en = 'Companies mentioned in the beneficiary account and in the payer account must be interrelated in terms of company structure.'; fa = 'Companies mentioned in the beneficiary account and in the payer account must be interrelated in terms of company structure.';
							|it = 'L''azienda del conto del destinatario deve essere interconnessa con l''azienda del conto del mittente in base alla struttura aziendale.';
							|pl = 'Firma rachunku odbiorcy powinna być wzajemnie powiązana z firmą rachunku nadawcy według struktury organizacyjnej.';
							|tr = 'Alıcının hesabının iş yeri, iş yerinin yapısı gereği gönderenin hesabının iş yeri ile bağlantılı olmalıdır.'");
				If FlagEDIWithBanks Then
					AddFillInError(FillingErrors, Text);
				Else
					CommonClientServer.MessageToUser(
						Text,
						DocumentObject,
						"CashAccountRecipient",
						,
						Cancel);
				EndIf;
			ElsIf DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
				And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(DocumentObject.Organization, AccountAttributes.Organization) Then
				
				Text = NStr("vi = 'Doanh nghiệp tài khoản người thụ hưởng không ràng buộc với doanh nghiệp tài khoản người gửi theo cơ cấu tổ chức.';
							|ru = 'Организация счета получателя не должна быть взаимосвязана с организацией счета отправителя по организационной структуре.';
							|en = 'Companies mentioned in the beneficiary account and in the payer account must not be interrelated in terms of company structure.'; fa = 'Companies mentioned in the beneficiary account and in the payer account must not be interrelated in terms of company structure.';
							|it = 'L''azienda del conto del destinatario non deve essere interconnessa con l''azienda del conto del mittente in base alla struttura aziendale.';
							|pl = 'Firma rachunku odbiorcy nie powinna być wzajemnie powiązana z firmą rachunku nadawcy według struktury organizacyjnej.';
							|tr = 'Alıcının hesabının iş yeri, iş yeri yapısı gereği gönderenin hesabının iş yeri ile bağlantılı olmamalıdır.'");
				If FlagEDIWithBanks Then
					AddFillInError(FillingErrors, Text);
				Else
					CommonClientServer.MessageToUser(
						Text,
						DocumentObject,
						"CashAccountRecipient",
						,
						Cancel);
				EndIf;
			EndIf;

		EndIf;

	EndIf;
	
EndProcedure // Check the Bank Account Recipient()

// The procedure checks the conversion currency specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - Flag for refusing to continue working
//	FlagEDIWithBanks - Boolean - Whether to use it when exchanging with banks
//	FillingErrors - String - A string that accumulates validation errors.
//
Procedure CheckConversionCurrency(DocumentObject, Cancel, FlagEDIWithBanks = False, FillingErrors = "") Export
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
	   And ValueIsFilled(DocumentObject.Currency)
	   And ValueIsFilled(DocumentObject.CurrencyOfConversion)
	Then
		
		If DocumentObject.Currency = DocumentObject.CurrencyOfConversion Then
			
			Text = NStr("vi = 'Tiền tệ quy đổi phải khác với tiền tệ trong chứng từ';
						|ru = 'Валюта конвертации должна отличаться от валюты документа';
						|en = 'Conversion currency should differ from the document currency'; fa = 'Conversion currency should differ from the document currency';
						|it = 'La valuta di conversione deve differire dalla valuta del documento';
						|pl = 'Waluta konwersji powinna różnić się od waluty dokumentu';
						|tr = 'Dönüştürücü para birimi, belgenin para biriminden farklı olmalıdır'");
			If FlagEDIWithBanks Then
				AddFillInError(FillingErrors, Text);
			Else
				CommonClientServer.MessageToUser(
					Text,
					DocumentObject,
					"CurrencyOfConversion",
					,
					Cancel);
			EndIf;
		EndIf;

	EndIf;
	
EndProcedure

// Determines whether payments are allowed without specifying requests for spending funds.
//
// Parameters:
//    DocumentObject - DocumentObject - the document that is being checked.
//
// Returns:
//    Boolean - Allowed, or not.
//
Function EnabledCreatingCashIssueWithoutPaymentRequest(DocumentObject) Export
	
	If Not GetFunctionalOption("UsePaymentRequests") Then
		Return True;
	EndIf;
	
	If TypeOf(DocumentObject.Ref) = Type("DocumentRef.CashVoucher") Then
		
		Attributes = Catalogs.CashAccounts.GetCheckoutDetails(DocumentObject.CashAccount);
		Return Attributes.EnableCreatingCashIssueWithoutPaymentRequest;
		
	ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.BankAccountIssue") Then
		
		Attributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(
			DocumentObject.BankAccount);
		Return Attributes.EnableCreatingCashIssueWithoutPaymentRequest;
		
	ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.PaymentCardTransaction") Then
		
		EnableCreatingCashIssueWithoutPaymentRequest = True;
		
		If ValueIsFilled(DocumentObject.POSTerminal) Then
			EnableCreatingCashIssueWithoutPaymentRequest = Common.ObjectAttributeValue(
				DocumentObject.POSTerminal, "EnableCreatingCashIssueWithoutPaymentRequest");
		ElsIf ValueIsFilled(DocumentObject.AcquiringContract) Then
			EnableCreatingCashIssueWithoutPaymentRequest = Common.ObjectAttributeValue(
				DocumentObject.AcquiringContract, "EnableCreatingCashIssueWithoutPaymentRequest");
		EndIf;
		
		Return EnableCreatingCashIssueWithoutPaymentRequest;
	Else
		Return False;
	EndIf;

EndFunction

// The procedure clears the Bank details that are not used for the business operation.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	ArrayOfAllProps - Array - An array of all the details of the document that need to be cleaned
//	ArrayOfOperationDetails - Array - Array of document details that relate to the business operation of the document.
//
Procedure ClearUnusedProps(DocumentObject, Val ArrayOfAllProps, Val ArrayOfOperationDetails) Export
	
	For Each ArrayElement In ArrayOfOperationDetails Do
		Number = ArrayOfAllProps.Find(ArrayElement);
		If Number <> Undefined Then
			ArrayOfAllProps.Delete(Number);
		EndIf;
	EndDo;
	
	StructureOfTableParts = New Structure;
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		Position = StrFind(ArrayElement, ".");
		If Position <> 0 Then
			
			TabularSectionName = Left(ArrayElement, Position - 1);
			TabularSectionAttributes = New Array;
			If Not StructureOfTableParts.Property(TabularSectionName, TabularSectionAttributes) Then
				StructureOfTableParts.Insert(TabularSectionName, New Array);
				TabularSectionAttributes = StructureOfTableParts[TabularSectionName];
			EndIf;
			TabularSectionAttributes.Add(Mid(ArrayElement, Position + 1));
			
		ElsIf ArrayElement = "ARAPDetails"
			Or ArrayElement = "ARAPDetailsWithVendor"
			Or ArrayElement = "ARAPDetailsWithCustomer" Then
			
			DocumentObject[ArrayElement].Clear();
			
		ElsIf ArrayElement = "PersonalAccountsOfStaff"
			Or ArrayElement = "PayrollPayment"
			Or ArrayElement = "RowIndividuals"
			Or ArrayElement = "BankAccountsOfCounterpartyList" Then
			Continue;
		Else
			If ValueIsFilled(DocumentObject[TrimAll(ArrayElement)]) Then
				DocumentObject[TrimAll(ArrayElement)] = Undefined;
			EndIf;
		EndIf;
	EndDo;
	
	If StructureOfTableParts.Count() > 0 Then
		For Each TabularSection In StructureOfTableParts Do
			For Each TableRow In DocumentObject[TabularSection.Key] Do
				For Each ArrayElement In TabularSection.Value Do
					If ValueIsFilled(TableRow[TrimAll(ArrayElement)]) Then
						TableRow[TrimAll(ArrayElement)] = Undefined;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure clears unused banking details for the payment form specified in the document.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	PaymentMethod - EnumRef.PaymentForms - Document payment form
//	ClearingForEmptyPaymentForm - Boolean - clear Bank details if the payment form is not specified (for any form of payment).
//
Procedure ClearUnusedPaymentFormDetails(DocumentObject, PaymentMethod, ClearingForEmptyPaymentForm = False) Export
	
	If Not (ValueIsFilled(PaymentMethod) Or ClearingForEmptyPaymentForm) Then
		Return;
	EndIf;
	
	AttributesArray = New Array;
	If PaymentMethod <> Enums.PaymentForms.CashAccountPayment_ Then
		AttributesArray.Add("CashAccount");
	EndIf;
	If PaymentMethod <> Enums.PaymentForms.BankAccountPayment
		And PaymentMethod <> Enums.PaymentForms.InstantPayments Then
		AttributesArray.Add("BankAccount");
	EndIf;
	
	ClearUnusedProps(DocumentObject, AttributesArray, New Array);
	
EndProcedure // Clear the non-used Visa Payment forms()

// Depending on the household. operations that add object details to the array that do not require verification of filling in.
// Parameters:
//    DocumentObject                  - DocumentObject - document intended for recording or conducting;
//    NotCheckedAttributeArray   - Array - array of details that do not require verification
//                                      when recording and conducting a document;
//    PayrollTransaction - Boolean - indicates that the business transaction specified in the document
//                                      reflects wage movements.
//
Procedure AddUnverifiableDetailsForPaymentOfWages(DocumentObject, NotCheckedAttributeArray, PayrollTransaction = False) Export
	
	If SalaryOperation(DocumentObject.BusinessOperation) Then
		
		NotCheckedAttributeArray.Add("AssetAndLiabilityItem");
		NotCheckedAttributeArray.Add("AssetsLiabilitiesDimension");
		NotCheckedAttributeArray.Add("ExpenseItem");
		
		If Constants.UsePayroll.Get()
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram Then
			NotCheckedAttributeArray.Add("PaymentRequest");
		EndIf;
		
		If Constants.UsePayroll.Get() Then
			
			NotCheckedAttributeArray.Add("PaysheetNumber");
			NotCheckedAttributeArray.Add("PaysheetDate");
			NotCheckedAttributeArray.Add("PersonalAccountsOfStaff");
		//++ WE
		ElsIf GetFunctionalOption("PayrollAndHumanResourcesWE") Then
			NotCheckedAttributeArray.Add("PersonalAccountsOfStaff");
		//-- WE
			
		ElsIf GetFunctionalOption("UseDataSynchronization") And Not GetFunctionalOption("TradeManagement") Then
			NotCheckedAttributeArray.Add("Statement");
			NotCheckedAttributeArray.Add("PayrollPayment");
			
		Else
			NotCheckedAttributeArray.Add("PaysheetNumber");
			NotCheckedAttributeArray.Add("PaysheetDate");
			NotCheckedAttributeArray.Add("Statement");
			NotCheckedAttributeArray.Add("PayrollPayment");
			
		EndIf;
		
		TransferViaBank = CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, "TransferToEmployeeViaABank")
			And DocumentObject.TransferToEmployeeViaABank;
		
		If PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then
			
			If Not TransferViaBank Then
				NotCheckedAttributeArray.Add("Counterparty");
				NotCheckedAttributeArray.Add("CounterpartyBankAccount");
			EndIf;
			
		ElsIf PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram Then 
			
			NotCheckedAttributeArray.Add("PersonalAccountsOfStaff");
			NotCheckedAttributeArray.Add("Individual");
			NotCheckedAttributeArray.Add("PersonalAccount");
			
			
		Else
			
			If Not TransferViaBank Then
				NotCheckedAttributeArray.Add("Counterparty");
				NotCheckedAttributeArray.Add("CounterpartyBankAccount");
			EndIf;
			
			NotCheckedAttributeArray.Add("PersonalAccountsOfStaff");
			
		EndIf;
		
		If Not Constants.UsePayroll.Get() Then
			NotCheckedAttributeArray.Add("ARAPDetails.Sum");
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds a string to the existing ones
//
// Parameters:
//    FillingErrors - String - The accumulated error description
//    ErrorText - String - Description of the next error.
//
Procedure AddFillInError(FillingErrors, ErrorText) Export
	
	FillingErrors = FillingErrors + "
	|" + ErrorText;
	
EndProcedure

// Performs verification of filling in the details instead of the platform. Errors are recorded, not displayed.
//
// Parameters:
//    DocumentObject - DocumentObject - document object
//    CheckedAttributes - Array - Bank details that require verification of their fullness
//    FillingErrors - String - Description of fill-in errors.
//
Procedure CheckRequiredBankingDetails(DocumentObject, CheckedAttributes, FillingErrors) Export
	
	MetadataOfDocument = DocumentObject.Metadata();
	DocumentAttributes = MetadataOfDocument.Attributes;
	TabularSections = MetadataOfDocument.TabularSections;
	
	For Each AttributeName In CheckedAttributes Do
		
		PosPoints = StrFind(AttributeName, ".");
		If PosPoints = 0 Then
			If AttributeName = "Date" Then
				Attribute = MetadataOfDocument.StandardAttributes.Date;
			Else
				Attribute = DocumentAttributes.Find(AttributeName);
			EndIf;
			
			If Attribute <> Undefined Then
				If Not ValueIsFilled(DocumentObject[AttributeName]) Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Chưa điền trường  ""%1"".';
							|ru = 'Поле ""%1"" не заполнено.';
							|en = '""%1"" is required.'; fa = '""%1"" is required.';
							|it = 'Il campo ""%1"" non è compilato.';
							|pl = 'Nie wypełniono pola ""%1"".';
							|tr = '""%1"" alanı doldurulmadı.'"),
						Attribute.Synonym);
					AddFillInError(FillingErrors, ErrorText);
				EndIf;
			EndIf;
			
			FirstPartOfDocument = TabularSections.Find(AttributeName);
			If FirstPartOfDocument <> Undefined Then
				If Not DocumentObject[AttributeName].Count() Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không một dòng nào được nhập vào danh sách ""%1"".';
							|ru = 'Не введено ни одной строки в список ""%1"".';
							|en = 'No lines entered into the ""%1"" list.'; fa = 'No lines entered into the ""%1"" list.';
							|it = 'Non è immessa alcuna riga nell''elenco ""%1"".';
							|pl = 'Nie wprowadzono żadnego wierszu do listy ""%1"".';
							|tr = '""%1"" listesinde hiçbir satır girilmedi.'"),
						FirstPartOfDocument.Synonym);
					AddFillInError(FillingErrors, ErrorText);
				EndIf;
			EndIf;
			
		Else
			TabSectionName = Left(AttributeName, PosPoints - 1);
			AttributeName = Mid(AttributeName, PosPoints + 1);
			
			FirstPartOfDocument = TabularSections[TabSectionName];
			If FirstPartOfDocument <> Undefined Then
				Attribute = FirstPartOfDocument.Attributes.Find(AttributeName);
				If Attribute <> Undefined Then
					For Each TabSectionRow In DocumentObject[TabSectionName] Do
						If Not ValueIsFilled(TabSectionRow[AttributeName]) Then
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Chưa điền cột ""%1"" trong dòng %2 của danh sách ""%3"".';
									|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3"".';
									|en = 'Column ""%1"" in line %2 of list ""%3"" is required.'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required.';
									|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata.';
									|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3"".';
									|tr = '""%3"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı.'"),
								Attribute.Synonym,
								TabSectionRow.LineNumber,
								FirstPartOfDocument.Synonym);
							AddFillInError(FillingErrors, ErrorText);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

// Checks the completion of a single-line payment transcript
//
// Parameters:
//    DocumentObject - DocumentObject - document being checked
//    CheckedAttributes - Array - Check the details of the document
//    TSName - String - Name of the table part, the current row of which is displayed as separate details
//    ReplacementNameTS - String - Name of the substitution substring for the name of the details of the table part
//    Cancel - Boolean - Indicates that the operation was rejected.
//
Procedure CheckCompletionOfDecryptionWithoutSplitting(DocumentObject, CheckedAttributes, TSName, ReplacementNameTS, Cancel) Export
	
	If Not DocumentObject[TSName].Count() Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	TabularSections = DocumentObject.Metadata().TabularSections;
	FirstPartOfDocument = TabularSections[TSName];
	
	ErrorTemplate = NStr("vi = 'Chưa điền trường ""%1""';
						|ru = 'Поле ""%1"" не заполнено';
						|en = '""%1"" is required'; fa = '""%1"" is required';
						|it = 'Il campo ""%1"" non è compilato';
						|pl = 'Pole ""%1"" nie jest wypełnione';
						|tr = '""%1"" alanı doldurulmadı.'");
	
	For Each AttributeToCheck In CheckedAttributes Do
		
		If StrFind(AttributeToCheck, TSName) = 0 Then
			Continue;
		EndIf;
		
		PosPoints = StrFind(AttributeToCheck, ".");
		If PosPoints = 0 Then
			Continue;
		EndIf;
		
		AttributeName = Mid(AttributeToCheck, PosPoints + 1);
		TagName = ReplacementNameTS + AttributeName;
		
		If Not ValueIsFilled(DocumentObject[TSName][0][AttributeName]) Then
			
			CommonClientServer.MessageToUser(
				StrTemplate(ErrorTemplate, FirstPartOfDocument.Attributes[AttributeName].Synonym),
				,
				"Items." + TSName + ".CurrentData." + AttributeName,
				,
				Cancel);
		EndIf;
		
		NotCheckedAttributeArray.Add(AttributeToCheck);
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);

EndProcedure

// Checks for filling in the Partner's details in PM payment Decryption
//
// Parameters:
//	Object                - DocumentObject - Monetary instrument.
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the object
//	NotCheckedAttributeArray - Array - Unverifiable document details
//	ExplanationWithoutSplit - Boolean - indicates the type of decryption in the document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckPartnerContent(Object, BusinessOperation, NotCheckedAttributeArray, ExplanationWithoutSplit, Cancel) Export
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		Return;
	EndIf;
	
	If NotCheckedAttributeArray.Find("ARAPDetails.Partner") = Undefined Then
		PresentationOfPropsPartner = PartnersAndCounterparties.HeaderOfPartnerDetailsDependingOnBusinessOperation( BusinessOperation);
		SynonymForPartnerDetails      = Object.Metadata().TabularSections.ARAPDetails.Attributes.Partner.Synonym;
		If PresentationOfPropsPartner <> SynonymForPartnerDetails Then
			NotCheckedAttributeArray.Add("ARAPDetails.Partner");
			For Each PaymentDecryptionLine In Object.ARAPDetails Do
				If Not ValueIsFilled(PaymentDecryptionLine.Partner) Then
					
					If ExplanationWithoutSplit Then
						FieldName = "Items.ARAPDetails.CurrentData.Partner";
						DataKey = Undefined;
					Else
						FieldName = CommonClientServer.PathToTabularSection("ARAPDetails", PaymentDecryptionLine.LineNumber, "Partner");
						DataKey = Object;
					EndIf;
					
					ErrorText = NStr("vi = 'Chưa điền trường ""%1""';
									|ru = 'Поле ""%1"" не заполнено';
									|en = '""%1"" is required'; fa = '""%1"" is required';
									|it = 'Il campo ""%1"" non è compilato';
									|pl = 'Pole ""%1"" nie jest wypełnione';
									|tr = '""%1"" alanı doldurulmadı.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, PresentationOfPropsPartner);
					
					CommonClientServer.MessageToUser(ErrorText, DataKey, FieldName, , Cancel);
					
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether the purchase documents match the advance report
//
// Parameters:
//    DocumentObject - DocumentObject.VendorInvoice - the object being checked (it can also be a document object.Receipt of monetary documents)
//    Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckPurchaseDocumentsOfAdvanceReport(DocumentObject, Cancel) Export
	
	If Not ValueIsFilled(DocumentObject.ExpenseReport) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	PRESENTATION(DocumentData.Ref) AS ExpenseReport,
	|	DocumentData.Organization <> &Organization AS DifferentOrganization,
	|	DocumentData.AdvanceHolder <> &AdvanceHolder AS AccountablePersonDiffers,
	|	DocumentData.Currency <> &Currency AND NOT DocumentData.Multicurrency AS DifferentCurrency_
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Query.SetParameter("Ref", DocumentObject.ExpenseReport);
	Query.SetParameter("Organization", DocumentObject.Organization);
	Query.SetParameter("AdvanceHolder", DocumentObject.AdvanceHolder);
	Query.SetParameter("Currency", DocumentObject.Currency);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.DifferentOrganization Then
			ErrorText = StrTemplate(NStr("vi = 'Doanh nghiệp %1 không khớp với doanh nghiệp trong chứng từ %2';
										|ru = 'Организация %1 не соответствует организации в документе %2';
										|en = 'The %1 company does not match the company in the %2 document'; fa = 'The %1 company does not match the company in the %2 document';
										|it = 'L''azienda %1 non coincide con l''azienda nel documento %2';
										|pl = 'Firma %1 nie odpowiada firmie w dokumencie %2';
										|tr = '%1 iş yeri, %2 belgesindeki iş yeri ile eşleşmiyor'"),
				DocumentObject.Organization, Selection.ExpenseReport);
			CommonClientServer.MessageToUser(ErrorText, DocumentObject, "",, Cancel);
		EndIf;
		
		If Selection.AccountablePersonDiffers Then
			ErrorText = StrTemplate(NStr("vi = 'Người nhận tạm ứng %1 không khớp với người nhận tạm ứng trong chứng từ %2';
										|ru = 'Подотчетное лицо %1 не соответствует подотчетному лицу в документе %2';
										|en = 'The %1 advance holder does not match the advance holder in the %2 document'; fa = 'The %1 advance holder does not match the advance holder in the %2 document';
										|it = 'Il responsabile %1 non coincide con il responsabile nel documento %2';
										|pl = 'Zaliczkobiorca %1 nie odpowiada zaliczkobiorcy w dokumencie %2';
										|tr = 'Sorumlu kişi %1, %2 belgesindeki sorumlu kişi ile eşleşmiyor'"),
				DocumentObject.AdvanceHolder, Selection.ExpenseReport);
			CommonClientServer.MessageToUser(ErrorText, DocumentObject, "",, Cancel);
		EndIf;
		
		If Selection.DifferentCurrency_ Then
			ErrorText = StrTemplate(NStr("vi = 'Tiền tệ %1 không khớp với tiền tệ trong chứng từ %2';
										|ru = 'Валюта %1 не соответствует валюте в документе %2';
										|en = 'The %1 currency does not match the currency in the %2 document'; fa = 'The %1 currency does not match the currency in the %2 document';
										|it = 'La valuta %1 non coincide con la valuta nel documento %2';
										|pl = 'Waluta %1 nie odpowiada walucie w dokumencie %2';
										|tr = '%1 para birimi, %2 belgesindeki para birimiyle eşleşmiyor'"),
				DocumentObject.Currency, Selection.ExpenseReport);
			CommonClientServer.MessageToUser(ErrorText, DocumentObject, "",, Cancel);
		EndIf;
	EndDo;
	
EndProcedure


// Checks the correspondence of the amount of the document with the amount of non-credited DS according to the document "Crediting DS to personal accounts".
// 
// Parameters:
//  Object - DocumentObject.BankAccountReceiptNote - the document for which the check is performed.
//  Cancel - Boolean - indication of a filling error
//
Procedure CheckCompletionOfAmountNotCredited(Object, Cancel) Export
	
	If Not ValueIsFilled(Object.BankConfirmationAboutCashReceiptOnEmployeeAccount) Then
		Return;
	EndIf;
	
	If Not Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	SUM(BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Sum) AS Sum
		|FROM
		|	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.EmployeesHR AS BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR
		|WHERE
		|	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Ref = &Ref
		|	AND BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Ref.Posted
		|	AND
		|		BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.SalaryCreditingResult <> VALUE(Enum.SalaryCreditingResults.Credited)";
	
	Query.SetParameter("Ref", Object.BankConfirmationAboutCashReceiptOnEmployeeAccount);
		
	QueryResult = Query.Execute().Select();
	
	AmountNotCredited = 0;
	
	If QueryResult.Next() Then
		AmountNotCredited = QueryResult.Sum;
	EndIf;
	
	If AmountNotCredited <> Object.DocumentAmount Then
		
		MessageText = NStr("vi = 'Số tiền chứng từ khác với số tiền chưa ghi có.';
							|ru = 'Сумма документа отличается от суммы не зачисленных денежных средств.';
							|en = 'Document amount is different from the non-deposited cash amount.'; fa = 'Document amount is different from the non-deposited cash amount.';
							|it = 'Importo documento diverso dall''importo dei fondi non accreditati.';
							|pl = 'Wartość dokumentu różni się od wartości nie zaliczonych środków pieniężnych.';
							|tr = 'Belgenin tutarı, transfer edilmiş nakit tutarından farklıdır.'");
		Common.MessageToUser(MessageText, Object, Object.DocumentAmount, , Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillingInCatalogs

// Filling in the General details of reference books
//
// Parameters:
//    Object - CatalogObject - Object.
Procedure ProcessingCatalogFilling(Object) Export
	
	If Not GetFunctionalOption("UseMultipleCompanies")
		And TMCommonUseClientServer.HasObjectAttribute(Object, "Owner")
		And Not ValueIsFilled(Object.Owner) Then
		Object.Owner = SettingsValueCached.GetDefaultOrganization(Object.Owner);
		If Not Object.IsFolder
			And Object.Metadata().Attributes.Find("CashCurrency") <> Undefined
			And Not ValueIsFilled(Object.CashCurrency) Then
			Object.CashCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Owner);
		EndIf;
		If Not ValueIsFilled(Object.Owner) Then
			
			Query = New Query(
			"SELECT ALLOWED TOP 2
			|	Companies.Ref
			|FROM
			|	Catalog.Companies AS Companies");
			
			If Query.Execute().Select().Count() = 2 Then
				Raise NStr("vi = 'Không thể xác định tính trực thuộc của phần tử đối với ""Doanh nghiệp"" nhất định. Trong cơ sở thông tin đã nhập nhiều doanh nghiệp,
				                             |Hãy bật tùy chọn chức năng ""Sử dụng nhiều doanh nghiệp""!';
				                             |ru = 'Не удалось определить принадлежность элемента к определенной ""Организации"". В информационной базе введено несколько организаций,
				                             |Включите функциональную опцию ""Использовать несколько организаций""!';
				                             |en = 'Cannot determine whether the item belongs to the ""Company"". Multiple companies are entered in the infobase, 
				                             |Enable the ""Use multiple companies"" option.'; fa = 'Cannot determine whether the item belongs to the ""Company"". Multiple companies are entered in the infobase, 
				                             |Enable the ""Use multiple companies"" option.';
				                             |it = 'Impossibile determinare l''elemento che appartiene a una particolare ""Azienda"". Diverse organizzazioni sono state inserite nel database informatico.
				                             | Abilitare l''opzione funzionale ""Utilizza diverse aziende""!';
				                             |pl = 'Nie udało się określić przynależność elementu do określonej ""Организации"". Do bazy informacyjnej wprowadzono kilka firm,
				                             |Włącz opcję funkcjonalną ""Использовать несколько организаций""!';
				                             |tr = 'Öğenin belirli bir ""İş yerine"" ait olup olmadığı belirlenemiyor. Infobase''e girilen birkaç iş yeri mevcut,
				                             |""Birden fazla iş yeri kullan"" işlevsel seçeneğini etkinleştir!'");
			Else
				Raise NStr("vi = 'Không thể xác định tính phụ thuộc của phần tử vào ""Doanh nghiệp"" nào đó. Có thể là trong cơ sở thông tin chưa nhập doanh nghiệp nào!';
							|ru = 'Не удалось определить принадлежность элемента к определенной ""Организации"". Возможно, в информационной базе не введено ни одной организации!';
							|en = 'Cannot determine whether the item belongs to the ""Company"". The infobase might not have any companies entered.'; fa = 'Cannot determine whether the item belongs to the ""Company"". The infobase might not have any companies entered.';
							|it = 'Impossibile determinare l''elemento che appartiene a una particolare ""Azienda"". Probabilmente nessuna azienda è stata inserita nel database informatico!';
							|pl = 'Nie udało się określić przynależność elementu do określonej ""Организации"". Możliwe, że do bazy informacyjnej nie wprowadzono żadnej firmy!';
							|tr = 'Öğenin  belirli bir ""İş yerine"" ait olup olmadığı belirlenemiyor. Infobase''e herhangi bir iş yeri girilmemiş olabilir!'");
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

// Defines the country by the Alpha2 code
// 
// Parameters:
// 	Code - String - code Alpha2
// Returns:
// 	CatalogRef.WorldCountries - country of the world
// 	Undefined - the country was not found.
Function Country(Code) Export
	
	Return Catalogs.WorldCountries.FindByAttribute("CodeAlpha2", Code);
	
EndFunction

// Identifies the bank by country and national code
// 
// Parameters:
// 	Country - CatalogRef.WorldCountries - country where the bank is located
// 	Code - String - national bank code
// Returns:
// 	CatalogRef.BankClassifier - link to the found bank.
// 	Undefined - the bank was not found. 
Function Bank(Country, Code) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	BankClassifier.Ref AS Ref
	|FROM
	|	Catalog.BankClassifier AS BankClassifier
	|		INNER JOIN Catalog.WorldCountries AS WorldCountries
	|		ON BankClassifier.CountryCode = WorldCountries.Code
	|			AND WorldCountries.Ref = &Country
	|			AND BankClassifier.Code = &Code
	|";
	Query.SetParameter("Code", Code);
	Query.SetParameter("Country", Country);
	Result = Query.Execute().Select();
	If Result.Next() Then
		Return Result.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines the national bank code from the IBAN
// 
// Parameters:
// 	IBAN - String - account number in IBAN format
// Returns:
// 	String - the national code of the bank.
//
Function NationalBankCode(IBAN) Export
	
	CountryCodeIBAN = CashClientServer.CountryCodeIBAN(IBAN);
	Placement = NationalCodeLocation(CountryCodeIBAN);
	If Placement <> Undefined Then
		Return Mid(IBAN, Placement.Position, Placement.Length);
	EndIf;
		 
EndFunction

// Returns bank Attributes.
// 
// Parameters:
//  Bank - CatalogRef.BankClassifier - the bank.
//  Attributes - Structure - list of Attributes to fill in.
// 
// Returns:
//  Structure - bank details for the Attributes parameter:
//  *CountryCode - String - country code.
//
Function BankAttributes(Bank, Val Attributes) Export
	
	Attributes.Insert("CountryCode", "CountryCode");
	Return Common.ObjectAttributesValues(Bank, Attributes);
	
EndFunction

// Returns the bank's country by country code.
// 
// Parameters:
//  CountryCode - String - country code.
// 
// Returns:
//  CatalogRef.WorldCountries - Bank's country by code.
//
Function BankCountryByCode(CountryCode) Export
	
	CountryOfBank = Catalogs.WorldCountries.EmptyRef();
	
	If ValueIsFilled(CountryCode) Then
		CountryOfBank = Catalogs.WorldCountries.FindByCode(CountryCode);
	EndIf;
	
	If Not ValueIsFilled(CountryOfBank) Then
		CountryOfBank = Constants.MainCountry.Get();
	EndIf;
	
	Return CountryOfBank;
	
EndFunction

// Returns the bank's country.
// 
// Parameters:
//  Bank - CatalogRef.BankClassifier - the bank.
// 
// Returns:
//  CatalogRef.WorldCountries - Bank's country by code.
//
Function BankCountryByBank(Bank) Export
	
	CountryOfBank = Catalogs.WorldCountries.EmptyRef();
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	WorldCountries.Ref AS Country
		|FROM
		|	Catalog.BankClassifier AS BankClassifier
		|		INNER JOIN Catalog.WorldCountries AS WorldCountries
		|		ON BankClassifier.CountryCode = WorldCountries.Code
		|		AND BankClassifier.Ref = &Bank";
	
	Query.SetParameter("Bank", Bank);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		If Selection.Next() Then
			CountryOfBank = Selection.Country;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(CountryOfBank) Then
		CountryOfBank = Constants.MainCountry.Get();
	EndIf;
	
	Return CountryOfBank;
	
EndFunction

#EndRegion

#Region FillingInDocuments

// The function checks whether the "Write-off of non-cash DS" document can be generated
// based on several documents. 
//
// Parameters:
//  ReferencesArrray  - Array - orders to suppliers for which you need to enter an implementation.
//
// Returns:
//   Boolean   - Truth, if formation is possible.
//
Function GenerateDataForFillingInCashDebitsForSeveralDocuments(ReferencesArrray) Export

	Cancel = False;

	QueryText =
	"SELECT
	|	CASE
	|		WHEN COUNT(DISTINCT NestedQuery.Counterparty) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesCounterparty,
	|	CASE
	|		WHEN COUNT(DISTINCT NestedQuery.Organization) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesCompany,
	|	CASE
	|		WHEN COUNT(DISTINCT NestedQuery.DocumentType) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesType
	|FROM
	|	(SELECT
	|		VendorInvoice.Organization AS Organization,
	|		VendorInvoice.Counterparty AS Counterparty,
	|		""A"" AS DocumentType
	|	FROM
	|		Document.VendorInvoice AS VendorInvoice
	|	WHERE
	|		VendorInvoice.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VendorInvoiceServicesAndAssets.Organization,
	|		VendorInvoiceServicesAndAssets.Counterparty,
	|		""A""
	|	FROM
	|		Document.VendorInvoiceServicesAndAssets AS VendorInvoiceServicesAndAssets
	|	WHERE
	|		VendorInvoiceServicesAndAssets.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseOrder.Organization,
	|		PurchaseOrder.Counterparty,
	|		""A""
	|	FROM
	|		Document.PurchaseOrder AS PurchaseOrder
	|	WHERE
	|		PurchaseOrder.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ConsignmentReportToVendor.Organization,
	|		ConsignmentReportToVendor.Counterparty,
	|		""A""
	|	FROM
	|		Document.ConsignmentReportToVendor AS ConsignmentReportToVendor
	|	WHERE
	|		ConsignmentReportToVendor.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseInvoiceConsignmentStockLost.Organization,
	|		PurchaseInvoiceConsignmentStockLost.Counterparty,
	|		""A""
	|	FROM
	|		Document.PurchaseInvoiceConsignmentStockLost AS PurchaseInvoiceConsignmentStockLost
	|	WHERE
	|		PurchaseInvoiceConsignmentStockLost.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ConsignmentReportFromCustomer.Organization,
	|		ConsignmentReportFromCustomer.Counterparty,
	|		""A""
	|	FROM
	|		Document.ConsignmentReportFromCustomer AS ConsignmentReportFromCustomer
	|	WHERE
	|		ConsignmentReportFromCustomer.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerInvoiceIntercompany.Organization,
	|		NULL,
	|		""A""
	|	FROM
	|		Document.CustomerInvoiceIntercompany AS CustomerInvoiceIntercompany
	|	WHERE
	|		CustomerInvoiceIntercompany.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CommissionReportIntercompany.Organization,
	|		NULL,
	|		""A""
	|	FROM
	|		Document.CommissionReportIntercompany AS CommissionReportIntercompany
	|	WHERE
	|		CommissionReportIntercompany.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ConsumptionReportSubcontractingServicesDeliveredIntercompany.Organization AS Organization,
	|		NULL,
	|		""A""
	|	FROM
	|		Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS ConsumptionReportSubcontractingServicesDeliveredIntercompany
	|	WHERE
	|		ConsumptionReportSubcontractingServicesDeliveredIntercompany.Ref IN(&ReferencesArrray)
	|
	|
	|	) AS NestedQuery
	|";
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return Cancel;
	EndIf;

	If ReportErrorsInGeneratingDataForFillingInCashDebits(Selection) Then
		ErrorText = NStr("vi = 'Không thể nhập một chứng từ Chi tiền từ tài khoản ngân hàng trên cơ sở lệnh đã chọn';
						|ru = 'Ввод одного документа Списание безналичных ДС на основании выделенных распоряжений невозможен';
						|en = 'Cannot register an ""Outgoing payment — Bank account"" document based on the selected references'; fa = 'Cannot register an ""Outgoing payment — Bank account"" document based on the selected references';
						|it = 'L''inserimento di un documento Cancellazione dei fondi cashless nella causale degli ordini selezionati è impossibile';
						|pl = 'Wprowadzanie dokumentu Wyksięgowanie bezgotówkowych ŚP na podstawie zaznaczonych zamówień jest niemożliwe';
						|tr = 'Seçilen siparişler bazında ""Giden ödeme — banka hesabı"" belgesinin girişi mümkün değildir'");
		CommonClientServer.MessageToUser(ErrorText,,,, Cancel);
	EndIf;

	Return Not Cancel;
	
EndFunction // To form the data of the completion of the list of the following documents()

// This procedure converts the document amounts to the new currency.
//
// Parameters:
//	Object - FormDataStructure - Current document
//	CurrentCurrency - CatalogRef.Currencies - Current currency
//	NewCurrency - CatalogRef.Currencies - New currency.
//
Procedure ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, NewCurrency) Export
	
	If Not ValueIsFilled(CurrentCurrency)
		Or Not ValueIsFilled(NewCurrency) Then
		Return;
	EndIf;
	
	If Object.Property("ARAPDetails") Then
		
		// It is needed to search for coefficients and determine the correspondence of the decryption string and the resulting coefficient by index
		AmountsTableByObjects = Object.ARAPDetails.Unload(, "ARAPObject, Sum");
		AmountsTableByObjects.Columns.Add("ZoomRatio");
		AmountsTableByObjects.Indexes.Add("ZoomRatio");
		
		TableOfCoefficients = ProcessingOfExchangeRatesTM.GetConversionFactorsForCalculationObjects(
			CurrentCurrency,
			NewCurrency,
			Object.Date,,
			AmountsTableByObjects.UnloadColumn("ARAPObject"));
		// We will find and fill in the coefficients for each calculation object
		TableOfCoefficients.Indexes.Add("ARAPObject");
		For Each AmmountLine In AmountsTableByObjects Do
			CoefficientString = TableOfCoefficients.Find(AmmountLine.ARAPObject, "ARAPObject");
			If CoefficientString = Undefined Then
				AmmountLine.ZoomRatio = 1;
			Else
				AmmountLine.ZoomRatio = CoefficientString.ZoomRatio;
			EndIf;
		EndDo;
		// To get the total amount for each coefficient
		AmountsTableByCoefficients = AmountsTableByObjects.Copy();
		AmountsTableByCoefficients.GroupBy("ZoomRatio", "Sum");
		
		DocumentAmount = 0;
		For Each CoefficientString In AmountsTableByCoefficients Do
			
			TotalAmount_5 = CoefficientString.Sum;
			AmountByCoefficient = Round(CoefficientString.ZoomRatio * TotalAmount_5, 2, 1);
			DocumentAmount = DocumentAmount + AmountByCoefficient;
			// Let's recalculate the amounts in the tabular part of the document.
			If TotalAmount_5 <> 0 Then
				SumLines = AmountsTableByObjects.FindRows(New Structure("ZoomRatio", CoefficientString.ZoomRatio));
				For Each AmmountLine In SumLines Do
					TableRow = Object.ARAPDetails[AmountsTableByObjects.IndexOf(AmmountLine)];
					Sum = ?(TotalAmount_5 <> 0, Round(AmountByCoefficient * TableRow.Sum / TotalAmount_5, 2, 1), 0);
					TotalAmount_5 = TotalAmount_5 - TableRow.Sum;
					AmountByCoefficient = AmountByCoefficient - Sum;
					TableRow.Sum = Sum;
				EndDo;
			EndIf;
			
		EndDo;
		
		Object.DocumentAmount = DocumentAmount;
		
	Else
		
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			CurrentCurrency,
			NewCurrency,
			Object.Date);
		
		// Recalculate the amount of the document into a new currency.
		Object.DocumentAmount = Round(ConversionFactor_ * Object.DocumentAmount, 2, 1);
		
	EndIf;
	
EndProcedure

// Returns the Contract found for the specified conditions.
// Parameters:
//    CurContract - CatalogRef.CounterpartyContracts - Contract with the counterparty
//    Partner - CatalogRef.Partners - Partner
//    Counterparty - CatalogRef.Counterparties - Counterparty
//    Organization - CatalogRef.Companies - Organization
//    BusinessTransactions - EnumRef.BusinessTransactions - economic operation.
//    AdditionalSelection - Undefined, Structure - additional selections.
//
// Returns:
//   CatalogRef.CounterpartyContracts - the default contract that is the object of settlement.
//
Function DefaultContract(
	CurContract,
	Partner,
	Counterparty,
	Organization,
	BusinessTransactions,
	AdditionalSelection = Undefined) Export
	
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
	
	Query = New Query("
	|SELECT ALLOWED
	|	CounterpartyContracts.Ref
	|
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|
	|WHERE
	|	(NOT CounterpartyContracts.DeletionMark)
	|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND CounterpartyContracts.Partner IN (&PartnerList)
	|	AND CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND ((NOT &FilterBusinessOperation)
	|			OR CounterpartyContracts.BusinessOperation IN (&BusinessOperation))
	|	AND CounterpartyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|	AND &AdditionalSelection
	|	AND CounterpartyContracts.Ref = &CurContract
	|;
	|
	|SELECT ALLOWED TOP 2
	|	CounterpartyContracts.Ref
	|
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|
	|WHERE
	|	(NOT CounterpartyContracts.DeletionMark)
	|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND CounterpartyContracts.Partner IN (&PartnerList)
	|	AND CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND ((NOT &FilterBusinessOperation)
	|			OR CounterpartyContracts.BusinessOperation IN (&BusinessOperation))
	|	AND CounterpartyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|	AND &AdditionalSelection
	|
	|");
	Query.SetParameter("CurContract", CurContract);
	Query.SetParameter("PartnerList", PartnerList);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("FilterBusinessOperation", ValueIsFilled(BusinessTransactions));
	Query.SetParameter("BusinessOperation", BusinessTransactions);

	If AdditionalSelection = Undefined Then
		Query.SetParameter("AdditionalSelection", True);
	Else
		
		AdditionalConditions = New Array;
		
		For Each KeyAndValue In AdditionalSelection Do
			
			AdditionalConditions.Add(StrTemplate("CounterpartyContracts.%1 IN (&%1)", KeyAndValue.Key));
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
			
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "&AdditionalSelection", StrConcat(AdditionalConditions, " And "));
		
	EndIf;
	
	ResultsArray = Query.ExecuteBatch();
	
	If Not ResultsArray[0].IsEmpty() Then
		
		Selection = ResultsArray[0].Select();
		Selection.Next();
		DefaultContract = Selection.Ref;
		
	Else
		Selection = ResultsArray[1].Select();
	
		If Not Selection.Next() Then
			DefaultContract = Catalogs.CounterpartyContracts.EmptyRef();
		ElsIf Selection.Count() = 1 Then
			DefaultContract = Selection.Ref;
		Else
			DefaultContract = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;
	
	Return DefaultContract;
	
EndFunction

// Generates the request text for getting the specified payment object details
//
// Parameters:
//    DocumentName - String - document name
//    SourceTable1 - String - Data source table
//    NameOfCalculationObject - String - Name of the calculation object
//    NameOfPaymentObjectDetails - String - Name of the payment object's details.
//
// Returns:
//    String - Query text
//
Function RequestTextForPaymentObjectDetails(DocumentName, SourceTable1, NameOfCalculationObject, NameOfPaymentObjectDetails) Export
	
	Return CashCached.RequestTextForPaymentObjectDetails(
				SourceTable1+"."+NameOfCalculationObject,
				NameOfPaymentObjectDetails,
				"Documents."+DocumentName+".TabularSections.ARAPDetails.Attributes."+NameOfCalculationObject);
	
EndFunction

// Deprecated. Returns the parameters of the function call to get the bank account of the organization to silence
//	
// Returns:
//    Structure - The structure of parameters for determining the account:
// 		* Organization    		  - CatalogRef.Companies - Organization to get an invoice for
// 		* PaymentMethod    		  - EnumRef.PaymentForms - The form of payment by which the need
// 									to obtain a bank account is determined
// 		* BankAccount 		  - CatalogRef.CompaniesBankAccounts - Bank account to fill out
//      * Currency		 		  - CatalogRef.Currencies - Account currency
//		* LineOfBusiness - CatalogRef.LinesOfBusiness - the desired direction of the account.
//
Function DefaultSettingsForFillingInOrganizationSBankAccount() Export
	
	Structure = New Structure;
	Structure.Insert("Organization");
	Structure.Insert("PaymentMethod");
	Structure.Insert("BankAccount");
	Structure.Insert("Currency");
	Structure.Insert("LineOfBusiness");
	
	Return Structure;
	
EndFunction

// Returns parameters for calling the function Get a bank accountcontradict by silence.
//
// Parameters:
//	Counterparty - CatalogRef.Counterparties, CatalogRef.Persons - Bank account holder.
//
// Returns:
//    Structure - The structure of parameters for determining the account:
//		* Counterparty            - CatalogRef.Counterparties, CatalogRef.Persons, Undefined -
//								The counterparty for whom you need to get an invoice.
//		* Currency                - CatalogRef.Currencies, Undefined - Account currency.
//		* OffsettingAccount - CatalogRef.CounterpartyBankAccounts, Undefined - Corresponding account.
//		* ExcludeCurrencyAccounts - Boolean - if True, the accounts in the currency passed in the Currency parameter will be excluded.
//
Function ParametersForFillingInCounterpartySBankAccount(Counterparty = Undefined) Export
	
	Structure = New Structure;
	Structure.Insert("Counterparty", Counterparty);
	Structure.Insert("Currency", Undefined);
	Structure.Insert("OffsettingAccount", Undefined);
	Structure.Insert("ExcludeCurrencyAccounts", False);
	
	Return Structure;
	
EndFunction

// Returns the parameters of the function call to get the bank account of the organization to silence
//
// Parameters:
//	Organization - CatalogRef.Companies - The organization for which you need to get an invoice.
//
// Returns:
//    Structure - The structure of parameters for determining the account:
//		* Organization             - CatalogRef.Companies, Undefined - The organization for which you need
//									to get an invoice.
//		* Currency                  - CatalogRef.Currencies, Undefined - Account currency.
//		* LineOfBusiness - CatalogRef.LinesOfBusiness, Undefined -
//									the desired direction of the account.
//		* OffsettingAccount   - CatalogRef.CompaniesBankAccounts, Undefined - Corresponding account.
//		* ExcludeCurrencyAccounts   - Boolean - if True, the accounts in the currency passed in the Currency parameter will be excluded.
//
Function ParametersForFillingOutOrganizationSBankAccount(Organization = Undefined) Export
	
	Structure = New Structure;
	Structure.Insert("Organization", Organization);
	Structure.Insert("Currency", Undefined);
	Structure.Insert("LineOfBusiness", Undefined);
	Structure.Insert("OffsettingAccount", Undefined);
	Structure.Insert("ExcludeCurrencyAccounts", False);
	
	Return Structure;
	
EndFunction

// Returns the parameters of the call to the getcassorganizationto silence function
//	
// Returns:
//    Structure - The structure of parameters for determining the account:
// 		* Organization    		  - CatalogRef.Companies - Organization to get an invoice for
// 		* PaymentMethod    		  - EnumRef.PaymentForms - The form of payment by which the need
// 									to obtain a bank account is determined
// 		* CashAccount					  - CatalogRef.CashAccounts - The cashier you need to fill out
//      * Currency		 		  - CatalogRef.Currencies - Account currency
//		* LineOfBusiness - CatalogRef.LinesOfBusiness - the desired direction of the account.
//		* Individual		  - CatalogRef.Persons
//
Function DefaultParametersForFillingInCheckout() Export
	
	Structure = New Structure;
	Structure.Insert("Organization");
	Structure.Insert("PaymentMethod");
	Structure.Insert("CashAccount");
	Structure.Insert("Currency");
	Structure.Insert("LineOfBusiness");
	Structure.Insert("Individual");
	
	Return Structure;
	
EndFunction


// Returns a list of business sales operations by document type
//
// Parameters:
//    DocumentType - Type - Document type
//
// Returns:
//    Array - List of business sales operations
//
Function GetListOfBusinessSalesOperationsForDocument(DocumentType) Export
	
	ArrayOfBusinessOperations = New Array();
	
	If DocumentType = Type("DocumentRef.CashVoucher") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
		
		
	ElsIf DocumentType = Type("DocumentRef.CashAccountReceiptNote") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
		
		
	ElsIf DocumentType = Type("DocumentRef.BankAccountReceiptNote") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.PaymentCardTransaction") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		
	ElsIf DocumentType = Type("DocumentRef.BankAccountIssue") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.PaymentRequest") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	
	EndIf;
	
	Return ArrayOfBusinessOperations;
	
EndFunction

// Returns a list of business purchase operations by document type
//
// Parameters:
//    DocumentType - Type - Document type
//
// Returns:
//    Array of EnumRef.BusinessTransactions - List of business purchase operations.
//
Function GetListOfPurchasingBusinessOperationsForDocument(DocumentType) Export
	
	ArrayOfBusinessOperations = New Array();
	
	If DocumentType = Type("DocumentRef.CashVoucher") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PaymentToVendor);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PaymentToLessor);
	ElsIf DocumentType = Type("DocumentRef.CashAccountReceiptNote") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromVendor);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.BankAccountReceiptNote") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromVendor);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.PaymentCardTransaction") Then
		
	ElsIf DocumentType = Type("DocumentRef.BankAccountIssue") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PaymentToVendor);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PaymentToLessor);
	ElsIf DocumentType = Type("DocumentRef.PaymentRequest") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PaymentToVendor);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PaymentToLessor);
	EndIf;
	
	Return ArrayOfBusinessOperations;
	
EndFunction

// fills in the data of the document form according to the array of Attributes used in the business operation.
// 
// Parameters:
//  DocumentObject - FormDataStructure - data of the document in which the filling is performed.
//  ManagerOfDocument - DocumentManager.PaymentRequest, DocumentManager.BankAccountIssue -
//                      document manager.
//
Procedure FillInFormDataAccordingToListOfAttributesOfBusinessTransaction(DocumentObject, ManagerOfDocument) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	ManagerOfDocument.FillInNamesOfBusinessTransactionDetails(
		DocumentObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
	ProcessingOfPaymentDecryption = EmptyTableForProcessingDecryptionOfPayment();
	
	If ArrayOfOperationDetails.Find("Counterparty") = Undefined Then
		DocumentObject.Counterparty = Undefined;
		DocumentObject.Contract = Undefined;
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"True",
			"Parameters.DecryptionString.ARAPObject = Catalogs.ARAPObjects.EmptyRef()");
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"True",
			"Parameters.DecryptionString.Partner = Catalogs.Partners.EmptyRef()");
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"True",
			"Parameters.DecryptionString.Contract = Undefined");
	EndIf;
	
	If ArrayOfOperationDetails.Find("Contract") = Undefined Then
		DocumentObject.Contract = Undefined;
	EndIf;
	
	If ArrayOfOperationDetails.Find("ARAPDetails.VATAmount") = Undefined
		And ArrayOfOperationDetails.Find("ARAPDetails.VATRate") = Undefined Then
		
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"True",
			"CashServer.ClearVATTaxation(Parameters.DocumentObject)");
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"True",
			"CashServer.UpdateTaxRateRecalculateVATAmount(Parameters.DocumentObject, Parameters.DecryptionString.GetID())");
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"True",
			"Parameters.DecryptionString.VATRate = Catalogs.VATRates.EXCLUDINGVAT");
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"True",
			"Parameters.DecryptionString.VATAmount = 0");
		
	Else
		AddPaymentDecryptionProcessing(
			ProcessingOfPaymentDecryption,
			"Parameters.DecryptionString.VATRate = Catalogs.VATRates.EXCLUDINGVAT",
			"CashServer.UpdateTaxRateRecalculateVATAmount(Parameters.DocumentObject, Parameters.DecryptionString.GetID())");
	EndIf;
	
	If ProcessingOfPaymentDecryption.Count() > 0 Then
		
		Parameters = New Structure;
		Parameters.Insert("DocumentObject", DocumentObject);
		
		For Each DecryptionString In DocumentObject.ARAPDetails Do
			
			Parameters.Insert("DecryptionString", DecryptionString);
			
			For Each ProcessingString In ProcessingOfPaymentDecryption Do
			
				If Common.CalculateInSafeMode(ProcessingString.Condition, Parameters) Then
					Common.ExecuteInSafeMode(ProcessingString.Action, Parameters);
				EndIf
			
			EndDo;
		
		EndDo;
		
	EndIf;
	
EndProcedure

// Sets/removes the payment with conversion attribute.
//
// Parameters:
//  DocumentObject - FormDataStructure - Current document.
//  NameOfDocumentManager - DocumentManager.PaymentRequest, DocumentManager.BankAccountIssue -
//  document manager. 
//
Procedure SetPaymentWithConversionAttribute(DocumentObject, NameOfDocumentManager) Export

	ManagerOfDocument = Common.ObjectManagerByFullName(NameOfDocumentManager);
	
	ArrayOfOperationDetails = New Array;
	ManagerOfDocument.FillInNamesOfBusinessTransactionDetails(
		DocumentObject, Undefined, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("PaymentWithConversion") = Undefined
		Or (DocumentObject.PersonsList
		And DocumentObject.TransferToEmployeeViaABank) Then
		DocumentObject.PaymentWithConversion = False;
	Else
		
		DocumentObject.PaymentWithConversion = DefinePaymentWithConversion(DocumentObject);
		
		If CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, "AllocationByAccounts") Then
			SetPaymentOptionWithConversionByListOfInvoices(DocumentObject);
		EndIf;
		
	EndIf;

EndProcedure

// Fills in the responsible persons of the organization in the document.
//
// Parameters:
//  DocumentObject - FormDataStructure - Payment document.
//
Procedure FillInResponsiblePersonsOfCompany(DocumentObject) Export

	Filter = New Structure;
	Filter.Insert("Date", DocumentObject.Date);
	Filter.Insert("Organization", DocumentObject.Organization);
	ResponsiblePersons = ResponsiblePersonsServer.GetTableOfResponsiblePersonsForSelection(Filter);
	
	If CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, "ChiefAccountant") Then
		
		DataOfChiefAccountant = ResponsiblePersons.Find(Enums.PersonsResponsibleAndCompanies.ChiefAccountant, "EmployeeInCharge_");
		
		If DataOfChiefAccountant <> Undefined Then
			DocumentObject.ChiefAccountant = DataOfChiefAccountant.Ref;
		Else
			DocumentObject.ChiefAccountant = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
		EndIf;
		
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, "Director") Then
		
		SupervisorData = ResponsiblePersons.Find(Enums.PersonsResponsibleAndCompanies.Director, "EmployeeInCharge_");
		
		If SupervisorData <> Undefined Then
			DocumentObject.Director = SupervisorData.Ref;
		Else
			DocumentObject.Director = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region CheckOffsetRatesInExpenseReports

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
//
Procedure AddStage_CheckOffsetRatesInExpenseReports(StepsTable, CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(
		StepsTable, CurrentParent, Catalogs.MonthEndClosingOperations.CheckOffsetRatesInExpenseReports);
		
	NewRow.MultilingualName = "vi = 'Kiểm tra tỷ giá khấu từ trong giấy thanh toán tiền tạm ứng';
								|ru = 'Проверка курсов зачета в авансовых отчетах';
								|en = 'Check offset rates in expense reports';
								|it = 'Verifica dei tassi di cambio di compensazione in report di anticipi';
								|pl = 'Sprawdzenie kursów zaliczenia w raportach zaliczkowych';
								|tr = 'Gider raporlarında mahsup kurlarının kontrolü'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Kết chuyển lại';
								|ru = 'Перепровести';
								|en = 'Repost'; fa = 'Repost';
								|it = 'Ripubblicare';
								|pl = 'Repost';
								|tr = 'Yeniden kaydet'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CashServer.Use_CheckingOffsettingRatesInAdvanceReports");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_ClientProcedure(
		"CashClient.Perform_VerificationOfCreditCoursesInAdvanceReports");
	
EndProcedure

// Stage handlers
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Use_CheckingOffsettingRatesInAdvanceReports(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	Query.SetParameter("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	
	QueryTexts = RequestTextsForCheckingCreditCoursesInAdvanceReports();
	
	ListItem = QueryTexts.Get(QueryTexts.Count()-1);
	ListItem.Value = StrReplace(ListItem.Value,
		"SELECT",
		"SELECT TOP 1"); //@query-part-1 @query-part-2
	ListItem.Value = StrReplace(ListItem.Value, "INTO TableCheckingOffsettingCoursesInAdvanceReports", "");
	
	Result = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts);
	
	If Result[Result.UBound()].IsEmpty() Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có khoản khấu trừ không chính xác số tiền ứng trước theo ngoại tệ cho người nhận thanh toán tạm ứng.';
				|ru = 'Нет некорректных зачетов валютных авансов подотчетным лицам.';
				|en = 'No incorrect currency prepayment offsets to advance holders.'; fa = 'No incorrect currency prepayment offsets to advance holders.';
				|it = 'Non vi sono compensazioni non corrette di anticipi di valuta ai soggetti dichiaranti.';
				|pl = 'Brak niepoprawnych zaliczeń zaliczek walutowych osobom odpowiedzialnym.';
				|tr = 'Döviz avanslarının sorumlu kişilere yanlış mahsup düzeltmeleri mevcut değildir.'", Common.DefaultLanguageCode()));
	Else
		MonthEndTransactionsServer.SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("vi = 'Đã tìm thấy các khoản khấu trừ không chính xác số tiền ứng trước theo ngoại tệ cho người nhận thanh toán tạm ứng. Cần kết chuyển lại giấy thanh toán tạm ứng.';
				|ru = 'Обнаружены некорректные зачеты валютных авансов подотчетным лицам. Требуется перепровести авансовые отчеты.';
				|en = 'Incorrect currency prepayment offsets to advance holders are found. Repost the expense reports.'; fa = 'Incorrect currency prepayment offsets to advance holders are found. Repost the expense reports.';
				|it = 'Sono state rilevate compensazioni non corrette di anticipi di valuta ai soggetti dichiaranti. Si richiede di ripubblicare i report di anticipi.';
				|pl = 'Wykryto niepoprawne zaliczenia zaliczek walutowych osobom odpowiedzialnym. Należy ponownie zatwierdzić raporty zaliczkowe.';
				|tr = 'Sorumlu kişilere yapılan döviz avanslarının yanlış mahsup edildiği tespit edildi. Gider raporlarının yeniden kaydı gerekir.'", Common.DefaultLanguageCode()),,
			MonthEndTransactionsServer.ActionDescription_OpenForm(Metadata.DataProcessors.JournalOfDocumentsExpenseReports.Forms.DocumentsList.FullName()),
			Enums.AccountingIssueSeverity.Warning);
	EndIf;
	
EndProcedure

// Stage handlers
// 
// Parameters:
// 	Handler ParameterSreferences - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
// Returns:
//	Boolean - indicates the End of processing
//
Function Perform_VerificationOfCreditCoursesInAdvanceReports(CalculationParameters) Export
	
	Query = New Query;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.SetParameter("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	
	QueryTexts = RequestTextsForCheckingCreditCoursesInAdvanceReports();
	
	QueryText = "
	|SELECT DISTINCT
	|	TableCheckingOffsettingCoursesInAdvanceReports.Recorder AS Recorder
	|FROM
	|	TableCheckingOffsettingCoursesInAdvanceReports
	|AUTOORDER
	|";
	QueryTexts.Add(QueryText);
	
	Result = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts);
	
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			DocumentObject = Selection.Recorder.GetObject();
			
			Try
				DocumentObject.Lock();
			Except
				MessageText = StrTemplate(
					NStr("vi = 'Chứng từ %1 do người sử dụng hoặc hệ thống đang chỉnh sửa nên không thể thay đổi.';
						|ru = 'Документ %1 находится в процессе редактирования пользователем или системой и не может быть изменен.';
						|en = 'The %1 document is being edited by a user or the system. It cannot be changed.'; fa = 'The %1 document is being edited by a user or the system. It cannot be changed.';
						|it = 'Il documento %1 si trova nel processo di modifica da parte dell''utente o del sistema e non può essere modificato.';
						|pl = 'Dokument %1 jest w trakcie edycji przez użytkownika lub przez system i nie może być zmieniony.';
						|tr = '%1 belgesi kullanıcı veya sistem tarafından düzenleniyor ve değiştirilemez.'"),
					DocumentObject);
				Common.MessageToUser(MessageText);
				Continue;
			EndTry;
			
			DocumentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", False);
			DocumentObject.Write(DocumentWriteMode.Posting);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorInfo = ErrorInfo();
			MessageText = NStr("vi = 'Không thể ghi lại chứng từ do nguyên nhân: %1';
								|ru = 'Не удалось записать документ по причине: %1';
								|en = 'Cannot save the document. Reason: %1'; fa = 'Cannot save the document. Reason: %1';
								|it = 'Non è stato possibile registrare il documento a causa di: %1';
								|pl = 'Nie udało się zapisać dokumentu z powodu: %1';
								|tr = 'Bu %1 nedenle belge kaydedilemedi'");
			MessageText = StrTemplate(MessageText, BriefErrorDescription(ErrorInfo));
			Common.MessageToUser(MessageText);
			
			ErrorText = NStr("vi = 'Không thể ghi lại chứng từ.';
							|ru = 'Не удалось записать документ.';
							|en = 'Cannot save the document.'; fa = 'Cannot save the document.';
							|it = 'Non è stato possibile registrare il documento.';
							|pl = 'Nie udało się zapisać dokumentu.';
							|tr = 'Belge kaydedilemedi.'", Common.DefaultLanguageCode());
			WriteLogEvent(
				ErrorText,
				EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo));
		EndTry;
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#Region GettingDataFromDocuments

// Returns the values of the document Attributes or undefined.
// 
// Parameters:
//  DocumentRef - DocumentRef - The document that uses the SBP.
//  PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of settlements with a partner.
//  SelectedAttributes - Map of KeyAndValue - Attributes to be obtained from the document.
//  GetSettlementAmounts - Boolean - indicates whether the settlement amount has been received.
// 
// Returns:
//  Structure - Document data:
//  *DocumentOperations - DocumentRef, CatalogRef.CounterpartyContracts - the document or Contract under which the payment operation of operation is performed.
//  *DocumentBasis - DocumentRef, Undefined - the basis of the Operation document.
//                       The type may be undefined if the Document Link parameter is entered for no reason.
//                       Required if the Documentlink parameter has the Documentlink type.Counter to the client.
//  *Organization - CatalogRef.Companies - Organization of the document.
//  *PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
//  *CounterpartyBankAccount - Undefined, CatalogRef.CompaniesBankAccounts, CatalogRef.CounterpartyBankAccounts - recipient's bank account.
//  *CompanyBankAccount - CatalogRef.CompaniesBankAccounts - The company's bank account.
//  *AccountNumber - String - the organization's bank account number.
//  *CounterpartyKind - EnumRef.LegalEntityIndividual - type of recipient.
//  *Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - recipient.
//  *TIN - String - Recipient's INN.
//  *Posted - Boolean - indicates whether the document is registered.
//  *ARAPObjectSettings - EnumRef.ARAPObjectSettings - the order of calculations in the document.
//  *PaymentID - String - Payment ID of the document.
//  *PaymentDate - Date, Undefined - the date of payment for the document.
//  *DocumentAmount - Number - the amount of the document.
//  *DocumentCurrency - CatalogRef.Currencies - the currency of the document.
//  *PaymentPurposes - String - purpose of payment for the document.
//  *PaymentSteps - Undefined, String - table of payment stages placed in temporary storage.
//  *ThisIsOrder - Boolean - the order document attribute.
//  *ThisIsSalePurchase - Boolean - the document attribute is an invoice.
//  *ChangesPaymentPlan - Boolean - reduces or increases the payment plan.
//  *OrderAsAProformaInvoice - Boolean - The order is used as an invoice.
//  *Warehouse - CatalogRef.Warehouses, Undefined - the warehouse on the document.
//  *AdditionalInformation - String - additional information.
//
Function DocumentData(DocumentRef, PaymentType_, SelectedAttributes, GetSettlementAmounts = False) Export

	AttributesStructure1 = ParametersByTypeOfCalculations(DocumentRef, PaymentType_);
	
	If AttributesStructure1 = Undefined Then
		Raise NStr("vi = 'Chưa xác định tham số hạch toán công nợ chứng từ.';
					|ru = 'Не определены параметры взаиморасчетов документа.';
					|en = 'The document AR/AP accounting parameters are not identified.'; fa = 'The document AR/AP accounting parameters are not identified.';
					|it = 'The document AR/AP accounting parameters are not identified.';
					|pl = 'The document AR/AP accounting parameters are not identified.';
					|tr = 'Belgenin alacak/borç muhasebesi parametreleri tanımlanmadı.'");
	EndIf;
	
	DocumentMetadata = DocumentRef.Metadata();
	FullName = DocumentMetadata.FullName();
	
	QuerySchema = New QuerySchema;
	SelectionRequest = QuerySchema.QueryBatch[0];
	SelectionOperator = SelectionRequest.Operators[0];
	SelectionOperator.Sources.Add(FullName, "Object");
	SelectionOperator.Filter.Add("Object.Ref = &Ref");
	
	If Common.IsDocument(DocumentMetadata) Then
		AddFieldSelectionToQuerySchema(SelectionRequest, "Object.Posted", "", "Posted");
	Else
		AddFieldSelectionToQuerySchema(SelectionRequest, "", "", "Posted", "False");
	EndIf;
	
	If TypeOf(DocumentRef) = Type("DocumentRef.CustomerCommercialInvoice") Then
		AddFieldSelectionToQuerySchema(SelectionRequest, AttributesStructure1.DocumentBasis, "", "DocumentOperations");
	Else
		AddFieldSelectionToQuerySchema(SelectionRequest, "Object.Ref", "", "DocumentOperations");
	EndIf;
	
	For Each CurrentAttribute In SelectedAttributes Do
		
		PointPosition = StrFind(CurrentAttribute.Key, ".");
		
		If PointPosition > 0 Then
			AttributeName = TrimAll(Mid(CurrentAttribute.Key, 1, PointPosition - 1));
			SubordinateAttribute = TrimAll(Mid(CurrentAttribute.Key, PointPosition + 1, StrLen(CurrentAttribute.Key)));
		Else
			AttributeName = CurrentAttribute.Key;
			SubordinateAttribute = "";
		EndIf;
		
		DefaultValue = 
			?(TypeOf(AttributesStructure1[AttributeName]) = Type("Boolean"), Format(AttributesStructure1[AttributeName], "BF=FALSE; BT=TRUE"), "Undefined");
		AddFieldSelectionToQuerySchema(SelectionRequest, AttributesStructure1[AttributeName], SubordinateAttribute, CurrentAttribute.Value, DefaultValue);
		
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	
	QueryResult = Query.Execute();
	
	Result = New Structure;
	
	For Each Column In QueryResult.Columns Do
		Result.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
		
		If CommonClientServer.HasAttributeOrObjectProperty(Selection, "PaymentSteps")
			And ValueIsFilled(Selection.PaymentSteps) Then
			Result.PaymentSteps = PutToTempStorage(Selection.PaymentSteps.Unload(), New UUID);
		EndIf;
	
	Else
		Raise NStr("vi = 'Chưa xác định dữ liệu chứng từ.';
					|ru = 'Не определены данные документа.';
					|en = 'The document data is not identified.'; fa = 'The document data is not identified.';
					|it = 'The document data is not identified.';
					|pl = 'The document data is not identified.';
					|tr = 'Belgenin verileri tanımlanmadı.'");
	EndIf;
	
	If GetSettlementAmounts Then
		
		MutualSettlementsStatus = ARAPAccountingServer.MutualSettlementsStatus(DocumentRef, AttributesStructure1);
		CommonClientServer.SupplementStructure(Result, MutualSettlementsStatus, True);
		
	EndIf;
	
	Return Result;

EndFunction

// Returns the counterparty type of the Operation document.
// 
// Parameters:
//  Document - DocumentRef - The document for which you need to get the type of counterparty.
//  PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of settlements with a partner.
// 
// Returns:
//  EnumRef.LegalEntityIndividual - Type of Counterparty of Operation Document
Function TypeOfCounterpartyOfOperationDocument(Document, PaymentType_) Export

	CounterpartyKind = Enums.LegalEntityIndividual.EmptyRef();
	
	If Document.IsEmpty() Then
		Return CounterpartyKind;
	EndIf;
	
	ParametersStructure = ParametersByTypeOfCalculations(Document, PaymentType_);
	
	If ParametersStructure = Undefined Then
		
		ParametersStructure = New Structure;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Document, "Counterparty") Then
			ParametersStructure.Insert("Counterparty", "Object.Counterparty");
		Else
			ParametersStructure = Undefined;
		EndIf;
		
	EndIf;
	
	If ParametersStructure <> Undefined Then
		
		QuerySchema = New QuerySchema;
		SelectionRequest = QuerySchema.QueryBatch[0];
		SelectionOperator = SelectionRequest.Operators[0];
		AddDescriptionOfSelectionForDocument(SelectionOperator, Document);
		AddFieldSelectionToQuerySchema(SelectionRequest, ParametersStructure.Counterparty, "LegalEntityIndividual", "CounterpartyKind");
		
		QueryText = QuerySchema.GetQueryText();
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Ref", Document);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		If Selection.Next() Then
			CounterpartyKind = ?(Selection.CounterpartyKind = Undefined, CounterpartyKind, Selection.CounterpartyKind);
		EndIf;
		
	EndIf;
	
	Return CounterpartyKind;

EndFunction

// Returns the sum of the document.
// 
// Parameters:
//   DocumentPayments - DocumentRef - Payment AR/AP transaction document (coincides with the document, except for the case of an invoice for payment to the client)
//   DocumentBasis - DocumentRef, CatalogRef.CounterpartyContracts - the document is the basis or Contract (for the invoice for payment)
// 
// Returns:
//  ValueTable - Document amounts:
//  * VATAmount - Number - amount of VAT.
//  * AmountIncludingVAT - Number - the amount including VAT.
//  * VATRate - Number - VAT rate
//
Function DocumentAmounts(DocumentPayments, DocumentBasis) Export

	IsAccount = TypeOf(DocumentPayments) = Type("DocumentRef.CustomerCommercialInvoice");
	
	If IsAccount Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	PaymentScheduleSteps.PaymentDate AS PaymentDate,
			|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
			|	PaymentScheduleSteps.PaymentAmount AS PaymentAmount,
			|	PaymentScheduleSteps.ThisIsDepositForPackage AS ThisIsDepositForPackage
			|FROM
			|	Document.CustomerCommercialInvoice.PaymentScheduleSteps AS PaymentScheduleSteps
			|WHERE
			|	PaymentScheduleSteps.Ref = &DocumentPayments";
		
		Query.SetParameter("DocumentPayments", DocumentPayments);
		PaymentScheduleSteps = Query.Execute().Unload();
		
		TableOfAmounts = InvoiceAmountsToBePaid(DocumentBasis, PaymentScheduleSteps);
		
	Else
		
		QueriesTexts = New Array;
		QueriesTexts.Add(QueryTextForFullPaymentAmounts(DocumentBasis));
		
		FinalSelection =
			"SELECT
			|	TableOfAmounts.VATRate AS VATRate,
			|	CAST(TableOfAmounts.VATAmount AS NUMBER(31,2)) AS VATAmount,
			|	CAST(TableOfAmounts.AmountIncludingVAT AS NUMBER(31,2)) AS AmountIncludingVAT
			|FROM
			|	&TableOfAmounts AS TableOfAmounts";
		
		FinalSelection = StrReplace(FinalSelection, "&TableOfAmounts", "FullPaymentAmounts");
		
		QueriesTexts.Add(FinalSelection);
		
		Query = New Query;
		Query.Text = StrConcat(QueriesTexts, ";");
		Query.SetParameter("DocumentOperations", DocumentBasis);
		TableOfAmounts = Query.Execute().Unload();
	
	EndIf;
	
	Return TableOfAmounts;

EndFunction

// Returns parameters for settlements with the client.
// 
// Parameters:
//  Document - DocumentRef - Document
//  PaymentType_ - EnumRef.PartnersARAPAccountingTypes - the type of calculation used to determine the parameters for the sample.
// 
// Returns:
//  See ARAPAccountingServer.MechanismParameters
//
Function ParametersByTypeOfCalculations(Document, PaymentType_) Export

	ObjectManager = Common.ObjectManagerByRef(Document);
	
	MechanismParameters = ObjectManager.SettlementParameters_(Document);
	
	If TypeOf(MechanismParameters) = Type("Array") Then
		ParametersArray = MechanismParameters;
	Else
		ParametersArray = CommonClientServer.ValueInArray(MechanismParameters);
	EndIf;
	
	ParametersStructure = Undefined;
	
	For Each DocumentParameters In ParametersArray Do
		
		If DocumentParameters.PaymentType_ <> PaymentType_ Then
			Continue;
		EndIf;
		
		ParametersStructure = Common.CopyRecursive(DocumentParameters);
		
	EndDo;
		
	Return ParametersStructure;

EndFunction

// Returns the purpose of payment for the Operation document.
// 
// Parameters:
//  DocumentRef - DocumentRef - Operation document.
//  DocumentData - Structure -Document data of operations:
//  *Number - String - document number.
//  *Date - Date - document date.
//  *CurrencyCode_ - String - the currency code of the document.
//  *Currency - CatalogRef.Currencies - the currency of the document.
//  *ARAPObjectSettings - EnumRef.ARAPObjectSettings - the order of calculations of the document of operation.
//  *ThisIsOrder - Boolean - indicates ofoperation document is an order.
//  *Contract - CatalogRef.CounterpartyContracts - The Contract is in the document of operation.
//  TableOfAmounts - ValueTable - Table with document amounts:
//  *VATRate - CatalogRef.VATRates - VAT rate.
//  *VATAmount - Number - amount of VAT.
//  *AmountIncludingVAT - Number - the amount including VAT.
// 
// Returns:
//  String - Purpose of Payment of the Operation Document
Function PurposeOfPaymentOfOperationDocument(DocumentRef, DocumentData, TableOfAmounts) Export

	PresentationsOfDocuments = GetDocumentPresentations();
	DocumentName = DocumentRef.Metadata().Name;
	
	If DocumentData.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or (DocumentData.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
			And DocumentData.ThisIsOrder) Then
		
		ContractData = Common.ObjectAttributesValues(DocumentData.Contract, "Date, Number");
		ReferenceDocumentDateForCertificate = Format(ContractData.Date, "DLF=D");
		NumberOfBaseDocument = ContractData.Number;
		
		If ValueIsFilled(ReferenceDocumentDateForCertificate)
			And ValueIsFilled(NumberOfBaseDocument) Then
			BaseDocumentPresentation = StrTemplate(NStr("vi = 'Thanh toán theo hợp đồng số %1 ngày %2';
														|ru = 'Оплата по договору №%1 от %2';
														|en = 'Payment under contract No. %1 dated %2'; fa = 'Payment under contract No. %1 dated %2';
														|it = 'Payment under contract No. %1 dated %2';
														|pl = 'Payment under contract No. %1 dated %2';
														|tr = '%2 itibarıyla %1 numaralı sözleşme kapsamındaki ödeme'"), NumberOfBaseDocument, ReferenceDocumentDateForCertificate);
		Else
			BaseDocumentPresentation = NStr("vi = 'Thanh toán theo hợp đồng';
											|ru = 'Оплата по договору';
											|en = 'Payment under contract'; fa = 'Payment under contract';
											|it = 'Payment under contract';
											|pl = 'Payment under contract';
											|tr = 'Sözleşme kapsamındaki ödeme'");
		EndIf;
		
	Else
		
		ReferenceDocumentDateForCertificate = Format(DocumentData.Date, "DLF=D");
		NumberOfBaseDocument = ObjectsPrefixesClientServer.NumberForPrinting(DocumentData.Number);
		
		If CommonClientServer.HasAttributeOrObjectProperty(PresentationsOfDocuments, DocumentName) Then
			BaseDocumentPresentation = StrTemplate(NStr("vi = 'Thanh toán theo %1 số %2 ngày %3';
														|ru = 'Оплата по %1 №%2 от %3';
														|en = 'Payment under %1 No. %2 dated %3'; fa = 'Payment under %1 No. %2 dated %3';
														|it = 'Payment under %1 No. %2 dated %3';
														|pl = 'Payment under %1 No. %2 dated %3';
														|tr = '%3 itibarıyla %2 numaralı %1 kapsamındaki ödeme'"), PresentationsOfDocuments[DocumentName], NumberOfBaseDocument, ReferenceDocumentDateForCertificate);
		Else
			BaseDocumentPresentation = StrTemplate(NStr("vi = 'Thanh toán theo hóa đơn số %1 ngày %2';
														|ru = 'Оплата по накладной №%1 от %2';
														|en = 'Payment under invoice No. %1 dated %2'; fa = 'Payment under invoice No. %1 dated %2';
														|it = 'Payment under invoice No. %1 dated %2';
														|pl = 'Payment under invoice No. %1 dated %2';
														|tr = '%2 itibarıyla %1 numaralı fatura kapsamındaki ödeme'"), NumberOfBaseDocument, ReferenceDocumentDateForCertificate);
		EndIf;
		
	EndIf;
	
	VATTemplate = NStr("vi = 'Thuế GTGT (%1) %2 %3';
						|ru = 'НДС (%1) %2 %3';
						|en = 'VAT (%1) %2 %3'; fa = 'VAT (%1) %2 %3';
						|it = 'VAT (%1) %2 %3';
						|pl = 'VAT (%1) %2 %3';
						|tr = 'KDV (%1) %2 %3'");
	
	VATTable = TableOfAmounts.Copy(, "VATRate, VATAmount");
	VATTable.GroupBy("VATRate, VATAmount");
	
	If DocumentData.CurrencyCode_ = "643" Then
		Currency = NStr("vi = 'đồng';
						|ru = 'руб.';
						|en = 'rub.'; fa = 'rub.';
						|it = 'rub.';
						|pl = 'rub.';
						|tr = 'rub.'");
	Else
		Currency = TrimAll(DocumentData.Currency);
	EndIf;
	
	LinesWithVAT = New Array;
	
	For Each TableRow In VATTable Do
		
		If TableRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT
			Or Not ValueIsFilled(TableRow.VATRate) Then
			Continue;
		EndIf;
		
		LinesWithVAT.Add(StrTemplate(VATTemplate, TableRow.VATRate, Format(TableRow.VATAmount, "NFD=2; NDS=-; NZ=0-00; NG="), Currency));
		
	EndDo;
	
	VATText = StrConcat(LinesWithVAT, ", ");
	
	If VATText = "" Then
		VATText = NStr("vi = 'Không gồm thuế (GTGT)';
						|ru = 'Без налога (НДС)';
						|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
						|it = 'senza imposta (IVA)';
						|pl = 'bez podatku (VAT)';
						|tr = 'Vergisiz (KDV)'");
	Else
		VATText = NStr("vi = 'trong đó';
						|ru = 'В т.ч.';
						|en = 'Including'; fa = 'شامل';
						|it = 'Incl.';
						|pl = 'W tym';
						|tr = 'Tablo bölümünde'") + " " + VATText;
	EndIf;
	
	Template = NStr("vi = '%1 Số tiền %2 %3 %4';
					|ru = '%1 Сумма %2 %3 %4';
					|en = '%1 Amount %2 %3 %4'; fa = '%1 Amount %2 %3 %4';
					|it = '%1 Amount %2 %3 %4';
					|pl = '%1 Amount %2 %3 %4';
					|tr = '%1 Tutar %2 %3 %4'");
	Result = StrTemplate(Template, 
		BaseDocumentPresentation,
		Format(TableOfAmounts.Total("AmountIncludingVAT"), "NFD=2; NDS=-; NZ=0-00; NG="),
		Currency,
		VATText);
	
	Result = StrReplace(Result, Char(160), Char(32));
	
	Return Result;

EndFunction

#EndRegion
 
#EndRegion

#Region Internal

// The function checks whether an order is available in the "payment Description" tabular part of the document.
//
// Parameters:
//	Object - FormDataStructure - the current object.
//
// Returns:
//	Boolean - True - the order is specified in the row of the table part.
//
Function OrderSpecifiedInPaymentDecryption(Object)
	
	OrderSpecified = False;
	For Each TableRow In Object.ARAPDetails Do
		If ValueIsFilled(TableRow.ARAPObject) Then
			OrderSpecified = True;
			Break;
		EndIf;
	EndDo;
	
	Return OrderSpecified;
	
EndFunction // The order of the payment decryption is specified()

// The procedure sets the selection parameters for the counterparty, if separate partner and counterparty management is not enabled.
//
// Parameters:
//	Object - FormDataStructure - Current object
//	Item - FormField - Field for entering the counterparty.
//
Procedure SetCounterpartySelectionParameters(Object, Item) Export
	
	If Not GetFunctionalOption("UsePartnersAsCounterparties") Then
		Return;
	EndIf;
	
	ParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or Object.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
		Or Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor
		Or Object.BusinessOperation = Enums.BusinessTransactions.TaxRefund Then
		
		ParametersArray.Add(New ChoiceParameter("Filter.OtherRelations", True));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue
		Or Object.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

// Generates a VAT table for the transferred payment items
// 
// Parameters:
//    Organization - CatalogRef.Companies - Organization of the payment document
//    DocumentDate - Date - Date of the payment document
//    DocumentCurrency - CatalogRef.Currencies - Currency of the payment document
//    ARAPObjects - Array of CatalogRef.ARAPObjects - Calculation objects whose VAT data is selected
//    PaymentFromCustomer - Boolean - Indicates payment from the customer or payment to the supplier.
//
// Returns:
//  ValueTable:
// * Ref - Undefined, document link.Implementationsparovuslug, Documentlink.Actfulfilled work,
//    Document link.Realizationuslug of other assets, documentlink.REPORTDAVALTSU2_5, Documentlink.Acquirementovarovuslug,
//    Document link.Purchasing services of other assets, documentlink.Processing report2_5 - document object of calculations.
// * DocumentAmount - Number - the amount of the document.
// * VATRate - CatalogRef.VATRates - the VAT rate of the document.
// * AmountIncludingVAT - Number - the amount of the document with VAT.
// * VATAmount - Number - the VAT amount of the document.
//
Function TranscriptOfVATPayment(Organization, DocumentDate, DocumentCurrency, ARAPObjects, PaymentFromCustomer = False) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ARAPObjects.Object AS Document,
	|	ARAPObjects.Ref AS ARAPObject,
	|	NULL AS DocumentBasis
	|INTO ObjectsArray
	|FROM 
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE 
	|	ARAPObjects.Ref IN (&ARAPObjects)
	|	AND NOT ARAPObjects.Object REFS Document.CCDImport
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPObjectsBetweenCompanies.Object AS Document,
	|	ARAPObjectsBetweenCompanies.Ref AS ARAPObject,
	|	NULL AS DocumentBasis
	|FROM 
	|	Catalog.ARAPObjects AS ARAPObjects
	|	INNER JOIN Catalog.ARAPObjects AS ARAPObjectsBetweenCompanies
	|		ON ARAPObjectsBetweenCompanies.Object = ARAPObjects.Object
	|			AND ARAPObjectsBetweenCompanies.Ref <> ARAPObjects.Ref
	|WHERE 
	|	ARAPObjects.Ref IN (&ARAPObjects)
	|	AND ARAPObjects.Counterparty REFS Catalog.Companies
	|
	|UNION ALL
	|
	|SELECT
	|	SaleAdjustment.Ref AS Document,
	|	ARAPObjects.Ref AS ARAPObject,
	|	SaleAdjustment.DocumentBasis AS DocumentBasis
	|FROM 
	|	Catalog.ARAPObjects AS ARAPObjects
	|	INNER JOIN
	|		Document.SaleAdjustment AS SaleAdjustment
	|	ON
	|		SaleAdjustment.DocumentBasis = ARAPObjects.Object
	|WHERE 
	|	ARAPObjects.Ref IN (&ARAPObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseAdjustment.Ref,
	|	ARAPObjects.Ref,
	|	PurchaseAdjustment.DocumentBasis
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		INNER JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
	|		ON (PurchaseAdjustment.DocumentBasis = ARAPObjects.Object)
	|WHERE
	|	ARAPObjects.Ref IN(&ARAPObjects)
	|
	|INDEX BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(ObjectsArray.DocumentBasis, Amounts.Recorder) AS Ref,
	|	CASE
	|		WHEN Amounts.Recorder REFS Document.SourceDocument
	|			THEN 
	|				CASE WHEN ISNULL(CAST(Amounts.Recorder AS Document.SourceDocument).Contract.VATRate, 
	|								VALUE(Catalog.VATRates.EmptyRef)) = VALUE(Catalog.VATRates.EmptyRef)
	|				 		THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				 	ELSE CAST(Amounts.Recorder AS Document.SourceDocument).Contract.VATRate
	|				END 
	|		WHEN Amounts.VATAmount = 0 AND ISNULL(Amounts.VATRate.Rate1, 0) <> 0 
	|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		ELSE Amounts.VATRate
	|	END                                     AS VATRate,
	|	SUM(Amounts.AmountExcludingVAT + Amounts.VATAmount) AS AmountIncludingVAT,
	|	SUM(Amounts.VATAmount)                     AS VATAmount,
	|	Amounts.Currency                              AS Currency
	|
	|INTO AmountsInAccountingCurrencies
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
	|	INNER JOIN
	|		ObjectsArray AS ObjectsArray
	|	ON
	|		ObjectsArray.Document = Amounts.Recorder
	|WHERE
	|	Amounts.ARAPObject IN (SELECT ARAPObject FROM ObjectsArray)
	|	AND Amounts.RecordedInARAPAccounting
	|	
	|GROUP BY
	|	ISNULL(ObjectsArray.DocumentBasis, Amounts.Recorder),
	|	CASE
	|		WHEN Amounts.Recorder REFS Document.SourceDocument
	|			THEN 
	|				CASE WHEN ISNULL(CAST(Amounts.Recorder AS Document.SourceDocument).Contract.VATRate, 
	|								VALUE(Catalog.VATRates.EmptyRef)) = VALUE(Catalog.VATRates.EmptyRef)
	|				 		THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				 	ELSE CAST(Amounts.Recorder AS Document.SourceDocument).Contract.VATRate
	|				END 
	|		WHEN Amounts.VATAmount = 0 AND ISNULL(Amounts.VATRate.Rate1, 0) <> 0 
	|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		ELSE Amounts.VATRate
	|	END,
	|	Amounts.Currency
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Amounts.Ref                     AS Ref,
	|	Amounts.VATRate                  AS VATRate,
	|	Amounts.AmountIncludingVAT                  AS AmountIncludingVAT,
	|	Amounts.VATAmount                   AS VATAmount,
	|	Amounts.Currency                     AS Currency,
	|	ResultsOnDocuments.DocumentAmount AS DocumentAmount
	|
	|INTO TableOfVATAmounts
	|FROM
	|	AmountsInAccountingCurrencies AS Amounts
	|		INNER JOIN (SELECT
	|			Amounts.Ref AS Ref,
	|			SUM(Amounts.AmountIncludingVAT) AS DocumentAmount
	|		FROM
	|			AmountsInAccountingCurrencies AS Amounts
	|		
	|		GROUP BY
	|			Amounts.Ref) AS ResultsOnDocuments
	|		ON Amounts.Ref = ResultsOnDocuments.Ref
	|	
	|UNION ALL
	|	
	|SELECT
	|	Amounts.Ref        AS Ref,
	|	Amounts.VATRate     AS VATRate,
	|	0                   AS AmountIncludingVAT,
	|	0                   AS VATAmount,
	|	UNDEFINED        AS Currency,
	|	0                   AS DocumentAmount
	|
	|FROM
	|	Catalog.CounterpartyContracts AS Amounts
	|
	|WHERE
	|	Amounts.Ref IN (SELECT Document FROM ObjectsArray)
	|	
	|UNION ALL
	|	
	|SELECT
	|	Amounts.Ref        AS Ref,
	|	Amounts.VATRate     AS VATRate,
	|	0                   AS AmountIncludingVAT,
	|	0                   AS VATAmount,
	|	UNDEFINED        AS Currency,
	|	0                   AS DocumentAmount
	|
	|FROM
	|	Catalog.IntercompanyContracts AS Amounts
	|
	|WHERE
	|	Amounts.Ref IN (SELECT Document FROM ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * DocumentExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * DocumentExchangeRate.CourseNumerator) AS ConversionFactor_
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|		INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate,
	|							Currency = &DocumentCurrency AND BaseCurrency = &BaseCurrency) AS DocumentExchangeRate
	|		ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND DocumentExchangeRate.CourseNumerator <> 0
	|
	|INDEX BY
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfVATAmounts.Ref                        AS Ref,
	|	TableOfVATAmounts.DocumentAmount                AS DocumentAmount,
	|	CASE
	|		WHEN TableOfVATAmounts.VATRate.RelevantBaseRate <> VALUE(Catalog.VATRates.EmptyRef)
	|			THEN TableOfVATAmounts.VATRate.RelevantBaseRate
	|		ELSE TableOfVATAmounts.VATRate
	|	END                                        AS VATRate,
	|	CASE
	|		WHEN TableOfVATAmounts.VATRate.RelevantBaseRate <> VALUE(Catalog.VATRates.EmptyRef)
	|			THEN TableOfVATAmounts.VATRate.RelevantBaseRate.Rate1
	|		ELSE TableOfVATAmounts.VATRate.Rate1
	|	END                                        AS Rate1,
	|	SUM(TableOfVATAmounts.AmountIncludingVAT)              AS AmountIncludingVAT,
	|	SUM(TableOfVATAmounts.VATAmount)               AS VATAmount,
	|	TableOfVATAmounts.Currency                        AS Currency,
	|	ISNULL(ExchangeRates.ConversionFactor_, 1) AS ConversionFactor_
	|
	|FROM
	|	TableOfVATAmounts AS TableOfVATAmounts
	|
	|	LEFT JOIN
	|		ExchangeRates
	|	ON
	|		TableOfVATAmounts.Currency = ExchangeRates.Currency
	|
	|GROUP BY
	|	TableOfVATAmounts.Ref,
	|	TableOfVATAmounts.DocumentAmount,
	|	ExchangeRates.ConversionFactor_,
	|	CASE
	|		WHEN TableOfVATAmounts.VATRate.RelevantBaseRate <> VALUE(Catalog.VATRates.EmptyRef)
	|			THEN TableOfVATAmounts.VATRate.RelevantBaseRate
	|		ELSE TableOfVATAmounts.VATRate
	|	END,
	|	TableOfVATAmounts.Currency,
	|	CASE
	|		WHEN TableOfVATAmounts.VATRate.RelevantBaseRate <> VALUE(Catalog.VATRates.EmptyRef)
	|			THEN TableOfVATAmounts.VATRate.RelevantBaseRate.Rate1
	|		ELSE TableOfVATAmounts.VATRate.Rate1
	|	END
	|
	|HAVING
	|	(SUM(TableOfVATAmounts.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfVATAmounts.VATAmount) <> 0)
	|	OR VALUETYPE(TableOfVATAmounts.Ref) IN (
	|		TYPE(Catalog.CounterpartyContracts),
	|		TYPE(Catalog.IntercompanyContracts)
	|	)
	|";
	
	If Not ValueIsFilled(DocumentCurrency) Then
		DocumentCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	BaseCurrency  = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	Query.SetParameter("ARAPObjects", ARAPObjects);
	Query.SetParameter("DocumentDate", DocumentDate);
	Query.SetParameter("DocumentCurrency", DocumentCurrency);
	Query.SetParameter("BaseCurrency", BaseCurrency);
	
	Result = Query.Execute();
	
	TableOfAmounts = New ValueTable;
	
	For Each Column In Result.Columns Do
		TableOfAmounts.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	TableOfAmounts.Columns.AmountIncludingVAT.Name = "Sum";
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
	RowsToProcess = New Array;
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NewRow = TableOfAmounts.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.DocumentAmount = Selection.DocumentAmount * Selection.ConversionFactor_;
		NewRow.VATRate = Selection.VATRate;
		NewRow.Sum = Selection.AmountIncludingVAT * Selection.ConversionFactor_;
		
		If Selection.Currency <> DocumentCurrency Then
			RowsToProcess.Add(NewRow);
		Else
			NewRow.VATAmount = Selection.VATAmount * Selection.ConversionFactor_;
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess, StructureOfActions, TableOfAmounts);
	
	TableOfAmounts.Columns.Sum.Name = "AmountIncludingVAT";
	
	Return TableOfAmounts;
	
EndFunction


// Fills in VAT rates and amounts in the payment transcript
//
// Parameters:
//    ARAPDetails - TabularSection, ValueTable - Table part "payment description" or table of values with corresponding columns
//    VATTable - ValueTable - Table with values of VAT rates and amounts.
//
Procedure FillInNDSInDecryption(ARAPDetails, VATTable) Export
	
	If TypeOf(ARAPDetails) = Type("ValueTable") Then
		Payments_2 = ARAPDetails.Copy();
	Else
		Payments_2 = ARAPDetails.Unload();
	EndIf;
	
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	Payments_2.Columns.Add("IndLines", New TypeDescription(TypesArray));
	Indus = 0;
	For Each TableRow In Payments_2 Do
		TableRow.IndLines = Indus;
		Indus = Indus + 1;
	EndDo;
	
	If Payments_2.Columns.Find("VATRate") = Undefined Then
		Payments_2.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
	EndIf;
	If Payments_2.Columns.Find("VATAmount") = Undefined Then
		Payments_2.Columns.Add("VATAmount", New TypeDescription("Number"));
	EndIf;
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	Payments_2.ARAPObject AS ARAPObject
	|INTO Payments_2
	|FROM
	|	&Payments_2 AS Payments_2
	|;
	|
	|SELECT
	|	VATTable.Ref AS Ref
	|INTO VATTable
	|FROM
	|	&VATTable AS VATTable
	|
	|INDEX BY
	|	Ref
	|";
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(Query.Text);
	
	PaymentsOperator = QuerySchema.QueryBatch[0].Operators[0]; // QuerySchemaSelectOperator
	For Each Column In Payments_2.Columns Do
		PaymentsOperator.SelectedFields.Add("Payments_2." + Column.Name);
	EndDo;
	
	VATTableOperator = QuerySchema.QueryBatch[1].Operators[0]; // QuerySchemaSelectOperator
	For Each Column In VATTable.Columns Do
		VATTableOperator.SelectedFields.Add("VATTable." + Column.Name);
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	Query.SetParameter("Payments_2", Payments_2);
	Query.SetParameter("VATTable", VATTable);
	Query.Execute();
	
	Query.Text = "
	|SELECT DISTINCT
	|	ARAPObjects.Ref AS Ref,
	|	ARAPObjects.Object AS Object
	|INTO ARAPObjects
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|	INNER JOIN
	|		Payments_2 AS Payments_2
	|	ON
	|		Payments_2.ARAPObject = ARAPObjects.Ref
	|;
	|
	|SELECT
	|	ISNULL(VATTable.VATRate, Payments_2.VATRate) AS VATRate,
	|	ISNULL(VATTable.VATAmount, Payments_2.VATAmount) AS VATAmount,
	|	NOT VATTable.Ref IS NULL AS RecalculateVAT,
	|	*
	|FROM
	|	Payments_2 AS Payments_2
	|	LEFT JOIN
	|		ARAPObjects AS ARAPObjects
	|	ON
	|		ARAPObjects.Ref = Payments_2.ARAPObject
	|	
	|	LEFT JOIN
	|		VATTable AS VATTable
	|	ON
	|		ARAPObjects.Object = VATTable.Ref
	|			OR &PaymentBasisCondition
	|		AND (Payments_2.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|			OR Payments_2.VATRate = UNDEFINED
	|			OR Payments_2.VATRate IS NULL)
	|ORDER BY
	|	Payments_2.IndLines
	|";
	
	If Payments_2.Columns.Find("PaymentPurpose") <> Undefined Then
		Query.Text = StrReplace(Query.Text, "&PaymentBasisCondition", "
		|((Payments_2.PaymentPurpose.DocumentBasis = VATTable.Ref
		|OR Payments_2.PaymentPurpose = VATTable.Ref)
		|AND ARAPObjects.Object NOT IN(&References))");
	Else
		Query.Text = StrReplace(Query.Text, "&PaymentBasisCondition", "FALSE");
	EndIf;
	Query.SetParameter("References", VATTable.UnloadColumn("Ref"));
	
	SetPrivilegedMode(True);
	Payments_2 = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	CalculateAmountOfSettlements_1 = (Payments_2.Columns.Find("AmountARAP") <> Undefined);
	ItIsOurDuty = (Payments_2.Columns.Find("AccountsPayableOfCompany") <> Undefined);
	CalculatePartnerDebt = (Payments_2.Columns.Find("PartnerDebt_") <> Undefined);
	
	TotalDebited_ = 0;
	TotalSettlementsWrittenOff = 0;
	WrittenOffAllOurDebt = 0;
	TotalPartnerDebtWrittenOff = 0;
	
	LinesToDelete = New Array;
	
	For Each Payment_ In Payments_2 Do
		
		If Not Payment_.RecalculateVAT Or Not ValueIsFilled(Payment_.VATRate) Then
			Continue;
		EndIf;
		
		If TypeOf(Payment_["Object"]) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(Payment_["Object"]) = Type("CatalogRef.IntercompanyContracts") Then
			
			Payment_.VATAmount = Payment_.Sum * Payment_.VATRate.Rate1 / (100 + Payment_.VATRate.Rate1);
		Else
			
			If Payments_2.IndexOf(Payment_) = 0 Then
				NewOrder = True;
			Else
				NewOrder = (Payment_.IndLines <> Payments_2[Payments_2.IndexOf(Payment_) - 1].IndLines);
			EndIf;
			
			If NewOrder Then
				TotalDebited_ = 0;
				TotalSettlementsWrittenOff = 0;
				WrittenOffAllOurDebt = 0;
				TotalPartnerDebtWrittenOff = 0;
			EndIf;
			
			Payment_.VATAmount = Payment_.VATAmount * ?(Payment_.DocumentAmount <> 0, Payment_.Sum / Payment_.DocumentAmount, 0);
			
			LastOrderLine = (Payments_2.IndexOf(Payment_) = Payments_2.Count() - 1)
				Or (Payment_.IndLines <> Payments_2[Payments_2.IndexOf(Payment_) + 1].IndLines);
			
			Payment_.Sum = Round(ARAPAccountingServer.DeductAmount(
				Payment_.Sum - TotalDebited_,
				Payment_.Sum * ?(Payment_.DocumentAmount <> 0, Payment_.AmountIncludingVAT / Payment_.DocumentAmount, 0),
				LastOrderLine), 2);
				
			If Payment_.Sum = 0 Then
				LinesToDelete.Add(Payment_);
				Continue;
			EndIf;
			
			TotalDebited_ = TotalDebited_ + Payment_.Sum;
			
			If CalculateAmountOfSettlements_1 Then
				Payment_.AmountARAP = Round(ARAPAccountingServer.DeductAmount(
					Payment_.AmountARAP - TotalSettlementsWrittenOff,
					Payment_.AmountARAP * ?(Payment_.DocumentAmount <> 0, Payment_.AmountIncludingVAT / Payment_.DocumentAmount, 0),
					LastOrderLine), 2);
					
				TotalSettlementsWrittenOff = TotalSettlementsWrittenOff + Payment_.AmountARAP;
			EndIf;
			If ItIsOurDuty Then
				Payment_.AccountsPayableOfCompany = Round(ARAPAccountingServer.DeductAmount(
					Payment_.AccountsPayableOfCompany - WrittenOffAllOurDebt,
					Payment_.AccountsPayableOfCompany * ?(Payment_.DocumentAmount <> 0, Payment_.AmountIncludingVAT / Payment_.DocumentAmount, 0),
					LastOrderLine), 2);
					
				WrittenOffAllOurDebt = WrittenOffAllOurDebt + Payment_.AccountsPayableOfCompany;
			EndIf;
			If CalculatePartnerDebt Then
				Payment_.PartnerDebt_ = Round(ARAPAccountingServer.DeductAmount(
					Payment_.PartnerDebt_ - TotalPartnerDebtWrittenOff,
					Payment_.PartnerDebt_ * ?(Payment_.DocumentAmount <> 0, Payment_.AmountIncludingVAT / Payment_.DocumentAmount, 0),
					LastOrderLine), 2);
					
				TotalPartnerDebtWrittenOff = TotalPartnerDebtWrittenOff + Payment_.PartnerDebt_;
			EndIf;
			
		EndIf;
	EndDo;
	
	If Payments_2.Count() > 1 Then
		For Each RowToDelete In LinesToDelete Do
			Payments_2.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Payments_2.Columns.Find("Sum") <> Undefined
		And Payments_2.Columns.Find("AmountARAP") <> Undefined
		And Payments_2.Total("Sum") <> Payments_2.Total("AmountARAP") Then
		
		StructureOfRecalculationOfAmount = New Structure;
		StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartServer.TreatTS(Payments_2, StructureOfActions, Undefined);
	EndIf;
	
	If TypeOf(ARAPDetails) = Type("ValueTable") Then
		ARAPDetails = Payments_2.Copy();
	Else
		ARAPDetails.Load(Payments_2);
	EndIf;
	
EndProcedure

// The procedure generates the payment destination text for the payment document
//
// Parameters:
//    Object - DocumentObject - Payment document.
//
Procedure FillInPaymentDestinationText(Object) Export
	
	TextAssignment = "";
	
	If ValueIsFilled(Object.CounterpartyBankAccount) Then
		TextAssignment = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(
			Object.CounterpartyBankAccount).PurposeText;
	EndIf;
	
	If TextAssignment = "" Then
			TextAssignment = PaymentPurposes(Object);
	Else
		
		IncludeVATText = True;
		
		
		If IncludeVATText Then 
			
			TextAmount = "Sum " + Format(Object.DocumentAmount, "NFD=2; NDS=-; NZ=0-00; NG=");
			TextVATAmount = TextAmountOfVATPayment(Object.Organization, Object.Currency, Object.ARAPDetails, True);
			TextAssignment = TextAssignment + Chars.LF + TextAmount + Chars.LF + TextVATAmount;
			
		EndIf;
		
	EndIf;
	
	Object.PaymentPurposes = TextAssignment;
	
EndProcedure

// Gets the VAT rate for the settlement object, if it is the only one
//
// Parameters:
//    Organization - CatalogRef.Companies - Organization of the payment document
//    ARAPObjects - Array, CatalogRef.ARAPObjects - Calculation objects
//    TheseAreSettlementsWithCustomers - Boolean - Indicates whether payments are made to clients.
// Returns:
//  - CatalogRef.VATRates
//  - Undefined
//
Function VATRateOfSettlementObject(Organization, ARAPObjects, TheseAreSettlementsWithCustomers = True) Export
	
	VATTable = TranscriptOfVATPayment(Organization, Undefined, Undefined, ARAPObjects, TheseAreSettlementsWithCustomers);
	If VATTable.Count() = 1 Then
		Return VATTable[0].VATRate;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Gets the DDS article for the calculation object
//
// Parameters:
//    ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
//    BusinessOperation - EnumRef.BusinessTransactions - the operation for the selection of articles of DDS by default.
//
// Returns:
//  - Undefined
//  - CatalogRef.CashFlowReportItems
//
Function ArticleOfCashFlowOfSettlementObject(ARAPObject, BusinessOperation) Export
	
	CashFlowItem = Undefined;
	
	SelectedFields = New Array;
	Object = Common.ObjectAttributeValue(ARAPObject, "Object");
	
	If ValueIsFilled(Object) Then
	
		AvailableAttributes = Object.Metadata().Attributes;
		If AvailableAttributes.Find("Terms") <> Undefined Then
			SelectedFields.Add("Terms.CashFlowItem");
		EndIf;
		If BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
			If AvailableAttributes.Find("Contract") <> Undefined Then
				SelectedFields.Add("Contract.CashFlowItemOfRecipient");
			EndIf;
			If AvailableAttributes.Find("CashFlowItemOfRecipient") <> Undefined Then
				SelectedFields.Add("CashFlowItemOfRecipient");
			EndIf;
		Else
			If AvailableAttributes.Find("Contract") <> Undefined Then
				SelectedFields.Add("Contract.CashFlowItem");
			EndIf;
			If AvailableAttributes.Find("CashFlowItem") <> Undefined Then
				SelectedFields.Add("CashFlowItem");
			EndIf;
		EndIf;
		
		If SelectedFields.Count() Then
			SetPrivilegedMode(True);
			AttributesValues = Common.ObjectAttributesValues(Object, SelectedFields);
			SetPrivilegedMode(False);
			If AttributesValues.Property("CashFlowAgreement")
				And ValueIsFilled(AttributesValues.CashFlowAgreement) Then
				CashFlowItem = AttributesValues.CashFlowAgreement;
			EndIf;
			If AttributesValues.Property("CashFlowContract")
				And ValueIsFilled(AttributesValues.CashFlowContract) Then
				CashFlowItem = AttributesValues.CashFlowContract;
			EndIf;
			If AttributesValues.Property("ContractCashFlowItemOfRecipient")
				And ValueIsFilled(AttributesValues.ContractCashFlowItemOfRecipient) Then
				CashFlowItem = AttributesValues.ContractCashFlowItemOfRecipient;
			EndIf;
			If AttributesValues.Property("CashFlowItem")
				And ValueIsFilled(AttributesValues.CashFlowItem) Then
				CashFlowItem = AttributesValues.CashFlowItem;
			EndIf;
			If AttributesValues.Property("CashFlowItemOfRecipient")
				And ValueIsFilled(AttributesValues.CashFlowItemOfRecipient) Then
				CashFlowItem = AttributesValues.CashFlowItemOfRecipient;
			EndIf;
		EndIf;
	EndIf;
	
	If ValueIsFilled(CashFlowItem)
		And ValueIsFilled(BusinessOperation)
		And Not Catalogs.CashFlowReportItems.ArticleCorrespondsToEconomicOperation(
			CashFlowItem, BusinessOperation) Then
		CashFlowItem = Undefined;
	EndIf;
	
	If Not ValueIsFilled(CashFlowItem) And ValueIsFilled(BusinessOperation) Then
		CashFlowItem =
			Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(BusinessOperation);
	EndIf;
	
	Return CashFlowItem;
	
EndFunction

// Returns a string listing documents from the payment transcript.
//
// Parameters: Document object - A document containing the payment transcript.
//
// Returns:
//  String
//
Function PaymentPurposes(Object)
	
	SetPrivilegedMode(True);
	
	ARAPDetails = Object.ARAPDetails.Unload(, "ARAPObject, Sum, VATRate, VATAmount");
	DocumentsTable = New ValueTable;
	DocumentsTable.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	DocumentsTable.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
	For Cnt = 1 To ARAPDetails.Count() Do
		DocumentsTable.Add();
	EndDo;
	DocumentsTable.LoadColumn(ARAPDetails.UnloadColumn("ARAPObject"), "ARAPObject");
	DocumentsTable.LoadColumn(ARAPDetails.UnloadColumn("Sum"), "Sum");
	
	Query = New Query("
	|SELECT
	|	SourceTable.ARAPObject                AS ARAPObject,
	|	SourceTable.Sum                         AS Sum
	|
	|INTO SourceTable
	|FROM
	|	&DocumentsTable AS SourceTable
	|
	|INDEX BY
	|	ARAPObject
	|;
	|SELECT
	|	SourceTable.ARAPObject.Object         AS Document,
	|	SourceTable.Sum                         AS Sum
	|
	|INTO DocumentsTable
	|FROM
	|	SourceTable AS SourceTable
	|
	|INDEX BY
	|	Document
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Document.SalesOrder AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.VendorReferenceNumber       AS Number,
	|	DocumentData.VendorReferenceDate        AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	TRUE                                        AS IncomingDocumentNumber
	|FROM
	|	Document.PurchaseOrder AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.IncomingDocumentNumber       AS Number,
	|	DocumentData.IncomingDocumentDate        AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	TRUE                                        AS IncomingDocumentNumber
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref               AS Document,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Number                AS Number,
	|	DocumentData.Date                 AS Date,
	|	SUM(DocumentsTable.Sum)       AS Sum,
	|	FALSE                                 AS IncomingDocumentNumber
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.IncomingDocumentNumber       AS Number,
	|	DocumentData.IncomingDocumentDate        AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	TRUE                                        AS IncomingDocumentNumber
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.IncomingDocumentNumber       AS Number,
	|	DocumentData.IncomingDocumentDate        AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	TRUE                                        AS IncomingDocumentNumber
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|	UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	FALSE                                          AS IncomingDocumentNumber
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                        AS Document,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.IncomingDocumentNumber       AS Number,
	|	DocumentData.IncomingDocumentDate        AS Date,
	|	SUM(DocumentsTable.Sum)                AS Sum,
	|	TRUE                                        AS IncomingDocumentNumber
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON DocumentsTable.Document = DocumentData.Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Number,
	|	DocumentData.Date
	|	
	|");
	
	Query.SetParameter("DocumentsTable", DocumentsTable);
	Selection = Query.Execute().Select();
	AmountForAllocation = Object.ARAPDetails.Total("Sum");
	PurposeOfPaymentText = "";
	PresentationsOfDocuments = GetDocumentPresentations();
	
	CurrencyDetails = Common.ObjectAttributesValues(Object.Currency, "Code, Description");
	If CurrencyDetails.Code = "643" Then
		CurrencyToPrint = NStr("vi = 'đồng';
								|ru = 'руб.';
								|en = 'rub.'; fa = 'rub.';
								|it = 'rub.';
								|pl = 'zł';
								|tr = 'rub.'");
	Else
		CurrencyToPrint = TrimAll(CurrencyDetails.Description);
	EndIf;
	
	While Selection.Next() Do
		If TypeOf(Selection.Document) = Type("CatalogRef.CounterpartyContracts") Then
			PurposeOfPaymentText = PurposeOfPaymentText + ", "
			+ Common.ObjectAttributeValue(Selection.Document, "NameForPrinting")
			+ " " + Format(Selection.Sum, "NFD=2; NDS=-; NZ=0-00; NG=")
			+ " " + CurrencyToPrint;
		Else
			DocumentKind = "";
			SampleDocument = Selection.Document; // DocumentRef
			PresentationsOfDocuments.Property(SampleDocument.Metadata().Name, DocumentKind);
			If ValueIsFilled(DocumentKind) Then
				PresentationForPrinting = NStr("vi = '%Kind% №%Number% от %Date% %Sum% %Currency%';
												|ru = '%Kind% №%Number% от %Date% %Sum% %Currency%';
												|en = '%Kind% #%Number% dated %Date% %Sum% %Currency%'; fa = '%Kind% #%Number% dated %Date% %Sum% %Currency%';
												|it = '%Kind% №%Number% от %Date% %Sum% %Currency%';
												|pl = '%Kind% nr%Number% z dn. %Date% %Sum% %Currency%';
												|tr = '%Kind% №%Number% %Date% tarihli %Sum% %Currency%'");
				PresentationForPrinting = StrReplace(PresentationForPrinting, "%Kind%", DocumentKind);
				If Selection.IncomingDocumentNumber Then
					PresentationForPrinting = StrReplace(PresentationForPrinting, "%Number%", TrimAll(Selection.Number));
				Else
					PresentationForPrinting = StrReplace(PresentationForPrinting, "%Number%",
						ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number, False, True));
				EndIf;
				PresentationForPrinting = StrReplace(PresentationForPrinting, "%Date%", Format(Selection.Date, "DLF=D"));
				PresentationForPrinting = StrReplace(PresentationForPrinting, "%Sum%",
					Format(Selection.Sum, "NFD=2; NDS=-; NZ=0-00; NG="));
				PresentationForPrinting = StrReplace(PresentationForPrinting, "%Currency%", CurrencyToPrint);
				PurposeOfPaymentText = PurposeOfPaymentText + ", " + PresentationForPrinting;
			EndIf;
		EndIf;
		AmountForAllocation = AmountForAllocation - Selection.Sum;
	EndDo;
	
	If AmountForAllocation > 0 Then
		PurposeOfPaymentText = PurposeOfPaymentText + ", "
			+ NStr("vi = 'không chỉ ra mục tiêu';
					|ru = 'без указания назначения';
					|en = 'without purpose specification'; fa = 'without purpose specification';
					|it = 'Senza indicazione di assegnazione';
					|pl = 'bez wskazania przeznaczenia';
					|tr = 'atama belirtmeden'")
			+ " " + Format(AmountForAllocation, "NFD=2; NDS=-; NZ=0-00; NG=")
			+ " " + CurrencyToPrint;
	EndIf;
	If AmountForAllocation <= 0 Then
		PurposeOfPaymentText = NStr("vi = 'Thanh toán theo';
									|ru = 'Оплата по';
									|en = 'Payment by'; fa = 'Payment by';
									|it = 'Pagamento per';
									|pl = 'Płatność na podstawie';
									|tr = 'Ödeme'") + Mid(PurposeOfPaymentText, 2);
	Else
		PurposeOfPaymentText = NStr("vi = 'Thanh toán';
									|ru = 'Оплата';
									|en = 'Payment'; fa = 'پرداخت';
									|it = 'Pagamento';
									|pl = 'Płatność';
									|tr = 'Ödeme'") + Mid(PurposeOfPaymentText, 2);
	EndIf;
	
	IncludeVATText = True;
	
	
	If Right(PurposeOfPaymentText, 1) <> "." Then
		PurposeOfPaymentText = PurposeOfPaymentText + ".";
	EndIf;
	DocumentTextLength = StrLen(PurposeOfPaymentText);
	
	If IncludeVATText Then
		
		TextVATAmount = TextAmountOfVATPayment(
			Object.Organization,
			Object.Currency,
			ARAPDetails,
			True);
		VATTextLength = StrLen(TextVATAmount);
		
	Else
		TextVATAmount = "";
		VATTextLength = 0;
	EndIf;
	
	If DocumentTextLength + VATTextLength > 210 Then
		DocumentTextLength = 207 - VATTextLength;
		PurposeOfPaymentText = Left(PurposeOfPaymentText, DocumentTextLength);
		SearchTextOfLastDocument = PurposeOfPaymentText;
		PositionOfLastComma = 0;
		CommaPosition = StrFind(SearchTextOfLastDocument, ",");
		While Not CommaPosition = 0 Do
			PositionOfLastComma = PositionOfLastComma + CommaPosition;
			SearchTextOfLastDocument = Mid(SearchTextOfLastDocument, CommaPosition + 1);
			CommaPosition = StrFind(SearchTextOfLastDocument, ",");
		EndDo;
		PurposeOfPaymentText = Left(PurposeOfPaymentText, PositionOfLastComma - 1) + "...";
	EndIf;
	PurposeOfPaymentText = TrimAll(PurposeOfPaymentText) + Chars.LF + TrimAll(TextVATAmount);
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return PurposeOfPaymentText;
	
EndFunction

Procedure RecordDatePaymentsWereUploaded(Payments_2, Block = True, Overwrite_ = True) Export
	
	For Each Payment_ In Payments_2 Do
		
		If Not (TypeOf(Payment_) = Type("DocumentRef.BankAccountIssue")
			Or TypeOf(Payment_) = Type("DocumentRef.BankAccountReceiptNote")) Then
			Continue;
		EndIf;
		
		DocumentUploadDate = Common.ObjectAttributeValue(Payment_, "ExportDate");
		
		If Not Overwrite_ And ValueIsFilled(DocumentUploadDate) Then
			Continue;
		EndIf;
		
		CurrentSessionDate = BegOfDay(CurrentSessionDate());
		
		If DocumentUploadDate = CurrentSessionDate Then
			Continue;
		EndIf;
		
		DocumentObject = Payment_.GetObject();
		
		If Block Then
			Try
				DocumentObject.Lock();
			Except
				MessageText = StrTemplate(NStr("vi = 'Không thể ghi ngày tải lên chứng từ ngân hàng:  %1';
												|ru = 'Не удалось записать дату выгрузки в банк документа: %1';
												|en = 'Cannot save date exported to document bank: %1'; fa = 'Cannot save date exported to document bank: %1';
												|it = 'Non è stato possibile registrare la data di upload del documento in banca: %1';
												|pl = 'Nie udało się zapisać datę przesyłania do banku dokumentu: %1';
												|tr = '%1 belgesinin yüklenme tarihi bankaya kaydedilmedi'"), DocumentObject);
				CommonClientServer.MessageToUser(MessageText);
				Continue;
			EndTry;
		EndIf;
		
		DocumentObject.ExportDate = CurrentSessionDate;
		DocumentObject.Write();
	EndDo;
	
EndProcedure

// Performs revaluation of funds from the accountable person
//
// Parameters:
//  Organization - CatalogRef.Companies - The organization in which it is necessary to reassess the cash
//  Date - Date - for which you need to perform a revaluation
//  AdvanceHolder - CatalogRef.Persons - accountable person.
//
Procedure RevaluateFundsHeldByAccountablePersons(Organization, Date, AdvanceHolder) Export
	
	SetPrivilegedMode(True);
	Documents.ExchangeDifferenceCalculation.RevaluateFundsHeldByAccountablePersons(Organization, Date, AdvanceHolder);
	
EndProcedure

Function InitializeConversionParameters() Export
	
	ConversionParameters_SSLy = New Structure;
	ConversionParameters_SSLy.Insert("Organization");
	ConversionParameters_SSLy.Insert("Currency");
	ConversionParameters_SSLy.Insert("CurrencyOfConversion");
	ConversionParameters_SSLy.Insert("CurrencyOfComplianceAccounting");
	ConversionParameters_SSLy.Insert("DocumentAmount");
	ConversionParameters_SSLy.Insert("ConversionAmount");
	ConversionParameters_SSLy.Insert("ConversionRate");
	ConversionParameters_SSLy.Insert("ConversionRateMultiplier");
	ConversionParameters_SSLy.Insert("Date");
	
	Return ConversionParameters_SSLy;
	
EndFunction

Procedure CalculateConversionParameters(ConversionParameters_SSLy, AttributeUpdate) Export
	
	If AttributeUpdate = "CurrencyOfConversion" Then
	
		If ConversionParameters_SSLy.Currency = ConversionParameters_SSLy.CurrencyOfComplianceAccounting Then
			
			CurrencyConversionRate_1 = ProcessingOfExchangeRatesTM.GetCurrencyRate(ConversionParameters_SSLy.CurrencyOfConversion,
					ConversionParameters_SSLy.Date, SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ConversionParameters_SSLy.Organization));
			ConversionParameters_SSLy.ConversionRate = CurrencyConversionRate_1.CourseNumerator;
			ConversionParameters_SSLy.ConversionRateMultiplier = CurrencyConversionRate_1.CourseDenominator;
			If Not ValueIsFilled(ConversionParameters_SSLy.DocumentAmount) And ValueIsFilled(ConversionParameters_SSLy.ConversionAmount) Then
				ConversionParameters_SSLy.DocumentAmount = ?(ConversionParameters_SSLy.ConversionRate <> 0,
					ConversionParameters_SSLy.ConversionAmount * ConversionParameters_SSLy.ConversionRate / ConversionParameters_SSLy.ConversionRateMultiplier, 0);
			Else
				ConversionParameters_SSLy.ConversionAmount = ?(ConversionParameters_SSLy.ConversionRateMultiplier <> 0,
					ConversionParameters_SSLy.DocumentAmount * ConversionParameters_SSLy.ConversionRateMultiplier / ConversionParameters_SSLy.ConversionRate, 0);
			EndIf;
		Else
			If ConversionParameters_SSLy.CurrencyOfConversion = ConversionParameters_SSLy.CurrencyOfComplianceAccounting Then
				CurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ConversionParameters_SSLy.Currency, ConversionParameters_SSLy.Date,
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ConversionParameters_SSLy.Organization));
				ConversionParameters_SSLy.ConversionRate = CurrencyExchangeRate.CourseNumerator;
				ConversionParameters_SSLy.ConversionRateMultiplier = CurrencyExchangeRate.CourseDenominator;
			Else
				If ValueIsFilled(ConversionParameters_SSLy.Currency) And ValueIsFilled(ConversionParameters_SSLy.CurrencyOfConversion) Then
					CrossCourse = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(
						ProcessingOfExchangeRatesTM.GetCurrencyRate(ConversionParameters_SSLy.Currency, ConversionParameters_SSLy.Date,
							SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ConversionParameters_SSLy.Organization)),
						ProcessingOfExchangeRatesTM.GetCurrencyRate(ConversionParameters_SSLy.CurrencyOfConversion, ConversionParameters_SSLy.Date,
							SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ConversionParameters_SSLy.Organization)));
				Else
					CrossCourse = New Structure("CourseNumerator, CourseDenominator", 0, 0);
				EndIf;
				
				ConversionParameters_SSLy.ConversionRate = CrossCourse.CourseNumerator;
				ConversionParameters_SSLy.ConversionRateMultiplier = CrossCourse.CourseDenominator;
			EndIf;
			
			If Not ValueIsFilled(ConversionParameters_SSLy.DocumentAmount) And ValueIsFilled(ConversionParameters_SSLy.ConversionAmount) Then
				ConversionParameters_SSLy.DocumentAmount = ?(ConversionParameters_SSLy.ConversionRate <> 0,
					ConversionParameters_SSLy.ConversionAmount * ConversionParameters_SSLy.ConversionRateMultiplier / ConversionParameters_SSLy.ConversionRate, 0);
			Else
				ConversionParameters_SSLy.ConversionAmount = ?(ConversionParameters_SSLy.ConversionRateMultiplier <> 0,
					ConversionParameters_SSLy.DocumentAmount * ConversionParameters_SSLy.ConversionRate / ConversionParameters_SSLy.ConversionRateMultiplier, 0);
			EndIf;
		EndIf;
		
	ElsIf AttributeUpdate = "ConversionRate" Then
		
		If ConversionParameters_SSLy.Currency = ConversionParameters_SSLy.CurrencyOfComplianceAccounting Then
			If ConversionParameters_SSLy.ConversionRate <> 0 Then
				ConversionParameters_SSLy.ConversionAmount =
					ConversionParameters_SSLy.DocumentAmount * ConversionParameters_SSLy.ConversionRateMultiplier / ConversionParameters_SSLy.ConversionRate;
			Else
				ConversionParameters_SSLy.ConversionAmount = 0;
			EndIf;
		Else
			If ConversionParameters_SSLy.ConversionRateMultiplier <> 0 Then
				ConversionParameters_SSLy.ConversionAmount =
					ConversionParameters_SSLy.DocumentAmount * ConversionParameters_SSLy.ConversionRate / ConversionParameters_SSLy.ConversionRateMultiplier;
			Else
				ConversionParameters_SSLy.ConversionAmount = 0;
			EndIf;
		EndIf;
		
	ElsIf AttributeUpdate = "ConversionAmount" Then
		
		If ConversionParameters_SSLy.DocumentAmount = 0 Then
			
			If ConversionParameters_SSLy.Currency = ConversionParameters_SSLy.CurrencyOfComplianceAccounting Then
				If ConversionParameters_SSLy.ConversionRateMultiplier <> 0 Then
					ConversionParameters_SSLy.DocumentAmount =
						ConversionParameters_SSLy.ConversionAmount * ConversionParameters_SSLy.ConversionRate / ConversionParameters_SSLy.ConversionRateMultiplier;
				EndIf;
			Else
				If ConversionParameters_SSLy.ConversionRate <> 0 Then
					ConversionParameters_SSLy.DocumentAmount =
						ConversionParameters_SSLy.ConversionAmount * ConversionParameters_SSLy.ConversionRateMultiplier / ConversionParameters_SSLy.ConversionRate;
				EndIf;
			EndIf;
		Else
			If ConversionParameters_SSLy.Currency = ConversionParameters_SSLy.CurrencyOfComplianceAccounting Then
				If ConversionParameters_SSLy.ConversionAmount <> 0 Then
					ConversionParameters_SSLy.ConversionRate =
						ConversionParameters_SSLy.DocumentAmount * ConversionParameters_SSLy.ConversionRateMultiplier / ConversionParameters_SSLy.ConversionAmount;
				Else
					ConversionParameters_SSLy.ConversionRate = 0;
				EndIf;
			Else
				If ConversionParameters_SSLy.DocumentAmount <> 0 Then
					ConversionParameters_SSLy.ConversionRate =
						ConversionParameters_SSLy.ConversionAmount * ConversionParameters_SSLy.ConversionRateMultiplier / ConversionParameters_SSLy.DocumentAmount;
				Else
					ConversionParameters_SSLy.ConversionRate = 0;
				EndIf;
			EndIf;
		EndIf;
	
	ElsIf AttributeUpdate = "ConversionRateMultiplier" Then
		
		If ConversionParameters_SSLy.ConversionRateMultiplier <> 0 Then
			
			ConversionParameters_SSLy.ConversionRate = 0;
			ConversionParameters_SSLy.ConversionAmount = 0;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the heading of the exchange rate currency and multiplicity currency on the document form.
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//  ConversionParameters_SSLy - See InitializeConversionParameters.
//
Procedure CurrencyHeadingExchangeRateAndConversionMultiplicity(Form, ConversionParameters_SSLy) Export
	
	Items = Form.Items;
	
	If ConversionParameters_SSLy.Currency = Form.CurrencyOfComplianceAccounting Then
		Items.CurrencyOfConversionRate.Title = ConversionParameters_SSLy.Currency;
		Items.CurrencyOfConversionRateMultiplicity.Title = ConversionParameters_SSLy.CurrencyOfConversion;
	ElsIf ConversionParameters_SSLy.CurrencyOfConversion = Form.CurrencyOfComplianceAccounting Then
		Items.CurrencyOfConversionRate.Title = ConversionParameters_SSLy.CurrencyOfConversion;
		Items.CurrencyOfConversionRateMultiplicity.Title = ConversionParameters_SSLy.Currency;
	Else
		Items.CurrencyOfConversionRate.Title = ConversionParameters_SSLy.CurrencyOfConversion;
		Items.CurrencyOfConversionRateMultiplicity.Title = ConversionParameters_SSLy.Currency;
	EndIf;
	
EndProcedure

Procedure FillInCurrencyOfMutualSettlementsOfDocument(Form) Export
	
	Object = Form.Object;
	
	CopyOfDecryption = Object.ARAPDetails.Unload(, "ARAPCurrency, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements");
	CopyOfDecryption.GroupBy("ARAPCurrency, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements");
	Form.MultipleARAPCurrency = False;
	If CopyOfDecryption.Count() = 1 Then
		Form.ARAPCurrency     = CopyOfDecryption[0].ARAPCurrency;
		Form.AmountARAP      = Object.ARAPDetails.Total("AmountARAP");
		Form.ExchangeRateNumeratorOfMutualSettlements       = CopyOfDecryption[0].ExchangeRateNumeratorOfMutualSettlements;
		Form.TheExchangeRateIsTheDenominatorOfMutualSettlements  = CopyOfDecryption[0].TheExchangeRateIsTheDenominatorOfMutualSettlements;
	Else
		CopyOfSettlementCurrencyDecryption = Object.ARAPDetails.Unload(, "ARAPCurrency");
		CopyOfSettlementCurrencyDecryption.GroupBy("ARAPCurrency");
		If CopyOfSettlementCurrencyDecryption.Count() = 1 Then
			Form.ARAPCurrency     = CopyOfDecryption[0].ARAPCurrency;
			Form.AmountARAP      = Object.ARAPDetails.Total("AmountARAP");
			Form.ExchangeRateNumeratorOfMutualSettlements       = Undefined;
			Form.TheExchangeRateIsTheDenominatorOfMutualSettlements  = Undefined;
		Else
			Form.ARAPCurrency     = Undefined;
			Form.AmountARAP      = Undefined;
			Form.ExchangeRateNumeratorOfMutualSettlements       = Undefined;
			Form.TheExchangeRateIsTheDenominatorOfMutualSettlements  = Undefined;
			
			LineWithEmptyCurrency = CopyOfSettlementCurrencyDecryption.Find(Catalogs.Currencies.EmptyRef(), "ARAPCurrency");
			
			If LineWithEmptyCurrency <> Undefined Then
				CopyOfSettlementCurrencyDecryption.Delete(LineWithEmptyCurrency);
			EndIf;
			
			If CopyOfSettlementCurrencyDecryption.Count() = 1 Then
				Form.ARAPCurrency = CopyOfSettlementCurrencyDecryption[0].ARAPCurrency;
			EndIf;
			
			Form.MultipleARAPCurrency = CopyOfSettlementCurrencyDecryption.Count() > 1;
		EndIf;
	EndIf;
	ContractRateOptions = Object.ARAPDetails.Unload(,"ContractRateOption, ARAPObjectType");
	ContractRateOptions.GroupBy("ContractRateOption, ARAPObjectType");
	If ContractRateOptions.Count() = 1 Then
		Form.ContractRateOption = ContractRateOptions[0].ContractRateOption;
		Form.ARAPObjectType = ContractRateOptions[0].ARAPObjectType;
	Else
		Form.ContractRateOption = Enums.ContractRateOptions.EmptyRef();
		Form.ARAPObjectType = Enums.ARAPObjectTypes.EmptyRef();
	EndIf;
	
EndProcedure

Function CurrencyLabelAndPaymentRate(Form) Export
	
	Object = Form.Object;
	
	CopyOfDecryption = Object.ARAPDetails.Unload(,
		"AmountARAP, ARAPCurrency, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements"); // ValueTable
	CopyOfDecryption.GroupBy("ARAPCurrency, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements", "AmountARAP");
	
	BasicFormatString = StrTemplate("NFD=%1", Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits);
	CourseTemplate = "(%1 %2 = %3 %4)";
	CaptionLines = New Array;
	For Each TableRow In CopyOfDecryption Do
		
		If CaptionLines.Count() = 3 Then
			CaptionLines.Add("...");
			Break;
		EndIf;
		
		If TableRow.ARAPCurrency <> Object.Currency Then
			If Object.Currency = Form.CurrencyOfComplianceAccounting Then
				FormatString = BasicFormatString;
				CourseLine = StrTemplate(CourseTemplate,
					TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
					TableRow.ARAPCurrency,
					String(Format(TableRow.ExchangeRateNumeratorOfMutualSettlements, FormatString)),
					Object.Currency);
			Else
				If TableRow.ARAPCurrency = Form.CurrencyOfComplianceAccounting Then
					FormatString = BasicFormatString;
				Else
					FormatString = "NFD=8";
				EndIf;
				CourseLine = StrTemplate(CourseTemplate,
					TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
					Object.Currency,
					String(Format(TableRow.ExchangeRateNumeratorOfMutualSettlements, FormatString)),
					TableRow.ARAPCurrency);
			EndIf;
			CaptionLines.Add(
				StrTemplate("%1 %2 %3",
					Format(TableRow.AmountARAP, "NFD=2"),
					TableRow.ARAPCurrency,
					CourseLine));
		Else
			CaptionLines.Add(
				StrTemplate("%1 %2",
					Format(TableRow.AmountARAP, "NFD=2"),
					TableRow.ARAPCurrency));
		EndIf;
		
		
	EndDo;
	
	Return StrTemplate("%1: %2", NStr("vi = 'Hạch toán';
										|ru = 'Расчеты';
										|en = 'AR/AP accounting'; fa = 'حسابداری دریافتنی/پرداختنی';
										|it = 'Regolamenti';
										|pl = 'AR/AP accounting';
										|tr = 'Mutabakatlar'"), StrConcat(CaptionLines, "; "));
	
EndFunction

Function CourseNumeratorAndCourseDenominatorOfMutualSettlements(DocumentCurrency, ARAPCurrency, CurrencyOfComplianceAccounting, OnDate, ARAPObject, Contract = Undefined) Export
	
	CourseAndMultiplicity = New Structure;
	CourseAndMultiplicity.Insert("CourseNumerator", 1);
	CourseAndMultiplicity.Insert("CourseDenominator", 1);
	CourseAndMultiplicity.Insert("ContractRateOption", Enums.ContractRateOptions.Mutable);
	CourseAndMultiplicity.Insert("ARAPObjectType", Enums.ARAPObjectTypes.EmptyRef());
	
	If DocumentCurrency <> ARAPCurrency Then 
		
		ContractRateOption = Enums.ContractRateOptions.EmptyRef();
		If ValueIsFilled(Contract) Then
			ContractRateOption = Common.ObjectAttributeValue(Contract, "ContractRateOption");
		EndIf;
		
		If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
			If DocumentCurrency = CurrencyOfComplianceAccounting Then
				CourseAndMultiplicity = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, OnDate);
			Else
				DocumentCourse = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, OnDate, CurrencyOfComplianceAccounting, ARAPObject);
				TransactionRate = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, OnDate);
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCourse, TransactionRate, 8);
			EndIf;
		Else
			If DocumentCurrency = CurrencyOfComplianceAccounting Then
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCurrencyRate(ARAPCurrency, OnDate, CurrencyOfComplianceAccounting,ARAPObject);
			ElsIf ARAPCurrency = CurrencyOfComplianceAccounting Then
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, OnDate, CurrencyOfComplianceAccounting, ARAPObject);
			Else
				DocumentCourse = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, OnDate, CurrencyOfComplianceAccounting, ARAPObject);
				TransactionRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ARAPCurrency, OnDate, CurrencyOfComplianceAccounting, ARAPObject);
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCourse, TransactionRate, 8);
			EndIf;
		EndIf;
		
		Query = New Query;
		Query.SetParameter("ARAPObject", ARAPObject);
		Query.Text = 
			"SELECT
			|	ARAPObjects.ARAPObjectType AS ARAPObjectType,
			|	ISNULL(
			|		ARAPObjects.Contract.ContractRateOption, 
			|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption
			|FROM
			|	Catalog.ARAPObjects AS ARAPObjects
			|WHERE
			|	ARAPObjects.Ref = &ARAPObject";
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		If Selection.Next() Then
			CourseAndMultiplicity.Insert("ContractRateOption", Selection.ContractRateOption);
			CourseAndMultiplicity.Insert("ARAPObjectType", Selection.ARAPObjectType);
		Else
			CourseAndMultiplicity.Insert("ContractRateOption", Enums.ContractRateOptions.Mutable);
			CourseAndMultiplicity.Insert("ARAPObjectType", Enums.ARAPObjectTypes.EmptyRef());
		EndIf; 
		
		If ValueIsFilled(ContractRateOption) Then
			CourseAndMultiplicity.ContractRateOption = ContractRateOption;
		EndIf;
		
	EndIf;
	
	Return CourseAndMultiplicity;
	
EndFunction

// Substitution of the organization prefix with the cash book prefix
//
// Parameters:
//    Source - DocumentObject - PKO, RKO, Cash book
//    StandardProcessing - Boolean - standard subscription processing flag
//    Prefix - String - the prefix of the object you want to modify.
//
Procedure SetInfobasePrefixAndCashBookPrefixToDocumentNumberOnSetNewNumber(Source, StandardProcessing, Prefix) Export
	
	ObjectsPrefixesEvents.SetInfobaseAndCompanyPrefix(Source, StandardProcessing, Prefix);
	
EndProcedure

// Returns a table of values containing the value of the Attributes (name and checkpoint) of the recipient (write-off)/payer
// (receipt) and organizations operating on the date of the document.
//
// Parameters:
//  DocumentsList - Array of DocumentRef - documents for which information about the name and checkpoint is determined.
//
// Returns:
//  See DataOfPayerSRecipient
//
Function InformationAboutRecipientPayerAccordingToDocuments(DocumentsList) Export

	If DocumentsList.Count() = 0 Then
		Return EmptyTableOfInformationAboutRecipientPayer();
	EndIf;
	
	RequestForTheseDocuments = New Query;
	RequestForTheseDocuments.Text =
		"SELECT ALLOWED
		|	DocumentsRegistry.Ref AS Ref,
		|	DocumentsRegistry.IBDocumentDate AS Date,
		|	DocumentsRegistry.Organization AS Organization,
		|	CASE
		|		WHEN DocumentsRegistry.Counterparty = VALUE(Catalog.DocumentRegistryKeys.EmptyRef)
		|		 THEN DocumentsRegistry.Organization
		|		ELSE DocumentRegistryKeys.Key
		|	END AS Counterparty

		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		LEFT JOIN Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
		|		ON DocumentsRegistry.Counterparty = DocumentRegistryKeys.Ref
		|WHERE
		|	DocumentsRegistry.Ref IN(&DocumentsArray)
		|";
	
	RequestForTheseDocuments.SetParameter("DocumentsArray", DocumentsList);
	Result = RequestForTheseDocuments.Execute();
	
	If Result.IsEmpty() Then
		
		DocumentsData = NewTableOfDocumentSidesByList(DocumentsList);
		
		For Each CurrentDocument In DocumentsList Do
			
			NewRow = DocumentsData.Add();
			FillPropertyValues(NewRow, CurrentDocument);
			
		EndDo;
	
	Else
		DocumentsData = Result.Unload();
	EndIf;
	
	Return DataOfPayerSRecipient(DocumentsData);

EndFunction

// Returns a structure with data about the payer and the recipient (TIN, KPP, names)
//
// Parameters:
//   Outgoing - Boolean - flag of outgoing payment
//   Filter - See ParametersForSearchingForDocumentSideData
//
// Returns:
//   Structure:
//     * TINOfPayer - String
//     * PayerCRTR - String
//     * FullNameOfPayer - String
//     * AbbreviatedNameOfPayer - String
//     * NameOfInternationalPayer - String
//     * RecipientTIN - String
//     * RecipientCRTR - String
//     * FullNameOfRecipient - String
//     * RecipientSAbbreviatedName - String
//     * NameOfInternationalRecipient - String
Function InformationAboutRecipientPayerByStructure(Outgoing, Filter) Export

	If Filter.Ref = Undefined Then
		Filter.Ref = Documents.BankAccountIssue.EmptyRef();
	EndIf;
	
	If Filter.Counterparty = Undefined Then
		Filter.Counterparty = Catalogs.Counterparties.EmptyRef();
	EndIf;
	
	DocumentsData = NewTableOfDocumentSidesByList(CommonClientServer.ValueInArray(Filter.Ref));
	
	NewRow = DocumentsData.Add();
	FillPropertyValues(NewRow, Filter);
	
	DataTable = DataOfPayerSRecipient(DocumentsData);
	
	DataOfParties = New Structure;
	DataOfParties.Insert("TINOfPayer", "");
	DataOfParties.Insert("PayerCRTR", "");
	DataOfParties.Insert("FullNameOfPayer", "");
	DataOfParties.Insert("AbbreviatedNameOfPayer", "");
	DataOfParties.Insert("NameOfInternationalPayer", "");
	
	DataOfParties.Insert("RecipientTIN", "");
	DataOfParties.Insert("RecipientCRTR", "");
	DataOfParties.Insert("FullNameOfRecipient", "");
	DataOfParties.Insert("RecipientSAbbreviatedName", "");
	DataOfParties.Insert("NameOfInternationalRecipient", "");
	
	For Each TableRow In DataTable Do
		
		If Outgoing Then
			
			If TableRow.Flag = 0 Then
				DataOfParties.FullNameOfRecipient = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 1 Then
				DataOfParties.RecipientCRTR = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 2 Then
				DataOfParties.RecipientSAbbreviatedName = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 3 Then
				DataOfParties.NameOfInternationalRecipient = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 4 Then
				DataOfParties.AbbreviatedNameOfPayer = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 5 Then
				DataOfParties.FullNameOfPayer = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 6 Then
				DataOfParties.NameOfInternationalPayer = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 7 Then
				DataOfParties.PayerCRTR = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 8 Then
				DataOfParties.TINOfPayer = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 9 Then
				DataOfParties.RecipientTIN = TableRow.AttributeValue;
			EndIf;
			
		Else
			
			If TableRow.Flag = 0 Then
				DataOfParties.FullNameOfPayer = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 1 Then
				DataOfParties.PayerCRTR = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 2 Then
				DataOfParties.AbbreviatedNameOfPayer = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 3 Then
				DataOfParties.NameOfInternationalPayer = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 4 Then
				DataOfParties.RecipientSAbbreviatedName = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 5 Then
				DataOfParties.FullNameOfRecipient = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 6 Then
				DataOfParties.NameOfInternationalRecipient = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 7 Then
				DataOfParties.RecipientCRTR = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 8 Then
				DataOfParties.RecipientTIN = TableRow.AttributeValue;
			ElsIf TableRow.Flag = 9 Then
				DataOfParties.TINOfPayer = TableRow.AttributeValue;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return DataOfParties;

EndFunction

// Returns a table of values containing the value of the Attributes (name, CHECKPOINT, TIN) of the recipient (write-off)/payer
// (receipt) and the company operating on the date of the document.
//
// Parameters:
//  DocumentsData - SeeNewTableOfDocumentSidesByList.
//
// Returns:
//  ValueTable:
//   * Document - DocumentRef - a document from the list of documents.
//   * AttributeValue - String - the value of the name or checkpoint.
//   * Flag - Number - Attribute attribute of the:
//      0 - Full name of the recipient (write-off) / payer (receipt),
//      1 - CHECKPOINT of the recipient (write-off) / payer (receipt),
//      2 - abbreviated name of the recipient (write-off) / payer (receipt),
//      3 - name of the international recipient (write-off) / payer (receipt),
//      4 - abbreviated name of the company,
//      5 - full name of the company,
//      6 - international name of the company,
//      7 - company's CHECKPOINT,
//      8 - TIN of the company,
//      9 - TIN of the recipient (write-off) / payer (receipt).
//
Function DataOfPayerSRecipient(DocumentsData) Export

	Query = New Query;
	Query.Text =
		"SELECT
		|	DocumentsData.Ref AS Ref,
		|	DocumentsData.Date AS Date,
		|	DocumentsData.Organization AS Organization,
		|	DocumentsData.Counterparty AS Counterparty
		|INTO DocumentsTable
		|FROM
		|	&DocumentsData AS DocumentsData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	DocumentsTable.Organization AS Organization,
		|	Companies.TIN AS TIN,
		|	Companies.CRTR AS CRTR,
		|	Companies.RegistrationWithTaxAuthority AS RegistrationWithTaxAuthority,
		|	Companies.DescriptionFull AS DescriptionFull,
		|	Companies.AbbreviatedDescription AS AbbreviatedDescription,
		|	Companies.DescriptionInternational AS DescriptionInternational
		|INTO CurrentDataOfCompanies
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN Catalog.Companies AS Companies
		|		ON DocumentsTable.Organization = Companies.Ref
		|
		|UNION
		|
		|SELECT
		|	DocumentsTable.Counterparty,
		|	Companies.TIN,
		|	Companies.CRTR,
		|	Companies.RegistrationWithTaxAuthority,
		|	Companies.DescriptionFull,
		|	Companies.AbbreviatedDescription,
		|	Companies.DescriptionInternational
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN Catalog.Companies AS Companies
		|		ON DocumentsTable.Counterparty = Companies.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	DocumentsTable.Counterparty AS Counterparty,
		|	Counterparties.TIN AS TIN,
		|	Counterparties.CRTR AS CRTR,
		|	Counterparties.DescriptionFull AS DescriptionFull
		|INTO CurrentCounterpartyData
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN Catalog.Counterparties AS Counterparties
		|		ON DocumentsTable.Counterparty = Counterparties.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	DocumentsTable.Counterparty AS Counterparty,
		|	Persons.TIN AS TIN,
		|	CASE 
		|		WHEN NOT &FramesSubsystemIsAvailable
		|			THEN Persons.Description
		|		ELSE Persons.LastFirstName
		|	END AS LastFirstName
		|INTO CurrentDataOfIndividuals
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN Catalog.Persons AS Persons
		|		ON DocumentsTable.Counterparty = Persons.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(CompaniesNameHistory.AbbreviatedDescription, Companies.AbbreviatedDescription) AS AbbreviatedDescription,
		|	ISNULL(CompaniesNameHistory.DescriptionFull, Companies.DescriptionFull) AS DescriptionFull,
		|	ISNULL(CompaniesNameHistory.DescriptionInternational, Companies.DescriptionInternational) AS DescriptionInternational,
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)) AS ValidOnDate,
		|	DocumentsTable.Ref AS Document
		|INTO HistoryOfNamesOfOrganizations
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Catalog.Companies.NameHistory AS CompaniesNameHistory
		|		ON DocumentsTable.Organization = CompaniesNameHistory.Ref
		|		INNER JOIN CurrentDataOfCompanies AS Companies
		|		ON DocumentsTable.Organization = Companies.Organization
		|WHERE
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)) <= DocumentsTable.Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CASE
		|		WHEN NOT FullNameOfPersons.Individual IS NULL
		|			THEN FullNameOfPersons.LastName + CASE
		|					WHEN FullNameOfPersons.Name <> """"
		|						THEN "" "" + FullNameOfPersons.Name
		|					ELSE """"
		|				END + CASE
		|					WHEN FullNameOfPersons.MiddleName <> """"
		|						THEN "" "" + FullNameOfPersons.MiddleName
		|					ELSE """"
		|				END
		|		ELSE CurrentDataOfIndividuals.LastFirstName
		|	END AS FullName_,
		|	CASE
		|		WHEN NOT FullNameOfPersons.Individual IS NULL AND NOT &FramesSubsystemIsAvailable
		|			THEN FullNameOfPersons.LastName + CASE
		|					WHEN FullNameOfPersons.Name <> """"
		|						THEN "" "" + SUBSTRING(FullNameOfPersons.Name, 1, 1) + "".""
		|					ELSE """"
		|				END + CASE
		|					WHEN FullNameOfPersons.MiddleName <> """"
		|						THEN "" "" + SUBSTRING(FullNameOfPersons.MiddleName, 1, 1) + "".""
		|					ELSE """"
		|				END
		|		WHEN NOT FullNameOfPersons.Individual IS NULL AND &FramesSubsystemIsAvailable
		|			THEN FullNameOfPersons.LastName + CASE
		|					WHEN FullNameOfPersons.Initials <> """"
		|						THEN "" "" + FullNameOfPersons.Initials
		|					ELSE """"
		|				END
		|		ELSE CurrentDataOfIndividuals.LastFirstName
		|	END AS AbbreviatedFullName,
		|	ISNULL(FullNameOfPersons.Period, DATETIME(1, 1, 1)) AS ValidOnDate,
		|	DocumentsTable.Ref AS Document
		|INTO HistoryOfNameOfNaturalPersons
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN CurrentDataOfIndividuals AS CurrentDataOfIndividuals
		|		ON DocumentsTable.Counterparty = CurrentDataOfIndividuals.Counterparty
		|		LEFT JOIN InformationRegister.FullNameOfPersons AS FullNameOfPersons
		|		ON DocumentsTable.Counterparty = FullNameOfPersons.Individual
		|WHERE
		|	ISNULL(FullNameOfPersons.Period, DATETIME(1, 1, 1)) <= DocumentsTable.Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(CounterpartiesNameHistory.NameAbbreviated, Counterparties.DescriptionFull) AS AttributeValue,
		|	ISNULL(CounterpartiesNameHistory.Period, DATETIME(1, 1, 1)) AS ValidOnDate,
		|	DocumentsTable.Ref AS Document,
		|	0 AS Flag
		|INTO HistoryOfPropsValues
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Catalog.Counterparties.NameHistory AS CounterpartiesNameHistory
		|		ON DocumentsTable.Counterparty = CounterpartiesNameHistory.Ref
		|		INNER JOIN CurrentCounterpartyData AS Counterparties
		|		ON DocumentsTable.Counterparty = Counterparties.Counterparty
		|WHERE
		|	ISNULL(CounterpartiesNameHistory.Period, DATETIME(1, 1, 1)) <= DocumentsTable.Date
		|
		|UNION ALL
		|
		|SELECT
		|	ISNULL(CompaniesNameHistory.DescriptionFull, Companies.DescriptionFull),
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)),
		|	DocumentsTable.Ref,
		|	0
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Catalog.Companies.NameHistory AS CompaniesNameHistory
		|		ON DocumentsTable.Counterparty = CompaniesNameHistory.Ref
		|		INNER JOIN CurrentDataOfCompanies AS Companies
		|		ON DocumentsTable.Counterparty = Companies.Organization
		|WHERE
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)) <= DocumentsTable.Date
		|
		|UNION ALL
		|
		|SELECT
		|	HistoryOfNameOfNaturalPersons.FullName_,
		|	HistoryOfNameOfNaturalPersons.ValidOnDate,
		|	HistoryOfNameOfNaturalPersons.Document,
		|	0
		|FROM
		|	HistoryOfNameOfNaturalPersons AS HistoryOfNameOfNaturalPersons
		|	
		|UNION ALL
		|
		|SELECT
		|	ISNULL(CounterpartiesCRTRHistory.CRTR, Counterparties.CRTR),
		|	ISNULL(CounterpartiesCRTRHistory.Period, DATETIME(1, 1, 1)),
		|	DocumentsTable.Ref,
		|	1
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Catalog.Counterparties.CRTRHistory AS CounterpartiesCRTRHistory
		|		ON DocumentsTable.Counterparty = CounterpartiesCRTRHistory.Ref
		|		INNER JOIN CurrentCounterpartyData AS Counterparties
		|		ON DocumentsTable.Counterparty = Counterparties.Counterparty
		|WHERE
		|	ISNULL(CounterpartiesCRTRHistory.Period, DATETIME(1, 1, 1)) <= DocumentsTable.Date
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN Companies.RegistrationWithTaxAuthority = """"
		|			THEN Companies.CRTR
		|	END,
		|	CASE
		|		WHEN Companies.RegistrationWithTaxAuthority = """"
		|			THEN DocumentsTable.Date
		|	END,
		|	DocumentsTable.Ref,
		|	1
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN CurrentDataOfCompanies AS Companies
		|		ON DocumentsTable.Counterparty = Companies.Organization
		|WHERE
		|	CASE
		|		WHEN Companies.RegistrationWithTaxAuthority = """"
		|			THEN TRUE
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	ISNULL(CompaniesNameHistory.AbbreviatedDescription, Companies.AbbreviatedDescription),
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)),
		|	DocumentsTable.Ref,
		|	2
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Catalog.Companies.NameHistory AS CompaniesNameHistory
		|		ON DocumentsTable.Counterparty = CompaniesNameHistory.Ref
		|		INNER JOIN CurrentDataOfCompanies AS Companies
		|		ON DocumentsTable.Counterparty = Companies.Organization
		|WHERE
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)) <= DocumentsTable.Date
		|
		|UNION ALL
		|
		|SELECT
		|	HistoryOfNameOfNaturalPersons.AbbreviatedFullName,
		|	HistoryOfNameOfNaturalPersons.ValidOnDate,
		|	HistoryOfNameOfNaturalPersons.Document,
		|	2
		|FROM
		|	HistoryOfNameOfNaturalPersons AS HistoryOfNameOfNaturalPersons
		|
		|UNION ALL
		|
		|SELECT
		|	ISNULL(CompaniesNameHistory.DescriptionInternational, Companies.DescriptionInternational),
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)),
		|	DocumentsTable.Ref,
		|	3
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Catalog.Companies.NameHistory AS CompaniesNameHistory
		|		ON DocumentsTable.Counterparty = CompaniesNameHistory.Ref
		|		INNER JOIN CurrentDataOfCompanies AS Companies
		|		ON DocumentsTable.Counterparty = Companies.Organization
		|WHERE
		|	ISNULL(CompaniesNameHistory.Period, DATETIME(1, 1, 1)) <= DocumentsTable.Date
		|
		|UNION ALL
		|
		|SELECT
		|	HistoryOfNamesOfOrganizations.AbbreviatedDescription,
		|	HistoryOfNamesOfOrganizations.ValidOnDate,
		|	HistoryOfNamesOfOrganizations.Document,
		|	4
		|FROM
		|	HistoryOfNamesOfOrganizations AS HistoryOfNamesOfOrganizations
		|
		|UNION ALL
		|
		|SELECT
		|	HistoryOfNamesOfOrganizations.DescriptionFull,
		|	HistoryOfNamesOfOrganizations.ValidOnDate,
		|	HistoryOfNamesOfOrganizations.Document,
		|	5
		|FROM
		|	HistoryOfNamesOfOrganizations AS HistoryOfNamesOfOrganizations
		|
		|UNION ALL
		|
		|SELECT
		|	HistoryOfNamesOfOrganizations.DescriptionInternational,
		|	HistoryOfNamesOfOrganizations.ValidOnDate,
		|	HistoryOfNamesOfOrganizations.Document,
		|	6
		|FROM
		|	HistoryOfNamesOfOrganizations AS HistoryOfNamesOfOrganizations
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN Companies.RegistrationWithTaxAuthority = """"
		|			THEN Companies.CRTR
		|	END,
		|	CASE
		|		WHEN Companies.RegistrationWithTaxAuthority = """"
		|			THEN DocumentsTable.Date
		|	END,
		|	DocumentsTable.Ref,
		|	7
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN CurrentDataOfCompanies AS Companies
		|		ON DocumentsTable.Organization = Companies.Organization
		|WHERE
		|	CASE
		|		WHEN Companies.RegistrationWithTaxAuthority = """"
		|			THEN TRUE
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	CurrentDataOfCompanies.TIN,
		|	DocumentsTable.Date,
		|	DocumentsTable.Ref,
		|	8
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN CurrentDataOfCompanies AS CurrentDataOfCompanies
		|		ON DocumentsTable.Organization = CurrentDataOfCompanies.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	CurrentDataOfCompanies.TIN,
		|	DocumentsTable.Date,
		|	DocumentsTable.Ref,
		|	9
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN CurrentDataOfCompanies AS CurrentDataOfCompanies
		|		ON DocumentsTable.Counterparty = CurrentDataOfCompanies.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	CurrentCounterpartyData.TIN,
		|	DocumentsTable.Date,
		|	DocumentsTable.Ref,
		|	9
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN CurrentCounterpartyData AS CurrentCounterpartyData
		|		ON DocumentsTable.Counterparty = CurrentCounterpartyData.Counterparty
		|
		|UNION ALL
		|
		|SELECT
		|	CurrentDataOfIndividuals.TIN,
		|	DocumentsTable.Date,
		|	DocumentsTable.Ref,
		|	9
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		INNER JOIN CurrentDataOfIndividuals AS CurrentDataOfIndividuals
		|		ON DocumentsTable.Counterparty = CurrentDataOfIndividuals.Counterparty
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	HistoryOfPropsValues.Document AS Document,
		|	MAX(HistoryOfPropsValues.ValidOnDate) AS ValidOnDate,
		|	HistoryOfPropsValues.Flag AS Flag
		|INTO NearestRecords
		|FROM
		|	HistoryOfPropsValues AS HistoryOfPropsValues
		|
		|GROUP BY
		|	HistoryOfPropsValues.Document,
		|	HistoryOfPropsValues.Flag
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	HistoryOfPropsValues.Document AS Document,
		|	HistoryOfPropsValues.AttributeValue AS AttributeValue,
		|	HistoryOfPropsValues.Flag AS Flag
		|FROM
		|	HistoryOfPropsValues AS HistoryOfPropsValues
		|		INNER JOIN NearestRecords AS NearestRecords
		|		ON HistoryOfPropsValues.Document = NearestRecords.Document
		|			AND HistoryOfPropsValues.ValidOnDate = NearestRecords.ValidOnDate
		|			AND HistoryOfPropsValues.Flag = NearestRecords.Flag";
	
	Query.SetParameter("DocumentsData", DocumentsData);
	Query.SetParameter("FramesSubsystemIsAvailable", Common.SubsystemExists("SalaryAndPersonnel"));
	
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;

EndFunction

// Returns a structure with initial values for searching for document side data
//
// Returns:
//   Structure:
//     * Ref - Undefined - link to the document
//     * Date - Date - Document date
//     * Counterparty - CatalogRef.Counterparties, Undefined - Document Counterparty
//     * Organization - CatalogRef.Companies - Organization of the document
Function ParametersForSearchingForDocumentSideData() Export

	Result = New Structure;
	Result.Insert("Ref", Undefined);
	Result.Insert("Date", Date('00010101'));
	Result.Insert("Counterparty", Undefined);
	Result.Insert("Organization", Catalogs.Companies.EmptyRef());
	
	Return Result;

EndFunction

Procedure CheckPersonalAccountsOfBankEmployees(DocumentObject, Cancel, FlagEDIWithBanks = False, FillingErrors = "") Export

	If DocumentObject.PersonalAccountsOfStaff.Count() = 0 Then
		Return;
	EndIf;
	
	BankAccountOfOrganization = Common.ObjectAttributeValue(DocumentObject.CounterpartyBankAccount, "Bank");
	
	If Not ValueIsFilled(BankAccountOfOrganization) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TableOfAccounts.LineNumber AS LineNumber,
		|	TableOfAccounts.PersonalAccount AS PersonalAccount
		|INTO InvoicesForVerification
		|FROM
		|	&TableOfAccounts AS TableOfAccounts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InvoicesForVerification.LineNumber AS LineNumber
		|FROM
		|	InvoicesForVerification AS InvoicesForVerification
		|		INNER JOIN Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
		|		ON InvoicesForVerification.PersonalAccount = CounterpartyBankAccounts.Ref
		|WHERE
		|	CounterpartyBankAccounts.Bank <> &Bank";
	
	Query.SetParameter("TableOfAccounts", DocumentObject.PersonalAccountsOfStaff);
	Query.SetParameter("Bank", BankAccountOfOrganization);
	
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		
		MessageText = StrTemplate(NStr("vi = 'Trong dòng %1 đã nhập tài khoản từ ngân hàng khác';
										|ru = 'В строке %1 введен счет из другого банка';
										|en = 'Another bank account is entered in the %1 line'; fa = 'Another bank account is entered in the %1 line';
										|it = 'Nella riga %1 è inserito un conto da un''altra banca';
										|pl = 'W wierszu %1 jest wprowadzony rachunek z innego banku';
										|tr = '%1 satırında hesap diğer bankadan girildi'"), QueryResult.LineNumber);
		
		If FlagEDIWithBanks Then
			AddFillInError(FillingErrors, MessageText);
		Else
			Common.MessageToUser(MessageText, DocumentObject, "PersonalAccountsOfStaff", , Cancel);
		EndIf;
	
	EndDo;

EndProcedure

// Returns an indication of the presence of a document on the enrollment of the DS according to the document specified in the parameter.
//
// Parameters:
//  DocumentRef - DocumentRef.BankAccountIssue - The document being checked.
//
// Returns:
//   Boolean
//
Function ThereAreDepositsOfDSToPersonalAccounts(DocumentRef) Export

	ThereAreDeposits = False;
	
	If ValueIsFilled(DocumentRef) Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref AS Ref
			|FROM
			|	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS BankConfirmationAboutCashReceiptOnEmployeeAccount
			|WHERE
			|	BankConfirmationAboutCashReceiptOnEmployeeAccount.SourceDocument = &SourceDocument
			|	AND NOT BankConfirmationAboutCashReceiptOnEmployeeAccount.DeletionMark";
		
		Query.SetParameter("SourceDocument", DocumentRef);
		SetPrivilegedMode(True);
		ThereAreDeposits = Not Query.Execute().IsEmpty();
		SetPrivilegedMode(False);
		
	EndIf;
	
	Return ThereAreDeposits;

EndFunction

// Filling in the payment ID selection data.
//
// Parameters:
//	ChoiceData - ValueList of Structure - The selection data to be filled in.
//	FilterStructure1 - Structure - Selection based on the operation data.
//
Procedure FillInUIPSelectionData(ChoiceData, FilterStructure1) Export

	Query = New Query;
	Query.Text = GetTextOfRequestDocumentsOfSettlementsWithClients(True, FilterStructure1);
	
	Query.SetParameter("Organization", FilterStructure1.Organization);
	Query.SetParameter("SearchString", FilterStructure1.Text);
	Query.SetParameter("SelectingThePaymentBasis", True);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		SelectionValue = New Structure;
		SelectionValue.Insert("PaymentPurpose", Undefined);
		SelectionValue.Insert("ARAPObject", Catalogs.ARAPObjects.EmptyRef());
		SelectionValue.Insert("Partner", Catalogs.Partners.EmptyRef());
		SelectionValue.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
		
		FillPropertyValues(SelectionValue, Selection);
		
		ChoiceData.Add(New Structure("Value", SelectionValue),
			String(Selection.ARAPObject));
	EndDo;

EndProcedure

// Checks the completion of the tabular part of the document according to the foundation document
//
// Parameters:
//  Object - DocumentObject.BankAccountIssue,
//           Document object.Payment confirmationaccumulation - the document in which the verification is performed.
//  ObjectTabularSectionName - String - the name of the tabular part of the document being checked with a list of personal accounts.
//  DocumentsSources - Array of DocumentRef.PaymentRequest,
//                       Array from documentlink.Write-off of non-cash funds - a list of documents
//                       that are used to check personal accounts.
//  Cancel - Boolean - blocking the execution of the main procedure.
//  FlagEDIWithBanks - Boolean - indicates that verification was performed during the exchange with the bank.
//  FillingErrors - String - error string.
//
Procedure CheckFillingOfPersonalAccountsBySources(Object, ObjectTabularSectionName, DocumentsSources, Cancel, FlagEDIWithBanks = False, FillingErrors = "") Export
	
	If DocumentsSources[0] = Undefined Then
		Return;
	EndIf;
	
	QueryText = 
		"SELECT
		|	PersonalAccounts.Individual AS Individual,
		|	PersonalAccounts.PersonalAccount AS PersonalAccount,
		|	PersonalAccounts.PersonalAccount.AccountNumber AS PersonalAccountNumber,
		|	SUM(PersonalAccounts.Sum) AS Sum
		|FROM
		|	Document.PaymentRequest.PersonalAccountsOfStaff AS PersonalAccounts
		|WHERE
		|	PersonalAccounts.Ref IN(&Ref)
		|
		|GROUP BY
		|	PersonalAccounts.Individual,
		|	PersonalAccounts.PersonalAccount,
		|	PersonalAccounts.PersonalAccount.AccountNumber
		|
		|UNION ALL
		|
		|SELECT
		|	PersonalAccounts.Individual,
		|	PersonalAccounts.PersonalAccount,
		|	PersonalAccounts.PersonalAccount.AccountNumber,
		|	SUM(PersonalAccounts.Sum)
		|FROM
		|	Document.BankAccountIssue.PersonalAccountsOfStaff AS PersonalAccounts
		|WHERE
		|	PersonalAccounts.Ref IN(&Ref)
		|
		|GROUP BY
		|	PersonalAccounts.Individual,
		|	PersonalAccounts.PersonalAccount,
		|	PersonalAccounts.PersonalAccount.AccountNumber
		|
		|UNION ALL
		|
		|SELECT
		|	PersonalAccounts.Employee,
		|	PersonalAccounts.PersonalAccount,
		|	PersonalAccounts.PersonalAccount.AccountNumber,
		|	SUM(PersonalAccounts.Sum)
		|FROM
		|	Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS PersonalAccounts
		|WHERE
		|	PersonalAccounts.Ref IN(&Ref)
		|
		|GROUP BY
		|	PersonalAccounts.Employee,
		|	PersonalAccounts.PersonalAccount,
		|	PersonalAccounts.PersonalAccount.AccountNumber";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentsSources);
	
	SetPrivilegedMode(True);
	DocumentData = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	If TypeOf(Object) = Type("DocumentObject.BankConfirmationAboutCashReceiptOnEmployeeAccount") Then
		NameOfInvoiceColumn = "PersonalAccountNumber";
	Else
		NameOfInvoiceColumn = "PersonalAccount";
	EndIf;
	
	TabularSectionData = Object[ObjectTabularSectionName].Unload(, "Individual, Sum, " + NameOfInvoiceColumn);
	TabularSectionData.GroupBy("Individual," + NameOfInvoiceColumn, "Sum");
	
	For Each TableRow In TabularSectionData Do
		
		Filter = New Structure("Individual," + NameOfInvoiceColumn);
		FillPropertyValues(Filter, TableRow);
		
		TableByIndividual = DocumentData.Copy(Filter);
		
		If TableByIndividual.Count() = 0 Then
			
			ErroneousLines = Object[ObjectTabularSectionName].FindRows(Filter);
			
			For Each LineOfATabularSection In ErroneousLines Do
				
				If TypeOf(Object) = Type("DocumentObject.BankConfirmationAboutCashReceiptOnEmployeeAccount") Then
					MessageString = StrTemplate(NStr("vi = 'Tại dòng số%1 đã chỉ ra nhân viên có tài  khoản cá nhân mà không có trong chứng từ gốc.';
													|ru = 'В строке №%1 указан сотрудник с лицевым счетом, отсутствующий в первичном документе.';
													|en = 'The employee with a personal account specified in row #%1 is missing in the source document.'; fa = 'The employee with a personal account specified in row #%1 is missing in the source document.';
													|it = 'Nella riga №%1 è indicato un dipendente con il conto personale assente nel documento primario.';
													|pl = 'W wierszu nr%1 jest już podany pracownik z kontem osobistym, którego nie ma w dokumencie podstawowym.';
													|tr = '№%1 satırında, birincil belgede olmayan kişisel hesabı olan bir çalışan belirtildi.'"),
										LineOfATabularSection["LineNumber"]);
				Else
					MessageString = StrTemplate(NStr("vi = 'Trong dòng số%1 đã chỉ ra nhân viên có tài khoản cá nhân mà không có trong yêu cầu.';
													|ru = 'В строке №%1 указан сотрудник с лицевым счетом, отсутствующий в заявке.';
													|en = 'The employee with a personal account specified in row #%1 is missing in the request.'; fa = 'The employee with a personal account specified in row #%1 is missing in the request.';
													|it = 'Nella riga N°%1 è indicato un dipendente con il conto personale assente nella richiesta.';
													|pl = 'W wierszu nr%1 jest już podany pracownik z kontem osobistym, którego nie ma w zleceniu.';
													|tr = '№%1 satırında, başvuruda olmayan kişisel hesabı olan bir çalışan belirtildi.'"),
										LineOfATabularSection["LineNumber"]);
				EndIf;
				
				Field = CommonClientServer.PathToTabularSection(ObjectTabularSectionName, LineOfATabularSection["LineNumber"], "Individual");
				
				If FlagEDIWithBanks Then
					AddFillInError(FillingErrors, MessageString);
				Else
					Common.MessageToUser(MessageString, Object, Field, , Cancel);
				EndIf;
				
			EndDo;
			
			Continue;
			
		EndIf;
		
		If TypeOf(Object) = Type("DocumentObject.BankConfirmationAboutCashReceiptOnEmployeeAccount") Then
		
			If TableRow.Sum <> TableByIndividual.Total("Sum") Then
				
				ErroneousLines = Object[ObjectTabularSectionName].FindRows(Filter);
				
				For Each LineOfATabularSection In ErroneousLines Do
					
					MessageString = StrTemplate(NStr("vi = 'Số tiền đã tính theo nhân viên %1, không trùng với số tiền chứng từ gốc.';
													|ru = 'Сумма, зачисленная по сотруднику %1, не совпадает с суммой первичного документа.';
													|en = 'Amount deposited to employee %1 does not match the amount in the source document.'; fa = 'Amount deposited to employee %1 does not match the amount in the source document.';
													|it = 'Importo accreditato per il dipendente %1 non corrisponde all''importo del documento primario.';
													|pl = 'Kwota, zaliczona według pracownika %1, nie jest zgodna z kwotą dokumentu podstawowego.';
													|tr = '%1 çalışanı için transfer edilen tutar, birincil belgenin tutarıyla eşleşmiyor.'"),
									TableRow.Individual);
					Field = CommonClientServer.PathToTabularSection(ObjectTabularSectionName, LineOfATabularSection["LineNumber"], "Sum");
					
					If FlagEDIWithBanks Then
						AddFillInError(FillingErrors, MessageString);
					Else
						Common.MessageToUser(MessageString, Object, Field, , Cancel);
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks whether the bank account is closed, displays a message about closing the bank account, but does not block the
// user's work.
// 
// Parameters:
//  Object - DocumentObject.PaymentRequest - the document that is being checked.
//  BankAccount - CatalogRef.CompaniesBankAccounts - a verifiable bank account.
//  TagName - String - the name of the form element of the document in which the check is performed.
//  FlagEDIWithBanks - Boolean - indicates a direct exchange through a bank.
//  FillingErrors - String - error description.
//
Procedure CheckAvailabilityOfBankAccount(
			Object, BankAccount, TagName, FlagEDIWithBanks = False, FillingErrors = "") Export
	
	If ValueIsFilled(BankAccount) And Common.ObjectAttributeValue(BankAccount, "Closed") Then
		
		MessageText = StrTemplate(NStr("vi = 'Đã đóng tài khoản ""%1"". Không cần để điền.';
										|ru = 'Cчет ""%1"" закрыт. Не рекомендуется для заполнения.';
										|en = 'Account ""%1"" is closed. Filling is not recommended.'; fa = 'Account ""%1"" is closed. Filling is not recommended.';
										|it = 'Il conto ""%1"" è chiuso. Si sconsiglia la compilazione.';
										|pl = 'Konto ""%1"" jest zamknięte. Nie jest zalecane do wypełnienia.';
										|tr = '""%1"" hesabı kapatıldı. Doldurulması önerilmemektedir.'"), BankAccount);
		
		If FlagEDIWithBanks Then
			AddFillInError(FillingErrors, MessageText);
		Else
			Common.MessageToUser(MessageText, Object, TagName);
		EndIf;
		
	EndIf;
	
EndProcedure

// Checks whether the bank account filled in the tabular part of the object is closed, displays a message about closing the bank
// account, but does not block the user's work..
// 
// Parameters:
//  Object - DocumentObject.PaymentRequest - the document that is being checked.
//  ObjectTabularSectionName - String - the name of the tabular part of the document in which the check is performed.
//  Column - String - the name of the column with the bank account in the tabular part of the document.
//  FlagEDIWithBanks - Boolean - indicates a direct exchange through a bank.
//  FillingErrors - String - error description.
//
Procedure CheckAvailabilityOfTabularPartOfBankAccount(
			Object, ObjectTabularSectionName, Column, FlagEDIWithBanks = False, FillingErrors = "") Export
	
	AccountList = Common.UnloadColumn(Object[ObjectTabularSectionName], Column, True);
	
	DeleteList = New Array;
	
	For IndexOf = 0 To AccountList.UBound() Do
		
		Account = AccountList.Get(IndexOf);
		
		If TypeOf(Account) <> Type("CatalogRef.CompaniesBankAccounts") Then
			DeleteList.Add(Account);
		EndIf;
		
	EndDo;
	
	For Each CurrentValue In DeleteList Do
		
		CurrentIndex = AccountList.Find(CurrentValue);
		
		If CurrentIndex <> Undefined Then
			AccountList.Delete(CurrentIndex);
		EndIf;
		
	EndDo;
	
	InformationByAccounts = Common.ObjectsAttributesValues(AccountList, "Closed");
	
	For Each InvoiceData In InformationByAccounts Do
		
		If InvoiceData["Value"]["Closed"] Then
		
			Filter = New Structure(Column, InvoiceData["Key"]);
			ErroneousLines = Object[ObjectTabularSectionName].FindRows(Filter);
			
			For Each LineOfATabularSection In ErroneousLines Do
				
				MessageText = StrTemplate(NStr("vi = 'Trong dòng số %1 đã nhập hóa đơn đã đóng ""%2"".';
												|ru = 'В строке № %1 введен закрытый счет ""%2"".';
												|en = 'In row #%1 closed account ""%2"" is specified.'; fa = 'In row #%1 closed account ""%2"" is specified.';
												|it = 'Nella riga N° %1 è stato inserito il conto chiuso ""%2""';
												|pl = 'W wierszu nr %1 jest wprowadzone zamknięte konto ""%2"".';
												|tr = '%1 numaralı satırında ""%2"" kapalı hesabı girildi.'"),
											LineOfATabularSection["LineNumber"],
											LineOfATabularSection[Column]);
				Field = CommonClientServer.PathToTabularSection(ObjectTabularSectionName, LineOfATabularSection["LineNumber"], Column);
				
				If FlagEDIWithBanks Then
					AddFillInError(FillingErrors, MessageText);
				Else
					Common.MessageToUser(MessageText, Object, Field);
				EndIf;
				
			EndDo;
		
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the cash flow item under the loan and deposit Contract, taking into account the type of loan and deposit amount.
// 
// Parameters:
//  LoanDepositContract - CatalogRef.LoanAndDepositContracts - The Contract under which the DDS article is determined.
//  LoanAndDepositAmountType - EnumRef.LoanAndDepositScheduleAmountTypes - the type of amount to be repaid.
//  DefaultCashFlowItem - CatalogRef.CashFlowReportItems - The DDS article that
//  is selected by default if the DDS article by amount type is not filled in.
// 
// Returns:
//  CatalogRef.CashFlowReportItems
//
Function ArticleOfDepositLoanContractByTypeOfDepositLoanAmount(
			LoanDepositContract, LoanAndDepositAmountType, DefaultCashFlowItem) Export

	CFItems = Common.ObjectAttributesValues(
		LoanDepositContract, "CashFlowItemOfPrincipalDebt, CashFlowItemOfInterestPayment, CashFlowItemOfFeePayment");
		
	If LoanAndDepositAmountType = Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt Then
		ArticleOnContract = CFItems.CashFlowItemOfPrincipalDebt;
	ElsIf LoanAndDepositAmountType = Enums.LoanAndDepositScheduleAmountTypes.Interests Then
		ArticleOnContract = CFItems.CashFlowItemOfInterestPayment;
	ElsIf LoanAndDepositAmountType = Enums.LoanAndDepositScheduleAmountTypes.Fee Then
		ArticleOnContract = CFItems.CashFlowItemOfFeePayment;
	EndIf;
	
	If ValueIsFilled(ArticleOnContract) Then
		Return ArticleOnContract;
	Else
		Return DefaultCashFlowItem;
	EndIf;

EndFunction

// defines the conversion payment attribute for the payment document
//
// Parameters:
//    Object - DocumentObject.PaymentRequest, DocumentObject.BankAccountIssue - Payment document
//
// Returns:
//    Boolean - flag for a payment with conversion
//
Function DefinePaymentWithConversion(Object) Export
	
	Result = False;
	
	If ValueIsFilled(Object.BankAccount) 
		And ValueIsFilled(Object.Currency) Then
		
		AccountCurrency = Common.ObjectAttributeValue(Object.BankAccount, "CashCurrency");
		PaymentCurrency = Object.Currency;
		Result = AccountCurrency <> PaymentCurrency;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the selection of the data layout with the condition for applying the payment operation to the self-employed.
// 
// Returns:
//  DataCompositionFilter - Selection Payment to the Self-Employed
//
Function FilterPaymentToSelfEmployed() Export

	Filter = New DataCompositionFilter();
	AndGroup = FinancialReportingServer.NewFilter(Filter, Undefined, , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	FinancialReportingServer.NewFilter(
		AndGroup,
		"BusinessOperation",
		Enums.BusinessTransactions.PaymentToVendor);
	FinancialReportingServer.NewFilter(
		AndGroup,
		"OperationWithSelfEmployedPerson",
		True);
	
	Return Filter;

EndFunction

// Returns the selection of the data layout with the condition that the list of counterparties is applied.
// 
// Parameters:
//  PaymentToSelfEmployed - DataCompositionFilter, Undefined - Selection Payment to the Self-Employed
// 
// Returns:
//  DataCompositionFilter - Selection list of counterparties
//
Function FilterListOfCounterparties_(PaymentToSelfEmployed = Undefined) Export

	If PaymentToSelfEmployed = Undefined Then
		PaymentToSelfEmployed = FilterPaymentToSelfEmployed();
	EndIf;
	
	Filter = New DataCompositionFilter();
	AndGroup = FinancialReportingServer.NewFilter(Filter, Undefined, , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.CopyFilter(PaymentToSelfEmployed, AndGroup);
	FinancialReportingServer.NewFilter(AndGroup, "ListOfCounterparties_", True);
	
	Return Filter;

EndFunction

// Returns the selection of the data layout with parameters for non-cash payment of the Cash Request document.
// 
// Returns:
//  DataCompositionFilter - Selection Non-Cash Payment Of The Application
//
Function SelectionNonCashPaymentOfApplication() Export

	Filter = New DataCompositionFilter();
	OrGroup = FinancialReportingServer.NewFilter(Filter, Undefined, , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	FinancialReportingServer.NewFilter(OrGroup, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.BankAccountPayment);
	NotGroup = FinancialReportingServer.NewFilter(OrGroup, Undefined, , Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	FinancialReportingServer.NewFilter(NotGroup, "More.PaymentMethod", "CashAccountPayment_");
	
	Return Filter;

EndFunction

// Refills the currency of mutual settlements in the tabular part "Decryption of payment".
// 
// Parameters:
//  DocumentName - String - the full name of the document.
//  Object - FormDataCollection - The object of filling in the table part.
//  LocalAccountingCurrency - CatalogRef.Currencies - Currency of regulated accounting.
//  PaymentCurrencyHasChanged - Boolean - indicates whether the item's currency has changed.
//
Procedure UpdateSettlementCurrencyOfPaymentDecryption(DocumentName, Object, LocalAccountingCurrency, PaymentCurrencyHasChanged = True) Export

	ArrayOfOperationDetails = New Array;
	
	ManagerOfDocument = Common.ObjectManagerByFullName(DocumentName);
	ManagerOfDocument.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("ARAPDetails.ARAPObject") <> Undefined Then
		ColumnName = "ARAPObject";
	ElsIf ArrayOfOperationDetails.Find("ARAPDetails.LeaseContracts") <> Undefined Then
		ColumnName = "LeaseContracts";
	ElsIf ArrayOfOperationDetails.Find("ARAPDetails.LoanDepositContract") <> Undefined Then
		ColumnName = "LoanDepositContract";
	Else
		ColumnName = "";
	EndIf;
	
	If ColumnName <> "" Then
		
		If DocumentName = "Document.PaymentRequest" Then
			ObjectDate = Object.Date;
		Else
			ObjectDate = ?(ValueIsFilled(Object.BankPostingDate), Object.BankPostingDate, Object.Date);
		EndIf;
		
		RefsTable = Object.ARAPDetails.Unload(, ColumnName);
		ReferencesArrray = RefsTable.UnloadColumn(ColumnName);
		CurrenciesOfObjects = Common.ObjectsAttributeValue(ReferencesArrray, "ARAPCurrency");
		
		For Each TableRow In Object.ARAPDetails Do
			
			ObjectSSettlementCurrency = CurrenciesOfObjects.Get(TableRow[ColumnName]);
			
			If Not ValueIsFilled(TableRow[ColumnName])
				And Not ValueIsFilled(Object.Contract) Then
				FillInSettlementCurrencyByPaymentCurrency(TableRow, Object.Currency);
			ElsIf ValueIsFilled(ObjectSSettlementCurrency)
				And TableRow.ARAPCurrency <> ObjectSSettlementCurrency Then
				
				TableRow.ARAPCurrency = ObjectSSettlementCurrency;
				
				FillInCourseOfMutualSettlementsOfDecryptionLine(
					Object, LocalAccountingCurrency, ObjectDate, TableRow);
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					TableRow, Object.Currency, LocalAccountingCurrency);
					
			ElsIf PaymentCurrencyHasChanged Then
				
				FillInCourseOfMutualSettlementsOfDecryptionLine(
					Object, LocalAccountingCurrency, ObjectDate, TableRow);
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					TableRow, Object.Currency, LocalAccountingCurrency);
					
			EndIf;
			
		EndDo;
		
	ElsIf ArrayOfOperationDetails.Find("ARAPDetails.ARAPCurrency") <> Undefined Then
			
		For Each TableRow In Object.ARAPDetails Do
			FillInSettlementCurrencyByPaymentCurrency(TableRow, Object.Currency);
		EndDo;
			
	EndIf;

EndProcedure

// Returns the structure of parameters for filling in the course and multiplicity.
// 
// Returns:
//  Structure - Course Filling And Multiplicity Parameters:
// * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// * Currency - CatalogRef.Currencies - the currency of the document.
// * LocalAccountingCurrency - CatalogRef.Currencies - Currency of regulated accounting.
// * ARAPObject - CatalogRef.ARAPObjects - The object of calculations.
// * Contract - Undefined - the Contract of the counterparty.
// * Date - Date - the date on which the rate and multiplicity will be determined.
//
Function CourseFillingAndMultiplicityParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ARAPCurrency", Catalogs.Currencies.EmptyRef());
	Parameters.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Parameters.Insert("LocalAccountingCurrency", Catalogs.Currencies.EmptyRef());
	Parameters.Insert("ARAPObject", Catalogs.ARAPObjects.EmptyRef());
	Parameters.Insert("Contract", Undefined);
	Parameters.Insert("Date", Date('00010101'));
	
	Return Parameters;
	
EndFunction

// Fills in the rate and multiplicity in the line of the tabular part "Decryption of payment".
// 
// Parameters:
//  DecryptionString - FormDataStructure - the row of the table part.
//  FillParameters - See CourseFillingAndMultiplicityParameters.
//
Procedure FillInCourseAndMultiplicityInDecryptionLine(DecryptionString, FillParameters) Export
	
	CourseAndMultiplicity = CourseNumeratorAndCourseDenominatorOfMutualSettlements(
		FillParameters.Currency,
		FillParameters.ARAPCurrency,
		FillParameters.LocalAccountingCurrency,
		FillParameters.Date,
		FillParameters.ARAPObject,
		FillParameters.Contract);
	
	DecryptionString.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
	DecryptionString.ContractRateOption = CourseAndMultiplicity.ContractRateOption;
	DecryptionString.ARAPObjectType = CourseAndMultiplicity.ARAPObjectType;
	
EndProcedure

// Returns the correspondence of the bank's Attributes according to the Classificatorbank Catalog.
// 
// Returns:
//  Map of KeyAndValue - list of matching Attributes:
//   *Key - String - the Attribute name from the bank classifier.
//   *Value - String - the name of the Attribute from the Catalog of bank accounts.
//
Function EquivalenceOfBankAttributesInCatalog() Export

	Result = New Map;
	Result.Insert("Description", "BankDescription");
	Result.Insert("CorrAccount", "BankCorrAccount");
	Result.Insert("City", "BankCity");
	Result.Insert("Address", "BankAddress");
	Result.Insert("Phones", "BankPhones");
	Result.Insert("BIC", "BankBIC");
	Result.Insert("SWIFT", "BankSWIFTCode");
	Result.Insert("InternationalDescription", "BankNameInt");
	Result.Insert("CityInternationalFormat", "BankCityInt");
	Result.Insert("InternationalAddress", "BankAddressInt");
	Result.Insert("ManualBankDetailsChange", "ManualBankDetailsChange");
	
	Return Result;

EndFunction

// Returns the correspondence of the bank Attributes for settlements in the Classifier of Banks Catalog.
// 
// Returns:
//  Map of KeyAndValue - list of matching Attributes:
//   *Key - String - the Attribute name from the bank classifier.
//   *Value - String - the name of the Attribute from the Catalog of bank accounts.
//
Function EquivalenceOfBankAttributesForSettlementsInCatalog() Export

	Result = New Map;
	Result.Insert("Description", "TransferBankDescription");
	Result.Insert("CorrAccount", "TransferBankCorrAccount");
	Result.Insert("City", "TransferBankCity");
	Result.Insert("Address", "TransferBankAddress");
	Result.Insert("Phones", "TransferBankPhones");
	Result.Insert("BIC", "TransferBankBIC");
	Result.Insert("SWIFT", "BankSWIFTCodeForPayments");
	Result.Insert("InternationalDescription", "BankNameForPaymentsInt");
	Result.Insert("CityInternationalFormat", "BankCityForPaymentsInt");
	Result.Insert("InternationalAddress", "BankAddressForPaymentInt");
	Result.Insert("ManualBankDetailsChange", "TransferBankDetailsManualEdit");
	
	Return Result;

EndFunction

// Fills in the Attributes of the bank in the Catalog of bank accounts and returns a sign of completion of the filling.
// 
// Parameters:
//  Object - CatalogObject.CounterpartyBankAccounts, CatalogObject.CompaniesBankAccounts - Object.
//  MatchingBankDetails - Map of KeyAndValue - a list of matching bank Attributes according to the Classifier of Banks Catalog.
//  BankingDetails - ValueTableRow - information from the classifier of banks.
// 
// Returns:
//  Boolean - indicates whether the bank's Attributes have been changed.
//
Function BankAttributesChanged(Object, MatchingBankDetails, BankingDetails) Export

	For Each CurrentItem In MatchingBankDetails Do
		Object[CurrentItem.Value] = BankingDetails[CurrentItem.Key];
	EndDo;
	
	Return True;

EndFunction

// Fill in the data of the settlement object in the tabular part "Decryption of payment" of the document
//
// Parameters:
//  DocumentObject - FormDataStructure - data of the document in which the filling is performed.
//  RowID - Number - ID of the row in the "Payment decryption" tabular part of the document.
//  FillInPaymentId - Boolean - indicates that you need to fill in the "Payment identifier" field
//  										in the "Payment decryption" tabular part of the document.
//
Procedure FillInDataOfSettlementObjectOfPaymentDecryption(
	DocumentObject, RowID = Undefined, FillInPaymentId = False) Export
	
	CounterpartyOfContract = Undefined;
	
	If DocumentObject.Contract <> Undefined
		And CommonClientServer.HasAttributeOrObjectProperty(DocumentObject.Contract, "Counterparty") Then
		
		SetPrivilegedMode(True);
		CounterpartyOfContract = Common.ObjectAttributeValue(DocumentObject.Contract, "Counterparty");
		SetPrivilegedMode(False);
		
	EndIf;
	
	AttributesNames = New Array;
	AttributesNames.Add("Contract");
	AttributesNames.Add("Object");
	
	If FillInPaymentId Then
		AttributesNames.Add("PaymentID");
	EndIf;
	
	If RowID = Undefined Then
	
		TableOfCalculationObjects = DocumentObject.ARAPDetails.Unload(, "ARAPObject");
		ListOfObjects = CommonClientServer.CollapseArray(TableOfCalculationObjects.UnloadColumn("ARAPObject"));
		ObjectsData = Common.ObjectsAttributesValues(ListOfObjects, AttributesNames);
		
		For Each TableRow In DocumentObject.ARAPDetails Do
			
			If ValueIsFilled(TableRow.ARAPObject) Then
				
				TableRow.CalculationObject = ObjectsData[TableRow.ARAPObject]["Object"];
				TableRow.Contract = ObjectsData[TableRow.ARAPObject]["Contract"];
				If FillInPaymentId Then
					TableRow.PaymentID = ObjectsData[TableRow.ARAPObject]["PaymentID"];
				EndIf;
				
			Else
				
				TableRow.CalculationObject = Undefined;
				If FillInPaymentId Then
					TableRow.PaymentID = "";
				EndIf;
				
			EndIf;
			
			FillInDecryptionLineWithContractFromItemHeader(DocumentObject, TableRow, CounterpartyOfContract);
			
		EndDo;
		
	Else
		
		TableRow = DocumentObject.ARAPDetails.FindByID(RowID);
		ObjectData = Common.ObjectAttributesValues(TableRow.ARAPObject, AttributesNames);
		
		TableRow.CalculationObject = ObjectData.Object;
		If ValueIsFilled(TableRow.ARAPObject) Then
			TableRow.Contract = ObjectData.Contract;
		EndIf;
		
		If FillInPaymentId Then
			TableRow.PaymentID = ObjectData.PaymentID;
		EndIf;
		
		FillInDecryptionLineWithContractFromItemHeader(DocumentObject, TableRow, CounterpartyOfContract);
		
	EndIf;

EndProcedure

// Sets a limit on the composition of types for the Contract on the "Payment decryption" page.
//
// Parameters:
//  Form - ClientApplicationForm - The Form on which the restriction of element types is performed.
//
Procedure SetRestrictionOnTypeOfPaymentDecryptionContract(Form) Export

	Form.AmountUnallocated = UnallocatedPaymentBalance(Form.Object);
	
	If Form.AmountUnallocated <> 0 And Not ValueIsFilled(Form.Object.Contract) Then
		
		If Form.Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
			Or Form.Object.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
			Or Form.Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
			Or Form.Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			
			Form.Object.Contract = Catalogs.IntercompanyContracts.EmptyRef();
			TypeDetails = New TypeDescription("CatalogRef.IntercompanyContracts");
			Form.Items.Contract.TypeRestriction = TypeDetails;
			Form.Items.ARAPDetailsContract.TypeRestriction = TypeDetails;
			
		Else
			
			Form.Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
			TypeDetails = New TypeDescription("CatalogRef.CounterpartyContracts");
			Form.Items.Contract.TypeRestriction = TypeDetails;
			Form.Items.ARAPDetailsContract.TypeRestriction = TypeDetails;
			
		EndIf;
		
	EndIf;

EndProcedure

// Returns the result of executing a query to the database to get Balances for the documents "Request for Cash spending".
//
// Parameters:
//  SelectionData_ - Structure - contains the values of the selection of applications.
//
// Returns:
//   QueryResult
//
Function RequestForBalancesOfRequestsForSpendingFunds(SelectionData_) Export

	Query = New Query;
	Query.Text = "
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * CurrencyConversionRate_2.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * CurrencyConversionRate_2.CourseNumerator) AS ConversionFactor_
	|INTO ExchangeRates
	|FROM InformationRegister.RelativeExchangeRates.SliceLast(&CurrentSessionDate, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(&CurrentSessionDate,
	|				Currency = &Currency AND BaseCurrency = &BaseCurrency) AS CurrencyConversionRate_2
	|	ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND CurrencyConversionRate_2.CourseNumerator <> 0
	|;
	|
	|//////////////////////////////////////////////
	|SELECT
	|	Cash.PaymentRequest AS PaymentRequest,
	|	Request.Number  AS RequestNumber,
	|	Request.Date   AS RequestDate,
	|	Request.Currency AS RequestCurrency,
	|	Cash.SumBalance AS AmountInCurrency,
	|	Cash.SumBalance * ExchangeRates.ConversionFactor_ AS Sum
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(,
	|		Organization = &Organization
	|		AND Recipient IN (&Recipient)
	|		AND BankAccountCashAccount IN (&BankAccountsCashAccounts)) AS Cash
	|	
	|	INNER JOIN Document.PaymentRequest AS Request
	|	ON Request.Ref = Cash.PaymentRequest
	|	
	|	LEFT JOIN ExchangeRates AS ExchangeRates
	|	ON Request.Currency = ExchangeRates.Currency
	|	
	|WHERE
	|	Request.BusinessOperation = &BusinessOperation
	|	AND Request.PayrollTransaction <> &BusinessOperation
	|	AND (Request.PaymentMethodOfPaymentRequest IN (&PaymentMethod))
	|	AND (Request.Currency = &Currency OR Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency))
	|	AND Request.Status = VALUE(Enum.StatusesOfPaymentRequests.AmountDue)
	|	AND (Request.OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson OR &OperationWithSelfEmployedPerson = UNDEFINED)
	|
	|UNION ALL
	|
	|SELECT
	|	Cash.PaymentRequest AS PaymentRequest,
	|	Request.Number  AS RequestNumber,
	|	Request.Date   AS RequestDate,
	|	Request.Currency AS RequestCurrency,
	|	Cash.SumBalance AS AmountInCurrency,
	|	Cash.SumBalance * ExchangeRates.ConversionFactor_ AS Sum
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(,
	|		Organization = &Organization
	|		AND Recipient IN (&Recipient)
	|		AND BankAccountCashAccount IN (&BankAccountsCashAccounts)) AS Cash
	|	
	|	INNER JOIN Document.PaymentRequest AS Request
	|	ON Request.Ref = Cash.PaymentRequest
	|	
	|	LEFT JOIN ExchangeRates AS ExchangeRates
	|	ON Request.Currency = ExchangeRates.Currency
	|	
	|WHERE
	|	Request.PayrollTransaction IN (&BusinessOperation)
	|	AND NOT Request.BusinessOperation IN (&BusinessOperation)
	|	AND (Request.PaymentMethodOfPaymentRequest IN (&PaymentMethod))
	|	AND (Request.Currency = &Currency OR Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency))
	|	AND Request.Status = VALUE(Enum.StatusesOfPaymentRequests.AmountDue)
	|	AND (Request.OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson OR &OperationWithSelfEmployedPerson = UNDEFINED)
	|";
	
	Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
	Query.SetParameter("Currency", SelectionData_.Currency);
	Query.SetParameter("Organization", SelectionData_.Organization);
	Query.SetParameter("BusinessOperation", SelectionData_.BusinessOperation);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
	Query.SetParameter("OperationWithSelfEmployedPerson", SelectionData_.OperationWithSelfEmployedPerson);
	
	BankAccountsCashAccounts = New Array;
	BankAccountsCashAccounts.Add(SelectionData_.BankAccountCashAccount);
	BankAccountsCashAccounts.Add(Undefined);
	Query.SetParameter("BankAccountsCashAccounts", BankAccountsCashAccounts);
	
	Recipient = PaymentBeneficiary(SelectionData_);
	Query.SetParameter("Recipient", Recipient);
	
	PaymentForms = ValueOfRequestPaymentFormParameter(SelectionData_.PaymentMethod);
	Query.SetParameter("PaymentMethod", PaymentForms);
	
	Return Query.Execute();

EndFunction

// Returns the conversion data table for the document "Debiting non-cash Cash".
// 
// Parameters:
//  UIPCondition - String, Array of String - payment ID or list of payment IDs.
//  DateOfRemainingGoods - Date - date of receipt of Balances.
// 
// Returns:
//  See InitializePropertiesTableByIP.
//
Function GroundsOfOperationOfConversionByUIP(UIPCondition, DateOfRemainingGoods) Export
	
	PropertiesTable = InitializePropertiesTableByIP();
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	DocumentWriteOffs.Ref AS PaymentPurpose,
		|	DocumentWriteOffs.Counterparty AS Counterparty,
		|	DocumentWriteOffs.Organization AS Organization,
		|	DocumentWriteOffs.Department AS Department,
		|	DocumentWriteOffs.Currency AS CurrencyOfConversion,
		|	DocumentWriteOffs.PaymentID AS PaymentID,
		|	DocumentWriteOffs.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	DocumentWriteOffs.BankAccountBeneficiary AS BankAccountBeneficiary,
		|	DocumentWriteOffs.Partner AS Partner,
		|	DocumentWriteOffs.DocumentAmount AS DocumentAmount,
		|	DocumentWriteOffs.BankAccountBeneficiary.CashCurrency AS Currency,
		|	DocumentWriteOffs.ConversionAmount AS ConversionAmount,
		|	CASE
		|		WHEN DocumentWriteOffs.Currency = DocumentWriteOffs.Organization.LocalAccountingCurrency
		|				OR DocumentWriteOffs.CurrencyOfConversion = DocumentWriteOffs.Organization.LocalAccountingCurrency
		|				OR DocumentWriteOffs.BankAccountBeneficiary.CashCurrency = DocumentWriteOffs.Organization.LocalAccountingCurrency
		|			THEN DocumentWriteOffs.ConversionRate
		|		ELSE 1 / DocumentWriteOffs.ConversionRate
		|	END AS ConversionRate,
		|	CASE
		|		WHEN DocumentWriteOffs.Currency = DocumentWriteOffs.Organization.LocalAccountingCurrency
		|				OR DocumentWriteOffs.CurrencyOfConversion = DocumentWriteOffs.Organization.LocalAccountingCurrency
		|				OR DocumentWriteOffs.BankAccountBeneficiary.CashCurrency = DocumentWriteOffs.Organization.LocalAccountingCurrency
		|			THEN DocumentWriteOffs.ConversionRateMultiplier
		|		ELSE 1
		|	END AS ConversionRateMultiplier
		|INTO WriteOffData
		|FROM
		|	Document.BankAccountIssue AS DocumentWriteOffs
		|WHERE
		|	DocumentWriteOffs.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|	AND &IdCondition
		|	AND NOT DocumentWriteOffs.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CashInTransitBalance.Organization AS Organization,
		|	CashInTransitBalance.Recipient AS Recipient,
		|	CashInTransitBalance.Counterparty AS Counterparty,
		|	CashInTransitBalance.Currency AS Currency,
		|	CashInTransitBalance.SumBalance AS SumBalance
		|INTO ConversionBalances
		|FROM
		|	AccumulationRegister.CashInTransit.Balance(
		|			&DateOfRemainingGoods,
		|			(Organization, Recipient, Counterparty, Currency) IN
		|				(SELECT DISTINCT
		|					WriteOffData.Organization AS Organization,
		|					WriteOffData.BankAccountBeneficiary AS BankAccountBeneficiary,
		|					WriteOffData.Counterparty AS Counterparty,
		|					WriteOffData.CurrencyOfConversion AS Currency
		|				FROM
		|					WriteOffData AS WriteOffData)) AS CashInTransitBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WriteOffData.PaymentPurpose AS PaymentPurpose,
		|	WriteOffData.Organization AS Organization,
		|	WriteOffData.BankAccountBeneficiary AS BankAccount,
		|	WriteOffData.Counterparty AS Counterparty,
		|	WriteOffData.Partner AS Partner,
		|	WriteOffData.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	WriteOffData.Department AS Department,
		|	WriteOffData.PaymentID AS PaymentID,
		|	WriteOffData.ConversionAmount AS DocumentAmount,
		|	ISNULL(ConversionBalances.SumBalance, 0) AS ConversionAmount,
		|	WriteOffData.CurrencyOfConversion AS CurrencyOfConversion,
		|	WriteOffData.Currency AS Currency,
		|	WriteOffData.ConversionRate AS ConversionRate,
		|	WriteOffData.ConversionRateMultiplier AS ConversionRateMultiplier
		|FROM
		|	WriteOffData AS WriteOffData
		|		LEFT JOIN ConversionBalances AS ConversionBalances
		|		ON WriteOffData.Organization = ConversionBalances.Organization
		|			AND WriteOffData.BankAccountBeneficiary = ConversionBalances.Recipient
		|			AND WriteOffData.Counterparty = ConversionBalances.Counterparty
		|			AND WriteOffData.CurrencyOfConversion = ConversionBalances.Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	WriteOffData.PaymentPurpose AS PaymentPurpose,
		|	BankAccountReceiptNote.CashFlowItem AS CashFlowItem,
		|	BankAccountReceiptNote.Date AS Date
		|FROM
		|	WriteOffData AS WriteOffData
		|		INNER JOIN Document.BankAccountReceiptNote AS BankAccountReceiptNote
		|		ON WriteOffData.Counterparty = BankAccountReceiptNote.Counterparty
		|			AND WriteOffData.Organization = BankAccountReceiptNote.Organization
		|			AND WriteOffData.CounterpartyBankAccount = BankAccountReceiptNote.CounterpartyBankAccount
		|			AND WriteOffData.BankAccountBeneficiary = BankAccountReceiptNote.BankAccount
		|			AND (BankAccountReceiptNote.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion))
		|
		|ORDER BY
		|	Date DESC";
	
	If TypeOf(UIPCondition) = Type("Array") Then
		Query.Text = StrReplace(Query.Text, "&IdCondition", "DocumentWriteOffs.PaymentID IN (&UIPCode)");
	Else
		UIPCondition = UIPCondition + "%";
		Query.Text = StrReplace(Query.Text, "&IdCondition", "DocumentWriteOffs.PaymentID LIKE &UIPCode");
	EndIf;
	
	Query.SetParameter("UIPCode", UIPCondition);
	Query.SetParameter("DateOfRemainingGoods", DateOfRemainingGoods);
	
	QueriesArray = Query.ExecuteBatch();
	SelectionOfWriteOffData = QueriesArray[QueriesArray.UBound() - 1].Select();
	ListOfDDSArticles = QueriesArray[QueriesArray.UBound()].Unload();
	
	DefaultCashFlowItem =
		Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
			Enums.BusinessTransactions.CurrencyConversion);
	
	While SelectionOfWriteOffData.Next() Do
		
		NewRow = PropertiesTable.Add();
		FillPropertyValues(NewRow, SelectionOfWriteOffData);
		
		Filter = New Structure("PaymentPurpose", SelectionOfWriteOffData.PaymentPurpose);
		TableRows = ListOfDDSArticles.FindRows(Filter);
		
		If TableRows.Count() <> 0 Then
			NewRow.CashFlowItem = TableRows[0].CashFlowItem;
		EndIf;
		
		If Not ValueIsFilled(NewRow.CashFlowItem)
			And ValueIsFilled(DefaultCashFlowItem) Then
			NewRow.CashFlowItem = DefaultCashFlowItem;
		EndIf;
		
	EndDo;
			
	Return PropertiesTable;
	
EndFunction

// Recalculates the conversion Attributes.
// 
// Parameters:
//  Object - DocumentObject.BankAccountIssue - the document conversion.
//  CurrencyOfComplianceAccounting - CatalogRef.Currencies - currency of regulated accounting.
//  AttributeName - String - the name of the Attribute that changed in the document.
//
Procedure RecalculateConversionParameters(Object, CurrencyOfComplianceAccounting, AttributeName) Export
	
	ConversionParameters_SSLy = InitializeConversionParameters();
	FillPropertyValues(ConversionParameters_SSLy, Object);
	ConversionParameters_SSLy.CurrencyOfComplianceAccounting = CurrencyOfComplianceAccounting;
	
	CalculateConversionParameters(ConversionParameters_SSLy, AttributeName);
	FillPropertyValues(Object, ConversionParameters_SSLy);
	
EndProcedure

// Returns the payee of the payment document for the business transaction.
// 
// Parameters:
//  Business Operation - Transfer link.Business operations - a business operation.
//  DocumentData - Structure - Document data.
// 
// Returns:
//  Array of CatalogRef.Counterparties, Undefined, CatalogRef.Counterparties, CatalogRef.Persons - The recipient of the business transaction.
Function PaymentBeneficiary(DocumentData) Export

	Recipient = Undefined;
	
	If DocumentData.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentData.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		Recipient = DocumentData.AdvanceHolder;
	ElsIf DocumentData.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentData.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentData.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		If DocumentData.PaymentMethod.Find(Enums.PaymentForms.BankAccountPayment) <> Undefined Then
			Recipient = Common.ObjectAttributeValue(DocumentData.BankAccountBeneficiary, "Owner");
		ElsIf DocumentData.PaymentMethod.Find(Enums.PaymentForms.CashAccountPayment_) <> Undefined Then
			Recipient = Common.ObjectAttributeValue(DocumentData.CashAccountRecipient, "Owner");
		EndIf;
		
	ElsIf DocumentData.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		And DocumentData.OperationWithSelfEmployedPerson = True Then
		Recipient = RecipientForSelfEmployedPaymentRequests(DocumentData);
	Else
		Recipient = DocumentData.Counterparty;
	EndIf;
	
	Return Recipient;

EndFunction

// Checks the Contract settlement procedure and clears inappropriate values
// 
// Parameters:
//  DocumentData - DocumentObject, FormDataStructure - Payment document
//  RowID - Number - ID of the Cur line of the payment decryption
Procedure CheckFillOutContract(DocumentData, RowID = Undefined) Export
	
	If Not ThisIsBusinessTransactionOfPaymentBySettlement(DocumentData.BusinessOperation) Then
		Return;
	EndIf;
	
	AmountUnallocated = UnallocatedPaymentBalance(DocumentData);
	
	If AmountUnallocated = 0 Then
		If DocumentData.ARAPDetails.Count() >= 1 Then
			ArrayOfCalculationObjects_ = DocumentData.ARAPDetails.Unload(,"ARAPObject").UnloadColumn("ARAPObject");
			ArrayOfCalculationObjects_ = CommonClientServer.CollapseArray(ArrayOfCalculationObjects_);
			SetPrivilegedMode(True);
			ContractsOfARAPObjects = Common.ObjectsAttributeValue(
				ArrayOfCalculationObjects_,
				"Contract");
			ArrayOfContracts = TMCommonUseClientServer.ConvertMatchOrStructureToArray(ContractsOfARAPObjects, False);
			// If there are empty calculation objects, then the Contract in the header does not need to be filled in with the only one filled in, add an empty contract to the array
			For Each ARAPObject In ArrayOfCalculationObjects_ Do
				If Not ValueIsFilled(ARAPObject) Then
					ArrayOfContracts.Add(EmptyValueOfContractOfOperation(DocumentData.BusinessOperation));
				EndIf;
			EndDo;
			ArrayOfContracts = CommonClientServer.CollapseArray(ArrayOfContracts);
			ARAPObjectSettingsForContracts = Common.ObjectsAttributeValue(
				ArrayOfContracts,
				"ARAPObjectSettings");
			SetPrivilegedMode(False);
			
			If ArrayOfContracts.Count() = 1 Then
				
				SettlementProcedureOfContract = 
					?(DocumentData.Contract = Undefined,
					Enums.ARAPObjectSettings.EmptyRef(),
					Common.ObjectAttributeValue(DocumentData.Contract, "ARAPObjectSettings"));
				
				If ValueIsFilled(ArrayOfContracts[0])
					Or (Not ValueIsFilled(ArrayOfContracts[0])
					And (SettlementProcedureOfContract = Enums.ARAPObjectSettings.ByCounterpartyContracts
					Or SettlementProcedureOfContract = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)) Then
					DocumentData.Contract = ArrayOfContracts[0];
				EndIf;
				
			ElsIf DocumentData.DocumentAmount <> 0 Then 
				DocumentData.Contract = Undefined;
			EndIf;
			
			If RowID <> Undefined Then 
				DecryptionString = DocumentData.ARAPDetails.FindByID(RowID);
				SetPrivilegedMode(True);
				SettlementProcedureOfContract = 
					?(DecryptionString.Contract = Undefined,
					Enums.ARAPObjectSettings.EmptyRef(),
					Common.ObjectAttributeValue(DecryptionString.Contract, "ARAPObjectSettings"));
				SetPrivilegedMode(False);
				If (ContractsOfARAPObjects[DecryptionString.ARAPObject] <> DecryptionString.Contract
					Or Not ValueIsFilled(DecryptionString.ARAPObject))
					And (SettlementProcedureOfContract = Enums.ARAPObjectSettings.ByCounterpartyContracts
						Or SettlementProcedureOfContract = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) Then
					// If one Contract was filled in in the other lines, then you need to clear the header Contract
					If ArrayOfContracts.Count() = 1
						And Not ValueIsFilled(ArrayOfContracts[0]) Then
						DocumentData.Contract = Undefined;
					EndIf;
					// Let's clear the Contract in the tabular part
					DecryptionString.Contract = Undefined;
				EndIf;
			EndIf;
		EndIf;
	Else
		ARAPObjects = ARAPObjectsServer.AllObjectsAreCalculatedByReference(DocumentData.Ref);
		If ValueIsFilled(DocumentData.Contract) Then
			SetPrivilegedMode(True);
			SettlementProcedureOfContract = Common.ObjectAttributeValue(DocumentData.Contract, "ARAPObjectSettings");
			SetPrivilegedMode(False);
			If SettlementProcedureOfContract = Enums.ARAPObjectSettings.ByCounterpartyContracts
				Or SettlementProcedureOfContract = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
				DocumentData.Contract = Undefined;
				If RowID <> Undefined Then
					DecryptionString = DocumentData.ARAPDetails.FindByID(RowID);
					If Not ValueIsFilled(DecryptionString.ARAPObject)
						Or ARAPObjects.Find(DecryptionString.ARAPObject) <> Undefined Then
						DecryptionString.Contract = Undefined;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If RowID <> Undefined Then
			DecryptionString = DocumentData.ARAPDetails.FindByID(RowID);
			If ValueIsFilled(DecryptionString.Contract) Then
				SetPrivilegedMode(True);
				SettlementProcedureOfContract = Common.ObjectAttributeValue(DecryptionString.Contract, "ARAPObjectSettings");
				SetPrivilegedMode(False);
				If (Not ValueIsFilled(DecryptionString.ARAPObject) 
					Or ARAPObjects.Find(DecryptionString.ARAPObject) <> Undefined)
						And (SettlementProcedureOfContract = Enums.ARAPObjectSettings.ByCounterpartyContracts
							Or SettlementProcedureOfContract = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) Then
						DecryptionString.Contract = Undefined;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Checks settlement objects and payment grounds for compliance with the selected Contract
// 
// Parameters:
//  DocumentData - DocumentObject, FormDataCollection - Payment document
//  RowID - Number - ID of the Cur line of the payment decryption
//  
// Returns:
//  Array of Number - indexes of rows where calculation objects have changed
Function CheckFillInARAPObject(DocumentData, RowID = Undefined) Export
	
	ModifiedRows = New Array;
	
	If Not ThisIsBusinessTransactionOfPaymentBySettlement(DocumentData.BusinessOperation) Then
		Return ModifiedRows;
	EndIf;
	
	Contract = DocumentData.Contract;
	If RowID <> Undefined Then
		Contract = DocumentData.ARAPDetails.FindByID(RowID).Contract;
	EndIf;
	If ValueIsFilled(Contract) Then
		
		SettlementProcedureOfContract = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings");
		If SettlementProcedureOfContract = Enums.ARAPObjectSettings.ByCounterpartyContracts
			Or SettlementProcedureOfContract = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			
			TheseAreSettlementsWithCustomers = DocumentData.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
			                       Or DocumentData.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer;
			AdditionalSearchCriteria_1 = ARAPObjectsServer.AdditionalSearchCriteria_1();
			AdditionalSearchCriteria_1.ReturnFirstOne = True;
			AdditionalSearchCriteria_1.Counterparty = DocumentData.Counterparty;
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(
				Contract,
				DocumentData.Organization,
				?(TheseAreSettlementsWithCustomers, Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, Enums.PartnersARAPAccountingTypes.VendorARAPAccounting));
			If ValueIsFilled(ARAPObjectContract) Then
				APARObjectDetails = Common.ObjectAttributesValues(ARAPObjectContract, "Object, Organization, Partner, ARAPCurrency");
				APARObjectDetails.Insert("PaymentPurpose", APARObjectDetails.Object);
				APARObjectDetails.Insert("Contract", APARObjectDetails.Object);
				APARObjectDetails.Insert("CalculationObject", APARObjectDetails.Object);
				APARObjectDetails.Insert("TheCalculationObjectMatchesTheDocument", False);
				
				If RowID <> Undefined Then
					DecryptionString = DocumentData.ARAPDetails.FindByID(RowID);
					DecryptionString.ARAPObject = ARAPObjectContract;
					FillPropertyValues(DecryptionString, APARObjectDetails);
					ModifiedRows.Add(DocumentData.ARAPDetails.IndexOf(DecryptionString));
				Else
					ARAPObjects = ARAPObjectsServer.AllObjectsAreCalculatedByReference(DocumentData.Ref);
					For Each DecryptionString In DocumentData.ARAPDetails Do
						If Not ValueIsFilled(DecryptionString.ARAPObject)
							Or ARAPObjects.Find(DecryptionString.ARAPObject) <> Undefined Then
							DecryptionString.ARAPObject = ARAPObjectContract;
							ModifiedRows.Add(DocumentData.ARAPDetails.IndexOf(DecryptionString));
							FillPropertyValues(DecryptionString, APARObjectDetails);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			
		ElsIf RowID = Undefined Then 
		// we have selected a Contract through an additional form - we check the calculation objects of all lines
			
			AmountUnallocated = UnallocatedPaymentBalance(DocumentData);
			
			If AmountUnallocated = 0 Then
				
				ContractsOfARAPObjects = Common.ObjectsAttributeValue(
					DocumentData.ARAPDetails.Unload(, "ARAPObject").UnloadColumn("ARAPObject"),
					"Contract");
				
				For Each DecryptionString In DocumentData.ARAPDetails Do
					If ContractsOfARAPObjects[DecryptionString.ARAPObject] <> DocumentData.Contract Then
						DecryptionString.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
						ModifiedRows.Add(DocumentData.ARAPDetails.IndexOf(DecryptionString));
						If TMCommonUse.ThereArePropsForPartOfObject("PaymentPurpose", DocumentData.Ref.Metadata(), "ARAPDetails") Then
							DecryptionString.PaymentPurpose = Undefined;
						EndIf;
						If CommonClientServer.HasAttributeOrObjectProperty(DecryptionString, "CalculationObject") Then
							DecryptionString.CalculationObject = DocumentData.Ref;
							DecryptionString.TheCalculationObjectMatchesTheDocument = True;
						EndIf;
					EndIf;
				EndDo;
				
			ElsIf TMCommonUse.ThereArePropsForPartOfObject("PaymentPurpose", DocumentData.Ref.Metadata(), "ARAPDetails") Then
			// If the document contains a payment basis with a non-conforming Contract, then this payment basis is cleared
				
				PaymentBaseObjects = New Array;
				ARAPObjects = ARAPObjectsServer.AllObjectsAreCalculatedByReference(DocumentData.Ref);
				For Each DecryptionString In DocumentData.ARAPDetails Do
					
					If (Not ValueIsFilled(DecryptionString.ARAPObject)
						Or ARAPObjects.Find(DecryptionString.ARAPObject) <> Undefined)
						And ValueIsFilled(DecryptionString.PaymentPurpose) Then
						
						If TypeOf(DecryptionString.PaymentPurpose) = Type("CatalogRef.CounterpartyContracts") 
							Or TypeOf(DecryptionString.PaymentPurpose) = Type("CatalogRef.IntercompanyContracts")
							And DecryptionString.PaymentPurpose <> DocumentData.Contract Then
							DecryptionString.PaymentPurpose = Undefined 
						ElsIf Common.HasObjectAttribute("Contract" ,DecryptionString.PaymentPurpose.Metadata()) Then
							PaymentBaseObjects.Add(DecryptionString.PaymentPurpose);
						EndIf;
						
					EndIf;
					
				EndDo;
				
				ContractsOfGrounds = Common.ObjectsAttributeValue(PaymentBaseObjects, "Contract");
				
				For Each DecryptionString In DocumentData.ARAPDetails Do
					If (Not ValueIsFilled(DecryptionString.ARAPObject)
						Or ARAPObjects.Find(DecryptionString.ARAPObject) <> Undefined)
						And ValueIsFilled(DecryptionString.PaymentPurpose)
						And ContractsOfGrounds[DecryptionString.PaymentPurpose] <> Undefined
						And ContractsOfGrounds[DecryptionString.PaymentPurpose] <> DocumentData.Contract Then
						DecryptionString.PaymentPurpose = Undefined;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	ElsIf RowID <> Undefined Then
		
		DecryptionString = DocumentData.ARAPDetails.FindByID(RowID);
		DecryptionString.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		ModifiedRows.Add(DocumentData.ARAPDetails.IndexOf(DecryptionString));
		If TMCommonUse.ThereArePropsForPartOfObject("PaymentPurpose", DocumentData.Ref.Metadata(), "ARAPDetails") Then
			DecryptionString.PaymentPurpose = Undefined;
		EndIf;
		If CommonClientServer.HasAttributeOrObjectProperty(DecryptionString, "CalculationObject") Then
			DecryptionString.CalculationObject = DocumentData.Ref;
			DecryptionString.TheCalculationObjectMatchesTheDocument = True;
		EndIf;
		
	ElsIf DocumentData.ARAPDetails.Count() = 1 Then
		
		DocumentData.ARAPDetails[0].ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		ModifiedRows.Add(0);
		If TMCommonUse.ThereArePropsForPartOfObject("PaymentPurpose", DocumentData.Ref.Metadata(), "ARAPDetails") Then
			DocumentData.ARAPDetails[0].PaymentPurpose = Undefined;
		EndIf;
		If CommonClientServer.HasAttributeOrObjectProperty(DocumentData.ARAPDetails[0], "CalculationObject") Then
			DocumentData.ARAPDetails[0].CalculationObject = DocumentData.Ref;
			DocumentData.ARAPDetails[0].TheCalculationObjectMatchesTheDocument = True;
		EndIf;
		
	EndIf;
	
	Return ModifiedRows;
	
EndFunction

// Clears the value of the details of the application for the use of monetary funds in the header and tabular part of the "Decryption of payment" document.
//
// Parameters:
//  DocumentObject - FormDataStructure - the document in which the field is being cleared.
//  ClearInDecryption - Boolean - the indication of clearing the field in the tabular part of the Payment description.
//
Procedure ClearApplicationForSpendingMoney(DocumentObject, ClearInDecryption = True) Export

	DocumentObject.PaymentRequest = Undefined;
	
	If ClearInDecryption Then
		
		For Each DecryptionString In DocumentObject.ARAPDetails Do
			DecryptionString.PaymentRequest = Undefined;
		EndDo;
		
	EndIf;

EndProcedure

// Clears the value of the account object in the tabular part of the "Payment decryption" document when changing 
// interrelated details.
//
// Parameters:
//  DocumentObject - FormDataStructure - the document in which the field is being cleared.
//  DecryptionString - FormDataCollection - the row of the table part in which the cleanup is performed.
//
Procedure ClearCalculationObject(DocumentObject, DecryptionString) Export

	If ValueIsFilled(DecryptionString.ARAPObject)
		And DecryptionString.CalculationObject = DocumentObject.Ref Then
		DecryptionString.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
	EndIf;

EndProcedure

// Calculates the value for filling in the "Activity Direction" Attribute in the payment document. The value depends on the value 
// of the Attribute "Business operation" and "Direction of activity" of the original.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//  LineOfBusiness - CatalogRef.LinesOfBusiness - The initial direction of activity.
//
// Returns:
//  CatalogRef.LinesOfBusiness
//
Function LineOfBusiness(BusinessOperation, LineOfBusiness) Export

	SettingEnabled = True;
	
	If BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		SettingEnabled = Common.ObjectAttributeValue(LineOfBusiness, "VendorARAP");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		SettingEnabled = Common.ObjectAttributeValue(LineOfBusiness, "IncomeAccounting");
	EndIf;
	
	If ValueIsFilled(LineOfBusiness)
		And SettingEnabled Then
		Return LineOfBusiness;
	Else
		Return Catalogs.LinesOfBusiness.EmptyRef();
	EndIf;

EndFunction

// Returns the text of the message that was called when entering the payment document based on the counterparty's Contract, which does not need to be created.
//
// Parameters:
//  DocumentName3  - String - name of the payment document.
//  TargetOfContract  - EnumRef.ContractTypes - The target of the Contract.
//
// Returns:
//   String - message text.
//
Function TextAboutExclusionOfPaymentUnderContract(DocumentName3, TargetOfContract) Export

	Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập %1 trên cơ sở hợp đồng có mục tiêu ""%2""';
					|ru = 'Не требуется вводить %1 на основании договора, цель которого ""%2""';
					|en = 'It is not required to generate %1 based on the contract whose scope is ""%2""'; fa = 'It is not required to generate %1 based on the contract whose scope is ""%2""';
					|it = 'Не требуется вводить %1 на основании договора, цель которого ""%2""';
					|pl = 'It is not required to generate %1 based on the contract whose scope is ""%2""';
					|tr = '""%2"" hedefli sözleşmeye göre %1 girmeye gerek yok'"),
				DocumentName3,
				TargetOfContract);

EndFunction

// Defines the bank account of the counterparty by default, excluding and taking into account the currency of the document.
//
// Parameters:
//  AccountOfCounterparty - CatalogRef.CounterpartyBankAccounts - The Cur account of the counterparty.
//  Counterparty - CatalogRef.Counterparties, CatalogRef.Persons - the counterparty by which the account is determined.
//  ListOfCurrencies - Array of CatalogRef.Currencies - list of possible currencies according to the document.
//  IndexOf - Number - Cur current index to search in the list of currencies.
//
Procedure DefaultCounterpartyBankAccount(AccountOfCounterparty, Counterparty, ListOfCurrencies, IndexOf = Undefined) Export
	
	If IndexOf = Undefined Then
		IndexOf = 0;
	EndIf;
	
	If IndexOf = ListOfCurrencies.Count() Then
		Return;
	EndIf;
	
	AccountOfCounterparty = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
		Counterparty, ListOfCurrencies[IndexOf]);
	
	If Not ValueIsFilled(AccountOfCounterparty) Then
		DefaultCounterpartyBankAccount(AccountOfCounterparty, Counterparty, ListOfCurrencies, IndexOf + 1);
	EndIf;
	
EndProcedure

// Checks whether the form fields are available or prohibited from being displayed for currency payments.
//
// Parameters:
//  Form - ClientApplicationForm - object form.
//
Procedure DetermineCurrencyPayment(Form) Export
	
	Object = Form.Object;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or Object.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
		Form.CurrencyPayment = False;
	Else
		Form.CurrencyPayment = True;	
	EndIf;
	
EndProcedure

// Fills in the settlement rate in the payment decryption line.
// 
// Parameters:
//  Object - FormDataCollection - the document in which the filling is performed.
//  LocalAccountingCurrency - CatalogRef.Currencies - Currency of regulated accounting.
//  DateOfCourse - Date - the date on which the course will be calculated.
//  DecryptionString - FormDataCollectionItem - The decryption string in the document.
//
Procedure FillInCourseOfMutualSettlementsOfDecryptionLine(Object, LocalAccountingCurrency, DateOfCourse, DecryptionString) Export

	FillParameters = CourseFillingAndMultiplicityParameters();
	FillPropertyValues(FillParameters, DecryptionString);
	
	If CommonClientServer.HasAttributeOrObjectProperty(Object, "ListOfCounterparties_")
		And Object.ListOfCounterparties_
		// If the Contract is filled in in the decryption line, then we take it, if not, from the header
		Or ValueIsFilled(FillParameters.Contract) Then
		FillPropertyValues(FillParameters, Object, "Currency");
	Else
		FillPropertyValues(FillParameters, Object, "Currency, Contract");
	EndIf;
	
	FillParameters.Insert("LocalAccountingCurrency", LocalAccountingCurrency);
	FillParameters.Insert("Date", DateOfCourse);
	
	FillInCourseAndMultiplicityInDecryptionLine(DecryptionString, FillParameters);

EndProcedure

// List of business of operations available for the foundation document.
//
// Parameters:
//  DocumentBasis - DocumentRef, CatalogRef - the basis on which the document was created.
//  PaymentMethod - EnumRef.PaymentForms - Payment form for the document.
//  TransactionList - ValueList of EnumRef.BusinessTransactions, Undefined - available of operations by base.
//
Procedure GetAvailableBusinessOfOperationsBasedOn(DocumentBasis, PaymentMethod, TransactionList = Undefined) Export
	
	If TransactionList = Undefined Then
		TransactionList = New ValueList;
	EndIf;
	
	If ValueIsFilled(DocumentBasis) Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(DocumentBasis, "BusinessOperation") Then
			BaseOperation = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(DocumentBasis, "RegistrationOption") Then
			BaseOperation = Common.ObjectAttributeValue(DocumentBasis, "RegistrationOption");
		Else
			BaseOperation = Enums.BusinessTransactions.EmptyRef();
		EndIf;
		
		If BaseOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
			Or BaseOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
			
			TransactionList.Add(Enums.BusinessTransactions.RefundToCustomer);
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent
			Or BaseOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
			Or BaseOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
			
			TransactionList.Add(Enums.BusinessTransactions.RefundToCustomer);
			TransactionList.Add(Enums.BusinessTransactions.OtherCashIssue);
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.PurchaseFromSupplier
			Or BaseOperation = Enums.BusinessTransactions.PurchaseByImport
			Or BaseOperation = Enums.BusinessTransactions.ImportFromEAEU
			Or BaseOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
			Or BaseOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
			Or BaseOperation = Enums.BusinessTransactions.ImportGoodsInTransit 
			Or BaseOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
			Or BaseOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
			Or BaseOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
			Or BaseOperation = Enums.BusinessTransactions.ConsignmentProcurement
			Or BaseOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
			Or BaseOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage
			Or BaseOperation = Enums.BusinessTransactions.ReceiptOfFinancialDocumentsFromVendor
			Or BaseOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
			Or BaseOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses Then
			
			TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
			

		ElsIf BaseOperation = Enums.BusinessTransactions.ProductionByToller2_5
			Or BaseOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5
			Or BaseOperation = Enums.BusinessTransactions.RenderRentalServices Then
			TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
		
		ElsIf BaseOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or BaseOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or BaseOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
			Or BaseOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or BaseOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
			TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
		ElsIf BaseOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			Or BaseOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
			
			TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			
			TransactionList.Add(Enums.BusinessTransactions.RefundToCustomer);
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
			
			TransactionList.Add(Enums.BusinessTransactions.RefundToCustomer);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.RegisterCCDUnassisted Then 
			
			If PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
				TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
			Else
				TransactionList.Add(Enums.BusinessTransactions.CustomsPayment);
			EndIf;
			
		ElsIf BaseOperation = Enums.BusinessTransactions.RegisterCCDThroughBroker Then
			
			TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer
			Or BaseOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
			
			TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
			TransactionList.Add(Enums.BusinessTransactions.RefundToCustomer);
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn Then
			
			If TheseAreSettlementsBetweenOrganizationsThroughSeparateCounterparty(DocumentBasis) Then
				TransactionList.Add(Enums.BusinessTransactions.RefundToCustomer);
			Else
				TransactionList.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
			EndIf;
			
		ElsIf BaseOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany Then
			
			If TheseAreSettlementsBetweenOrganizationsThroughSeparateCounterparty(DocumentBasis) Then
				TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
			Else
				TransactionList.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
			EndIf;
			
		ElsIf BaseOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany Then
			
			TransactionList.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.VATIsAccruedByTaxAgent Then
			
			TransactionList.Add(Enums.BusinessTransactions.TransferOfTaxesAndContributions);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount
			Or BaseOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
			Or BaseOperation = Enums.BusinessTransactions.CustomsPayment
			Or BaseOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
			Or BaseOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
			Or BaseOperation = Enums.BusinessTransactions.PaymentToLessor
			Or BaseOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
			Or BaseOperation = Enums.BusinessTransactions.TransferToDeposits
			Or BaseOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
			Or BaseOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
			Or BaseOperation = Enums.BusinessTransactions.CurrencyConversion
			Or BaseOperation = Enums.BusinessTransactions.OtherCashIssue
			Or BaseOperation = Enums.BusinessTransactions.RefundToCustomer
			Or BaseOperation = Enums.BusinessTransactions.RefundToAnotherCompany
			Or BaseOperation = Enums.BusinessTransactions.RefundAcquiringPayment Then
			
			TransactionList.Add(BaseOperation);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
			
			TransactionList.Add(BaseOperation);
			TransactionList.Add(Enums.BusinessTransactions.CashReturnByAdvanceHolder);
			TransactionList.Add(Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.SalaryPayment Then
			
			If CommonClientServer.HasAttributeOrObjectProperty(DocumentBasis, "PayrollTransaction") Then
				TransactionList.Add(Common.ObjectAttributeValue(DocumentBasis, "PayrollTransaction"));
			EndIf;
			
		ElsIf BaseOperation = Enums.BusinessTransactions.CashCollectionToBank Then
			
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
			
			TransactionList.Add(BaseOperation);
			TransactionList.Add(Enums.BusinessTransactions.CashCollectionFromBank);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor
			Or BaseOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor
			Or BaseOperation = Enums.BusinessTransactions.ReturnOfCashEquivalentsToVendor Then
			
			TransactionList.Add(Enums.BusinessTransactions.RefundFromVendor);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then
			
			TransactionList.Add(Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram Then
			
			TransactionList.Add(Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount Then
			
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromAnotherAccount);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
			
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			
			TransactionList.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.PaymentToVendor Then
			
			TransactionList.Add(BaseOperation);
			TransactionList.Add(Enums.BusinessTransactions.RefundFromVendor);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.SaleToCustomer
			Or BaseOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			Or BaseOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or BaseOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
			Or BaseOperation = Enums.BusinessTransactions.RedemptionOfGoodsByCustodian
			Or BaseOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller Then
			
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount Then
			
			TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount);
			
		ElsIf BaseOperation = Enums.BusinessTransactions.EmptyRef() Then
			
			BasisType = TypeOf(DocumentBasis);
			
			If BasisType = Type("DocumentRef.ConsignmentReportFromCustomer") Then
				
				TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
				TransactionList.Add(Enums.BusinessTransactions.RefundToCustomer);
			ElsIf BasisType = Type("DocumentRef.ReceivingLeaseServices") Then
				TransactionList.Add(Enums.BusinessTransactions.PaymentToLessor);
			ElsIf BasisType = Type("DocumentRef.CommissionReportIntercompany")
				Or BasisType = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
				
				If TheseAreSettlementsBetweenOrganizationsThroughSeparateCounterparty(DocumentBasis) Then
					TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
				Else
					TransactionList.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
				EndIf;
				
			ElsIf BasisType = Type("DocumentRef.ConsignmentReportToVendor")
				Or BasisType = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
				
				TransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
				TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
				
			ElsIf BasisType = Type("DocumentRef.ExpenseReport") Then
				
				TransactionList.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder);
				TransactionList.Add(Enums.BusinessTransactions.OtherCashIssue);
				
			ElsIf BasisType = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer")
				Or BasisType = Type("DocumentRef.CustomerInvoiceServices")
				Or BasisType = Type("DocumentRef.CustomerCommercialInvoice") Then
				
				TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
				
			ElsIf BasisType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
				TransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
			

			EndIf;
			
		EndIf;
		
	EndIf;
	
	CashServerLocalization.GetAvailableBusinessOfOperationsBasedOn(DocumentBasis, TransactionList);
	
EndProcedure

// Returns an empty Contract value for a business transaction.
//
// Parameters:
//  Operation - EnumRef.BusinessTransactions - economic operation.
// 
// Returns:
//  CatalogRef.IntercompanyContracts, CatalogRef.CounterpartyContracts - Contract.
//
Function EmptyValueOfContractOfOperation(Operation) Export

	If Operation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or Operation = Enums.BusinessTransactions.RefundFromAnotherCompany
		Or Operation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Operation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		Return Catalogs.IntercompanyContracts.EmptyRef();
	Else
		Return Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;

EndFunction

// Returns the unit that initiated the Registering Recording of funds.
//
// Parameters:
//  DocumentReferences - DocumentRef.CashTransferReferenceOrder - an order for the issuance of cash.
//  CashAccountRecipient - CatalogRef.CashAccounts - Cash account cash recipient
//
// Returns:
//   CatalogRef.BusinessStructure - the initiator division.
//
Function InitiatorOfCashWithdrawal(DocumentReferences, CashAccountRecipient) Export

	If ValueIsFilled(DocumentReferences) Then
		
		Department = Common.ObjectAttributeValue(DocumentReferences, "Department");
		
		If Not ValueIsFilled(Department) Then
			Department = Common.ObjectAttributeValue(CashAccountRecipient, "Department");
		EndIf;
		
	Else
		Department = Common.ObjectAttributeValue(CashAccountRecipient, "Department");
	EndIf;
	
	Return Department;

EndFunction

// Clears the column "Contract" in the tabular part "Decryption of the payment", where the document itself is the "payment object" and if the Contract
// in the header of the document is not filled in. The payment AR/AP object is the document itself.
//
// Parameters:
//  Object - FormDataStructure - the document in which the Contract is being cleared.
//  RowID - Number, Undefined - the line in which the Contract needs to be cleared.
//
Procedure ClearPaymentDecryptionContract(Object, RowID = Undefined) Export
	
	If ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	If RowID = Undefined Then
		
		For Each DecryptionString In Object.ARAPDetails Do
			ClearContractInPaymentDecryptionLine(Object, DecryptionString);
		EndDo
		
	Else
		
		DecryptionString = Object.ARAPDetails.FindByID(RowID);
		ClearContractInPaymentDecryptionLine(Object, DecryptionString);
		
	EndIf;
	
EndProcedure

// Fills in the data of the Contract document form and the Contract credentials.
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//  ContractDetails_ - See Catalogs.CounterpartyContracts.AccountingInformationUnderAgreement.
//
Procedure FillInDataOfDocumentFormByContract(Form, ContractDetails_) Export

	Object = Form.Object;
	
	Form.CounterpartyContract = Object.Contract;
	Form.AccountingInformationOfContract = Catalogs.CounterpartyContracts.AccountingInformationUnderAgreement(Form.CounterpartyContract);
	
	If ContractDetails_ = Undefined Then
		
		ContractDetails_ = New Structure;
		
		If ValueIsFilled(Form.AccountingInformationOfContract) Then
			ContractDetails_ = Common.CopyRecursive(Form.AccountingInformationOfContract);
			// If the Cash flow Item in the Contract is not filled in, the empty value is not transferred to the billing.
			If ContractDetails_.Property("CashFlowItem")
				And Not ValueIsFilled(ContractDetails_.CashFlowItem) Then
				ContractDetails_.Delete("CashFlowItem");
			EndIf;
		ElsIf TypeOf(Object.Contract) = Type("CatalogRef.IntercompanyContracts") Then
			ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "ARAPCurrency, ContractRateOption, LineOfBusiness, VATRate");
		EndIf;
		
	EndIf;

EndProcedure

// Recalculates the amount to the amount in the sender's currency in the payment transcript and fills in the Attributes 
// "Amounts in the sender's currency" and "VAT amount in the sender's currency".
// 
// Parameters:
//  DocumentObject - FormDataStructure, DocumentObject.BankAccountIssue - Payment AR/AP transaction with conversion on the side of the bank of the sender of the payment.
//  SenderSCurrency - CatalogRef.Currencies, Undefined - The currency of the payment sender.
//  ConversionFactor_ - Number - The conversion ratio to the sender's currency.
//
Procedure CalculateAmountsInSenderSCurrencyInDecryption(DocumentObject, SenderSCurrency = Undefined, ConversionFactor_ = 0) Export

	If DocumentObject.PaymentWithConversion Then
		
		If Not ValueIsFilled(SenderSCurrency) Then
			SenderSCurrency = Common.ObjectAttributeValue(DocumentObject.BankAccount, "CashCurrency");
		EndIf;
		
		If ConversionFactor_ = 0 Then
			ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
				DocumentObject.Currency,
				SenderSCurrency,
				?(DocumentObject.ProcessedByBank, DocumentObject.BankPostingDate, DocumentObject.Date));
		EndIf;
		
		AmountsInRecipientSCurrency = DocumentObject.ARAPDetails.Unload(, "LineNumber, Sum, VATAmount");
		AmountTotal = AmountsInRecipientSCurrency.Total("Sum");
		VATAmount_Total = AmountsInRecipientSCurrency.Total("VATAmount");
		
		SumCoefficients = New Array;
		CoefficientsOfVATAmount = New Array;
		
		For Each SumString In AmountsInRecipientSCurrency Do
				
			If AmountTotal <> 0 Then
				SumCoefficients.Add(SumString.Sum / AmountTotal);
			EndIf;
			
			If VATAmount_Total <> 0 Then
				CoefficientsOfVATAmount.Add(SumString.VATAmount / VATAmount_Total);
			EndIf;
			
		EndDo;
		
		If SumCoefficients.Count() = 0 Then
			SumCoefficients.Add(1);
		EndIf;
		
		If CoefficientsOfVATAmount.Count() = 0 Then
			CoefficientsOfVATAmount.Add(1);
		EndIf;
		
		ListOfAmounts = Common.DistributeAmountInProportionToCoefficients(
			Round(AmountTotal * ConversionFactor_, 2), SumCoefficients);
		ListOfVATAmounts = Common.DistributeAmountInProportionToCoefficients(
			Round(VATAmount_Total * ConversionFactor_, 2), CoefficientsOfVATAmount);
			
		For Each AmmountLine In AmountsInRecipientSCurrency Do
			
			DecryptionString = DocumentObject.ARAPDetails.Get(AmountsInRecipientSCurrency.IndexOf(AmmountLine));
			
			If ListOfAmounts <> Undefined Then 
				
				If SenderSCurrency = DecryptionString.ARAPCurrency
					And DecryptionString.AmountARAP <> 0 Then
					DecryptionString.AmountInPayerSCurrency = DecryptionString.AmountARAP;
				Else
					DecryptionString.AmountInPayerSCurrency = ListOfAmounts[AmountsInRecipientSCurrency.IndexOf(AmmountLine)];
				EndIf;
				
			EndIf;
			
			If ListOfVATAmounts <> Undefined Then
				DecryptionString.VATAmountInPayerSCurrency = ListOfVATAmounts[AmountsInRecipientSCurrency.IndexOf(AmmountLine)];
			EndIf;
			
		EndDo;
		
	Else
		
		For Each DecryptionString In DocumentObject.ARAPDetails Do
			
			DecryptionString.AmountInPayerSCurrency = 0;
			DecryptionString.VATAmountInPayerSCurrency = 0;
			
		EndDo;
	
	EndIf;

EndProcedure

// Returns the correspondence of the bank Attributes in the bank account with the Attributes of the bank classifier.
// 
// Returns:
//  Map of KeyAndValue - Account Details By Bank Classifier:
//  *Key - String - the name of the Attribute in the invoice.
//  *Value - String - the name of the Attribute in the classifier.
//
Function AccountDetailsByBankClassifier() Export
	
	ComplianceWithBankDetails = New Map;
	ComplianceWithBankDetails.Insert("BankBIC", "BIC");
	ComplianceWithBankDetails.Insert("BankSWIFTCode", "SWIFT");
	ComplianceWithBankDetails.Insert("BankCorrAccount", "CorrAccount");
	ComplianceWithBankDetails.Insert("BankDescription", "Description");
	ComplianceWithBankDetails.Insert("BankNameInt", "DescriptionInternational");
	ComplianceWithBankDetails.Insert("BankCity", "City");
	ComplianceWithBankDetails.Insert("BankCityInt", "CityInternationalFormat");
	ComplianceWithBankDetails.Insert("BankAddress", "Address");
	ComplianceWithBankDetails.Insert("BankAddressInt", "InternationalAddress");
	ComplianceWithBankDetails.Insert("BankPhones", "Phones");
	ComplianceWithBankDetails.Insert("TransferBankBIC", "BIC");
	ComplianceWithBankDetails.Insert("BankSWIFTCodeForPayments", "SWIFT");
	ComplianceWithBankDetails.Insert("TransferBankDescription", "Description");
	ComplianceWithBankDetails.Insert("BankNameForPaymentsInt", "DescriptionInternational");
	ComplianceWithBankDetails.Insert("TransferBankCorrAccount", "CorrAccount");
	ComplianceWithBankDetails.Insert("TransferBankCity", "City");
	ComplianceWithBankDetails.Insert("BankCityForPaymentsInt", "CityInternationalFormat");
	ComplianceWithBankDetails.Insert("TransferBankAddress", "Address");
	ComplianceWithBankDetails.Insert("BankAddressForPaymentInt", "InternationalAddress");
	ComplianceWithBankDetails.Insert("TransferBankPhones", "Phones");
	
	Return ComplianceWithBankDetails;
	
EndFunction

// Returns a list of Contract types that use the "Payment to supplier" operation (settlements with suppliers).
// 
// Returns:
//  Array of EnumRef.ContractTypes
Function TypesOfContractsForPaymentToSupplier() Export

	Result = New Array;
	Result.Add(Enums.ContractTypes.WithVendor);
	Result.Add(Enums.ContractTypes.WithConsignor);
	Result.Add(Enums.ContractTypes.TransferToTolling2_5);
	Result.Add(Enums.ContractTypes.SubcontractingToTheEAEUCountries);
	Result.Add(Enums.ContractTypes.Import);
	Result.Add(Enums.ContractTypes.PurchaseEAEU);
	Result.Add(Enums.ContractTypes.ReceivingForCustody);
	Result.Add(Enums.ContractTypes.ReceiptForTolling2_5);
	
	Return Result;

EndFunction

// Returns a list of Contract types that use the "Refund or other payment to the client" operation (settlements with clients).
// 
// Returns:
//  Array of EnumRef.ContractTypes
Function TypesOfRefundContracts() Export

	Result = New Array;
	Result.Add(Enums.ContractTypes.WithCustomer);
	Result.Add(Enums.ContractTypes.TransferToCustody);
	Result.Add(Enums.ContractTypes.CustomerInvoiceOutsourcedSale);
	
	Return Result;

EndFunction

// Creates a list of Forms of payment for applications by value.
//
// Parameters:
//  PaymentForms  - Array of EnumRef.PaymentForms, EnumRef.PaymentForms, Undefined - Forms of payment.
//
// Returns:
//   Array of EnumRef.PaymentForms
//
Function ValueOfRequestPaymentFormParameter(Val PaymentForms) Export

	If TypeOf(PaymentForms) <> Type("Array") Then
		PaymentForms = CommonClientServer.ValueInArray(PaymentForms);
	EndIf;
	
	If PaymentForms.Find(Enums.PaymentForms.EmptyRef()) = Undefined Then
		PaymentForms.Add(Enums.PaymentForms.EmptyRef());
	EndIf;
	
	Return PaymentForms;

EndFunction

// Returns an indication that the value of VAT taxation was received of operation of purchase or sale. 
// The list of acceptable types of VAT taxation is received and, if necessary, filled of operation (sale/purchase).
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject - The document is the object of payment.
//  DefaultVATTaxation - EnumRef.VATTaxationTypes - Default VAT taxation.
//  ElementVATTaxation - Undefined, FormField - The VAT taxation element on the form of the payment document.
//  ItemTaxationVATRefund - Undefined, FormField - The VAT refund taxation element is displayed on the payment document form.
// 
// Returns:
//  Boolean
Function FillInTaxationOfVATOnSalesPurchases(Object, DefaultVATTaxation, ElementVATTaxation = Undefined, ItemTaxationVATRefund = Undefined) Export

	DocumentType = TypeOf(Object.Ref);
	
	UseVATTaxationForBusinessOperations = False;
	WriteOffOfBusinessSalesOperations = GetListOfBusinessSalesOperationsForDocument(DocumentType);
	ListOfBusinessProcurementOperations = GetListOfPurchasingBusinessOperationsForDocument(DocumentType);
	
	If Not WriteOffOfBusinessSalesOperations.Find(Object.BusinessOperation) = Undefined Then
		
		ObjectManager = Common.ObjectManagerByRef(Object.Ref);
		FillParameters = ObjectManager.ParametersForFillingInSalesVATTaxation(Object);
		VATAccountingERP.FillInSalesVATTaxation(DefaultVATTaxation, FillParameters, Undefined);
		
		If ElementVATTaxation <> Undefined Then
			VATAccountingERP.FillInSalesVATTaxSelectionList(ElementVATTaxation, DefaultVATTaxation, FillParameters, Undefined);
		EndIf;
		
		If ItemTaxationVATRefund <> Undefined Then
			VATAccountingERP.FillInSalesVATTaxSelectionList(ItemTaxationVATRefund, DefaultVATTaxation, FillParameters, Undefined);
		EndIf;
		
		UseVATTaxationForBusinessOperations = True;
		
	ElsIf Not ListOfBusinessProcurementOperations.Find(Object.BusinessOperation) = Undefined Then
		
		ObjectManager = Common.ObjectManagerByRef(Object.Ref);
		FillParameters = ObjectManager.ParametersForFillingInVATTaxationPurchases(Object);
		VATAccountingERP.FillInVATTaxationPurchases(DefaultVATTaxation, FillParameters, Undefined);
		
		If ElementVATTaxation <> Undefined Then
			VATAccountingERP.FillInListOfVATTaxChoices(ElementVATTaxation, DefaultVATTaxation, FillParameters, Undefined);
		EndIf;
		
		If ItemTaxationVATRefund <> Undefined Then
			VATAccountingERP.FillInListOfVATTaxChoices(ItemTaxationVATRefund, DefaultVATTaxation, FillParameters, Undefined);
		EndIf;
		
		UseVATTaxationForBusinessOperations = True;
		
	EndIf;
	
	Return UseVATTaxationForBusinessOperations;

EndFunction

Procedure CalculateExchangeRateNumeratorOfMutualSettlementsInDecryptionLine(TSRow, DocumentCurrency, CurrencyOfComplianceAccounting) Export
	
	BasicCourseAccuracy = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
	
	If TSRow.ARAPCurrency = DocumentCurrency Then
		
		TSRow.ExchangeRateNumeratorOfMutualSettlements = 1;
		
	ElsIf DocumentCurrency = CurrencyOfComplianceAccounting Then
		
		If TSRow.AmountARAP <> 0 Then
			TSRow.ExchangeRateNumeratorOfMutualSettlements = Round(TSRow.Sum / TSRow.AmountARAP * TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements, BasicCourseAccuracy);
		Else
			TSRow.ExchangeRateNumeratorOfMutualSettlements = 1;
		EndIf;
	Else
		CourseAccuracy = ?(TSRow.ARAPCurrency = CurrencyOfComplianceAccounting, BasicCourseAccuracy, 8);
		If TSRow.Sum <> 0 Then
			TSRow.ExchangeRateNumeratorOfMutualSettlements = Round(TSRow.AmountARAP / TSRow.Sum * TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements, CourseAccuracy);
		Else
			TSRow.ExchangeRateNumeratorOfMutualSettlements = 0;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FormCourseDenominatorByText(TSRow, DocumentCurrency, CurrencyOfComplianceAccounting) Export
	
	BasicCourseAccuracy = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
	
	MultiplicityPattern = NStr("vi = '%1 trong %2 %3';
								|ru = '%1 за %2 %3';
								|en = '%1 for %2 %3'; fa = '%1 for %2 %3';
								|it = '%1 per %2 %3';
								|pl = '%1 za %2 %3';
								|tr = '%1 %2 %3 için'");
	If DocumentCurrency = CurrencyOfComplianceAccounting Then
		TSRow.CourseDenominatorOfMutualSettlementsInscription = StrTemplate(MultiplicityPattern,
			DocumentCurrency, TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements, TSRow.ARAPCurrency);
	Else
		TSRow.CourseDenominatorOfMutualSettlementsInscription = StrTemplate(MultiplicityPattern,
			TSRow.ARAPCurrency, TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements, DocumentCurrency);
	EndIf;
	
	CourseTemplate = "%1 %2 = %3 %4";
	If TSRow.ExchangeRateNumeratorOfMutualSettlements <> 0 Then
		If DocumentCurrency = CurrencyOfComplianceAccounting Then
			
			FormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
			TSRow.CourseNumeratorOfMutualSettlementsText = StrTemplate(CourseTemplate,
				TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				TSRow.ARAPCurrency,
				String(Format(TSRow.ExchangeRateNumeratorOfMutualSettlements, FormatString)),
				DocumentCurrency);
		Else
			If TSRow.ARAPCurrency = CurrencyOfComplianceAccounting Then
				FormatString = StrTemplate("NFD=%1", BasicCourseAccuracy);
			Else
				FormatString = "NFD=8";
			EndIf;
			TSRow.CourseNumeratorOfMutualSettlementsText = StrTemplate(CourseTemplate,
				TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				DocumentCurrency,
				String(Format(TSRow.ExchangeRateNumeratorOfMutualSettlements, FormatString)),
				TSRow.ARAPCurrency);
		EndIf;
	Else
		TSRow.CourseNumeratorOfMutualSettlementsText = "0";
	EndIf;
	
EndProcedure

// Generates the name of the payer or payee in the payment order.
//
// Parameters:
//   Description - String - name of the payer or recipient.
//   DirectCalculations - Boolean - indicates payments without a correspondent bank.
//   AccountNumber - String - account number of the payer or recipient
//   Bank - String - name of the correspondent bank of the payer's or recipient's account.
//   City - String - the city of the correspondent bank.
//
// Returns:
//   String - generated name of the payer or payee
//
Function NameOfPayerPayee(Description, DirectCalculations, AccountNumber, Bank, City) Export

	If DirectCalculations Then
		Result = Description;
	Else
		
		If IsBlankString(AccountNumber) Then
			Result = Description;
		ElsIf IsBlankString(Bank) Then
			Result = StrTemplate(
				NStr("vi = '%1 tài khoản thanh toán %2';
					|ru = '%1 р/с %2';
					|en = '%1 account %2'; fa = '%1 account %2';
					|it = '%1 account %2';
					|pl = '%1 account %2';
					|tr = '%1 hesap no %2'"), Description, TrimAll(AccountNumber));
		ElsIf IsBlankString(City) Then
			Result = StrTemplate(
				NStr("vi = '%1 tài khoản thanh toán %2 trong %3';
					|ru = '%1 р/с %2 в %3';
					|en = '%1 account %2 in %3'; fa = '%1 account %2 in %3';
					|it = '%1 account %2 in %3';
					|pl = '%1 account %2 in %3';
					|tr = '%1 hesap no %2, banka %3'"), Description, TrimAll(AccountNumber), TrimAll(Bank));
		Else
			Result = StrTemplate(
				NStr("vi = '%1 tài khoản thanh toán %2 trong %3 %4';
					|ru = '%1 р/с %2 в %3 %4';
					|en = '%1 account %2 in %3 %4'; fa = '%1 account %2 in %3 %4';
					|it = '%1 account %2 in %3 %4';
					|pl = '%1 account %2 in %3 %4';
					|tr = '%1 hesap no %2, banka %3, şehir %4'"), Description, TrimAll(AccountNumber), TrimAll(Bank), TrimAll(City));
		EndIf;
		
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

#Region Private

// Returns a list of documents with their synonyms for the payment purpose
//
// Returns:
//  Structure - A structure with document names in its keys and synonyms in its values.
//
Function GetDocumentPresentations()

	TypesOfCounterpartyDocuments = New Structure;
	TypesOfCounterpartyDocuments.Insert("SalesOrder",                         NStr("vi = 'đơn hàng';
																					|ru = 'заказу';
																					|en = 'order'; fa = 'order';
																					|it = 'ordine';
																					|pl = 'order';
																					|tr = 'sipariş'"));
	TypesOfCounterpartyDocuments.Insert("PurchaseOrder",                      NStr("vi = 'đơn hàng';
																					|ru = 'заказу';
																					|en = 'order'; fa = 'order';
																					|it = 'ordine';
																					|pl = 'order';
																					|tr = 'sipariş'"));
	TypesOfCounterpartyDocuments.Insert("RequestForReturnOfGoodsFromCustomer",      NStr("vi = 'giấy đề nghị trả lại hàng';
																						|ru = 'заявке на возврат товаров';
																						|en = 'sales return request'; fa = 'sales return request';
																						|it = 'Domanda di restituzione della merce';
																						|pl = 'zgłoszeniu na zwrot towarów';
																						|tr = 'ürün iadesi başvurusu'"));
	TypesOfCounterpartyDocuments.Insert("ConsignmentReportFromCustomer",                    NStr("vi = 'bảng kê dành cho người đặt ký gửi';
																								|ru = 'отчету комитенту';
																								|en = 'consignment notification'; fa = 'consignment notification';
																								|it = 'al report del committente';
																								|pl = 'raportu dla komitenta';
																								|tr = 'konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("ConsignmentReportToVendor",                       NStr("vi = 'bảng kê dành cho người đặt ký gửi';
																								|ru = 'отчету комитенту';
																								|en = 'consignment notification'; fa = 'consignment notification';
																								|it = 'al report del committente';
																								|pl = 'raportu dla komitenta';
																								|tr = 'konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("PurchaseInvoiceConsignmentStockLost",              NStr("vi = 'bảng kê dành cho người đặt ký gửi';
																								|ru = 'отчету комитенту';
																								|en = 'consignment notification'; fa = 'consignment notification';
																								|it = 'al report del committente';
																								|pl = 'raportu dla komitenta';
																								|tr = 'konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("CommissionReportIntercompany",    NStr("vi = 'bảng kê dành cho người đặt ký gửi';
																				|ru = 'отчету комитенту';
																				|en = 'consignment notification'; fa = 'consignment notification';
																				|it = 'al report del committente';
																				|pl = 'raportu dla komitenta';
																				|tr = 'konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("CustomerInvoiceIntercompany",    NStr("vi = 'hóa đơn';
																				|ru = 'накладной';
																				|en = 'invoice'; fa = 'invoice';
																				|it = 'lettera di vettura';
																				|pl = 'invoice';
																				|tr = 'irsaliye'"));
	TypesOfCounterpartyDocuments.Insert("ConsumptionReportSubcontractingServicesDeliveredIntercompany",      NStr("vi = 'báo cáo dành cho người đặt ký gửi';
																													|ru = 'отчету давальцу';
																													|en = 'consumption report — subcontracting services delivered'; fa = 'consumption report — subcontracting services delivered';
																													|it = 'отчету давальцу';
																													|pl = 'consumption report — subcontracting services delivered';
																													|tr = 'tedarikçi için tüketim raporu'"));
	TypesOfCounterpartyDocuments.Insert("MaterialProviderOrder2_5",                     NStr("vi = 'biên bản';
																							|ru = 'акту';
																							|en = 'certificate'; fa = 'certificate';
																							|it = 'all''atto';
																							|pl = 'certificate';
																							|tr = 'tutanak'"));
	TypesOfCounterpartyDocuments.Insert("ReportToMaterialProvider2_5",                     NStr("vi = 'biên bản';
																								|ru = 'акту';
																								|en = 'certificate'; fa = 'certificate';
																								|it = 'all''atto';
																								|pl = 'certificate';
																								|tr = 'tutanak'"));

	TypesOfCounterpartyDocuments.Insert("VendorInvoice",             NStr("vi = 'hóa đơn';
																			|ru = 'накладной';
																			|en = 'invoice'; fa = 'invoice';
																			|it = 'lettera di vettura';
																			|pl = 'invoice';
																			|tr = 'irsaliye'"));
	TypesOfCounterpartyDocuments.Insert("VendorInvoiceServicesAndAssets",       NStr("vi = 'biên bản';
																					|ru = 'акту';
																					|en = 'certificate'; fa = 'certificate';
																					|it = 'all''atto';
																					|pl = 'certificate';
																					|tr = 'tutanak'"));
	TypesOfCounterpartyDocuments.Insert("CustomerInvoice",               NStr("vi = 'hóa đơn';
																				|ru = 'накладной';
																				|en = 'invoice'; fa = 'invoice';
																				|it = 'lettera di vettura';
																				|pl = 'invoice';
																				|tr = 'irsaliye'"));
	TypesOfCounterpartyDocuments.Insert("CCDImport",           NStr("vi = 'tờ khai hàng hóa';
																	|ru = 'декларации на товары';
																	|en = 'declarations for goods'; fa = 'declarations for goods';
																	|it = 'Dichiarazione delle merci';
																	|pl = 'deklaracji na wiersze pozycji';
																	|tr = 'ürün beyanları'"));
	TypesOfCounterpartyDocuments.Insert("PlatonSystemOperatorSReport",          NStr("vi = 'biên bản';
																					|ru = 'акту';
																					|en = 'certificate'; fa = 'certificate';
																					|it = 'all''atto';
																					|pl = 'certificate';
																					|tr = 'tutanak'"));
	
	
	TypesOfCounterpartyDocuments.Insert("SubcontractorReport2_5",                NStr("vi = 'báo cáo gia công';
																						|ru = 'отчету переработчика';
																						|en = 'to ""Subcontracting services notification received""'; fa = 'to ""Subcontracting services notification received""';
																						|it = 'al report del processore';
																						|pl = 'raportu przetwórcy';
																						|tr = 'fason üretici raporu'"));
	Return TypesOfCounterpartyDocuments;
	
EndFunction // Get a representation of the documents()

// displays error messages when entering non-cash Cash debits based
// on several documents.
//
// Parameters:
//  Selection  - Selection from the query result.
//
// Returns:
//   Boolean   - True if the refusal to enter is based on.
//
Function ReportErrorsInGeneratingDataForFillingInCashDebits(Selection)

	Cancel = False;
	
	MessageText = NStr("vi = 'Trong các chứng từ đã chọn có khác biệt %FieldPresentation%';
						|ru = 'У выделенных документов отличается %FieldPresentation%';
						|en = '%FieldPresentation% of the selected documents is different.'; fa = '%FieldPresentation% of the selected documents is different.';
						|it = 'Nei documenti selezionati non coincidono %FieldPresentation%';
						|pl = 'W wyznaczonych dokumentach różni się %FieldPresentation%';
						|tr = 'Seçilen belgelerde %FieldPresentation% farklı'");
	
	If Selection.ThereAreDifferencesCounterparty Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'trường ""Đối tác""';
																|ru = 'поле ""Контрагент""';
																|en = '""Counterparty"" field'; fa = '""Counterparty"" field';
																|it = 'Campo ""Controparte""';
																|pl = 'pole ""Контрагент""';
																|tr = 'alan ""Cari hesap""'")),,,, Cancel);
	EndIf;

	If Selection.ThereAreDifferencesCompany Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'trường ""Doanh nghiệp""';
																|ru = 'поле ""Организация""';
																|en = '""Company"" field'; fa = '""Company"" field';
																|it = 'Campo ""Azienda""';
																|pl = 'pole ""Firma""';
																|tr = 'alan ""İş yeri""'")),,,, Cancel);
	EndIf;
	
	If Selection.ThereAreDifferencesType Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'kiểu chứng từ';
																|ru = 'тип документов';
																|en = 'document type'; fa = 'document type';
																|it = 'Tipo di documenti';
																|pl = 'typ dokumentów';
																|tr = 'belge tipi'")),,,, Cancel);
	EndIf;
	
	Return Cancel;


EndFunction

Function DecomposeDestinationStringIntoArrayOfWords(Val String)
	
	Words = New Array;
	
	TextSize = StrLen(String);
	WordBeginning = 1;
	For Position = 1 To TextSize Do
		OchSymbol = Mid(String, Position, 1);
		If OchSymbol = " " Then
			If Position <> WordBeginning And Position - WordBeginning > 2 Then
				Words.Add(Mid(String, WordBeginning, Position - WordBeginning));
			EndIf;
			WordBeginning = Position + 1;
		EndIf;
	EndDo;
	
	If Position <> WordBeginning And Position - WordBeginning > 2 Then
		Words.Add(Mid(String, WordBeginning, Position - WordBeginning));
	EndIf;
	
	Return Words;
	
EndFunction

Function DetermineTypeOfDocumentToCreate(Details_Payment)

	DocumentType = Undefined;

	If Details_Payment.ReceiptIssue = Enums.CashFlowTypes.WriteOff Then
		If Details_Payment.PaymentMethod = Enums.PaymentForms.BankAccountPayment
			Or Details_Payment.PaymentMethod = Enums.PaymentForms.InstantPayments Then
			DocumentType = "BankAccountIssue";
		ElsIf Details_Payment.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
			DocumentType = "CashVoucher";
		ElsIf Details_Payment.PaymentMethod = Enums.PaymentForms.PaymentCard Then
			DocumentType = "PaymentCardTransaction";
		EndIf;
	ElsIf Details_Payment.ReceiptIssue = Enums.CashFlowTypes.Inpayment Then
		If Details_Payment.PaymentMethod = Enums.PaymentForms.BankAccountPayment
			Or Details_Payment.PaymentMethod = Enums.PaymentForms.InstantPayments Then
			DocumentType = "BankAccountReceiptNote";
		ElsIf Details_Payment.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
			DocumentType = "CashAccountReceiptNote";
		ElsIf Details_Payment.PaymentMethod = Enums.PaymentForms.PaymentCard Then
			DocumentType = "PaymentCardTransaction";
		EndIf;
	EndIf;

	Return DocumentType;

EndFunction

Function InitializeDependenciesOfFormFields() Export
	
	DependenceOfFormFields = New ValueTable;
	DependenceOfFormFields.Columns.Add("AttributeName", New TypeDescription("String"));
	DependenceOfFormFields.Columns.Add("DependentFields", New TypeDescription("Array"));
	
	Return DependenceOfFormFields;
	
EndFunction

Procedure FillInSelectionDetails(Filter, Attributes)
	
	If Filter = Undefined Then
		Return;
	EndIf;

	For Each FilterElement In Filter.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			If Attributes.Find(String(FilterElement.LeftValue)) = Undefined Then
				Attributes.Add(String(FilterElement.LeftValue));
			EndIf;
		ElsIf TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			FillInSelectionDetails(FilterElement, Attributes);
		EndIf;
	EndDo;

EndProcedure

// The function returns the Unallocated payment balance of the payment document for settlement objects.
//
// Parameters:
//	Object - ClientApplicationForm, DocumentObject - The form or document that you need to calculate the balance for.
//	Ref - Undefined
//
// Returns:
//	Number - The amount of the undistributed payment.
//
Function UnallocatedPaymentBalance(Object, Ref = Undefined) Export
	
	If Ref = Undefined Then
		Ref = Object.Ref;
	EndIf;
	
	SettlementOperations = New Array;
	SettlementOperations.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	SettlementOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	SettlementOperations.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
	SettlementOperations.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
	SettlementOperations.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	SettlementOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
	SettlementOperations.Add(Enums.BusinessTransactions.PaymentToVendor);
	SettlementOperations.Add(Enums.BusinessTransactions.RefundFromVendor);
	SettlementOperations.Add(Enums.BusinessTransactions.CustomsPayment);
	
	If SettlementOperations.Find(Object.BusinessOperation) = Undefined Then
		Return 0;
	EndIf;
	
	ARAPObjects = ARAPObjectsServer.AllObjectsAreCalculatedByReference(Ref);
	
	AmountUnallocated = 0;
	For Each DecryptionString In Object.ARAPDetails Do
		If Not ValueIsFilled(DecryptionString.ARAPObject) Or ARAPObjects.Find(DecryptionString.ARAPObject) <> Undefined Then
			AmountUnallocated = AmountUnallocated + DecryptionString.Sum;
		EndIf;
	EndDo;
	Return AmountUnallocated;
	
EndFunction

// The procedure creates a hyperlink label for the Unallocated payment. 
// The form must contain an element of the Decoration type-the Label "Hyperlinkrequisitsobjectaccounts".
//
// Parameters:
//	Form					- ClientApplicationForm - Initiator form.
//	Object					- FormDataStructure - object to the form.
//	CheckForDiscrepancies	- Boolean - Do I need to check for discrepancies in decryption contracts by key details?
//								If you need to check for discrepancies, the form must contain an element of the Decoration-Picture type "Decorationextensions".
//
Procedure GenerateHyperlinkCaptionPaymentObjectDetails(Form, Object, CheckForDiscrepancies = False) Export
	
	FormItem = Form.Items.HyperlinkPaymentObjectDetails; // FormField
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "AmountUnallocated") Then
		AmountUnallocated = Form.AmountUnallocated;
	Else
		AmountUnallocated = UnallocatedPaymentBalance(Object);
	EndIf;
	
	If AmountUnallocated = 0 Then
		
		Operation = Object.BusinessOperation;
		ThisIsCashReturnOperation = (Operation = Enums.BusinessTransactions.RefundFromAnotherCompany
			Or Operation = Enums.BusinessTransactions.RefundToAnotherCompany
			Or Operation = Enums.BusinessTransactions.RefundFromVendor
			Or Operation = Enums.BusinessTransactions.RefundToCustomer);
		
		If Not ThisIsCashReturnOperation Then
			FormItem.Enabled = False;
			If CheckForDiscrepancies Then
				Form.Items.DecorationThereAreDiscrepancies.Visible = False;
			EndIf;
			
			Form.HyperlinkPaymentObjectDetails = NStr("ru = 'Объекты расчетов указаны для всей суммы платежа';
														|vi = 'AR/AP objects are specified for the entire payment amount';
														|en = 'AR/AP objects are specified for the entire payment amount'; fa = 'AR/AP objects are specified for the entire payment amount';
														|it = 'AR/AP objects are specified for the entire payment amount';
														|pl = 'AR/AP objects are specified for the entire payment amount';
														|tr = 'Tüm ödeme tutarları için alacak/borç nesneleri belirtildi'");
			
		Else
			FormItem.Enabled = True;
			Form.HyperlinkPaymentObjectDetails = NStr("ru = 'Аналитика возврата';
														|vi = 'Refund dimension';
														|en = 'Refund dimension'; fa = 'Refund dimension';
														|it = 'Refund dimension';
														|pl = 'Refund dimension';
														|tr = 'İade boyutu'");
			TMCommonUseClientServer.SetFormItemProperty(
				Form.Items, "DecorationThereAreDiscrepancies", "Visible", False);
		EndIf;
		
	Else
		
		FormItem.Enabled = True;
		Form.HyperlinkPaymentObjectDetails =
			StrTemplate(NStr("ru = 'Без указания объекта расчетов: %1 %2';
							|vi = 'Without AR/AP object specified: %1 %2';
							|en = 'Without AR/AP object specified: %1 %2'; fa = 'Without AR/AP object specified: %1 %2';
							|it = 'Without AR/AP object specified: %1 %2';
							|pl = 'Without AR/AP object specified: %1 %2';
							|tr = 'Alacak/Borç nesnesi belirmeden: %1 %2'"), Format(AmountUnallocated, "NFD=2"), Object.Currency);
			
		If CheckForDiscrepancies Then
			
			AttributesStructure1 = New Structure();
			AttributesStructure1.Insert("FinancialAccountingGroup",  Object.FinancialAccountingGroup);
			AttributesStructure1.Insert("LineOfBusiness", Object.LineOfBusiness);
			AttributesStructure1.Insert("Contract",                 Object.Contract);
			AttributesStructure1.Insert("Department",           Object.Department);
			AttributesStructure1.Insert("DocumentRef",          Object["Ref"]);
			
			UnallocatedPaymentDetails = UnallocatedPaymentDetails(Object.ARAPDetails, AttributesStructure1);
			If UnallocatedPaymentDetails.Count() > 1 Then
				Form.Items.DecorationThereAreDiscrepancies.Visible = True;
			Else
				Form.Items.DecorationThereAreDiscrepancies.Visible = False;
			EndIf;
		EndIf;
	EndIf;
		
EndProcedure

// The function returns a table of contract details with non-contract payments and the payment document itself.
//
// Parameters:
//	ARAPDetails - ValueTable - Decryption of the payment document.
//	AttributesStructure1 - Structure - Structure of Attributes of the settlement object-payment:
//		* FinancialAccountingGroup 	- CatalogRef.FinancialAccountingGroupsOfARAP 	- HFC billing.
//		* Department 			- CatalogRef.BusinessStructure 			- Payment division.
//		* LineOfBusiness	- CatalogRef.LinesOfBusiness	- The direction of the payment activity.
//		* Contract 					- CatalogRef.CounterpartyContracts,CatalogRef.IntercompanyContracts - payment Contract.
//		* DocumentRef			- DocumentRef - Link to the payment document.
//
// Returns:
//	ValueTable - Table of Contract Attributes from the table part:
//		* FinancialAccountingGroup 	- CatalogRef.FinancialAccountingGroupsOfARAP 	- hfc Contract/payment system.
//		* Department 			- CatalogRef.BusinessStructure 			- Contract/billing division.
//		* LineOfBusiness	- CatalogRef.LinesOfBusiness	- the business line of the Contract/billing.
//		* Contract 					- CatalogRef.CounterpartyContracts,CatalogRef.IntercompanyContracts - decryption and payment Contracts.
//
Function UnallocatedPaymentDetails(Val ARAPDetails, Val AttributesStructure1) Export
	
	ArrayOfContracts    = New Array;
	ThereIsEmptyValue = False;
	ARAPObjects = ARAPObjectsServer.AllObjectsAreCalculatedByReference(AttributesStructure1.DocumentRef);
	
	For Each DecryptionString In ARAPDetails Do
		If (Not ValueIsFilled(DecryptionString.ARAPObject) Or ARAPObjects.Find(DecryptionString.ARAPObject) <> Undefined) Then
			If ValueIsFilled(DecryptionString.PaymentPurpose) Then
				If ArrayOfContracts.Find(DecryptionString.PaymentPurpose) = Undefined Then
					ArrayOfContracts.Add(DecryptionString.PaymentPurpose);
				EndIf;
			Else
				ThereIsEmptyValue = True;
			EndIf;
		EndIf;
	EndDo;
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED DISTINCT
	|	AllContracts.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	AllContracts.Department           AS Department,
	|	AllContracts.LineOfBusiness AS LineOfBusiness,
	|	AllContracts.Ref                  AS Contract
	|FROM
	|	(SELECT
	|		CounterpartyContracts.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|		CounterpartyContracts.Department           AS Department,
	|		CounterpartyContracts.LineOfBusiness AS LineOfBusiness,
	|		CounterpartyContracts.Ref                  AS Ref
	|	FROM
	|		Catalog.CounterpartyContracts AS CounterpartyContracts
	|	WHERE
	|		CounterpartyContracts.Ref IN(&ListOfAgreements)
	|
	|	UNION ALL
	|
	|	SELECT
	|		IntercompanyContracts.FinancialAccountingGroup,
	|		IntercompanyContracts.Department,
	|		IntercompanyContracts.LineOfBusiness,
	|		IntercompanyContracts.Ref
	|	FROM
	|		Catalog.IntercompanyContracts AS IntercompanyContracts
	|	WHERE
	|		IntercompanyContracts.Ref IN(&ListOfAgreements)) AS AllContracts";
	Query.SetParameter("ListOfAgreements", ArrayOfContracts);
	UnallocatedPaymentDetails = Query.Execute().Unload();
	If ThereIsEmptyValue Then
		NwRw = UnallocatedPaymentDetails.Add();
		NwRw.Contract                 = AttributesStructure1.Contract;
		NwRw.FinancialAccountingGroup  = AttributesStructure1.FinancialAccountingGroup;
		NwRw.Department           = AttributesStructure1.Department;
		NwRw.LineOfBusiness = AttributesStructure1.LineOfBusiness;
	EndIf;
	UnallocatedPaymentDetails.GroupBy("FinancialAccountingGroup, Department, LineOfBusiness, Contract");
	Return UnallocatedPaymentDetails;
EndFunction

// Fills in the period selection list
//
// Parameters:
//     Form - ClientApplicationForm - shape.
//     Date - Date - Date of the report.
//
Procedure FillInListOfAdvanceReportPeriodSelections(Form, Date) Export
	
	Object = Form.Object;
	Items = Form.Items;
	
	PeriodSelectionList = Items.ExpenseReportPeriod.ChoiceList;
	PeriodSelectionList.Clear();
	PeriodSelectionList.Add(NStr("vi = 'Qua tuần';
								|ru = 'Через неделю';
								|en = 'In a week'; fa = 'In a week';
								|it = 'Tra una settimana';
								|pl = 'Za tydzień';
								|tr = 'Bir hafta sonra'"),     NStr("vi = 'Qua tuần';
																|ru = 'Через неделю';
																|en = 'In a week'; fa = 'In a week';
																|it = 'Tra una settimana';
																|pl = 'Za tydzień';
																|tr = 'Bir hafta sonra'"));
	PeriodSelectionList.Add(NStr("vi = 'Trong hai tuần';
								|ru = 'Через две недели';
								|en = 'In two weeks'; fa = 'In two weeks';
								|it = 'Tra due settimane';
								|pl = 'Za dwa tygodni';
								|tr = 'İki hafta sonra'"), NStr("vi = 'Trong hai tuần';
																|ru = 'Через две недели';
																|en = 'In two weeks'; fa = 'In two weeks';
																|it = 'Tra due settimane';
																|pl = 'Za dwa tygodni';
																|tr = 'İki hafta sonra'"));
	PeriodSelectionList.Add(NStr("vi = 'Trong một tháng';
								|ru = 'Через месяц';
								|en = 'In a month'; fa = 'In a month';
								|it = 'Tra un mese';
								|pl = 'Za miesiąc';
								|tr = 'Bir ay sonra'"),      NStr("vi = 'Trong một tháng';
																|ru = 'Через месяц';
																|en = 'In a month'; fa = 'In a month';
																|it = 'Tra un mese';
																|pl = 'Za miesiąc';
																|tr = 'Bir ay sonra'"));
	PeriodSelectionList.Add("TillDate",                      NStr("vi = 'Cho đến ngày ...';
																	|ru = 'До даты...';
																	|en = 'To date ...'; fa = 'To date ...';
																	|it = 'Entro la data...';
																	|pl = 'Do daty...';
																	|tr = 'Tarihe kadar...'"));
	
	If Not ValueIsFilled(Object["Ref"])
		And Not ValueIsFilled(Object.ExpenseReportDate) Then
		
		Form.ExpenseReportPeriod = NStr("vi = 'Trong một tuần';
										|ru = 'Через неделю';
										|en = 'In a week'; fa = 'In a week';
										|it = 'Tra una settimana';
										|pl = 'Za tydzień';
										|tr = 'Bir hafta sonra'");
		
	Else
		If Object.ExpenseReportDate = BegOfDay(Date) + 7 * 24 * 3600 Then
			Form.ExpenseReportPeriod = NStr("vi = 'Trong một tuần';
											|ru = 'Через неделю';
											|en = 'In a week'; fa = 'In a week';
											|it = 'Tra una settimana';
											|pl = 'Za tydzień';
											|tr = 'Bir hafta sonra'");
		ElsIf Object.ExpenseReportDate = BegOfDay(Date) + 14 * 24 * 3600 Then
			Form.ExpenseReportPeriod = NStr("vi = 'Trong hai tuần';
											|ru = 'Через две недели';
											|en = 'In two weeks'; fa = 'In two weeks';
											|it = 'Tra due settimane';
											|pl = 'Za dwa tygodni';
											|tr = 'İki hafta sonra'");
		ElsIf Object.ExpenseReportDate = AddMonth(BegOfDay(Date), 1) Then
			Form.ExpenseReportPeriod = NStr("vi = 'Trong một tháng';
											|ru = 'Через месяц';
											|en = 'In a month'; fa = 'In a month';
											|it = 'Tra un mese';
											|pl = 'Za miesiąc';
											|tr = 'Bir ay sonra'");
		Else
			Form.ExpenseReportPeriod = Object.ExpenseReportDate;
			
			Items.ExpenseReportPeriod.TypeRestriction = New TypeDescription("Date");
			Items.ExpenseReportPeriod.ChoiceButton = True;
			Items.ExpenseReportPeriod.TextEdit = True;
		EndIf;
	EndIf;
	
EndProcedure


Function NationalCodeLocation(CountryCode)
	
	CodeLocations = New Structure;
	CodeLocations.Insert("AL", New Structure("Position, Length", 5, 7));
	CodeLocations.Insert("AD", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("AT", New Structure("Position, Length", 5, 5));
	CodeLocations.Insert("AZ", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("BH", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("BY", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("BE", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("BA", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("BR", New Structure("Position, Length", 5, 13));
	CodeLocations.Insert("BG", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("CR", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("HR", New Structure("Position, Length", 5, 7));
	CodeLocations.Insert("CY", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("CZ", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("DK", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("DO", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("TL", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("EE", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("FO", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("FI", New Structure("Position, Length", 5, 6));
	CodeLocations.Insert("FR", New Structure("Position, Length", 5, 10));
	CodeLocations.Insert("GE", New Structure("Position, Length", 5, 2));
	CodeLocations.Insert("DE", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("GI", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("GR", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("GL", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("GT", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("HU", New Structure("Position, Length", 5, 7));
	CodeLocations.Insert("IS", New Structure("Position, Length", 5, 6));
	CodeLocations.Insert("IE", New Structure("Position, Length", 5, 10));
	CodeLocations.Insert("IL", New Structure("Position, Length", 5, 6));
	CodeLocations.Insert("IT", New Structure("Position, Length", 6, 10));
	CodeLocations.Insert("JO", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("KZ", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("XK", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("KW", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("LV", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("LB", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("LI", New Structure("Position, Length", 5, 5));
	CodeLocations.Insert("LT", New Structure("Position, Length", 5, 5));
	CodeLocations.Insert("LU", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("MK", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("MT", New Structure("Position, Length", 5, 9));
	CodeLocations.Insert("MR", New Structure("Position, Length", 5, 10));
	CodeLocations.Insert("MU", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("MC", New Structure("Position, Length", 5, 10));
	CodeLocations.Insert("MD", New Structure("Position, Length", 5, 2));
	CodeLocations.Insert("ME", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("NL", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("NO", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("PK", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("PS", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("PL", New Structure("Position, Length", 5, 7));
	CodeLocations.Insert("PT", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("QA", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("RO", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("SM", New Structure("Position, Length", 6, 10));
	CodeLocations.Insert("SA", New Structure("Position, Length", 5, 2));
	CodeLocations.Insert("RS", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("SK", New Structure("Position, Length", 5, 4));
	CodeLocations.Insert("SI", New Structure("Position, Length", 5, 5));
	CodeLocations.Insert("ES", New Structure("Position, Length", 5, 8));
	CodeLocations.Insert("SE", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("CH", New Structure("Position, Length", 5, 5));
	CodeLocations.Insert("TN", New Structure("Position, Length", 5, 5));
	CodeLocations.Insert("TR", New Structure("Position, Length", 5, 5));
	CodeLocations.Insert("UA", New Structure("Position, Length", 5, 6));
	CodeLocations.Insert("AE", New Structure("Position, Length", 5, 3));
	CodeLocations.Insert("GB", New Structure("Position, Length", 5, 10));
	CodeLocations.Insert("VG", New Structure("Position, Length", 5, 4));
	
	ReturnValue = Undefined;
	CodeLocations.Property(CountryCode, ReturnValue);
	Return ReturnValue
	
EndFunction

Function EmptyTableOfInformationAboutRecipientPayer()

	Result = New ValueTable;
	Result.Columns.Add("Document");
	Result.Columns.Add("Flag");
	Result.Columns.Add("AttributeValue");
	
	Return Result;

EndFunction

// The function returns the text of the request for customer settlement documents.
//
// Parameters:
//	SelectingThePaymentBasis - Boolean - an indication of the operation performed to select the payment basis.
//	FilterParameters - See ARAPAccountingServer.SelectionParametersWhenSelectingCustomerSettlementDocument.
//
// Returns:
// 	String - query text.
//
Function GetTextOfRequestDocumentsOfSettlementsWithClients(SelectingThePaymentBasis, FilterParameters) Export
	
	QueriesTexts = New Array;
	
	If AccessRight("Read", Metadata.Documents.SalesOrder) Then
		
		QueryText = "SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.PaymentID AS PaymentID,
		|	DocumentData.Date AS Date,
		|	DocumentData.Number AS Number,
		|	DocumentData.NumberAccordingToCustomerData AS NumberAccordingToCounterparty,
		|	DocumentData.DateAccordingToInformationFromCustomer AS DateAccordingToCounterparty,
		|	DocumentData.Organization,
		|	DocumentData.Partner,
		|	DocumentData.Counterparty,
		|	DocumentData.Contract,
		|	DocumentData.DocumentAmount AS Sum,
		|	DocumentData.Currency,
		|	VALUETYPE(DocumentData.Ref) AS Type,
		|	TRUE AS TheseAreSettlementsWithCustomers,
		|
		|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.Ref
		|	END AS ARAPObject,
		|	
		|	CASE WHEN DocumentData.Posted THEN
		|		0
		|	WHEN DocumentData.DeletionMark THEN
		|		1
		|	ELSE
		|		2
		|	END AS DocumentState
		|FROM
		|	Document.SalesOrder AS DocumentData
		|WHERE
		|	(DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|		OR (&SelectingThePaymentBasis AND DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)))
		|	AND NOT DocumentData.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
		|		VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale))
		|	AND &DynamicConditions
		|";
		
		CompleteTextOfRequestDocumentsOfSettlementsWithClients(
			QueryText, Type("DocumentRef.SalesOrder"), FilterParameters);
		
		QueriesTexts.Add(QueryText);
		
	EndIf;
	
	If SelectingThePaymentBasis And AccessRight("Read", Metadata.Documents.CustomerCommercialInvoice) Then
		
		QueryText = "SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.PaymentID AS PaymentID,
		|	DocumentData.Date AS Date,
		|	DocumentData.Number AS Number,
		|	"""" AS NumberAccordingToCounterparty,
		|	DATETIME(1,1,1) AS DateAccordingToCounterparty,
		|	DocumentData.Organization,
		|	DocumentData.Partner,
		|	DocumentData.Counterparty,
		|	DocumentData.Contract,
		|	DocumentData.DocumentAmount AS Sum,
		|	DocumentData.Currency,
		|	VALUETYPE(DocumentData.Ref) AS Type,
		|	TRUE AS TheseAreSettlementsWithCustomers,
		|
		|	CASE WHEN DocumentData.DocumentBasis REFS Document.SalesOrder
		|		AND DocumentData.DocumentBasis.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|		THEN DocumentData.DocumentBasis
		|	WHEN DocumentData.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
		|		DocumentData.Contract
		|	ELSE
		|		DocumentData.DocumentBasis
		|	END AS ARAPObject,
		|	
		|	CASE WHEN DocumentData.Posted THEN
		|		0
		|	WHEN DocumentData.DeletionMark THEN
		|		1
		|	ELSE
		|		2
		|	END AS DocumentState
		|FROM
		|	Document.CustomerCommercialInvoice AS DocumentData
		|WHERE
		|	TRUE
		|	AND &DynamicConditions
		|";
		
		CompleteTextOfRequestDocumentsOfSettlementsWithClients(
			QueryText, Type("DocumentRef.CustomerCommercialInvoice"), FilterParameters);
		
		QueriesTexts.Add(QueryText);
		
	EndIf;
	
	QueryText = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF);
	
	If QueryText = "" Then
		Return "";
	Else
		
		FinalRequest = "
		|SELECT
		|	DocumentsTable.Ref                        AS PaymentPurpose,
		|	DocumentsTable.PaymentID          AS PaymentID,
		|	DocumentsTable.Date                          AS Date,
		|	DocumentsTable.Number                         AS Number,
		|	DocumentsTable.NumberAccordingToCounterparty      AS NumberAccordingToCounterparty,
		|	DocumentsTable.DateAccordingToCounterparty       AS DateAccordingToCounterparty,
		|	DocumentsTable.Organization                   AS Organization,
		|	DocumentsTable.Partner                       AS Partner,
		|	DocumentsTable.Counterparty                    AS Counterparty,
		|	DocumentsTable.Contract                       AS Contract,
		|	DocumentsTable.Sum                         AS Sum,
		|	DocumentsTable.Currency                        AS Currency,
		|	DocumentsTable.Type                           AS Type,
		|	DocumentsTable.TheseAreSettlementsWithCustomers          AS TheseAreSettlementsWithCustomers,
		|	DocumentsTable.ARAPObject                AS ARAPObject,
		|	DocumentsTable.DocumentState            AS DocumentState
		|FROM
		|	&QueryText AS DocumentsTable";
		
		FinalRequest = StrReplace(FinalRequest, "&QueryText", "(" + QueryText + ")");
		
		Return FinalRequest;
		
	EndIf;
	
EndFunction

// Complements the text of the request with selections in the function getttextcountcounts with clients().
// 
// Parameters:
//	QueryText - String - the modified query text.
//	ObjectType - Type - The type of document for which the request is being generated.
//	FilterParameters - See ARAPAccountingServer.SelectionParametersWhenSelectingCustomerSettlementDocument.
//
Procedure CompleteTextOfRequestDocumentsOfSettlementsWithClients(QueryText, ObjectType, FilterParameters)
	
	QueryConditions = New Array;
	
	If FilterParameters.Property("Organization") Then
		QueryConditions.Add("DocumentData.Organization IN (&Organization)");
	EndIf;
	
	If FilterParameters.Property("Text") And ValueIsFilled(FilterParameters.Text) Then
		
		If FilterParameters.InputByString Then
			
			If FilterParameters.ThisIsWhip Then
				QueryConditions.Add("DocumentData.PaymentID LIKE ""%"" + &SearchString + ""%""");
			Else
				QueryConditions.Add("DocumentData.Number LIKE ""%"" + &SearchString + ""%""");
			EndIf;
			
		Else
			
			If FilterParameters.ThisIsWhip Then
				QueryConditions.Add("DocumentData.PaymentID IN (&SearchString)");
			Else	
				QueryConditions.Add("DocumentData.Number IN (&SearchString)");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DynamicConditions", StrConcat(QueryConditions, " And "));
	
EndProcedure

Function BalancesDebitedToEmployeesPersonalAccounts(Requests)

	ToBeDebitedOnPersonalAccounts = AccountablePersonsFundsToBeWrittenOff(Requests);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TableForDebiting.Individual AS Individual,
		|	TableForDebiting.PersonalAccount AS PersonalAccount,
		|	TableForDebiting.SumBalance AS SumBalance,
		|	TableForDebiting.CashFlowItem AS CashFlowItem
		|INTO RawData
		|FROM
		|	&TableForDebiting AS TableForDebiting
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RawData.Individual AS Individual,
		|	RawData.PersonalAccount AS PersonalAccount,
		|	RawData.CashFlowItem AS CashFlowItem,
		|	SUM(RawData.SumBalance) AS Sum
		|FROM
		|	RawData AS RawData
		|GROUP BY
		|	RawData.Individual,
		|	RawData.PersonalAccount,
		|	RawData.CashFlowItem
		|HAVING
		|	SUM(RawData.SumBalance) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RawData";
	
	Query.SetParameter("TableForDebiting", ToBeDebitedOnPersonalAccounts);
	
	Return Query.Execute().Unload();

EndFunction

Function AccountablePersonsFundsToBeWrittenOff(ArrayOfRequests)

	DataLayoutDiagram = Documents.BankAccountIssue.GetTemplate("PaymentRequestsForPersonalAccounts");
	DataLayoutSchemeSettings = DataLayoutDiagram.SettingVariants["0"].Settings;
	
	Parameter = New DataCompositionParameter("ArrayOfRequests");
	DataLayoutSchemeSettings.DataParameters.SetParameterValue(Parameter, ArrayOfRequests);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	TypeOfLayoutGenerator = Type("DataCompositionValueCollectionTemplateGenerator");
	CompositionTemplate = TemplateComposer.Execute(DataLayoutDiagram, DataLayoutSchemeSettings, , , TypeOfLayoutGenerator);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Result = New ValueTable;
	OutputProcessor.SetObject(Result);
	OutputProcessor.Output(DataCompositionProcessor, True);
	
	Return Result;

EndFunction

// Prepares the texts of the request for verification of credit courses in advance reports
//
// Returns:
//    ValueList - A list of the String type with request texts
Function RequestTextsForCheckingCreditCoursesInAdvanceReports()
	
	QueryTexts = New ValueList;
	
	QueryText = "
	|SELECT DISTINCT
	|	BEGINOFPERIOD(Data.Period, DAY) AS Date,
	|	Data.Organization AS Organization,
	|	Data.Currency AS ARAPCurrency
	|INTO PeriodsTable
	|FROM
	|	AccumulationRegister.AdvanceHolderCash AS Data
	|WHERE
	|	VALUETYPE(Data.Recorder) IN (
	|		TYPE(Document.ExpenseReport),
	|		TYPE(Document.VendorInvoice),
	|		TYPE(Document.ElectronicTicketTransaction)
	|	)
	|	AND Data.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Data.Organization IN (&CompanyArray)
	|";
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, "TTCurrencyConversionFactors", True);
	
	QueryText = "
	|SELECT
	|	Data.Recorder         AS DocumentRecorder,
	|	Data.Organization         AS Organization,
	|	Data.AdvanceHolder     AS AdvanceHolder,
	|	Data.Department       AS Department,
	|	Data.IssuancePurpose          AS IssuancePurpose,
	|	Data.Currency              AS Currency,
	|	Data.SumOpeningBalance     AS SumOpeningBalance,
	|	Data.SumComplOpeningBalance AS SumComplOpeningBalance,
	|	Data.SumManOpeningBalance  AS SumManOpeningBalance,
	|	Data.SumClosingBalance      AS SumClosingBalance,
	|	Data.SumComplClosingBalance  AS SumComplClosingBalance,
	|	Data.SumManClosingBalance   AS SumManClosingBalance
	|INTO BalancesAndTurnoversRegister
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod, Recorder,, Organization IN (&CompanyArray)) AS Data
	|WHERE
	|	VALUETYPE(Data.Recorder) IN (
	|		TYPE(Document.ExpenseReport),
	|		TYPE(Document.VendorInvoice),
	|		TYPE(Document.ElectronicTicketTransaction))";
	QueryTexts.Add(QueryText, "BalancesAndTurnoversRegister");
	
	QueryText = "
	|SELECT
	|	BEGINOFPERIOD(Data.Period, DAY) AS Period,
	|	Data.Recorder                 AS Recorder,
	|	Data.Organization                 AS Organization,
	|	Data.AdvanceHolder             AS AdvanceHolder,
	|	Data.Department               AS Department,
	|	Data.IssuancePurpose                  AS IssuancePurpose,
	|	Data.Currency                      AS Currency,
	|	SUM(CASE WHEN Data.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -Data.Sum
	|		ELSE Data.Sum
	|	END) AS SumTurnover,
	|	SUM(CASE WHEN Data.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -Data.SumCompl
	|		ELSE Data.SumCompl
	|	END) AS SumComplTurnover,
	|	SUM(CASE WHEN Data.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -Data.SumMan
	|		ELSE Data.SumMan
	|	END) AS SumManTurnover
	|INTO ClearedTurnovers
	|FROM
	|	AccumulationRegister.AdvanceHolderCash AS Data
	|WHERE
	|	Data.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Data.Recorder IN (SELECT DocumentRecorder FROM BalancesAndTurnoversRegister)
	|	AND NOT BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain),
	|								VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss))
	|GROUP BY
	|	BEGINOFPERIOD(Data.Period, DAY),
	|	Data.Recorder,
	|	Data.Organization,
	|	Data.AdvanceHolder,
	|	Data.Department,
	|	Data.IssuancePurpose,
	|	Data.Currency
	|INDEX BY
	|	Data.Recorder,
	|	Data.Organization,
	|	Data.AdvanceHolder,
	|	Data.Department,
	|	Data.IssuancePurpose,
	|	Data.Currency";
	
	QueryTexts.Add(QueryText, "ClearedTurnovers");
	QueryText = "
	|SELECT
	|	Data.DocumentRecorder AS Recorder,
	|	ClearedTurnovers.Period    AS Period,
	|	Data.Organization         AS Organization,
	|	Data.AdvanceHolder     AS AdvanceHolder,
	|	Data.Department       AS Department,
	|	Data.IssuancePurpose          AS IssuancePurpose,
	|	Data.Currency              AS Currency,
	|	Data.SumOpeningBalance     AS SumOpeningBalance,
	|	Data.SumComplOpeningBalance AS SumComplOpeningBalance,
	|	Data.SumManOpeningBalance  AS SumManOpeningBalance,
	|	ClearedTurnovers.SumTurnover     AS SumTurnover,
	|	ClearedTurnovers.SumComplTurnover AS SumComplTurnover,
	|	ClearedTurnovers.SumManTurnover  AS SumManTurnover,
	|	Data.SumClosingBalance      AS SumClosingBalance,
	|	Data.SumComplClosingBalance  AS SumComplClosingBalance,
	|	Data.SumManClosingBalance   AS SumManClosingBalance
	|INTO BalanceAndTurnovers
	|FROM
	|	BalancesAndTurnoversRegister AS Data
	|		INNER JOIN ClearedTurnovers AS ClearedTurnovers
	|			ON ClearedTurnovers.Recorder = Data.DocumentRecorder
	|				AND ClearedTurnovers.Organization = Data.Organization
	|				AND ClearedTurnovers.AdvanceHolder = Data.AdvanceHolder
	|				AND ClearedTurnovers.Department = Data.Department
	|				AND ClearedTurnovers.IssuancePurpose = Data.IssuancePurpose
	|				AND ClearedTurnovers.Currency = Data.Currency";
	QueryTexts.Add(QueryText, "BalanceAndTurnovers");
	
	QueryText = "
	|//The Local control is checked if there is a Cash balance at the time of the document
	|SELECT
	|	Data.Recorder         AS Recorder,
	|	Data.Organization         AS Organization,
	|	Data.AdvanceHolder     AS AdvanceHolder,
	|	Data.Department       AS Department,
	|	Data.IssuancePurpose          AS IssuancePurpose,
	|	Data.Currency              AS Currency
	|INTO TableCheckingOffsettingCoursesInAdvanceReports
	|FROM
	|	BalanceAndTurnovers AS Data
	|		LEFT JOIN TTCurrencyConversionFactors
	|			ON TTCurrencyConversionFactors.Organization = Data.Organization
	|				AND TTCurrencyConversionFactors.Date = BEGINOFPERIOD(Data.Period, DAY)
	|				AND TTCurrencyConversionFactors.ARAPCurrency = Data.Currency
	|WHERE
	|	Data.SumOpeningBalance > 0
	|	AND Data.SumComplOpeningBalance / Data.SumOpeningBalance <> 1
	|	AND NOT (
	|		// The Balance is debited proportionally (at the Balance rate)
	|		Data.SumComplOpeningBalance
	|		* (1 - CASE
	|			WHEN Data.SumClosingBalance > 0
	|				THEN Data.SumClosingBalance
	|			ELSE 0
	|		END / Data.SumOpeningBalance)
	|		//over-expenditure at the exchange rate of the Central Bank
	|		+ CASE
	|			WHEN Data.SumClosingBalance < 0
	|				THEN -Data.SumClosingBalance
	|			ELSE 0
	|		END * TTCurrencyConversionFactors.LocalConversionRatio
	|		//Turnover of the document
	|		+ Data.SumComplTurnover BETWEEN -0.9 AND 0.9)
	|
	|UNION ALL
	|
	|//The Local control is checked if there is no Cash Balance at the time of the document
	|SELECT
	|	Data.Recorder         AS Recorder,
	|	Data.Organization         AS Organization,
	|	Data.AdvanceHolder     AS AdvanceHolder,
	|	Data.Department       AS Department,
	|	Data.IssuancePurpose          AS IssuancePurpose,
	|	Data.Currency              AS Currency
	|FROM
	|	BalanceAndTurnovers AS Data
	|	LEFT JOIN
	|		TTCurrencyConversionFactors
	|	ON
	|		TTCurrencyConversionFactors.Organization = Data.Organization
	|		AND TTCurrencyConversionFactors.Date = BEGINOFPERIOD(Data.Period, DAY)
	|		AND TTCurrencyConversionFactors.ARAPCurrency = Data.Currency
	|WHERE
	|	Data.SumOpeningBalance < 0
	|	AND Data.SumComplOpeningBalance / Data.SumOpeningBalance <> 1
	|	AND NOT ((Data.SumOpeningBalance - Data.SumClosingBalance)
	|			* TTCurrencyConversionFactors.LocalConversionRatio
	|			+ Data.SumComplTurnover BETWEEN -0.9 AND 0.9)
	|
	|UNION ALL
	|
	|//The upr is checked if there is a Cash balance at the time of the document
	|SELECT
	|	Data.Recorder         AS Recorder,
	|	Data.Organization         AS Organization,
	|	Data.AdvanceHolder     AS AdvanceHolder,
	|	Data.Department       AS Department,
	|	Data.IssuancePurpose          AS IssuancePurpose,
	|	Data.Currency              AS Currency
	|FROM
	|	BalanceAndTurnovers AS Data
	|	LEFT JOIN
	|		TTCurrencyConversionFactors
	|	ON
	|		TTCurrencyConversionFactors.Organization = Data.Organization
	|		AND TTCurrencyConversionFactors.Date = BEGINOFPERIOD(Data.Period, DAY)
	|		AND TTCurrencyConversionFactors.ARAPCurrency = Data.Currency
	|WHERE
	|	Data.SumOpeningBalance > 0
	|	AND Data.SumManOpeningBalance / Data.SumOpeningBalance <> 1
	|	AND NOT (
	|		// The Balance is debited proportionally (at the Balance rate)
	|		Data.SumManOpeningBalance
	|		* (1 - CASE
	|			WHEN Data.SumClosingBalance > 0
	|				THEN Data.SumClosingBalance
	|			ELSE 0
	|		END / Data.SumOpeningBalance)
	|		//over-expenditure at the exchange rate of the Central Bank
	|		+ CASE
	|			WHEN Data.SumClosingBalance < 0
	|				THEN -Data.SumClosingBalance
	|			ELSE 0
	|		END * TTCurrencyConversionFactors.ManConversionFactor
	|		//Turnover of the document
	|		+ Data.SumManTurnover BETWEEN -0.9 AND 0.9)
	|
	|UNION ALL
	|
	|//UPR is checked if there is no Balance at the time of the document
	|SELECT
	|	Data.Recorder         AS Recorder,
	|	Data.Organization         AS Organization,
	|	Data.AdvanceHolder     AS AdvanceHolder,
	|	Data.Department       AS Department,
	|	Data.IssuancePurpose          AS IssuancePurpose,
	|	Data.Currency              AS Currency
	|FROM
	|	BalanceAndTurnovers AS Data
	|	LEFT JOIN
	|		TTCurrencyConversionFactors
	|	ON
	|		TTCurrencyConversionFactors.Organization = Data.Organization
	|		AND TTCurrencyConversionFactors.Date = BEGINOFPERIOD(Data.Period, DAY)
	|		AND TTCurrencyConversionFactors.ARAPCurrency = Data.Currency
	|WHERE
	|	Data.SumOpeningBalance < 0
	|	AND Data.SumManOpeningBalance / Data.SumOpeningBalance <> 1
	|	AND NOT ((Data.SumOpeningBalance - Data.SumClosingBalance)
	|			* TTCurrencyConversionFactors.ManConversionFactor
	|			+ Data.SumManTurnover BETWEEN -0.9 AND 0.9)
	|";
	QueryTexts.Add(QueryText, "TableCheckingOffsettingCoursesInAdvanceReports");
	
	Return QueryTexts;
	
EndFunction

Function EmptyTableForProcessingDecryptionOfPayment()

	Table = New ValueTable;
	Table.Columns.Add("Condition", New TypeDescription("String"));
	Table.Columns.Add("Action", New TypeDescription("String"));
	
	Return Table;

EndFunction

// adds a row to the table for processing the Attributes of the "payment decryption" tabular part.
// 
// Parameters:
//  Table - ValueTable - a table with elements to process.
//  Condition - String - condition for processing in the tabular part.
//  Action - String - the action being performed with the data in the table part.
//
Procedure AddPaymentDecryptionProcessing(Table, Condition, Action)

	NewRow = Table.Add();
	NewRow.Condition = Condition;
	NewRow.Action = Action;

EndProcedure

Function RecipientForSelfEmployedPaymentRequests(FilterParameters)

	Recipient = Undefined;
	
	If FilterParameters.ListOfCounterparties_ Then
		
		Recipient = New Array;
		Recipient.Add(Undefined);
		Recipient.Add(FilterParameters.Counterparty);
		
	Else
		Recipient = FilterParameters.Counterparty
	EndIf;
	
	Return Recipient;

EndFunction

Procedure FillInSettlementCurrencyByPaymentCurrency(TableRow, PaymentCurrency)

	TableRow.AmountARAP = TableRow.Sum;
	TableRow.ARAPCurrency = PaymentCurrency;
	TableRow.ExchangeRateNumeratorOfMutualSettlements = 1;
	TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;

EndProcedure

Procedure AddTermsAndConditionsForContract(SelectionGroupOr)
	
	FilterAndGroup = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterAndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FilterContractIsFilled = FilterAndGroup.Items.Add(Type("DataCompositionFilterItem"));
	FilterContractIsFilled.LeftValue = New DataCompositionField("Object.ARAPDetails.LoanDepositContract");
	FilterContractIsFilled.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.LeaseContracts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
EndProcedure

// Fills in the "Contract" column in the table row using the "Contract" Attribute in the object 
// if the Contract in the object header is filled in, but the Contract in the table is not filled in or differs from the value
// in the object header, and the settlement object is not filled in or the document itself is filled in in the settlement object.
//
// Parameters:
//  Object - FormDataStructure - data of the object that is being filled in.
//  TableRow - FormDataCollectionItem - the payment decryption string in the object.
//  CounterpartyUnderContract - Undefined, CatalogRef.Counterparties - the counterparty from the Contract.
//
Procedure FillInDecryptionLineWithContractFromItemHeader(Object, TableRow, CounterpartyUnderContract)

	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	If (Not ValueIsFilled(TableRow.ARAPObject)
		Or TableRow.CalculationObject = Object.Ref)
		And (Not ValueIsFilled(TableRow.Contract)
		Or TableRow.Contract <> Object.Contract) Then
		
		// If the registry is used, then we do not take the Contract from the header to fill in.
		If TableRow.Property("Counterparty")
			And CounterpartyUnderContract <> Undefined
			And CounterpartyUnderContract <> TableRow.Counterparty Then
			Return;
		EndIf;
		
		TableRow.Contract = Object.Contract;
		
	EndIf;

EndProcedure

// Initialize the properties table by IP.
// 
// Returns:
//  ValueTable - Empty Data Table:
// * PaymentPurpose - DocumentRef.BankAccountIssue - the write-off document.
// * PaymentID - String - unique payment ID.
// * Counterparty - CatalogRef.Counterparties - broker.
// * Partner - CatalogRef.Partners - partner broker.
// * CounterpartyBankAccount - CatalogRef.CounterpartyBankAccounts - broker's account.
// * Department - CatalogRef.BusinessStructure - write-off division.
// * CashFlowItem - CatalogRef.CashFlowReportItems - article DDS Cash receipts to the current account for conversion.
// * Organization - CatalogRef.Companies - Organization.
// * BankAccount - CatalogRef.CompaniesBankAccounts - the organization's crediting account.
// * ConversionAmount - Number - the amount debited for conversion.
// * DocumentAmount - Number - the amount of the deposit.
// * CurrencyOfConversion - CatalogRef.Currencies - currency of conversion.
// * Currency - CatalogRef.Currencies - the currency of the transfer.
// * ConversionRate - Number - conversion rate.
// * ConversionRateMultiplier - Number - the multiplicity of the conversion rate.
//
Function InitializePropertiesTableByIP()
	
	Table = New ValueTable;
	Table.Columns.Add("PaymentPurpose", New TypeDescription("DocumentRef.BankAccountIssue"));
	Table.Columns.Add("PaymentID", New TypeDescription("String"));
	Table.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
	Table.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
	Table.Columns.Add("CounterpartyBankAccount", New TypeDescription("CatalogRef.CounterpartyBankAccounts"));
	Table.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	Table.Columns.Add("CashFlowItem", New TypeDescription("CatalogRef.CashFlowReportItems"));
	Table.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	Table.Columns.Add("BankAccount", New TypeDescription("CatalogRef.CompaniesBankAccounts"));
	Table.Columns.Add("ConversionAmount", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	Table.Columns.Add("DocumentAmount", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	Table.Columns.Add("CurrencyOfConversion", New TypeDescription("CatalogRef.Currencies"));
	Table.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	Table.Columns.Add("ConversionRate", Metadata.DefinedTypes.CurrencyExchangeRate.Type);
	Table.Columns.Add("ConversionRateMultiplier", Metadata.DefinedTypes.CurrencyExchangeRate.Type);
	
	Return Table;
	
EndFunction

Function NewTableOfDocumentSidesByList(DocumentsList)

	DocumentTypes = New Array;
	
	For Each CurrentDocument In DocumentsList Do
		
		If DocumentTypes.Find(TypeOf(CurrentDocument)) = Undefined Then
			DocumentTypes.Add(TypeOf(CurrentDocument));
		EndIf;
		
	EndDo;
	
	Table = New ValueTable;
	Table.Columns.Add("Ref", New TypeDescription(DocumentTypes));
	Table.Columns.Add("Date", New TypeDescription("Date", New DateQualifiers(DateFractions.DateTime)));
	AllowedTypes = New Array;
	AllowedTypes.Add(Type("CatalogRef.Companies"));
	AllowedTypes.Add(Type("CatalogRef.Counterparties"));
	AllowedTypes.Add(Type("CatalogRef.Persons"));
	Table.Columns.Add("Counterparty", New TypeDescription(AllowedTypes));
	Table.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	
	Return Table;

EndFunction

Function ThisIsBusinessTransactionOfPaymentBySettlement(BusinessOperation)
	
	SettlementOperations = New Array;
	SettlementOperations.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	SettlementOperations.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
	SettlementOperations.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	SettlementOperations.Add(Enums.BusinessTransactions.PaymentToVendor);
	SettlementOperations.Add(Enums.BusinessTransactions.CustomsPayment);
	
	Return SettlementOperations.Find(BusinessOperation) <> Undefined;
	
EndFunction

Function QueryTextForBalancesToBePaid()

	Return
	"SELECT
	|	CashToBePaidTurnovers.PaymentRequest AS PaymentRequest,
	|	CashToBePaidTurnovers.BankAccountCashAccount AS BankAccountCashAccount,
	|	CashToBePaidTurnovers.Recipient AS Recipient,
	|	CashToBePaidTurnovers.Organization AS Organization,
	|	CashToBePaidTurnovers.SumReceipt AS SumReceipt
	|INTO ScheduledForPayment
	|FROM
	|	AccumulationRegister.CashToBePaid.Turnovers(
	|			,
	|			,
	|			,
	|			PaymentRequest IN (&ReferencesArrray)
	|				AND (BankAccountCashAccount IN (&BankAccountsCashAccounts)
	|					OR &DonTLimitYourBankAccountToCheckout)) AS CashToBePaidTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashToBePaidTurnovers.PaymentRequest AS PaymentRequest,
	|	CashToBePaidTurnovers.BankAccountCashAccount AS BankAccountCashAccount,
	|	CashToBePaidTurnovers.Recipient AS Recipient,
	|	CashToBePaidTurnovers.Organization AS Organization,
	|	SUM(CashToBePaidTurnovers.SumExpense) AS SumExpense
	|INTO HasBeenPaid
	|FROM
	|	AccumulationRegister.CashToBePaid.Turnovers(
	|			,
	|			,
	|			Recorder,
	|			PaymentRequest IN (&ReferencesArrray)
	|				AND (BankAccountCashAccount IN (&BankAccountsCashAccounts)
	|					OR &DonTLimitYourBankAccountToCheckout)) AS CashToBePaidTurnovers
	|WHERE
	|	CashToBePaidTurnovers.Recorder <> &Recorder
	|
	|GROUP BY
	|	CashToBePaidTurnovers.PaymentRequest,
	|	CashToBePaidTurnovers.BankAccountCashAccount,
	|	CashToBePaidTurnovers.Recipient,
	|	CashToBePaidTurnovers.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(ScheduledForPayment.SumReceipt - ISNULL(HasBeenPaid.SumExpense, 0)) AS SumBalance
	|INTO CashBalance
	|FROM
	|	ScheduledForPayment AS ScheduledForPayment
	|		LEFT JOIN HasBeenPaid AS HasBeenPaid
	|		ON ScheduledForPayment.PaymentRequest = HasBeenPaid.PaymentRequest
	|			AND ScheduledForPayment.BankAccountCashAccount = HasBeenPaid.BankAccountCashAccount
	|			AND ScheduledForPayment.Recipient = HasBeenPaid.Recipient
	|			AND ScheduledForPayment.Organization = HasBeenPaid.Organization";

EndFunction

Function ResultOfRequestIsCounterpartySPartnersForOperation(Counterparties, BusinessOperation)

	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	Counterparties.Ref AS Counterparty,
	|	Counterparties.Partner AS Partner
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Ref IN (&Counterparty)
	|	AND (CASE WHEN &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer))
	|	THEN
	|		Counterparties.Partner.Client
	|	WHEN &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CustomsPayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
	|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty),
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty))
	|	THEN
	|		Counterparties.Partner.OtherRelations
	|	ELSE
	|		Counterparties.Partner.Vendor
	|	END
	|		OR &BusinessOperation = UNDEFINED
	|		OR &UsePartnersAsCounterparties)
	|";
	
	Query.SetParameter("Counterparty", Counterparties);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("UsePartnersAsCounterparties", GetFunctionalOption("UsePartnersAsCounterparties"));
	
	Return Query.Execute();

EndFunction

Procedure SetPaymentOptionWithConversionByListOfInvoices(DocumentObject)

	AccountList = New Array;
	
	For Each LineOfATabularSection In DocumentObject.AllocationByAccounts Do
		
		If TypeOf(LineOfATabularSection.BankAccountCashAccount) = Type("CatalogRef.CompaniesBankAccounts")
			And LineOfATabularSection.BankAccountCashAccount <> Catalogs.CompaniesBankAccounts.EmptyRef() Then
			AccountList.Add(LineOfATabularSection.BankAccountCashAccount);
		EndIf;
		
	EndDo;
	
	If AccountList.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	CompaniesBankAccounts.CashCurrency AS Currency
		|FROM
		|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
		|WHERE
		|	CompaniesBankAccounts.Ref IN(&Ref)";
	
	Query.SetParameter("Ref", AccountList);
	
	QueryResult = Query.Execute().Select();
	
	If QueryResult.Count() > 1 Then
		DocumentObject.PaymentWithConversion = True;
	ElsIf QueryResult.Count() = 1 Then
		
		If QueryResult.Next() Then
			DocumentObject.PaymentWithConversion =
				DocumentObject.PaymentWithConversion
				Or DocumentObject.Currency <> QueryResult.Currency;
		EndIf;
		
	EndIf;

EndProcedure

Function TheseAreSettlementsBetweenOrganizationsThroughSeparateCounterparty(Document)

	If CommonClientServer.HasAttributeOrObjectProperty(Document, "ARAPAccountingViaSeparateCounterparty") Then
		Return Common.ObjectAttributeValue(Document, "ARAPAccountingViaSeparateCounterparty");
	Else
		Return False;
	EndIf;

EndFunction

Procedure ClearContractInPaymentDecryptionLine(Object, DecryptionString)
	
	If (Not ValueIsFilled(DecryptionString.ARAPObject)
		Or DecryptionString.CalculationObject = Object.Ref) Then
		DecryptionString.Contract = Undefined;
	EndIf;
	
EndProcedure

Procedure AddFieldSelectionToQuerySchema(SelectionRequest, Field, NestedField, FieldAlias, Simple = "Undefined")

	SelectionOperator = SelectionRequest.Operators[0];
	
	If FieldSelectionIsAvailable(Field) Then
		
		NewField = Field;
		
		If NestedField <> "" Then
			
			AdditionalField = New Array;
			AdditionalField.Add(Field);
			AdditionalField.Add(NestedField);
			NewField = StrConcat(AdditionalField, ".");
			
		EndIf;
		
		SelectionOperator.SelectedFields.Add(NewField);
		
	Else
		SelectionOperator.SelectedFields.Add(Simple);
	EndIf;
	
	Column = SelectionRequest.Columns.Get(SelectionRequest.Columns.Count() - 1);
	Column.Alias = FieldAlias;

EndProcedure

Procedure AddDescriptionOfSelectionForDocument(SelectionOperator, Document)

	FullName = Document.Metadata().FullName();
	
	SelectionOperator.Sources.Add(FullName, "Object");
	SelectionOperator.SelectedFields.Add("Object.Ref");
	SelectionOperator.Filter.Add("Object.Ref = &Ref");

EndProcedure

Function FieldSelectionIsAvailable(ParameterOfDocument)

	If ParameterOfDocument <> "" Then
		
		ListOfParts = StrSplit(ParameterOfDocument, ".");
		
		If ListOfParts[0] = "Object" Then
			Return True;
		EndIf;
		
	EndIf;
	
	Return False;

EndFunction

Function QueryTextForFullPaymentAmounts(Document)

	If TypeOf(Document) = Type("DocumentRef.CustomerInvoice") Then
		QueryText = 
			"SELECT
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	TabularSectionData.VATRate AS VATRate,
			|	CASE
			|		WHEN TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	Document.CustomerInvoice.Goods AS TabularSectionData
			|WHERE
			|	(TabularSectionData.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
			|			OR TabularSectionData.Ref.PackageDepositIsRequired
			|			OR NOT TabularSectionData.Ref.ToReturnReusablePackage)
			|	AND TabularSectionData.Ref = &DocumentOperations
			|
			|GROUP BY
			|	TabularSectionData.VATRate,
			|	CASE
			|		WHEN TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.CustomerInvoiceServices") Then
		QueryText = 
			"SELECT
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	TabularSectionData.VATRate AS VATRate,
			|	FALSE AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	Document.CustomerInvoiceServices.Services AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|GROUP BY
			|	TabularSectionData.VATRate
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		QueryText = 
			"SELECT
			|	TabularSectionData.VATRate AS VATRate,
			|	FALSE AS ThisIsDepositForPackage,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	SUM(TabularSectionData.VATAmount) AS VATAmount
			|INTO FullPaymentAmounts
			|FROM
			|	Document.CustomerInvoiceServicesAndAssets.Income AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|GROUP BY
			|	TabularSectionData.VATRate
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.SaleAdjustment") Then
		QueryText = 
			"SELECT
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	TabularSectionData.VATRate AS VATRate,
			|	CASE
			|		WHEN TabularSectionData.Ref.DocumentBasis REFS Document.CustomerInvoice
			|				AND TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.DocumentBasis.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	Document.SaleAdjustment.Discrepancies AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|	AND NOT TabularSectionData.Ref.AdjustmentKind IN (
			|		VALUE(Enum.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated), 
			|		VALUE(Enum.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated))
			|
			|GROUP BY
			|	TabularSectionData.VATRate,
			|	CASE
			|		WHEN TabularSectionData.Ref.DocumentBasis REFS Document.CustomerInvoice
			|				AND TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.DocumentBasis.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END
			|
			|HAVING
			|	SUM(TabularSectionData.AmountIncludingVAT) > 0
			|
			|UNION ALL
			|
			|SELECT
			|	SUM(ARAPAdjustment.VATAmount),
			|	SUM(ARAPAdjustment.AmountIncludingVAT),
			|	ARAPAdjustment.VATRate AS VATRate,
			|	FALSE
			|FROM
			|	Document.SaleAdjustment.ARAPAdjustment AS ARAPAdjustment
			|WHERE
			|	ARAPAdjustment.Ref = &DocumentOperations
			|	AND ARAPAdjustment.Ref.AdjustmentKind IN (
			|		VALUE(Enum.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated), 
			|		VALUE(Enum.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated))
			|
			|GROUP BY
			|	ARAPAdjustment.VATRate
			|
			|HAVING
			|	SUM(ARAPAdjustment.AmountIncludingVAT) <> 0
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		QueryText =
			"SELECT
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	TabularSectionData.VATRate AS VATRate,
			|	CASE
			|		WHEN TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|	AND NOT TabularSectionData.Canceled
			|	AND (TabularSectionData.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
			|			OR TabularSectionData.Ref.PackageDepositIsRequired
			|			OR NOT TabularSectionData.Ref.ToReturnReusablePackage)
			|
			|GROUP BY
			|	TabularSectionData.VATRate,
			|	CASE
			|		WHEN TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
		QueryText = 
			"SELECT
			|	FALSE AS ThisIsDepositForPackage,
			|	TabularSectionData.VATRate AS VATRate,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	SUM(TabularSectionData.VATAmount) AS VATAmount
			|INTO FullPaymentAmounts
			|FROM
			|	Document.ReturnablePackagingRedemptionByCustomer.Goods AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|GROUP BY
			|	TabularSectionData.VATRate
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
		QueryText = 
			"SELECT
			|	FALSE AS ThisIsDepositForPackage,
			|	TabularSectionData.VATRate AS VATRate,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	SUM(TabularSectionData.VATAmount) AS VATAmount
			|INTO FullPaymentAmounts
			|FROM
			|	Document.RedemptionOfGoodsByCustodian.Goods AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|GROUP BY
			|	TabularSectionData.VATRate
			|";
	
		
	ElsIf TypeOf(Document) = Type("DocumentRef.MaterialProviderOrder2_5") Then
		QueryText = 
			"SELECT
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	UNDEFINED AS VATRate,
			|	FALSE AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|	AND NOT TabularSectionData.Canceled
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		QueryText = 
			"SELECT
			|	FALSE AS ThisIsDepositForPackage,
			|	UNDEFINED AS VATRate,
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT
			|INTO FullPaymentAmounts
			|FROM
			|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
		QueryText = 
			"SELECT
			|	FALSE AS ThisIsDepositForPackage,
			|	TabularSectionData.VATRate AS VATRate,
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT
			|INTO FullPaymentAmounts
			|FROM
			|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|GROUP BY
			|	TabularSectionData.VATRate
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
		QueryText = 
			"SELECT
			|	FALSE AS ThisIsDepositForPackage,
			|	TabularSectionData.VATRate AS VATRate,
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT
			|INTO FullPaymentAmounts
			|FROM
			|	Document.WriteOffReportFromCommissionAgent.Goods AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|GROUP BY
			|	TabularSectionData.VATRate
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
		QueryText = 
			"SELECT
			|	FALSE AS ThisIsDepositForPackage,
			|	TabularSectionData.VATRate AS VATRate,
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT
			|INTO FullPaymentAmounts
			|FROM
			|	Document.PurchasingReportToConsignorPrincipal.Goods AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|GROUP BY
			|	TabularSectionData.VATRate
			|";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ConsignmentReportToVendor") Then
		QueryText =  
			"SELECT
			|	TabularSectionData.AmountVATRemuneration AS VATAmount,
			|	TabularSectionData.VATRateOfRemuneration AS VATRate,
			|	TabularSectionData.CommissionAmount AS AmountIncludingVAT,
			|	FALSE AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	Document.ConsignmentReportToVendor AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations";
		
	ElsIf TypeOf(Document) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
		QueryText =  
			"SELECT
			|	FALSE AS ThisIsDepositForPackage,
			|	SUM(TabularSectionData.AmountSalesVAT) AS VATAmount,
			|	SUM(TabularSectionData.SalesAmount) AS AmountIncludingVAT,
			|	TabularSectionData.VATRate AS VATRate
			|INTO FullPaymentAmounts
			|FROM
			|	Document.ConsignmentReportFromCustomer.Goods AS TabularSectionData
			|WHERE
			|	TabularSectionData.Ref = &DocumentOperations
			|
			|GROUP BY
			|	TabularSectionData.VATRate";
		
	Else
		QueryText =  
			"SELECT
			|	SUM(TabularSectionData.VATAmount) AS VATAmount,
			|	SUM(TabularSectionData.AmountIncludingVAT) AS AmountIncludingVAT,
			|	TabularSectionData.VATRate AS VATRate,
			|	CASE
			|		WHEN TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	Document.SalesOrder.Goods AS TabularSectionData
			|WHERE
			|	NOT TabularSectionData.Canceled
			|	AND (TabularSectionData.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
			|			OR TabularSectionData.Ref.PackageDepositIsRequired
			|			OR NOT TabularSectionData.Ref.ToReturnReusablePackage)
			|	AND TabularSectionData.Ref = &DocumentOperations
			|
			|GROUP BY
			|	TabularSectionData.VATRate,
			|	CASE
			|		WHEN TabularSectionData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|				AND TabularSectionData.Ref.PackageDepositIsRequired
			|			THEN TRUE
			|		ELSE FALSE
			|	END
			|";
	EndIf;
	
	Return QueryText;

EndFunction

Function QueryTextForPartialPaymentAmounts()

	Return 
	"SELECT
	|	SUM(PaymentScheduleSteps.PaymentAmount) AS PaymentAmount,
	|	PaymentScheduleSteps.ThisIsDepositForPackage AS ThisIsDepositForPackage
	|INTO PaymentSteps
	|FROM
	|	PaymentScheduleSteps AS PaymentScheduleSteps
	|
	|GROUP BY
	|	PaymentScheduleSteps.ThisIsDepositForPackage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(FullPaymentAmounts.AmountIncludingVAT) AS AmountIncludingVAT,
	|	FullPaymentAmounts.ThisIsDepositForPackage AS ThisIsDepositForPackage
	|INTO TotalAmount_1
	|FROM
	|	FullPaymentAmounts AS FullPaymentAmounts
	|
	|GROUP BY
	|	FullPaymentAmounts.ThisIsDepositForPackage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentAmounts.VATRate AS VATRate,
	|	CASE
	|		WHEN TotalAmount_1.AmountIncludingVAT = 0
	|			THEN 0
	|		ELSE PaymentSteps.PaymentAmount / TotalAmount_1.AmountIncludingVAT * DocumentAmounts.AmountIncludingVAT
	|	END AS AmountIncludingVAT,
	|	CASE
	|		WHEN TotalAmount_1.AmountIncludingVAT = 0
	|			THEN 0
	|		ELSE PaymentSteps.PaymentAmount / TotalAmount_1.AmountIncludingVAT * DocumentAmounts.VATAmount
	|	END AS VATAmount
	|INTO PartialPaymentAmounts
	|FROM
	|	FullPaymentAmounts AS DocumentAmounts
	|		INNER JOIN PaymentSteps AS PaymentSteps
	|			INNER JOIN TotalAmount_1 AS TotalAmount_1
	|			ON PaymentSteps.ThisIsDepositForPackage = TotalAmount_1.ThisIsDepositForPackage
	|		ON DocumentAmounts.ThisIsDepositForPackage = PaymentSteps.ThisIsDepositForPackage
	|";

EndFunction

// Calculates the amount due, including VAT, according to the document-the basis and stages of payment of the document "Invoice for payment to the client"
//
// Parameters:
//   DocumentBasis - CatalogRef.CounterpartyContracts, DocumentRef - the document defining the VAT rate
//   PaymentSteps - ValueTable - table with payment stages (amounts, dates, percentages):
//   * PaymentAmount - Number - Payment Amount By Stage
//   * ThisIsDepositForPackage - Boolean - indication of the deposit amount for the container
//   * PaymentDate - Date - payment date by stage
//   * PaymentPercentage - Number - percentage of payment by stage
//
// Returns:
//   ValueTable - table with totals:
//     * VATRate - Number - VAT rate
//     * VATAmount - Number - amount of VAT
//     * AmountIncludingVAT - Number - amount including VAT
//
Function InvoiceAmountsToBePaid(DocumentBasis, PaymentSteps)
	
	RequestPaymentStages = New Query;
	TempTablesManager = New TempTablesManager;
	RequestPaymentStages.TempTablesManager = TempTablesManager;
	RequestPaymentStages.Text = 
		"SELECT
		|	PaymentSteps.PaymentAmount AS PaymentAmount,
		|	PaymentSteps.ThisIsDepositForPackage AS ThisIsDepositForPackage,
		|	PaymentSteps.PaymentDate AS PaymentDate,
		|	PaymentSteps.PaymentPercentage AS PaymentPercentage
		|INTO PaymentScheduleSteps
		|FROM
		|	&PaymentSteps AS PaymentSteps";
	RequestPaymentStages.SetParameter("PaymentSteps", PaymentSteps);
	RequestPaymentStages.Execute();
	
	QueriesTexts = New Array;
	
	If TypeOf(DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
		
		QueryText = 
			"SELECT
			|	CounterpartyContracts.VATRate AS VATRate,
			|	SUM(PaymentSteps.PaymentAmount) AS AmountIncludingVAT,
			|	SUM(PaymentSteps.PaymentAmount) * CounterpartyContracts.VATRate.Rate1 / (100 + CounterpartyContracts.VATRate.Rate1) AS VATAmount,
			|	PaymentSteps.ThisIsDepositForPackage AS ThisIsDepositForPackage
			|INTO FullPaymentAmounts
			|FROM
			|	PaymentScheduleSteps AS PaymentSteps
			|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
			|		ON CounterpartyContracts.Ref = &DocumentOperations
			|
			|GROUP BY
			|	CounterpartyContracts.VATRate,
			|	PaymentSteps.ThisIsDepositForPackage,
			|	CounterpartyContracts.VATRate.Rate1";
			
		QueriesTexts.Add(QueryText);
		
	Else
		QueriesTexts.Add(QueryTextForFullPaymentAmounts(DocumentBasis));
	EndIf;
	
	QueriesTexts.Add(QueryTextForPartialPaymentAmounts());
	
	FinalSelection =
		"SELECT
		|	TableOfAmounts.VATRate AS VATRate,
		|	CAST(TableOfAmounts.VATAmount AS NUMBER(31,2)) AS VATAmount,
		|	CAST(TableOfAmounts.AmountIncludingVAT AS NUMBER(31,2)) AS AmountIncludingVAT
		|FROM
		|	PartialPaymentAmounts AS TableOfAmounts";
	
	QueriesTexts.Add(FinalSelection);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueriesTexts, ";");
	Query.SetParameter("DocumentOperations", DocumentBasis);
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region VATTaxation

// The procedure fills in the tax details In the table part of the payment Decryption.
//
// Parameters:
//	Object - FormDataStructure - Current object;
//	DefaultVATTaxation - EnumRef.VATTaxationTypes - Initial value of VAT taxation for the document;
//	ElementVATTaxation - FormField - element of the form for selecting VAT taxation.
//	ItemTaxationVATRefund - FormField - Duplicate form field for the Return Analytics group.
//	UpdateVATRateAndAmount - Boolean - If "True", then we Update the VAT Rate and Recalculate the VAT Amount (with the changed rate). If "False", then fill In Only The VAT Taxation.
//
Procedure CompleteVATTaxation(Object, DefaultVATTaxation,
		ElementVATTaxation,
		ItemTaxationVATRefund=Undefined,
		UpdateVATRateAndAmount=True) Export
	
	DefaultVATTaxation = Object.VATTaxation;
	TaxationUnderContract = Enums.VATTaxationTypes.EmptyRef();
	
	If ValueIsFilled(Object.Contract) Then
		TaxationUnderContract = Common.ObjectAttributeValue(Object.Contract, "VATTaxation");
	EndIf;
	
	If Not ValueIsFilled(DefaultVATTaxation) Then
		TaxationUnderContract = DefaultVATTaxation;
	EndIf;
	
	UseVATTaxationForBusinessOperations = 
		FillInTaxationOfVATOnSalesPurchases(Object, DefaultVATTaxation, ElementVATTaxation, ItemTaxationVATRefund);
	
	CalculationObjects = Object.ARAPDetails.Unload(, "ARAPObject");
	CalculationObjects.GroupBy("ARAPObject");

	DetailsOfCalculationObjects = Common.ObjectsAttributesValues(CalculationObjects.UnloadColumn("ARAPObject"), "VATTaxation, Object");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	LinesToRecalculateVATAmount = New Array;
	FillInLinesAndRecalculateVAT = New Array;
	
	For Each PaymentDecryptionString In Object.ARAPDetails Do
			
		If (ValueIsFilled(PaymentDecryptionString.ARAPObject)
				And Not DetailsOfCalculationObjects[PaymentDecryptionString.ARAPObject].Object = Object.Ref)
				Or Not UseVATTaxationForBusinessOperations Then
				
			If ValueIsFilled(DetailsOfCalculationObjects[PaymentDecryptionString.ARAPObject]) Then
				VATTaxation = DetailsOfCalculationObjects[PaymentDecryptionString.ARAPObject].VATTaxation;
			EndIf;
			
			If Not ValueIsFilled(VATTaxation) Then
				VATTaxation = TaxationUnderContract;
			EndIf;
			
		Else
			VATTaxation = DefaultVATTaxation;
		EndIf;
		
		CalculateBid = False;
		RecalculateVATAmount = False;
		
		If Not VATTaxation = PaymentDecryptionString.VATTaxation Then
			
			PaymentDecryptionString.VATTaxation = VATTaxation; 
			CalculateBid = True;
		
		EndIf;
		
		If UpdateVATRateAndAmount
			And (CalculateBid Or PaymentDecryptionString.VATRate = Catalogs.VATRates.EmptyRef()) Then
			
			If PaymentDecryptionString.VATRate = Catalogs.VATRates.EmptyRef() Then
				
				FillInLinesAndRecalculateVAT.Add(PaymentDecryptionString);
				
			Else
				
				VATRate = PaymentDecryptionString.VATRate;
				VATAccountingERP.FillInVATRateForPayments_(
					PaymentDecryptionString.VATRate,
					PaymentDecryptionString.VATTaxation,
					Object.Organization,
					Object.Date);
				RecalculateVATAmount = Not VATRate = PaymentDecryptionString.VATRate;
				If RecalculateVATAmount Then
					LinesToRecalculateVATAmount.Add(PaymentDecryptionString);
				EndIf;
				
			EndIf;

		EndIf;
			
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		LinesToRecalculateVATAmount,
		StructureOfActions,
		Object.ARAPDetails,
		CachedValues);
		
	StructureOfActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	StructureOfActionParameters.VATTaxationAtTabularPart = True;
		
	StructureOfActions.Insert("FillInVATRate", StructureOfActionParameters);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		FillInLinesAndRecalculateVAT,
		StructureOfActions,
		Object.ARAPDetails,
		CachedValues);
	
EndProcedure

// The procedure fills in the details of Stalkings,Commands table part of Rasshifrovyvaetsya.
//
// Parameters:
//	Object - FormDataStructure - Current object;
//	LineID - Number, Undefined - The ID of the row to refresh rates, if not specified, it updates all rows;
//
Procedure UpdateTaxRateRecalculateVATAmount(Object, LineID) Export
	
	StructureOfActions = New Structure;
	
	PaymentDecryptionString = Object.ARAPDetails.FindByID(LineID);
	
	ARAPObjectLink = Common.ObjectAttributeValue(PaymentDecryptionString.ARAPObject, "Object");
	
	If (ValueIsFilled(PaymentDecryptionString.ARAPObject)
		And Not ARAPObjectLink = Object.Ref) Then //NOT value filled in(Payment string.Order) OR A payment string.Order = Object.Link Then
		
		PaymentDecryptionString.VATTaxation = Common.ObjectAttributeValue(PaymentDecryptionString.ARAPObject, "VATTaxation");
		
		If ValueIsFilled(ARAPObjectLink)
			And CommonClientServer.HasAttributeOrObjectProperty(ARAPObjectLink, "VATTaxationIsDeterminedInDocuments") Then
			If Common.ObjectAttributeValue(ARAPObjectLink, "VATTaxationIsDeterminedInDocuments") Then
				PaymentDecryptionString.VATTaxation = Object.VATTaxation;
			EndIf;
		EndIf;
		
		VATAccountingERP.FillInVATRateForPayments_(PaymentDecryptionString.VATRate, PaymentDecryptionString.VATTaxation, Object.Organization, Object.Date);
		
	Else
		
		PaymentDecryptionString.VATTaxation = Object.VATTaxation;
		
		If Not ValueIsFilled(PaymentDecryptionString.ARAPObject)
			And ValueIsFilled(Object.Contract) Then
			
			VATRateForPayments = Common.ObjectAttributeValue(Object.Contract, "VATRate");
			PaymentDecryptionString.VATRate = VATRateForPayments;
			
		Else
			
			StructureOfActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
			StructureOfActionParameters.VATTaxationAtTabularPart = True;
			StructureOfActions.Insert("FillInVATRate", StructureOfActionParameters);
			
		EndIf;
		
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	RowsToProcess = New Array;
	RowsToProcess.Add(PaymentDecryptionString);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ARAPDetails,
		CachedValues);
	
EndProcedure

// The procedure fills in the Attributes of the SummaNDS of the table part of the decryption of the payment.
//
// Parameters:
//	Object - FormDataStructure - the current object.
//	LineID - Number - Id of the row to update the bid.
//
Procedure RecalculateVATAmount(Object, LineID) Export
	
	PaymentDecryptionString = Object.ARAPDetails.FindByID(LineID);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	RowsToProcess = New Array;
	RowsToProcess.Add(PaymentDecryptionString);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ARAPDetails,
		CachedValues);
	
EndProcedure

Function GetListOfBusinessReturnTransactionsForDocument(DocumentType)
	
	ArrayOfBusinessOperations = New Array();
	
	If DocumentType = Type("DocumentRef.CashVoucher") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.CashAccountReceiptNote") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromVendor);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.BankAccountReceiptNote") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromVendor);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.PaymentCardTransaction") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		
	ElsIf DocumentType = Type("DocumentRef.BankAccountIssue") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
		
	ElsIf DocumentType = Type("DocumentRef.PaymentRequest") Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
		
	EndIf;
	
	Return ArrayOfBusinessOperations;
	
EndFunction

// Clears the "VAT taxation" field of the object.
// 
// Parameters:
//  Object - DocumentObject.PaymentRequest, DocumentObject.BankAccountIssue - Object.
//
Procedure ClearVATTaxation(Object) Export
	
	If ValueIsFilled(Object.VATTaxation) Then
		
		DocumentType = TypeOf(Object.Ref);
		
		ListOfAvailablOperations = GetListOfBusinessSalesOperationsForDocument(DocumentType);
		CommonClientServer.SupplementArray(ListOfAvailablOperations, GetListOfPurchasingBusinessOperationsForDocument(DocumentType));
		
		If ListOfAvailablOperations.Find(Object.BusinessOperation) = Undefined Then
			Object.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
		Else
			Query = New Query();
			Query.Text = "SELECT
			|	CAST(ARAPDetails.ARAPObject AS Catalog.ARAPObjects) AS ARAPObject
			|INTO ARAPDetails
			|FROM
			|	&PaymentTable_3 AS ARAPDetails
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ARAPObjects.Ref AS Ref
			|FROM
			|	ARAPDetails AS ARAPDetails
			|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
			|		ON ARAPDetails.ARAPObject = ARAPObjects.Ref
			|WHERE
			|	ARAPObjects.RefType = &RefType
			|	OR ARAPDetails.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)";
			
			ReferenceTypeForCalculationObject = Common.MetadataObjectID(DocumentType);
			
			Query.SetParameter("PaymentTable_3", Object.ARAPDetails);
			Query.SetParameter("RefType", ReferenceTypeForCalculationObject);
			Result = Query.Execute().Select();
			
			If Not Result.Next() Then
				Object.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure sets the representation of VAT taxation in the selection list.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the document.
//	ChoiceList - ValueList - list of available taxes and views.
//
Procedure SetVATTaxationDisplay(Form, ChoiceList) Export
	
	For Each ChoiceItem In ChoiceList Do
		SetConditionalRegistrationTaxationVATDisplay(Form, ChoiceItem.Value,
			?(ValueIsFilled(ChoiceItem.Presentation), ChoiceItem.Presentation, ChoiceItem.Value));
	EndDo;
	
EndProcedure

// The procedure sets whether the calculation object is missing or matches in the line with the document.
//
// Parameters:
//	Object - FormDataStructure - Current object
//
Procedure FillInCorrespondenceOfCalculationObjectsToCurDocument(Object) Export
	
	For Each PaymentDecryptionString In Object.ARAPDetails Do
		
		PaymentDecryptionString.TheCalculationObjectMatchesTheDocument = ?( Not ValueIsFilled(PaymentDecryptionString.ARAPObject)
			Or Common.ObjectAttributeValue(PaymentDecryptionString.ARAPObject, "Object") = Object.Ref, True, False);
		
	EndDo;
	
EndProcedure

// Procedure sets a conditional clearance for the field of Nalogooblozhenie.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the document
//
Procedure EstablishConditionalAppearanceVATTaxation(Form) Export
	
	DocumentType = TypeOf(Form.Object.Ref);
	
	ListOfAvailablOperations = GetListOfBusinessSalesOperationsForDocument(DocumentType);
	CommonClientServer.SupplementArray(ListOfAvailablOperations, GetListOfPurchasingBusinessOperationsForDocument(DocumentType));
	
	BusinessTransactionList = New ValueList();
	BusinessTransactionList.LoadValues(ListOfAvailablOperations);
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.TranscriptOfPaymentVATTaxation.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = BusinessTransactionList;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.TranscriptOfPaymentVATTaxation.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = BusinessTransactionList;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.TranscriptOfPaymentVATTaxationText.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = BusinessTransactionList;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khớp với đối tượng tính toán>';
													|ru = '<совпадает с объектом расчетов>';
													|en = '<match with the AR/AP object>'; fa = '<match with the AR/AP object>';
													|it = '<corrisponde all''oggetto dei calcoli>';
													|pl = '<zbiega się z obiektem rozliczeń>';
													|tr = '<alacak/borç nesnesiyle eşleşir>'"));
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.TranscriptOfPaymentVATTaxationText.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = BusinessTransactionList;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.ARAPDetailsVATRate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.ARAPDetailsVATAmount.Name);
	
	ListOfTaxation = New ValueList();
	ListOfTaxation.LoadValues(VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTaxation;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

Procedure SetConditionalRegistrationTaxationVATDisplay(Form, VATTaxation, Presentation)
	
	UserSettingID = String(VATTaxation);
	Item = Undefined;
	
	For Each AppearanceItem In Form.ConditionalAppearance.Items Do
		If AppearanceItem.UserSettingID = UserSettingID Then
			Item = AppearanceItem;
			Break;
		EndIf;
	EndDo;
	
	If Item = Undefined Then
		Item = Form.ConditionalAppearance.Items.Add();
	EndIf;
	
	Item.UserSettingID = String(VATTaxation);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.TranscriptOfPaymentVATTaxation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = VATTaxation;
	
	Item.Appearance.SetParameterValue("Text", Presentation);
	
EndProcedure

// The procedure sets parameters for selecting a lease agreement.
//
// Parameters:
//	Object - FormDataStructure - Current object
//  Item - FormField - Field for entering the lease agreement.
//
Procedure SetParametersForSelectingLeaseAgreement(Object, Item) Export
	
	If Not (Object.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor) Then
		Return;
	EndIf;
	
	// Set the selection parameter
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark",False));
	
	If ValueIsFilled(Object.Counterparty) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", Object.Counterparty));
	EndIf;
	If ValueIsFilled(Object.Organization) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure
Function NamesOfFormItems(Items, AttributesArray)
	
	ReturnValue = New Array;
	For Each Item In AttributesArray Do
		If Item = "Goods.CommissionAmount" Then
			ReturnValue.Add(Items.GoodsCommissionAmount.Name);
		ElsIf Item = "Goods.AmountVATRemuneration" Then
			ReturnValue.Add(Items.GoodsAmountVATRemuneration.Name);
		Else
			ReturnValue.Add(Items[Item].Name);
		EndIf;
	EndDo;
	
	Return ReturnValue
	
EndFunction

#EndRegion
