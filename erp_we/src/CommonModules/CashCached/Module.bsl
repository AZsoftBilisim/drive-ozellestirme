
#Region Public

// Generates the request text for getting the specified payment object details
//
// Parameters:
//	SourceDetails_ - String - The name of the source item containing the calculation object
//                             consisting of the table name and separated by a period of the item name.
//                             For Example: Data From The Register.Order
//	PaymentObjectDetails_ - String - Name of the payment object's details
//	FullNameOfPropsMetadata - String - The full path to the Attribute metadata as in the metadata tree.
//                                          For example: "Documents.Receipt of non-cash monetary funds.Tabular parts.Decryption of the payment.Attributes.Order"
//                                                or "Accumulation registers.calculationsclientamiposrocam.Measurements.Object of accounts".
//
// Returns:
//	String - Query text
//
Function RequestTextForPaymentObjectDetails(
			SourceDetails_ = "T.ARAPObject",
			PaymentObjectDetails_ = "Contract",
			FullNameOfPropsMetadata = "DefinedTypes.ARAPObject") Export
	
	FieldText = "CASE" + Chars.LF; //@Query-part
	ConditionTemplate = "		WHEN VALUETYPE(%1) = TYPE(%2)
					|			THEN CAST(%1 AS %2).%3";
	ContractTemplate = "		WHEN VALUETYPE(%1) = TYPE(%2)
					 |			THEN %1";
	SelectionConditions = New Array;
	ContractTypes = Metadata.Catalogs.DimensionKeysOfAccountingByPartners.Attributes.Contract.Type.Types();
	ContractTypes.Add(Type("CatalogRef.GiftCertificates"));
	
	TypesOfCalculationObjects = TMCommonUse.MetadataByName(FullNameOfPropsMetadata).Type.Types();
	For Each TypeOfCalculationObject In TypesOfCalculationObjects Do
		
		If TypeOfCalculationObject = Type("Null") Or TypeOfCalculationObject = Type("Undefined") Then
			Continue;
		EndIf;
		
		FullTypeName = Metadata.FindByType(TypeOfCalculationObject).FullName();
		
		If StrFind(FullTypeName, "Enum") > 0 Then
			Continue;
		EndIf;
		
		If Upper(PaymentObjectDetails_) = "CONTRACT" And ContractTypes.Find(TypeOfCalculationObject) <> Undefined Then
			ConditionText = StrTemplate(ContractTemplate, SourceDetails_, FullTypeName);
		Else
			PropsForSubstitution = PaymentObjectDetails_;
			If FullNameOfPropsMetadata = "DefinedTypes.ARAPObjectWithVendor"
				And PropsForSubstitution = "FinancialAccountingGroup"
				And (FullTypeName = "Document.CustomerInvoiceIntercompany" Or
					FullTypeName = "Catalog.IntercompanyContracts") Then
				PropsForSubstitution = "FinancialAccountingGroupOfRecipient";
			ElsIf FullNameOfPropsMetadata = "DefinedTypes.ARAPObjectWithVendor"
				And PropsForSubstitution = "FinancialAccountingGroup"
				And FullTypeName = "Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany" Then
				PropsForSubstitution = "MaterialProviderFinancialAccountingGroup";
			EndIf;
			ConditionText = StrTemplate(ConditionTemplate, SourceDetails_, FullTypeName, PropsForSubstitution);
		EndIf;
		SelectionConditions.Add(ConditionText);
		
	EndDo;
	ConditionText = StrConcat(SelectionConditions, Chars.LF);
	Return FieldText + ConditionText + Chars.LF + "END"; //@Query-part
	
EndFunction

// Getting the XDTO factory according to the schema version .
//
// Parameters:
//  FormatVersion - String - schema version.
// 
// Returns:
//  XDTOFactory - a factory created based on the scheme.
//
Function ISO20022Factory(FormatVersion) Export
	
	SetPrivilegedMode(True);
	
	SchemaBinaryData = DataProcessors.EDIWithBanks.GetTemplate(StrReplace(FormatVersion, ".", "_"));
	VremSchemaFile = GetTempFileName("xsd");
	SchemaBinaryData.Write(VremSchemaFile);
	Factory = CreateXDTOFactory(VremSchemaFile);
	FileSystem.DeleteTempFile(VremSchemaFile);
	Return Factory;
	
EndFunction

// Returns information about the company's bank account.
//
// Parameters:
//  BankAccount - CatalogRef.CompaniesBankAccounts - link to the bank account.
//
// Returns:
//	See Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails.
//
Function GetCompanySBankAccountDetails(BankAccount) Export

	Return Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);

EndFunction

// Returns information about the company's cash account.
//
// Parameters:
//  CashAccount - CatalogRef.CashAccounts - The link to the cashier.
//
// Returns:
//	See Catalogs.CashAccounts.GetCheckoutDetails.
//
Function GetCheckoutDetails(CashAccount) Export

	Return Catalogs.CashAccounts.GetCheckoutDetails(CashAccount);

EndFunction

// See Catalogs.CashFlowReportItems.ArticlesOfBusinessOfOperation
// 
Function ArticlesOfBusinessOfOperation(BusinessOperation) Export

	Return Catalogs.CashFlowReportItems.ArticlesOfBusinessOfOperation(BusinessOperation);

EndFunction

#EndRegion

#Region Private

Function RequestTextCacheOfPaymentDetails(TableName, GraphFields) Export
	
	QuerySchema = New QuerySchema;
	SelectionRequest = QuerySchema.QueryBatch[0];
	Operator = QuerySchema.QueryBatch[0].Operators[0];
	
	If Operator.Sources.FindByName(TableName) = Undefined Then
		SchemaSource = Operator.Sources.Add(TableName);
		
		For Each Field In GraphFields Do
			If SchemaSource.Source.AvailableFields.Find(Field.Key) <> Undefined Then
				SchemaExpression = Operator.SelectedFields.Add(Field.Key);
				If ValueIsFilled(Field.Value) Then
					SchemeColumn = SelectionRequest.Columns.Find(SchemaExpression);
					If SchemeColumn <> Undefined And SelectionRequest.Columns.Find(Field.Value) = Undefined Then
						SchemeColumn.Alias = Field.Value;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		If SchemaSource.Source.AvailableFields.Find("Contract") <> Undefined Then
			Operator.SelectedFields.Add("Contract.CashFlowItem");
		EndIf;
		If SchemaSource.Source.AvailableFields.Find("Terms") <> Undefined Then
			Operator.SelectedFields.Add("Terms.CashFlowItem");
		EndIf;
	EndIf;
	
	Operator.Filter.Add("Ref IN (&Ref)");
	
	Return QuerySchema.GetQueryText();
	
EndFunction

Function RateOfConversion(CurrentCurrency, NewCurrency, Date) Export
	
	RateOfConversion = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(CurrentCurrency, NewCurrency, Date);
	
	Return ?(RateOfConversion = 0, 1, RateOfConversion);
	
EndFunction

#EndRegion
