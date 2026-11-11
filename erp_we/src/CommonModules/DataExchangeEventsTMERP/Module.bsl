
#Region Public


#Region RegisteringChangesForInitialDataUpload

// Registers changes for the initial data upload, taking into account the upload start date and the list of organizations.
// The procedure is universal and can be used to register data changes by upload start date
// and list of organizations for object data types and register record sets.
// If the list of organizations is not set (Organizations = Undefined), then changes are registered only by the start date of uploading.
// Data for all metadata objects included in the exchange plan are subject to registration.
// If the auto-registration feature is set for the metadata object as part of the exchange plan
// , or if the auto-registration feature is not set and registration rules are not set,
// then registration of changes will be performed unconditionally for all data of this type.
// If registration rules are set for the metadata object, changes will be 
// registered taking into account the upload start date and the list of organizations.
// For documents, registration of changes by upload start date and by the list of organizations is supported.
// Registration of changes by upload start date is supported for business processes and tasks.
// Registration of changes by upload start date and by the list of organizations is supported for sets of register entries.
// This procedure can serve as a prototype for developing your own change registration procedures
// for initial data upload.
//
// Parameters:
//  Recipient         - ExchangePlanRef - The node of the exchange plan for which you want to register data changes.
//  ExportStartDate - Date - The date relative to which it is necessary to register data changes for uploading.
//                       Changes will be registered for data that are located on the time axis after this date.
//  Companies        - Array of CatalogRef.Companies - A list of organizations for which you need to register data changes.
//                       If this parameter is omitted, the organizations will not be taken into account when registering changes.
//  Data             - Array of MetadataObject
//
Procedure RegisterDataByExportStartDateAndCompanies(Val Recipient, ExportStartDate, Companies = Undefined, Data = Undefined) Export
	
	FilterByCompanies = (Companies <> Undefined);
	FilterByExportStartDate = ValueIsFilled(ExportStartDate);
	
	If Not FilterByCompanies And Not FilterByExportStartDate Then
		
		If TypeOf(Data) = Type("Array") Then
			
			For Each MetadataObject In Data Do
				
				ExchangePlans.RecordChanges(Recipient, MetadataObject);
				
			EndDo;
			
		Else
			
			ExchangePlans.RecordChanges(Recipient, Data);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	FilterByExportStartDateAndCompanies = FilterByExportStartDate And FilterByCompanies;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Recipient);
	
	ExchangePlanContent = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	UseFilterByMetadata = (TypeOf(Data) = Type("Array"));
	
	For Each ExchangePlanContentItem In ExchangePlanContent Do
		
		If UseFilterByMetadata
			And Data.Find(ExchangePlanContentItem.Metadata) = Undefined
			// When forced registration, the algorithm of registration rules does not start.
			// The RPS documents are not uploaded, on their basis a retail sales report must be registered for exchange.
			Or ExchangePlanContentItem.Metadata = Metadata.Documents.GiftCertificateSale Then
			
			Continue;
			
		EndIf;
		
		FullObjectName = ExchangePlanContentItem.Metadata.FullName();
		
		If ExchangePlanContentItem.AutoRecord = AutoChangeRecord.Deny
			And DataExchangeCached.ObjectRegistrationRulesExist(ExchangePlanName, FullObjectName) Then
			
			If Common.IsCatalog(ExchangePlanContentItem.Metadata)
				And FilterByCompanies Then // Catalogs
				
				Selection = OrganizationCatalogSelection(FullObjectName, ExchangePlanContentItem, Companies);
				
				If Selection <> Undefined Then
					While Selection.Next() Do
						ExchangePlans.RecordChanges(Recipient, Selection.Ref);
					EndDo;
					
					Continue;
					
				EndIf;
				
			ElsIf Common.IsDocument(ExchangePlanContentItem.Metadata) Then // Documents
				
				If FilterByExportStartDateAndCompanies
					And ExchangePlanContentItem.Metadata.Attributes.Find("Organization") <> Undefined Then // Registration by date and organizations
					
					Selection = DocumentsSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies);
					
					While Selection.Next() Do
						
						ExchangePlans.RecordChanges(Recipient, Selection.Ref);
						
					EndDo;
					
					Continue;
					
				Else // Registration by date
					
					Selection = ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate);
					
					While Selection.Next() Do
						
						ExchangePlans.RecordChanges(Recipient, Selection.Ref);
						
					EndDo;
					
					Continue;
					
				EndIf;
				
			ElsIf Common.IsBusinessProcess(ExchangePlanContentItem.Metadata)
				Or Common.IsTask(ExchangePlanContentItem.Metadata) Then // Business processes and Tasks
				
				// Registration by date
				Selection = ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate);
				
				While Selection.Next() Do
					
					ExchangePlans.RecordChanges(Recipient, Selection.Ref);
					
				EndDo;
				
				Continue;
				
			ElsIf Common.IsRegister(ExchangePlanContentItem.Metadata) Then // Registers
				
				// Data registers (independent)
				If Common.IsInformationRegister(ExchangePlanContentItem.Metadata)
					And ExchangePlanContentItem.Metadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					
					MainFilter = MainInformationRegisterFilter(ExchangePlanContentItem.Metadata);
					
					FilterByPeriod     = (MainFilter.Find("Period") <> Undefined);
					FilterByCompany = (MainFilter.Find("Organization") <> Undefined);
					
					If FilterByExportStartDateAndCompanies And FilterByPeriod And FilterByCompany Then // Registration by date and organizations
						
						Selection = MainInformationRegisterFilterValuesSelectionByExportStartDateAndCompanies(MainFilter, FullObjectName, ExportStartDate, Companies);
						
					ElsIf FilterByExportStartDate And FilterByPeriod Then // Registration by date
						
						Selection = MainInformationRegisterFilterValuesSelectionByExportStartDate(MainFilter, FullObjectName, ExportStartDate);
						
					ElsIf FilterByCompanies And FilterByCompany Then // Registration by organization
						
						Selection = MainInformationRegisterFilterValuesSelectionByCompanies(MainFilter, FullObjectName, Companies);
						
					Else
						
						Selection = Undefined;
						
					EndIf;
					
					If Selection <> Undefined Then
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							For Each DimensionName In MainFilter Do
								
								RecordSet.Filter[DimensionName].Value = Selection[DimensionName];
								RecordSet.Filter[DimensionName].Use = True;
								
							EndDo;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					EndIf;
					
				Else // Registers (other)
					
					If FilterByExportStartDateAndCompanies
						And ExchangePlanContentItem.Metadata.Dimensions.Find("Period") <> Undefined
						And ExchangePlanContentItem.Metadata.Dimensions.Find("Organization") <> Undefined Then // Registration by date and organizations
						
						Selection = RecordSetsRecordersSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies);
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							RecordSet.Filter.Recorder.Value = Selection.Recorder;
							RecordSet.Filter.Recorder.Use = True;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					ElsIf ExchangePlanContentItem.Metadata.Dimensions.Find("Period") <> Undefined Then // Registration by date
						
						Selection = RecordSetsRecordersSelectionByExportStartDate(FullObjectName, ExportStartDate);
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							RecordSet.Filter.Recorder.Value = Selection.Recorder;
							RecordSet.Filter.Recorder.Use = True;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		ExchangePlans.RecordChanges(Recipient, ExchangePlanContentItem.Metadata);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region RegisteringChangesForInitialDataUpload

