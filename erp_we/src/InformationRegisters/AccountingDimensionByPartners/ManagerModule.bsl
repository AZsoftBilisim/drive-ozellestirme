#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function gets the reference element-the accounting Analytics key.
//
// Parameters:
//	AnalyticsParameters - Arbitrary, Structure - Collection of parameters for getting the key.
//
// Returns:
//	CatalogRef.DimensionKeysOfAccountingByPartners - The found element of the directory.
//
Function AnalyticsKeyValue(AnalyticsParameters) Export

	DimensionKey = Undefined;
	
	RecordSet = GetRecordSet(AnalyticsParameters);

	If RecordSet <> Undefined Then
		RecordSet.Read();
		
		If RecordSet.Count() > 0
			And Not ValueIsFilled(RecordSet[0].DimensionKey) Then
			RecordSet.Clear();
			RecordSet.Write();
		EndIf;

		If RecordSet.Count() > 0
			And ValueIsFilled(RecordSet[0].DimensionKey) Then
			DimensionKey = RecordSet[0].DimensionKey;
		Else
			DimensionKey = CreateAnalyticsKey(AnalyticsParameters);
		EndIf;
	Else
		DimensionKey = RecordSet[0].DimensionKey
	EndIf;
	
	Return DimensionKey;
EndFunction

