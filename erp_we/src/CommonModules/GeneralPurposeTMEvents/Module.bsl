
#Region Internal

// Parameters:
// 	Source - ChartOfCharacteristicTypesObject, DocumentObject, CatalogObject -
// 	Cancel - Boolean -
Procedure ExcludeLinksSearchBeforeDelete(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;

	SourceType = TypeOf(Source);
	
	If SourceType = Type("ChartOfCharacteristicTypesObject.AdditionalAttributesAndInfo") Then
		
		SetPrivilegedMode(True);
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	Attributes.Ref
		|FROM
		|	(SELECT
		|		TabularSection.Ref AS Ref
		|	FROM
		|		Catalog.ItemKinds.AttributesForProductsControl AS TabularSection
		|	WHERE
		|		TabularSection.Property = &PropertyToDelete
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TabularSection.Ref
		|	FROM
		|		Catalog.ItemKinds.AttributesForItemVariantsControl AS TabularSection
		|	WHERE
		|		TabularSection.Property = &PropertyToDelete
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TabularSection.Ref
		|	FROM
		|		Catalog.ItemKinds.AttributesForBatchControl AS TabularSection
		|	WHERE
		|		TabularSection.Property = &PropertyToDelete
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TabularSection.Ref
		|	FROM
		|		Catalog.ItemKinds.AttributesOfQuickFilterOfProducts AS TabularSection
		|	WHERE
		|		TabularSection.Property = &PropertyToDelete
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TabularSection.Ref
		|	FROM
		|		Catalog.ItemKinds.AttributesOfItemVariantQuickFilter AS TabularSection
		|	WHERE
		|		TabularSection.Property = &PropertyToDelete) AS Attributes";
		
		Query.SetParameter("PropertyToDelete", Source.Ref);
		
		Selection = Query.Execute().Select();
		
		BeginTransaction();
			
		Try
			
			While Selection.Next() Do
				
				Block = New DataLock;
				LockItem = Block.Add("Catalog.ItemKinds");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.SetValue("Ref", Selection.Ref);
				
				Block.Lock();
				LockDataForEdit(Selection.Ref);
				ObjectWithLink = Selection.Ref.GetObject(); // CatalogObject.ItemKinds - 
				
				RemoveOccurrencesOfElementFromTablePart(ObjectWithLink.AttributesForProductsControl,     Source.Ref, "Property");
				RemoveOccurrencesOfElementFromTablePart(ObjectWithLink.AttributesForItemVariantsControl,    Source.Ref, "Property");
				RemoveOccurrencesOfElementFromTablePart(ObjectWithLink.AttributesForBatchControl,            Source.Ref, "Property");
				RemoveOccurrencesOfElementFromTablePart(ObjectWithLink.AttributesOfQuickFilterOfProducts,  Source.Ref, "Property");
				RemoveOccurrencesOfElementFromTablePart(ObjectWithLink.AttributesOfItemVariantQuickFilter, Source.Ref, "Property");
				
				ObjectWithLink.Write();
				
			EndDo;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorDescription = ErrorDescription();
			Raise ErrorDescription;
			
		EndTry;
	ElsIf SourceType = Type("DocumentObject.ChangeIntangibleAssetFinancialDetails2_4") 
		Or SourceType = Type("DocumentObject.ChangeFixedAssetFinancialDetails2_4")
		Or SourceType = Type("DocumentObject.FixedAssetsCostAdditions2_4")
		Or SourceType = Type("DocumentObject.IARevaluation2_4")
		Or SourceType = Type("DocumentObject.FARevaluation2_4")
		Or SourceType = Type("DocumentObject.IntangibleAssetsInitialRecognition2_4")
		Or SourceType = Type("DocumentObject.FixedAssetsInitialRecognition2_4")
		Or SourceType = Type("DocumentObject.RecognizeSubAssetsComponentsOfDepreciation")
		Or SourceType = Type("DocumentObject.SplitFixedAssets")
		Or SourceType = Type("DocumentObject.MergeOfFixedAssets")
		Or SourceType = Type("DocumentObject.DisposeIntangibleAssets2_4")
		Or SourceType = Type("DocumentObject.DisposeFixedAssets2_4")
		Or SourceType = Type("DocumentObject.IntangibleAssetImprovement") Then
		
		SetPrivilegedMode(True);
		
		TableName = Common.TableNameByRef(Source.Ref);
		
		QueryText = 
		"SELECT
		|	DocumentData.Ref AS Ref
		|FROM
		|	&Table AS DocumentData
		|WHERE
		|	DocumentData.DocumentInAnotherAccounting = &RemovableObject";
		QueryText = StrReplace(QueryText, "&Table", TableName);
		
		Query = New Query(QueryText);
		Query.SetParameter("RemovableObject", Source.Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		BeginTransaction();
		Try
		
			While Selection.Next() Do
			
				Block = New DataLock;
				LockItem = Block.Add(TableName);
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.SetValue("Ref", Selection.Ref);
				
				Block.Lock();
				LockDataForEdit(Selection.Ref);
				
				ObjectWithLink = Selection.Ref.GetObject(); // DocumentObject - 
				ObjectWithLink.DocumentInAnotherAccounting = Undefined;
				ObjectWithLink.Write();
			
			EndDo;
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
			
			ErrorDescription = ErrorDescription();
			Raise ErrorDescription;
		EndTry; 
		
	ElsIf SourceType = Type("CatalogObject.BudgetFlowItems") 
		Or SourceType = Type("CatalogObject.BudgetBalanceItems") Then
		
		SetPrivilegedMode(True);
		
		QueryText = 
		"SELECT
		|	ActualDataQueryRulesByBudgetBalanceItems.Ref AS Ref
		|FROM
		|	Catalog.ActualDataQueryRulesByBudgetBalanceItems AS ActualDataQueryRulesByBudgetBalanceItems
		|WHERE
		|	ActualDataQueryRulesByBudgetBalanceItems.BudgetBalanceItem = &RemovableObject
		|
		|UNION ALL
		|
		|SELECT
		|	ActualDataQueryRulesByBudgetFlowItems.Ref
		|FROM
		|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
		|WHERE
		|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem = &RemovableObject";
		
		Query = New Query(QueryText);
		Query.SetParameter("RemovableObject", Source.Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		BeginTransaction();
		Try
		
			While Selection.Next() Do
			
				Block = New DataLock;
				TableName = Common.TableNameByRef(Selection.Ref);
		
				LockItem = Block.Add(TableName);
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.SetValue("Ref", Selection.Ref);
				
				Block.Lock();
				LockDataForEdit(Selection.Ref);
				
				ObjectWithLink = Selection.Ref.GetObject();
				ObjectWithLink.Delete();
			
			EndDo;
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
			
			ErrorDescription = ErrorDescription();
			Raise ErrorDescription;
		EndTry; 
	ElsIf SourceType = Type("CatalogObject.TechnologicalProcesses") Then
		
		SetPrivilegedMode(True);
		
		QueryText = "
		|SELECT
		|	ManufacturingOperations.Ref                  AS Ref,
		|	ManufacturingOperations.Owner                AS Owner,
		|	ManufacturingOperations.Basis.Presentation AS BasisPresentation
		|FROM
		|	Catalog.ManufacturingOperations AS ManufacturingOperations
		|WHERE
		|	ManufacturingOperations.Basis = &RemovableObject";
		
		Query = New Query(QueryText);
		Query.SetParameter("RemovableObject", Source.Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		BeginTransaction();
		Try
		
			While Selection.Next() Do
			
				Block = New DataLock;
		
				LockItem = Block.Add("Catalog.ManufacturingOperations");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.SetValue("Ref", Selection.Ref);
				LockItem.SetValue("Owner", Selection.Owner);
				LockItem.SetValue("BillOfMaterials", Catalogs.BillsOfMaterials.GetRef());
				
				Block.Lock();
				
				ObjectWithLink = Selection.Ref.GetObject(); // CatalogObject.ManufacturingOperations
				ObjectWithLink.Basis = StrTemplate("%1 (%2)", Selection.BasisPresentation, NStr("vi = 'đã xóa';
																								|ru = 'удален';
																								|en = 'deleted'; fa = 'deleted';
																								|it = 'eliminato';
																								|pl = 'deleted';
																								|tr = 'silindi'"));
				ObjectWithLink.Write();
			
			EndDo;
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
			
			ErrorDescription = ErrorDescription();
			Raise ErrorDescription;
		EndTry;
	EndIf;
	
EndProcedure

Procedure DeleteEmployeeInChargeInCatalogsFilling(Source, FillingData, FillingText, StandardProcessing) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	EmployeeInChargeInDocuments = GetFunctionalOption("EmployeeInChargeInDocuments");
	StandardRef 		 = Catalogs.Users.GetRef(New UUID("aa00559e-ad84-4494-88fd-f0826edc46f0"));
	CurrentUser		 = Users.AuthorizedUser();
	MetadataOfDocument 	 = Source.Metadata();
	
	If Not EmployeeInChargeInDocuments Or (StandardRef = CurrentUser 
		And Common.ObjectAttributeValue(CurrentUser, "IsInternal")) Then
		
		If Not Source.IsFolder Then 
			If MetadataOfDocument.Attributes.Find("EmployeeResponsible") <> Undefined Then
				Source.EmployeeResponsible = Undefined;
			EndIf;
			
			If MetadataOfDocument.Attributes.Find("Manager") <> Undefined Then
				Source.Manager = Undefined;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DeleteEmployeeInChargeInDocumentsFilling(Source, FillingData, FillingText, StandardProcessing) Export
	
	ResponsiblePersonsServer.ClearResponsiblePersonInDocument(Source);
	
EndProcedure

// Handler for subscribing to the event registrationdannotable Documents
// 
// Parameters:
// 	Source - DocumentObject -
// 	Cancel - Boolean - 
Procedure WhenRecordingDocumentRegistrationOfPrimaryDocumentData(Source, Cancel) Export
	Var DocumentNumber, DocumentDate;
	 
	If Source.DataExchange.Load = True
		And Source.AdditionalProperties.Property("RegisterPrimaryDocumentData")
		And Source.AdditionalProperties.RegisterPrimaryDocumentData = False Then
		// The data register of primary documents essentially contains the data of the document.
		// During exchanges, register formation must also be performed. Without this, the data will not be correct.
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Ref = Source.Ref;
	MetadataOfDocument = Source.Metadata();
	
	AttributesNames = "Number, Date";
	
	ThisIsIntercampanyDocument     = Common.HasObjectAttribute("ARAPAccountingViaSeparateCounterparty", MetadataOfDocument);
	ThereIsIncomingDocumentNumber = Common.HasObjectAttribute("IncomingDocumentNumber", MetadataOfDocument);
	ThereIsPresentationOfNumber     = Common.HasObjectAttribute("PresentationOfNumber", MetadataOfDocument);
	ThereIsDateOfIncomingDocument  = Common.HasObjectAttribute("IncomingDocumentDate", MetadataOfDocument); 
	ThereAreAttributeFix     = Common.HasObjectAttribute("Patch", MetadataOfDocument);
	ThereIsCommissionAgentSNumber       = Common.HasObjectAttribute("ConsigneeNumber", MetadataOfDocument);
	ThereIsCommissionAgentSDate        = Common.HasObjectAttribute("ConsigneeDate", MetadataOfDocument);
	
	ThereArePropsBusinessOperation = Common.HasObjectAttribute("BusinessOperation", MetadataOfDocument); 
	ThereArePropsAndDate         = Common.HasObjectAttribute("ReferenceDocumentDateForPrintForms", MetadataOfDocument); 
	ThereArePropsAndNumber        = Common.HasObjectAttribute("BaseDocumentNumber", MetadataOfDocument); 
	
	If ?(ThisIsIntercampanyDocument, Source["ARAPAccountingViaSeparateCounterparty"], True) 
		 And ThereIsIncomingDocumentNumber Then
		 
		AttributesNames = AttributesNames + ", IncomingDocumentNumber";
		If ThereIsDateOfIncomingDocument Then
			AttributesNames = AttributesNames + ", IncomingDocumentDate";
		EndIf;
		
	EndIf;
	
	If ThereIsPresentationOfNumber Then
		AttributesNames = AttributesNames + ", PresentationOfNumber";
	EndIf;
	
	Attributes = New Structure(AttributesNames);
	FillPropertyValues(Attributes, Source);
	
	// Installation of a controlled lock.
	DataLock = New DataLock;
	LockItem = DataLock.Add("InformationRegister.SourceDocumentsData");
	LockItem.SetValue("Document", Ref);
	DataLock.Lock();
	
	DocumentNumber	= "";
	DocumentDate	= '00010101';
	
	If ThereIsCommissionAgentSNumber And ValueIsFilled(Source.ConsigneeNumber)
		And ThereIsCommissionAgentSDate And ValueIsFilled(Source.ConsigneeDate) Then
		DocumentNumber = Source.ConsigneeNumber;
		DocumentDate  = Source.ConsigneeDate;
	ElsIf ThereArePropsBusinessOperation
		And ConsignmentSalesServer.SalesViaCommissionAgent(Source.BusinessOperation)
		And ThereArePropsAndNumber And ValueIsFilled(Source.BaseDocumentNumber)
		And ThereArePropsAndDate And ValueIsFilled(Source.ReferenceDocumentDateForPrintForms) Then
		DocumentNumber = Source.BaseDocumentNumber;
		DocumentDate  = Source.ReferenceDocumentDateForPrintForms;
	ElsIf Attributes.Property("IncomingDocumentNumber") Then
		DocumentNumber	= TrimAll(Attributes.IncomingDocumentNumber);
		If Attributes.Property("IncomingDocumentDate") Then
			DocumentDate = Attributes.IncomingDocumentDate;
		EndIf;
	ElsIf Attributes.Property("PresentationOfNumber") Then
		DocumentNumber	= TrimAll(Attributes.PresentationOfNumber);
		DocumentDate	= Attributes.Date;
	Else
		DocumentNumber	= ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number, False, True);
		DocumentDate	= Attributes.Date;
	EndIf;
	
	OrganizationsToRegister = New Map();
	AddOrganizationsToRegistration(Source, MetadataOfDocument, OrganizationsToRegister);
	
	If Common.HasObjectAttribute("ReversedDocument", MetadataOfDocument) 
		And ValueIsFilled(Source["ReversedDocument"]) Then
		DocumentObjectBeingReversed = Source["ReversedDocument"].GetObject();
		AddOrganizationsToRegistration(DocumentObjectBeingReversed, DocumentObjectBeingReversed.Metadata(), OrganizationsToRegister);
	EndIf;
	
	RegisterRecordSet = InformationRegisters.SourceDocumentsData.CreateRecordSet();
	RegisterRecordSet.Filter.Document.Set(Ref);
	
	For Each KeyAndValue In OrganizationsToRegister Do
		
		Organization = KeyAndValue.Key;
		AttributeName = KeyAndValue.Value;
		
		NewRecord = RegisterRecordSet.Add();
		NewRecord.Organization = Organization;
		NewRecord.Document    = Ref;
		
		If ThisIsIntercampanyDocument And AttributeName = "Organization" Then
			NewRecord.Number    = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number, True, True);
			NewRecord.Date     = Attributes.Date;
		Else
			NewRecord.Number    = DocumentNumber;
			NewRecord.Date     = DocumentDate;
		EndIf;
		
		NewRecord.RecorderNumber = Attributes.Number;
		NewRecord.RecorderDate = Attributes.Date;
		
	EndDo;
	
	RegisterRecordSet.Write(True);
	
	SetPrivilegedMode(False);
	
EndProcedure

// The event subscription handler checks the option value and uses multiple Organizations.
// Called when writing an item in the Organizations directory.
//
Procedure CheckValueOfUseMultipleCompaniesOptionOnWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Source.IsFolder
	 And Not GetFunctionalOption("UseMultipleCompanies")
	 And Catalogs.Companies.NumberOfOrganizations() > 1 Then
		
		SetPrivilegedMode(True);
		Constants.UseMultipleCompanies.Set(True);
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure RemoveOccurrencesOfElementFromTablePart(TabularSection, Ref, Column)
	
	Filter = New Structure(Column, Ref);
	
	Rows = TabularSection.FindRows(Filter);
	For Each CurrRow In Rows Do
		TabularSection.Delete(CurrRow);
	EndDo;
	
EndProcedure

Procedure AddOrganizationsToRegistration(Source, MetadataOfDocument, OrganizationsToRegister)
	
	// Let's add organizations to the array of organizations from the document header
	ArrayOfBusinessDetails = NamesOfBusinessDetails(MetadataOfDocument);
	For Each CompanyAttribute1 In ArrayOfBusinessDetails Do
		AddCompany(OrganizationsToRegister, Source, CompanyAttribute1);
	EndDo;
	
	// Let's add an array of organizations with organizations from tabular parts
	For Each TabularSection In MetadataOfDocument.TabularSections Do
		
		ArrayOfBusinessDetails = NamesOfBusinessDetails(TabularSection);
		If ArrayOfBusinessDetails.Count() = 0 Then
			Continue;
		EndIf;
		
		For Each String In Source[TabularSection.Name] Do
			For Each CompanyAttribute1 In ArrayOfBusinessDetails Do
				AddCompany(OrganizationsToRegister, String, CompanyAttribute1);
			EndDo;
		EndDo;
	
	EndDo;
	
EndProcedure

Procedure AddCompany(OrganizationsToRegister, Data, AttributeName)
	
	AttributeValue = Data[AttributeName];
	
	If ValueIsFilled(AttributeValue) 
		And TypeOf(AttributeValue) = Type("CatalogRef.Companies") Then
		
		OrganizationsToRegister.Insert(AttributeValue, AttributeName);
		
	EndIf;
	
EndProcedure

Function NamesOfBusinessDetails(MetadataObject)
	
	FullName = MetadataObject.FullName();
	
	Return CompaniesCached.NamesOfBusinessDetails(FullName);

EndFunction

#EndRegion