Function OrganizationCatalogSelection(FullObjectName, ExchangePlanContentItem, Companies)
	
	QueryText = "SELECT
		|	Table.Ref AS Ref
		|FROM
		|	#FullObjectName AS Table
		|WHERE
		|	Table.Organization IN(&Companies)";
	
	QueryText        = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	OrganizationSDetails = Undefined;
	
	If FullObjectName = "Catalog.Companies" Then
		
		OrganizationSDetails = "Ref";
		
	ElsIf FullObjectName = "Catalog.IntercompanyContracts" Then
		
		OrganizationSDetails = "Organization";
		
		QueryText = QueryText + "
		| OR Table.CompanyRecipient IN(&Companies)";
		
	ElsIf FullObjectName = "Catalog.CompaniesBankAccounts" Then
		
		OrganizationSDetails = "Owner";
		
	Else
		If ExchangePlanContentItem.Metadata.Attributes.Find("Organization") <> Undefined Then
			OrganizationSDetails = "Organization";
		EndIf;
	EndIf;
	
	If OrganizationSDetails = Undefined Then
		Return Undefined;
	EndIf;
	
	QueryText = StrReplace(QueryText, "Table.Organization", "Table." + OrganizationSDetails);
	
	Query = New Query;
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
	
EndFunction

Function DocumentsSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies)
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref
	|FROM
	|	#FullObjectName AS Table
	|WHERE
	|	Table.Date >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	
	If FullObjectName = "Document.BankAccountIssue" Then
		
		QueryText = QueryText + "
		|	AND (Table.Organization IN(&Companies) 
		|		OR Table.BankAccountBeneficiary.Owner IN(&Companies))";
		
	ElsIf FullObjectName = "Document.ARAPSettlement" Then
		
		QueryText = QueryText + "
		|	AND (Table.Organization IN(&Companies) 
		|		OR Table.CounterpartyDebtor IN(&Companies)
		|		OR Table.Creditor IN(&Companies))";
		
	ElsIf FullObjectName = "Document.IntercompanyGoodsReturn"
		Or FullObjectName = "Document.CustomerInvoiceIntercompany"
		Or FullObjectName = "Document.InventoryTransfer" Then
		
		QueryText = QueryText + "
		|	AND (Table.Organization IN(&Companies) 
		|		OR Table.CompanyRecipient IN(&Companies))";
		
	ElsIf FullObjectName = "Document.CommissionReportIntercompany"
		Or FullObjectName = "Document.CommissionWriteOffReportIntercompany" Then
		
		QueryText = QueryText + "
		|	AND (Table.Organization IN(&Companies) 
		|		OR Table.Consignee IN(&Companies))";
		
	Else
		QueryText = QueryText + "
		|	AND Table.Organization IN(&Companies)";
	
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref
	|FROM
	|	#FullObjectName AS Table
	|WHERE
	|	Table.Date >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function RecordSetsRecordersSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	#FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Organization IN(&Companies)
	|	AND RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function RecordSetsRecordersSelectionByExportStartDate(FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	#FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByExportStartDateAndCompanies(MainFilter, FullObjectName, ExportStartDate, Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	*
	|FROM
	|	#FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Organization IN(&Companies)
	|	AND RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "*", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByExportStartDate(MainFilter, FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT DISTINCT
	|	*
	|FROM
	|	#FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "*", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByCompanies(MainFilter, FullObjectName, Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	*
	|FROM
	|	#FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Organization IN(&Companies)";
	
	QueryText = StrReplace(QueryText, "#FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "*", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilter(MetadataObject)
	
	Result = New Array;
	
	If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical
		And MetadataObject.MainFilterOnPeriod Then
		
		Result.Add("Period");
		
	EndIf;
	
	For Each Dimension In MetadataObject.Dimensions Do
		
		If Dimension.MainFilter Then
			
			Result.Add(Dimension.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region ProceduresAndFunctionsCommonToAllExchangePlans

// Updates the cache of exchange plan node settings values
Procedure UpdateRegistrationMechanismCache() Export
	
	If Not Common.DataSeparationEnabled() Then
		DataExchangeServerCall.ResetObjectsRegistrationMechanismCache();
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Controls the creation of the exchange plan node
// 
// Parameters:
//   Source - ExchangePlanObject - The node of the exchange plan that we record
//   Cancel - Boolean - False if node entry is allowed.
//
Procedure ControlCreationOfExchangePlanNodeBeforeWriting(Source, Cancel) Export
	
	If Source.DataExchange.Load = True Then
		
		Return;
		
	EndIf;
	
	If Source.ThisNode = True Then
		
		Return;
		
	EndIf;
	
	Cancel = Not DataExchangeTMERP.ThisIsCreationOfExchangeNode(Source);
	
EndProcedure

// Defines the default account mask.
// Returns:
//	 String
Function AccountMask() Export 
	LocalizationRFService = Constants.LocalizationRFService.Get();
	If LocalizationRFService Then
		Return "99.99.9";
	Else
		Return "";
	EndIf;
EndFunction

#EndRegion

#EndRegion