// The function gets the reference element-the accounting Analytics key.
//
// Parameters:
//	AnalyticsParameters - Structure, QueryResultSelection - Collection of parameters for creating a key:
//		* Organization - CatalogRef.Companies - The organization for which the key is requested.
//		* Partner - CatalogRef.Partners - The partner for which the key is requested.
//		* Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - The counterparty for which the key is requested.
//		* Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - The Contract for which the key is requested.
//		* LineOfBusiness - CatalogRef.LinesOfBusiness - The activity for which the key is requested.
//
// Returns:
//	CatalogRef.DimensionKeysOfAccountingByPartners - The found element of the directory.
//
Function CreateAnalyticsKey(AnalyticsParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT TOP 1
	|	Dimension.Partner,
	|	Dimension.Organization,
	|	Dimension.Counterparty,
	|	Dimension.Contract,
	|	Dimension.LineOfBusiness,
	|	Dimension.DimensionKey
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS Dimension
	|WHERE
	|	Dimension.Partner = &Partner
	|	AND Dimension.Organization = &Organization
	|	AND Dimension.Counterparty = &Counterparty
	|	AND Dimension.LineOfBusiness = &LineOfBusiness
	|	AND (Dimension.Contract = &Contract 
	|		OR (Dimension.Contract = UNDEFINED AND &UpdateAgreementInKey)
	|		OR (Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				AND VALUETYPE(Dimension.Counterparty) = TYPE(Catalog.Companies)
	|				AND &UpdateAgreementInKey)
	|		)
	|");
	
	RecordSet = InformationRegisters.AccountingDimensionByPartners.CreateRecordSet();
	
	FieldsRequired = FieldsRequired();
	StructureOfAnalytics = New Structure(FieldsRequired);
	FillPropertyValues(StructureOfAnalytics, AnalyticsParameters);
	
	For Each KeyValue In StructureOfAnalytics Do
		Filter = RecordSet.Filter[KeyValue.Key]; // FilterItem
		Filter.Set(KeyValue.Value);
	EndDo;
		
	NewRow = RecordSet.Add();
		
	FillPropertyValues(NewRow, StructureOfAnalytics, FieldsRequired);
	
	Query.SetParameter("Partner", NewRow.Partner);
	Query.SetParameter("Organization", NewRow.Organization);
	Query.SetParameter("Counterparty", NewRow.Counterparty);
	Query.SetParameter("LineOfBusiness", NewRow.LineOfBusiness);
	
	If ValueIsFilled(NewRow.Contract) Then
		Query.SetParameter("Contract", NewRow.Contract);
		Query.SetParameter("UpdateAgreementInKey", False);
	Else
		If TypeOf(NewRow.Counterparty) = Type("CatalogRef.Companies") Then
			Query.SetParameter("Contract", Catalogs.IntercompanyContracts.EmptyRef());
		Else
			Query.SetParameter("Contract", Catalogs.CounterpartyContracts.EmptyRef());
		EndIf;
		Query.SetParameter("UpdateAgreementInKey", True);
	EndIf;
	
	//If the same analytics is created in another session, then one of the transactions will wait for the lock and receive the created key by request.
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.AccountingDimensionByPartners");
		LockItem.SetValue("Partner", AnalyticsParameters.Partner);
		LockItem.SetValue("Organization", AnalyticsParameters.Organization);
		LockItem.SetValue("Counterparty", AnalyticsParameters.Counterparty);
		LockItem.SetValue("Contract", AnalyticsParameters.Contract);
		LockItem.SetValue("LineOfBusiness", AnalyticsParameters.LineOfBusiness);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Result = Query.Execute();
		
		If Result.IsEmpty() Then // creating a new key
			
			CheckAgreementField(NewRow);
			
			// Creating a new analytics key.
			CatalogObject = Catalogs.DimensionKeysOfAccountingByPartners.CreateItem();
			CatalogObject.Description = DimensionKeyName(NewRow);
			FillPropertyValues(CatalogObject, AnalyticsParameters, FieldsRequired);
			CatalogObject.Write();
	
			Var_Key = CatalogObject.Ref;
	
			NewRow.DimensionKey = Var_Key;
			RecordSet.Write(False);
		Else // updating the contract in the existing key
		
			DataToFillIn = Result.Unload()[0];
			
			RecordSet.Filter.Reset();
			
			RecordSet.Filter.Partner.Set(DataToFillIn.Partner);
			RecordSet.Filter.Organization.Set(DataToFillIn.Organization);
			RecordSet.Filter.Counterparty.Set(DataToFillIn.Counterparty);
			RecordSet.Filter.LineOfBusiness.Set(DataToFillIn.LineOfBusiness);
			
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				
				If Not ValueIsFilled(Record.Contract) Then
					If TypeOf(DataToFillIn.Counterparty) = Type("CatalogRef.Counterparties") Then
						Contract = Catalogs.CounterpartyContracts.EmptyRef();
					Else
						Contract = Catalogs.IntercompanyContracts.EmptyRef();
					EndIf;
					Record.Contract = Contract;
					
					CatObject = Record.DimensionKey.GetObject();
					CatObject.Contract = Contract;
					InfobaseUpdate.WriteData(CatObject);
					
					Var_Key = Record.DimensionKey;
				EndIf;
				
			EndDo;
			
			RecordSet.Write(True);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise(ErrorDescription())
		
	EndTry;
	
	Return Var_Key;

EndFunction

// The function returns an array of accounting analytics keys for partners in which the organization matches
// the one passed in the parameters. If an empty link to the Organizations Catalog is passed, 
// an array of analytics keys is generated for all organizations available to the user.
//
// Parameters:
//	Organization - CatalogRef.Companies - The organization that the key array is generated for.
//
// Returns:
//	Array of CatalogRef.DimensionKeysOfAccountingByPartners - An array of keys by organization.
//
Function OrganizationAnalyticsKeys(Organization) Export
	
	Query = New Query;
	Query.Text ="
		|SELECT ALLOWED
		|	CatalogData.Ref AS Organization
		|INTO TTOrganizations
		|FROM
		|	Catalog.Companies AS CatalogData
		|WHERE
		|	CatalogData.Ref = &Organization
		|	OR &Organization = VALUE(Catalog.Companies.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccountingDimensionByPartners.DimensionKey AS DimensionKey
		|FROM
		|	TTOrganizations AS TTOrganizations
		|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|		ON TTOrganizations.Organization = AccountingDimensionByPartners.Organization";

	Query.SetParameter("Organization", Organization);
	
	ArrayOfAnalyticsKeysForPartners = Query.Execute().Unload().UnloadColumn("DimensionKey");
	
	Return ArrayOfAnalyticsKeysForPartners;
	
EndFunction

// The function returns the name of the analytics key.
//
// Parameters:
//	RecordManager - InformationRegisterRecordManager.AccountingDimensionByPartners
//                 - CatalogObject.DimensionKeysOfAccountingByPartners - A completed object with the necessary fields to generate the name of the analytics key.
//
// Returns:
//	String
//
Function DimensionKeyName(RecordManager) Export
	
	Description = "";
	
	MetadataDimensions = Metadata.InformationRegisters.AccountingDimensionByPartners.Dimensions;
	For Each Dimension In MetadataDimensions Do
		
		// We get a representation of the value that is specified in the data register dimension.
		ValueText = String(RecordManager[Dimension.Name]);
		If Not IsBlankString(ValueText) Then
			Description = Description + ValueText + "; ";
		EndIf;
		
	EndDo;
	
	If Right(Description, 2) = "; " Then
		Description = Left(Description, StrLen(Description) - 2);
	EndIf;
	
	Return Description;
	
EndFunction

#EndRegion

#Region Private

#Region Other

Function GetRecordSet(AnalyticsParameters)
	
	RecordSet = InformationRegisters.AccountingDimensionByPartners.CreateRecordSet();
	
	// The analytics parameters may not have all the properties
	FieldsRequired = FieldsRequired();
	StructureOfAnalytics = New Structure(FieldsRequired);
	FillPropertyValues(StructureOfAnalytics, AnalyticsParameters);
	If Not ValueIsFilled(StructureOfAnalytics.Organization)
	 And Not ValueIsFilled(StructureOfAnalytics.Partner)
	 And Not ValueIsFilled(StructureOfAnalytics.Counterparty) 
	 And Not ValueIsFilled(StructureOfAnalytics.Contract)
	 And Not ValueIsFilled(StructureOfAnalytics.LineOfBusiness) Then
		Return RecordSet
	Else
		
		For Each KeyValue In StructureOfAnalytics Do
			Filter = RecordSet.Filter[KeyValue.Key]; // FilterItem
			Filter.Set(KeyValue.Value);
		EndDo;
		
		NewRow = RecordSet.Add();
		
		FillPropertyValues(NewRow, StructureOfAnalytics, FieldsRequired);
		CheckAgreementField(NewRow);
		Return RecordSet;
	EndIf;
	
EndFunction

Function FieldsRequired()
	
	FieldsRequired = "";
	
	MetadataDimensions = Metadata.InformationRegisters.AccountingDimensionByPartners.Dimensions;
	For Each Dimension In MetadataDimensions Do
		If ValueIsFilled(FieldsRequired) Then
			FieldsRequired = FieldsRequired + ", " + Dimension.Name;
		Else
			FieldsRequired = Dimension.Name;
		EndIf;
	EndDo;
	Return FieldsRequired;
EndFunction

Procedure CheckAgreementField(RecordManager)

	If TypeOf(RecordManager.Contract) = Type("CatalogRef.CounterpartyContracts")
		And RecordManager.Partner = Catalogs.Partners.OurEnterprise
		And TypeOf(RecordManager.Counterparty) = Type("CatalogRef.Companies") Then
		Raise NStr("vi = 'Sai giá trị tham số ""Hợp đồng""';
					|ru = 'Ошибочное значение параметра ""Договор""';
					|en = 'Error value of the Contract parameter'; fa = 'Error value of the Contract parameter';
					|it = 'Valore del parametro ""Contratto"" è errato';
					|pl = 'Błąd wartości parametru ""Umowa""';
					|tr = '""Sözleşme"" parametresinin hatalı değeri'");
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf