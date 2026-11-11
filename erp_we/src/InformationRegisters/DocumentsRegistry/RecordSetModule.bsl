#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		FillInRecordIds(ThisObject);
		Return;
	EndIf;
	
	FillInRecordIds(ThisObject);
	
	If Not PrivilegedMode()
		And Not Users.IsFullUser() Then
		Cancel = True;
	EndIf;

	If AdditionalProperties.Property("TempTablesManager") Then // is it holding or removing a holding
		
		Query = New Query(
			"SELECT
			|	DocumentsRegistry.BusinessOperation    AS BusinessOperation,
			|	DocumentsRegistry.Organization              AS Organization,
			|	DocumentsRegistry.Partner                  AS Partner,
			|	DocumentsRegistry.StorageLocation            AS StorageLocation,
			|	DocumentsRegistry.Counterparty               AS Counterparty,
			|	DocumentsRegistry.Department            AS Department,
			|	DocumentsRegistry.IBDocumentDate          AS IBDocumentDate,
			|	DocumentsRegistry.Ref                   AS Ref,
			|	DocumentsRegistry.IBDocumentNumber         AS IBDocumentNumber,
			|	DocumentsRegistry.Status                   AS Status,
			|	DocumentsRegistry.EmployeeResponsible            AS EmployeeResponsible,
			|	DocumentsRegistry.AdditionalRecord     AS AdditionalRecord,
			|	DocumentsRegistry.Posted                 AS Posted,
			|	DocumentsRegistry.DeletionMark          AS DeletionMark,
			|	DocumentsRegistry.SourceDocumentDate  AS SourceDocumentDate,
			|	DocumentsRegistry.SourceDocumentNumber AS SourceDocumentNumber,
			|	DocumentsRegistry.Sum                    AS Sum,
			|	DocumentsRegistry.Currency                   AS Currency,
			|	DocumentsRegistry.Contract                  AS Contract,
			|	DocumentsRegistry.LineOfBusiness  AS LineOfBusiness,
			|	DocumentsRegistry.RecordingInAccountingDate      AS RecordingInAccountingDate,
			|	DocumentsRegistry.ReverseTransactionCorrection        AS ReverseTransactionCorrection,
			|	DocumentsRegistry.ReversedDocument     AS ReversedDocument,
			|	DocumentsRegistry.CorrectedDocument     AS CorrectedDocument,
			|	DocumentsRegistry.Priority                AS Priority
			|INTO DocumentsRegistryBeforeWrite
			|FROM
			|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|WHERE
			|	DocumentsRegistry.Ref = &Ref");
		
		Query.SetParameter("Ref", Filter.Ref.Value);
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.Execute();
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("TempTablesManager") Then // is it holding or removing a holding
		
		Query = New Query(
			"SELECT
			|	RegisterOfDocumentsChanges.BusinessOperation    AS BusinessOperation,
			|	RegisterOfDocumentsChanges.Organization              AS Organization,
			|	RegisterOfDocumentsChanges.Partner                  AS Partner,
			|	RegisterOfDocumentsChanges.StorageLocation            AS StorageLocation,
			|	RegisterOfDocumentsChanges.Counterparty               AS Counterparty,
			|	RegisterOfDocumentsChanges.Department            AS Department,
			|	RegisterOfDocumentsChanges.IBDocumentDate          AS IBDocumentDate,
			|	RegisterOfDocumentsChanges.Ref                   AS Ref,
			|
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.IBDocumentNumber
			|				ELSE
			|			NULL
			|		END) AS IBDocumentNumberBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Status
			|				ELSE
			|			NULL
			|		END) AS StatusBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.EmployeeResponsible
			|				ELSE
			|			NULL
			|		END) AS ResponsiblePriorToChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.AdditionalRecord
			|				ELSE
			|			NULL
			|		END) AS AdditionalEntryBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Posted
			|				ELSE
			|			NULL
			|		END) AS HeldBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.DeletionMark
			|				ELSE
			|			NULL
			|		END) AS MarkingDeletionsBeforeChanges,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.SourceDocumentDate
			|				ELSE
			|			NULL
			|		END) AS DateOfPrimaryDocumentBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.SourceDocumentNumber
			|				ELSE
			|			NULL
			|		END) AS NumberOfPrimaryDocumentBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Sum
			|				ELSE
			|			NULL
			|		END) AS AmountBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Currency
			|				ELSE
			|			NULL
			|		END) AS CurrencyBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Contract
			|				ELSE
			|			NULL
			|		END) AS ContractBeforeModifications,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.LineOfBusiness
			|				ELSE
			|			NULL
			|		END) AS LineOfBusinessBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.RecordingInAccountingDate
			|				ELSE
			|			NULL
			|		END) AS DateOfAccountingBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.ReverseTransactionCorrection
			|				ELSE
			|			NULL
			|		END) AS ReverseFixBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.ReversedDocument
			|				ELSE
			|			NULL
			|		END) AS DocumentToBeReversedBeforeModification,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.CorrectedDocument
			|				ELSE
			|			NULL
			|		END) AS DocumentBeingCorrectedBeforeChange,
			|	MAX(CASE WHEN RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Priority
			|				ELSE
			|			NULL
			|		END) AS PriorityBeforeChange,
			|
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.IBDocumentNumber
			|				ELSE
			|			NULL
			|		END) AS IBDocumentNumber,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Status
			|				ELSE
			|			NULL
			|		END) AS Status,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.EmployeeResponsible
			|				ELSE
			|			NULL
			|		END) AS EmployeeResponsible,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.AdditionalRecord
			|				ELSE
			|			NULL
			|		END) AS AdditionalRecord,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Posted
			|				ELSE
			|			NULL
			|		END) AS Posted,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.DeletionMark
			|				ELSE
			|			NULL
			|		END) AS DeletionMark,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.SourceDocumentDate
			|				ELSE
			|			NULL
			|		END) AS SourceDocumentDate,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.SourceDocumentNumber
			|				ELSE
			|			NULL
			|		END) AS SourceDocumentNumber,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Sum
			|				ELSE
			|			NULL
			|		END) AS Sum,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Currency
			|				ELSE
			|			NULL
			|		END) AS Currency,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Contract
			|				ELSE
			|			NULL
			|		END) AS Contract,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.LineOfBusiness
			|				ELSE
			|			NULL
			|		END) AS LineOfBusiness,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.RecordingInAccountingDate
			|				ELSE
			|			NULL
			|		END) AS RecordingInAccountingDate,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.ReverseTransactionCorrection
			|				ELSE
			|			NULL
			|		END) AS ReverseTransactionCorrection,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.ReversedDocument
			|				ELSE
			|			NULL
			|		END) AS ReversedDocument,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.CorrectedDocument
			|				ELSE
			|			NULL
			|		END) AS CorrectedDocument,
			|	MAX(CASE WHEN NOT RegisterOfDocumentsChanges.BeforeChange THEN
			|					RegisterOfDocumentsChanges.Priority
			|				ELSE
			|			NULL
			|		END) AS Priority
			|INTO RegisterOfDocumentsChanges
			|FROM (
			|	SELECT
			|		FALSE                                      AS BeforeChange,
			|		DocumentsRegistry.BusinessOperation    AS BusinessOperation,
			|		DocumentsRegistry.Organization              AS Organization,
			|		DocumentsRegistry.Partner                  AS Partner,
			|		DocumentsRegistry.StorageLocation            AS StorageLocation,
			|		DocumentsRegistry.Counterparty               AS Counterparty,
			|		DocumentsRegistry.Department            AS Department,
			|		DocumentsRegistry.IBDocumentDate          AS IBDocumentDate,
			|		DocumentsRegistry.Ref                   AS Ref,
			|		DocumentsRegistry.IBDocumentNumber         AS IBDocumentNumber,
			|		DocumentsRegistry.Status                   AS Status,
			|		DocumentsRegistry.EmployeeResponsible            AS EmployeeResponsible,
			|		DocumentsRegistry.AdditionalRecord     AS AdditionalRecord,
			|		DocumentsRegistry.Posted                 AS Posted,
			|		DocumentsRegistry.DeletionMark          AS DeletionMark,
			|		DocumentsRegistry.SourceDocumentDate  AS SourceDocumentDate,
			|		DocumentsRegistry.SourceDocumentNumber AS SourceDocumentNumber,
			|		DocumentsRegistry.Sum                    AS Sum,
			|		DocumentsRegistry.Currency                   AS Currency,
			|		DocumentsRegistry.Contract                  AS Contract,
			|		DocumentsRegistry.LineOfBusiness  AS LineOfBusiness,
			|		DocumentsRegistry.RecordingInAccountingDate      AS RecordingInAccountingDate,
			|		DocumentsRegistry.ReverseTransactionCorrection        AS ReverseTransactionCorrection,
			|		DocumentsRegistry.ReversedDocument     AS ReversedDocument,
			|		DocumentsRegistry.CorrectedDocument     AS CorrectedDocument,
			|		DocumentsRegistry.Priority                AS Priority
			|	FROM
			|		InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|	WHERE
			|		DocumentsRegistry.Ref = &Ref
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		TRUE                                    AS BeforeChange,
			|		DocumentsRegistry.BusinessOperation    AS BusinessOperation,
			|		DocumentsRegistry.Organization              AS Organization,
			|		DocumentsRegistry.Partner                  AS Partner,
			|		DocumentsRegistry.StorageLocation            AS StorageLocation,
			|		DocumentsRegistry.Counterparty               AS Counterparty,
			|		DocumentsRegistry.Department            AS Department,
			|		DocumentsRegistry.IBDocumentDate          AS IBDocumentDate,
			|		DocumentsRegistry.Ref                   AS Ref,
			|		DocumentsRegistry.IBDocumentNumber         AS IBDocumentNumber,
			|		DocumentsRegistry.Status                   AS Status,
			|		DocumentsRegistry.EmployeeResponsible            AS EmployeeResponsible,
			|		DocumentsRegistry.AdditionalRecord     AS AdditionalRecord,
			|		DocumentsRegistry.Posted                 AS Posted,
			|		DocumentsRegistry.DeletionMark          AS DeletionMark,
			|		DocumentsRegistry.SourceDocumentDate  AS SourceDocumentDate,
			|		DocumentsRegistry.SourceDocumentNumber AS SourceDocumentNumber,
			|		DocumentsRegistry.Sum                    AS Sum,
			|		DocumentsRegistry.Currency                   AS Currency,
			|		DocumentsRegistry.Contract                  AS Contract,
			|		DocumentsRegistry.LineOfBusiness  AS LineOfBusiness,
			|		DocumentsRegistry.RecordingInAccountingDate      AS RecordingInAccountingDate,
			|		DocumentsRegistry.ReverseTransactionCorrection        AS ReverseTransactionCorrection,
			|		DocumentsRegistry.ReversedDocument     AS ReversedDocument,
			|		DocumentsRegistry.CorrectedDocument     AS CorrectedDocument,
			|		DocumentsRegistry.Priority                AS Priority
			|	FROM
			|		DocumentsRegistryBeforeWrite AS DocumentsRegistry) AS RegisterOfDocumentsChanges
			|GROUP BY
			|	RegisterOfDocumentsChanges.BusinessOperation,
			|	RegisterOfDocumentsChanges.Organization,
			|	RegisterOfDocumentsChanges.Partner,
			|	RegisterOfDocumentsChanges.StorageLocation,
			|	RegisterOfDocumentsChanges.Counterparty,
			|	RegisterOfDocumentsChanges.Department,
			|	RegisterOfDocumentsChanges.IBDocumentDate,
			|	RegisterOfDocumentsChanges.Ref
			|;
			|DROP DocumentsRegistryBeforeWrite");
		
		Query.SetParameter("Ref", Filter.Ref.Value);
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.Execute();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  TableDocumentRegistry - ValueTable - 
Procedure UploadWithProcessing(TableDocumentRegistry) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableDocumentRegistry.RefType AS RefType,
	|	TableDocumentRegistry.Organization AS Organization,
	|	TableDocumentRegistry.BusinessOperation AS BusinessOperation,
	|	TableDocumentRegistry.Partner AS Partner,
	|	CASE
	|		WHEN TableDocumentRegistry.Counterparty = UNDEFINED
	|			THEN VALUE(Catalog.DocumentRegistryKeys.EmptyRef)
	|		ELSE TableDocumentRegistry.Counterparty
	|	END AS Counterparty,
	|	TableDocumentRegistry.LineOfBusiness AS LineOfBusiness,
	|	TableDocumentRegistry.AdditionalRecord AS AdditionalRecord,
	|	TableDocumentRegistry.Department AS Department,
	|	CASE
	|		WHEN TableDocumentRegistry.StorageLocation = UNDEFINED
	|			THEN VALUE(Catalog.DocumentRegistryKeys.EmptyRef)
	|		ELSE TableDocumentRegistry.StorageLocation
	|	END AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate AS IBDocumentDate,
	|	TableDocumentRegistry.Ref AS Ref,
	|	TableDocumentRegistry.RecordSeparator AS RecordSeparator,
	|	TableDocumentRegistry.IBDocumentNumber AS IBDocumentNumber,
	|	TableDocumentRegistry.Status AS Status,
	|	TableDocumentRegistry.EmployeeResponsible AS EmployeeResponsible,
	|	TableDocumentRegistry.Author AS Author,
	|	TableDocumentRegistry.More AS More,
	|	TableDocumentRegistry.Comment AS Comment,
	|	TableDocumentRegistry.Posted AS Posted,
	|	TableDocumentRegistry.DeletionMark AS DeletionMark,
	|	TableDocumentRegistry.SourceDocumentDate AS SourceDocumentDate,
	|	TableDocumentRegistry.SourceDocumentNumber AS SourceDocumentNumber,
	|	TableDocumentRegistry.SourceDocumentName AS SourceDocumentName,
	|	TableDocumentRegistry.Sum AS Sum,
	|	TableDocumentRegistry.Currency AS Currency,
	|	TableDocumentRegistry.RecordingInAccountingDate AS RecordingInAccountingDate,
	|	TableDocumentRegistry.Contract AS Contract,
	|	TableDocumentRegistry.ReverseTransactionCorrection AS ReverseTransactionCorrection,
	|	TableDocumentRegistry.ReversedDocument AS ReversedDocument,
	|	TableDocumentRegistry.CorrectedDocument AS CorrectedDocument,
	|	TableDocumentRegistry.Priority
	|INTO TableDocumentRegistry
	|FROM
	|	&TableDocumentRegistry AS TableDocumentRegistry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentRegistryKeys.Ref) AS Ref,
	|	DocumentRegistryKeys.Key AS Key
	|INTO TableOfGroupedKeys
	|FROM
	|	Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
	|WHERE
	|	DocumentRegistryKeys.Key IN(&SelectionKeys)
	|
	|GROUP BY
	|	DocumentRegistryKeys.Key
	|
	|INDEX BY
	|	Key
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableDocumentRegistry.RefType AS RefType,
	|	TableDocumentRegistry.Organization AS Organization,
	|	TableDocumentRegistry.BusinessOperation AS BusinessOperation,
	|	TableDocumentRegistry.Partner AS Partner,
	|	CASE
	|		WHEN VALUETYPE(TableDocumentRegistry.Counterparty) = TYPE(Catalog.DocumentRegistryKeys)
	|			THEN TableDocumentRegistry.Counterparty
	|		ELSE ISNULL(DocumentRegistryKeysCounterparty.Ref, VALUE(Catalog.DocumentRegistryKeys.EmptyRef))
	|	END AS Counterparty,
	|	TableDocumentRegistry.LineOfBusiness AS LineOfBusiness,
	|	TableDocumentRegistry.AdditionalRecord AS AdditionalRecord,
	|	TableDocumentRegistry.Department AS Department,
	|	CASE
	|		WHEN VALUETYPE(TableDocumentRegistry.StorageLocation) = TYPE(Catalog.DocumentRegistryKeys)
	|			THEN TableDocumentRegistry.StorageLocation
	|		ELSE ISNULL(DocumentRegistryKeysStorageLocation.Ref, VALUE(Catalog.DocumentRegistryKeys.EmptyRef))
	|	END AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate AS IBDocumentDate,
	|	TableDocumentRegistry.Ref AS Ref,
	|	TableDocumentRegistry.RecordSeparator AS RecordSeparator,
	|	TableDocumentRegistry.IBDocumentNumber AS IBDocumentNumber,
	|	TableDocumentRegistry.Status AS Status,
	|	TableDocumentRegistry.EmployeeResponsible AS EmployeeResponsible,
	|	TableDocumentRegistry.Author AS Author,
	|	TableDocumentRegistry.More AS More,
	|	TableDocumentRegistry.Comment AS Comment,
	|	TableDocumentRegistry.Posted AS Posted,
	|	TableDocumentRegistry.DeletionMark AS DeletionMark,
	|	TableDocumentRegistry.SourceDocumentDate AS SourceDocumentDate,
	|	TableDocumentRegistry.SourceDocumentNumber AS SourceDocumentNumber,
	|	TableDocumentRegistry.SourceDocumentName AS SourceDocumentName,
	|	TableDocumentRegistry.Sum AS Sum,
	|	TableDocumentRegistry.Currency AS Currency,
	|	TableDocumentRegistry.RecordingInAccountingDate AS RecordingInAccountingDate,
	|	TableDocumentRegistry.Contract AS Contract,
	|	TableDocumentRegistry.Priority AS Priority,
	|	TableDocumentRegistry.ReverseTransactionCorrection AS ReverseTransactionCorrection,
	|	TableDocumentRegistry.ReversedDocument AS ReversedDocument,
	|	TableDocumentRegistry.CorrectedDocument AS CorrectedDocument,
	|	CASE
	|		WHEN VALUETYPE(TableDocumentRegistry.Counterparty) = TYPE(Catalog.DocumentRegistryKeys)
	|			THEN FALSE
	|		WHEN NOT TableDocumentRegistry.Counterparty IN (&EmptyKeyValues_)
	|		AND DocumentRegistryKeysCounterparty.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ErrorEmptyCounterpartyKey,
	|	CASE
	|		WHEN VALUETYPE(TableDocumentRegistry.StorageLocation) = TYPE(Catalog.DocumentRegistryKeys)
	|			THEN FALSE
	|		WHEN NOT TableDocumentRegistry.StorageLocation IN (&EmptyKeyValues_)
	|		AND DocumentRegistryKeysStorageLocation.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsErrorEmptyKeyStorageLocation,
	|	TableDocumentRegistry.StorageLocation AS StorageLocationFromTable,
	|	TableDocumentRegistry.Counterparty AS CounterpartyFromTable,
	|	CAST("""" AS STRING(36)) AS RecordID
	|INTO TableRegistryOfDocumentsWithKeys
	|FROM
	|	TableDocumentRegistry AS TableDocumentRegistry
	|		LEFT JOIN TableOfGroupedKeys AS DocumentRegistryKeysStorageLocation
	|		ON TableDocumentRegistry.StorageLocation = DocumentRegistryKeysStorageLocation.Key
	|		LEFT JOIN TableOfGroupedKeys AS DocumentRegistryKeysCounterparty
	|		ON TableDocumentRegistry.Counterparty = DocumentRegistryKeysCounterparty.Key
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableDocumentRegistry.Ref AS Ref,
	|	DocumentsRegistry.AdditionalRecord AS AdditionalRecord,
	|	DocumentsRegistry.RecordID AS RecordID,
	|	FALSE AS Processed
	|INTO IdsOfAdditionalRecords
	|FROM TableDocumentRegistry AS TableDocumentRegistry
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableDocumentRegistry.Ref = DocumentsRegistry.Ref
	|		AND DocumentsRegistry.AdditionalRecord = TableDocumentRegistry.AdditionalRecord
	|		AND DocumentsRegistry.RecordID <> """"
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableRegistryOfDocumentsWithKeys.ErrorEmptyCounterpartyKey AS ErrorEmptyCounterpartyKey,
	|	TableRegistryOfDocumentsWithKeys.ThereIsErrorEmptyKeyStorageLocation AS ThereIsErrorEmptyKeyStorageLocation,
	|	TableRegistryOfDocumentsWithKeys.StorageLocationFromTable AS StorageLocationFromTable,
	|	TableRegistryOfDocumentsWithKeys.CounterpartyFromTable AS CounterpartyFromTable
	|FROM
	|	TableRegistryOfDocumentsWithKeys AS TableRegistryOfDocumentsWithKeys
	|WHERE
	|	(TableRegistryOfDocumentsWithKeys.ErrorEmptyCounterpartyKey
	|	OR TableRegistryOfDocumentsWithKeys.ThereIsErrorEmptyKeyStorageLocation)";
	
	For Each Dimension In Metadata.InformationRegisters.DocumentsRegistry.Dimensions Do
		
		Column = TableDocumentRegistry.Columns.Find(Dimension.Name);
		
		If Column <> Undefined Then
			If Column.ValueType = New TypeDescription("Undefined")
				Or Column.ValueType = New TypeDescription("Null") Then
				TableDocumentRegistry.Columns.Delete(Column);
			Else
				Continue;
			EndIf;
		EndIf;
		
		TableDocumentRegistry.Columns.Add(Dimension.Name, Dimension.Type);
		
	EndDo;
	
	For Each Resource In Metadata.InformationRegisters.DocumentsRegistry.Resources Do
		
		Column = TableDocumentRegistry.Columns.Find(Resource.Name);
		
		If Column <> Undefined Then
			If Column.ValueType = New TypeDescription("Undefined")
				Or Column.ValueType = New TypeDescription("Null") Then
				TableDocumentRegistry.Columns.Delete(Column);
			Else
				Continue;
			EndIf;
		EndIf;
		
		TableDocumentRegistry.Columns.Add(Resource.Name, Resource.Type);
		
	EndDo;
	
	EmptyKeyValues_ = New Array;
	EmptyKeyValues_.Add(Undefined);
	EmptyKeyValues_.Add(Null);
	
	For Each KeyValueType In Metadata.Catalogs.DocumentRegistryKeys.Attributes.Key.Type.Types() Do
		EmptyKeyValues_.Add(PredefinedValue(Metadata.FindByType(KeyValueType).FullName() + ".EmptyRef"));
	EndDo;
	
	TableOfRegistryKeys = TableDocumentRegistry.Copy(, "Counterparty, StorageLocation");
	TableOfRegistryKeys.GroupBy("Counterparty, StorageLocation");
	
	SelectionKeys = New Array;
	
	For Each String_Keys In TableOfRegistryKeys Do
		CounterpartyKey = ?(String_Keys.Counterparty = Undefined,
							Catalogs.DocumentRegistryKeys.EmptyRef(),
							String_Keys.Counterparty);
		
		If SelectionKeys.Find(CounterpartyKey) = Undefined Then
			SelectionKeys.Add(CounterpartyKey);
		EndIf;

		StorageLocationKey = ?(String_Keys.StorageLocation = Undefined,
								Catalogs.DocumentRegistryKeys.EmptyRef(),
								String_Keys.StorageLocation);
								
		If SelectionKeys.Find(StorageLocationKey) = Undefined Then
			SelectionKeys.Add(StorageLocationKey);
		EndIf;
	EndDo;
	
	Query.SetParameter("EmptyKeyValues_",		EmptyKeyValues_);
	Query.SetParameter("TableDocumentRegistry",	TableDocumentRegistry);
	Query.SetParameter("SelectionKeys",				SelectionKeys);
	
	QueryResults = Query.ExecuteBatchWithIntermediateData();
	
	Errors = QueryResults[4].Select();
	
	While Errors.Next() Do
		
		If Common.IsSubordinateDIBNode() Then
			
			MessageText = NStr("vi = 'Đối với giá trị""%Value%"" chưa tìm thấy khóa sổ đăng ký chứng từ. Hãy liên hệ với người quản trị.';
								|ru = 'Для значения ""%Value%"" не найден ключ реестра документов. Обратитесь к администратору.';
								|en = 'For the value ""%Value%"" the document registry key was not found. Please contact the administrator.'; fa = 'For the value ""%Value%"" the document registry key was not found. Please contact the administrator.';
								|it = 'Per il valore""%Value%"" non è trovata la chiave del registro dei documenti.Rivolgetevi all''amministratore.';
								|pl = 'Dla wartości ""%Value%"" nie znaleziono kluczu rejestru dokumentów. Zwróć się do administratora.';
								|tr = '""%Value%"" değeri için belge kayıt defteri anahtarı bulunamadı. Yöneticiyle iletişime geç.'");
			
			If Errors.ErrorEmptyCounterpartyKey Then
				MessageText = StrReplace(MessageText, "%Value%", Errors.CounterpartyFromTable);
			EndIf;
			
			If Errors.ThereIsErrorEmptyKeyStorageLocation Then
				MessageText = StrReplace(MessageText, "%Value%", Errors.StorageLocationFromTable);
			EndIf;
			
			Raise MessageText;
		Else
			
			If Errors.ErrorEmptyCounterpartyKey Then
				Catalogs.DocumentRegistryKeys.CreateUpdateRegistryKeys(,Errors.CounterpartyFromTable);
			EndIf;
			
			If Errors.ThereIsErrorEmptyKeyStorageLocation Then
				Catalogs.DocumentRegistryKeys.CreateUpdateRegistryKeys(,Errors.StorageLocationFromTable);
			EndIf;
			
		EndIf;
	EndDo;
	
	If Errors.Count() > 0 Then
		QueryResults = Query.ExecuteBatchWithIntermediateData();
	EndIf;
	
	TableRegisterOfDocumentsToBeUploaded = QueryResults[2].Unload();
	TableRecordIds = QueryResults[3].Unload();
	TableRecordIds.Indexes.Add("Ref, AdditionalRecord, Processed");
	
	If TableRecordIds.Count() > 0 Then
		
		SelectionStructureIdentifiers = New Structure;
		
		For Each CurrentRegisterLine In TableRegisterOfDocumentsToBeUploaded Do
		
			SelectionStructureIdentifiers.Insert("Ref", CurrentRegisterLine.Ref);
			SelectionStructureIdentifiers.Insert("AdditionalRecord", CurrentRegisterLine.AdditionalRecord);
			SelectionStructureIdentifiers.Insert("Processed", False);

			IdsOfFoundRows = TableRecordIds.FindRows(SelectionStructureIdentifiers);
			If IdsOfFoundRows.Count() > 0 Then

				CurrentRegisterLine.RecordID = IdsOfFoundRows[0].RecordID;
				IdsOfFoundRows[0].Processed = True;

			EndIf;

		EndDo;
	EndIf;
	
	Load(TableRegisterOfDocumentsToBeUploaded);
	
EndProcedure

// Filling in the service dimension "Record ID"
// When exchanging and recording documents, filling in this dimension is mandatory, because it is included in the key
// fields in the dynamic lists of document logs.
// 
// Parameters:
//  RecordSet - InformationRegisterRecordSet.DocumentsRegistry - Recordset
//
Procedure FillInRecordIds(RecordSet)
	
	For Each Record In RecordSet Do
		If Not ValueIsFilled(Record.RecordID) Then
			Record.RecordID = String(New UUID);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
