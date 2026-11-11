#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Matching with the list of details that determine the uniqueness of the key
// 
// Returns:
//   Map - the key is the name of the props 
//
Function KeyAttributes() Export
	
	Return TMCommonUse.KeyDetailsOfKeyCatalogForInformationRegister(Metadata.InformationRegisters.ItemsLocationAttributes);
	
EndFunction

#Region InterfaceImplementation

// Called when replacing duplicates in the Attributes of elements.
//
// Parameters:
//  ReplacementPairs - Map - contains the original and duplicate value pairs.
//  UnprocessedOriginalsValues - Array of Structure:
//    * ValueToReplace - AnyRef - the original value of the object being replaced.
//    * UsedLinks - See Common.SubordinateObjectsLinksByTypes
//    * KeyAttributesValue - Structure - Key - name of the item, value-value of the item.
//
Procedure OnSearchForReferenceReplacement(ReplacementPairs, UnprocessedOriginalsValues) Export
	
	For Each UnprocessedDuplicate In UnprocessedOriginalsValues Do
		
		ParametersOfKey = New Structure;
		For Each KeyAttribute In UnprocessedDuplicate.KeyAttributesValue Do
			ValueOfOriginal = ReplacementPairs.Get(KeyAttribute.Value);
			ParametersOfKey.Insert(KeyAttribute.Key, ?(ValueOfOriginal = Undefined, KeyAttribute.Value, ValueOfOriginal));
		EndDo;
		
		ReplacementPairs.Insert(
			UnprocessedDuplicate.ValueToReplace,
			InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(ParametersOfKey));
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ReplacingDuplicateAnalyticsKeys

// Replace the duplicates of the analytics keys.
// 
// Parameters:
//  KeysCount - Number - Number of keys
// 
// Returns:
//  Structure - Replace duplicate analytics keys:
// * RunTime - Number - execution time, in seconds
// * KeysProcessed - Number - number of key duplicates processed
// * ProcessedDocuments_1 - Number - the number of processed documents with movements in the register of the cost of goods
//
Function ReplaceDimensionKeyDuplicates(KeysCount = Undefined) Export
	
	Result = New Structure;
	Result.Insert("RunTime", CurrentUniversalDateInMilliseconds());
	Result.Insert("KeysProcessed", 0);
	Result.Insert("ProcessedDocuments_1", 0);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	// Let's choose the duplicates of the analytics keys.
	Query.Text =
	"SELECT
	|	CatalogData.Ref AS Ref,
	|	CatalogData.DeletionMark AS DeletionMark,
	|	Dimension.DimensionKey AS DimensionKey
	|INTO DuplicatesOfKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS CatalogData
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS RegisterData
	|	ON
	|		CatalogData.Ref = RegisterData.DimensionKey
	|
	|	INNER JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		CatalogData.Products		= Dimension.Products
	|		AND CatalogData.Characteristic	= Dimension.Characteristic
	|		AND CatalogData.Series			= Dimension.Series
	|		AND CatalogData.StorageLocation	= Dimension.StorageLocation
	|		AND CatalogData.Purpose		= Dimension.Purpose
	|		AND CatalogData.ProductCostElement = Dimension.ProductCostElement
	|WHERE
	|	RegisterData.DimensionKey IS NULL
	|INDEX BY
	|	Ref
	|";
	
	Query.Execute();
	
	// We will clear the movements of the register of the cost of goods by duplicates of keys (for all duplicates, regardless of their marking for deletion)
	Query.Text =
	"SELECT DISTINCT
	|	GoodsCost.Recorder AS Recorder
	|FROM
	|	InformationRegister.GoodsCost AS GoodsCost
	|		INNER JOIN DuplicatesOfKeys AS T
	|		ON GoodsCost.ItemsLocationAttributes = T.Ref
	|
	|ORDER BY
	|	Recorder
	|AUTOORDER";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	
	Query.Text =
	"SELECT
	|	*
	|FROM
	|	InformationRegister.GoodsCost AS T
	|	LEFT JOIN DuplicatesOfKeys AS Duplicates
	|		ON T.ItemsLocationAttributes = Duplicates.Ref
	|WHERE
	|	T.Recorder = &Recorder
	|	AND Duplicates.Ref IS NULL
	|
	|ORDER BY
	|	T.LineNumber";
	
	DataChunkSize = CalculationOfCostCached.ValuesOfTechnologicalParameters().NumberOfVTZLines;
	
	For Each Recorder In Recorders Do
		
		Query.SetParameter("Recorder", Recorder);
		
		Selection = Query.Execute().Select();
		
		RecordSet = InformationRegisters.GoodsCost.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(Recorder);
		
		BeginTransaction();
		RegisteredRecordsRecorded = False;
		
		Try
			
			While Selection.Next() Do
				
				FillPropertyValues(RecordSet.Add(), Selection,, "LineNumber, Active");
				
				If RecordSet.Count() = DataChunkSize Then
					
					RecordSet.Write(Not RegisteredRecordsRecorded);
					RecordSet.Clear();
					
					RegisteredRecordsRecorded = True;
					
				EndIf;
				
			EndDo;
			
			If RecordSet.Count() > 0 Or Not RegisteredRecordsRecorded Then
				RecordSet.Write(Not RegisteredRecordsRecorded);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể ghi lại bản ghi kết chuyển của chứng từ ""%1"" do nguyên nhân:
					|%2';
					|ru = 'Не удалось записать движения документа ""%1"" по причине:
					|%2';
					|en = 'Cannot save the ""%1"" document register records due to:
					|%2'; fa = 'Cannot save the ""%1"" document register records due to:
					|%2';
					|it = 'Non è stato possibile registrare i movimenti del documento ""%1"" a causa di:
					|%2';
					|pl = 'Nie udało się zapisać przepływu dokumentu ""%1"" z powodu:
					|%2';
					|tr = '
					|%2 nedeniyle ""%1"" belgesinin akışı kaydedilemedi'"),
				Recorder,
				DetailErrorDescription(ErrorInfo()));
				
			Raise ErrorText;
			
		EndTry;
		
		Result.ProcessedDocuments_1 = Result.ProcessedDocuments_1 + 1;
		
	EndDo;
	
	// We will clear the remaining links to duplicate keys (only for those that are not marked for deletion; the number of keys processed is determined by the parameter of the number of keys of this function).
	Query.Text =
	"SELECT TOP 1
	|	T.Ref AS Ref,
	|	T.DimensionKey AS DimensionKey
	|FROM
	|	DuplicatesOfKeys AS T
	|WHERE
	|	NOT T.DeletionMark
	|";
	
	Query.Text = StrReplace(Query.Text, "1", ?(ValueIsFilled(KeysCount), Format(KeysCount, "NG="), "999999999"));
	
	ComplianceAnalyst = New Map;
	
	Exceptions = New Array;
	Exceptions.Add(Metadata.InformationRegisters.GoodsCost);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
	
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			ComplianceAnalyst.Insert(Selection.Ref, Selection.DimensionKey);
			Result.KeysProcessed = Result.KeysProcessed + 1;
			
			CatalogObject = Selection.Ref.GetObject();
			CatalogObject.SetDeletionMark(True, False);
			
		EndDo;
		
		TMCommonUse.ReplaceReferences(ComplianceAnalyst, Exceptions);
		
	EndIf;
	
	Result.RunTime = (CurrentUniversalDateInMilliseconds() - Result.RunTime) / 1000;
	
	Return Result;
	
EndFunction

Procedure ClearProductCostRegisterRecordsAfterReplacingLinksAndAnalyticsKeys(Result, SearchTable) Export
	
	KeysToRemoval = Result.QueueForDirectDeletion;
	If Not KeysToRemoval.Count() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	// Select the analytics keys to delete.
	Query.Text =
	"SELECT
	|	CatalogData.Ref AS Ref
	|INTO DuplicatesOfKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS CatalogData
	|WHERE
	|	CatalogData.Ref IN (&DuplicatesOfKeys)
	|INDEX BY
	|	Ref
	|";
	Query.SetParameter("DuplicatesOfKeys", KeysToRemoval);
	
	Query.Execute();
	
	// We will clear the register records of the cost of goods by the keys being deleted
	Query.Text =
	"SELECT DISTINCT
	|	GoodsCost.Recorder AS Recorder
	|FROM
	|	InformationRegister.GoodsCost AS GoodsCost
	|		INNER JOIN DuplicatesOfKeys AS T
	|		ON GoodsCost.ItemsLocationAttributes = T.Ref
	|
	|ORDER BY
	|	Recorder
	|AUTOORDER";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	
	Query.Text =
	"SELECT
	|	*
	|FROM
	|	InformationRegister.GoodsCost AS T
	|WHERE
	|	T.Recorder = &Recorder
	|	AND NOT T.ItemsLocationAttributes IN (&DuplicatesOfKeys)
	|
	|ORDER BY
	|	T.LineNumber";
	DataChunkSize = CalculationOfCostCached.ValuesOfTechnologicalParameters().NumberOfVTZLines;
	
	For Each Recorder In Recorders Do
		
		Query.SetParameter("Recorder", Recorder);
		
		Selection = Query.Execute().Select();
		
		RecordSet = InformationRegisters.GoodsCost.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(Recorder);
		
		BeginTransaction();
		RegisteredRecordsRecorded = False;
		
		Try
			
			While Selection.Next() Do
				
				FillPropertyValues(RecordSet.Add(), Selection,, "LineNumber, Active");
				
				If RecordSet.Count() = DataChunkSize Then
					
					RecordSet.Write(Not RegisteredRecordsRecorded);
					RecordSet.Clear();
					
					RegisteredRecordsRecorded = True;
					
				EndIf;
				
			EndDo;
			
			If RecordSet.Count() > 0 Or Not RegisteredRecordsRecorded Then
				RecordSet.Write(Not RegisteredRecordsRecorded);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể ghi lại bản ghi kết chuyển của chứng từ ""%1"" do nguyên nhân:
					|%2';
					|ru = 'Не удалось записать движения документа ""%1"" по причине:
					|%2';
					|en = 'Cannot save the ""%1"" document register records due to:
					|%2'; fa = 'Cannot save the ""%1"" document register records due to:
					|%2';
					|it = 'Non è stato possibile registrare i movimenti del documento ""%1"" a causa di:
					|%2';
					|pl = 'Nie udało się zapisać przepływu dokumentu ""%1"" z powodu:
					|%2';
					|tr = '
					|%2 nedeniyle ""%1"" belgesinin akışı kaydedilemedi'"),
				Recorder,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			Selection.Reset();
			While Selection.Next() Do
				Result.HasErrors = Result.HasErrors Or True;
				ErrorDescription = Result.Errors.Add();
				ErrorDescription.Ref = Selection.ItemsLocationAttributes;
				ErrorDescription.ErrorObjectPresentation = Common.SubjectString(Recorder);
				ErrorDescription.ErrorObject = Recorder;
				ErrorDescription.ErrorInfo = ErrorInfo();
				ErrorDescription.ErrorText = ErrorText;
				ErrorDescription.ErrorType = "WritingError";
			EndDo;
			
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf