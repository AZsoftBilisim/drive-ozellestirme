#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Checks whether documents are ready for processing.
// 
// Returns:
//  Boolean - True if there are documents to be processed.
//
Function ThereAreDocumentsForProcessing() Export

	Result = DocumentsForProcessing_(1);
	
	Return Not Result.IsEmpty();

EndFunction 

#EndRegion

#Region Private

Function DocumentsForProcessing_(Top)

	QueryText = 
	"SELECT DISTINCT TOP 1
	|	FACost.Recorder AS Recorder,
	|	""FixedAssetsInitialRecognition2_4"" AS DocumentName
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|		INNER JOIN Document.FixedAssetsInitialRecognition2_4.FA AS FATable
	|		ON (FATable.Ref = FACost.Recorder)
	|			AND (FATable.FixedAsset = FACost.FixedAsset)
	|WHERE
	|	FACost.CostCalculation
	|	AND FACost.Active
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND FACost.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND (FACost.Period < &CostAccountingStartDate
	|			OR &CostAccountingStartDate = DATETIME(1, 1, 1))
	|
	|GROUP BY
	|	FACost.Recorder,
	|	FACost.FixedAsset
	|
	|HAVING
	|	(MAX(FATable.CostInAccounting) <> SUM(FACost.LocalCost + FACost.CostTargetFinancing)
	|		OR MAX(FATable.CostInTaxAccounting) <> SUM(FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA)
	|		OR MAX(FATable.CostPermanentDifference) <> SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD)
	|		OR MAX(FATable.CostInManagementAccounting) <> SUM(FACost.Cost))
	|
	|UNION ALL
	|
	|SELECT DISTINCT TOP 1
	|	FACost.Recorder,
	|	""FixedAssetsCostAdditions2_4"" AS DocumentName
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|		INNER JOIN Document.FixedAssetsCostAdditions2_4.FA AS FATable
	|		ON (FATable.Ref = FACost.Recorder)
	|			AND (FATable.FixedAsset = FACost.FixedAsset)
	|WHERE
	|	FACost.CostCalculation
	|	AND FACost.Active
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND FACost.Recorder REFS Document.FixedAssetsCostAdditions2_4
	|	AND (FACost.Period < &CostAccountingStartDate
	|			OR &CostAccountingStartDate = DATETIME(1, 1, 1))
	|
	|GROUP BY
	|	FACost.Recorder,
	|	FACost.FixedAsset
	|
	|HAVING
	|	(MAX(FATable.CostInAccounting) <> SUM(FACost.LocalCost + FACost.CostTargetFinancing)
	|		OR MAX(FATable.CostInTaxAccounting) <> SUM(FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA)
	|		OR MAX(FATable.CostPermanentDifference) <> SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD)
	|		OR MAX(FATable.CostInManagementAccounting) <> SUM(FACost.Cost))
	|
	|
	|UNION ALL
	|
	|SELECT DISTINCT TOP 1
	|	FACost.Recorder,
	|	""AllocateVariancesToFixedAssetCost"" AS DocumentName
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|		INNER JOIN Document.AllocateVariancesToFixedAssetCost.FA AS FATable
	|		ON (FATable.Ref = FACost.Recorder)
	|			AND (FATable.FixedAsset = FACost.FixedAsset)
	|WHERE
	|	FACost.CostCalculation
	|	AND FACost.Active
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND FACost.Recorder REFS Document.AllocateVariancesToFixedAssetCost
	|	AND (FACost.Period < &CostAccountingStartDate
	|			OR &CostAccountingStartDate = DATETIME(1, 1, 1))
	|
	|GROUP BY
	|	FACost.Recorder,
	|	FACost.FixedAsset
	|
	|HAVING
	|	(MAX(FATable.AmountAccounting) <> SUM(FACost.LocalCost + FACost.CostTargetFinancing)
	|		OR MAX(FATable.AmountFA) <> SUM(FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA)
	|		OR MAX(FATable.AmountPermanentDifferences) <> SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD)
	|		OR MAX(FATable.AmountOfUU) <> SUM(FACost.Cost))
	|
	|UNION ALL
	|
	|SELECT DISTINCT TOP 1
	|	IACost.Recorder,
	|	""IntangibleAssetsInitialRecognition2_4"" AS DocumentName
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|		INNER JOIN Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|		ON (DocumentData.Ref = IACost.Recorder)
	|			AND (DocumentData.IntangibleAsset = IACost.IntangibleAsset)
	|WHERE
	|	IACost.CostCalculation
	|	AND IACost.Active
	|	AND IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND IACost.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND (IACost.Period < &CostAccountingStartDate
	|			OR &CostAccountingStartDate = DATETIME(1, 1, 1))
	|
	|GROUP BY
	|	IACost.Recorder,
	|	IACost.IntangibleAsset
	|
	|HAVING
	|	(MAX(DocumentData.InitialCostLocalAccounting) <> SUM(IACost.LocalCost + IACost.CostTargetFinancing)
	|		OR MAX(DocumentData.InitialCostTA) <> SUM(IACost.CostInTaxAccounting + IACost.CostTargetFinancingTA)
	|		OR MAX(DocumentData.InitialCostPD) <> SUM(IACost.CostPermanentDifference + IACost.CostTargetFinancingPD)
	|		OR MAX(DocumentData.InitialCostMA) <> SUM(IACost.Cost))";
	
	QueryText = StrReplace(QueryText, "DISTINCT TOP 1", "DISTINCT TOP " + Format(Top, "NG="));
	
	Query = New Query(QueryText);
	Query.SetParameter("CostAccountingStartDate", Constants.CostAccountingStartDate.Get());
	
	Result = Query.Execute();
	
	Return Result;
	
EndFunction

Procedure FillInCost(Parameters = "", StorageAddress = "") Export

	UseCostAccounting = GetFunctionalOption("UseCostAccounting");
	CostAccountingStartDate = Constants.CostAccountingStartDate.Get();
	
	If UseCostAccounting
		And Not ValueIsFilled(CostAccountingStartDate) Then
		Return; 
	EndIf;
	
	SetPrivilegedMode(True);
	
	ErrorText = Undefined;
	
	While True Do
	
		Result = DocumentsForProcessing_(100);
		
		If Result.IsEmpty() Then
			Break;
		EndIf; 
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			BeginTransaction();
			
			Try
				
				If Selection.DocumentName = "FixedAssetsInitialRecognition2_4" Then
					UpdateFAAccountingAcceptanceDocument(Selection)
				ElsIf Selection.DocumentName = "FixedAssetsCostAdditions2_4" Then
					UpdateFAUpgradeDocument(Selection)
				ElsIf Selection.DocumentName = "AllocateVariancesToFixedAssetCost" Then
					UpdateDocumentAttributionOfDeviationsToCostOfFA(Selection)
				Else
					UpdateDocumentAcceptanceForAccountingOfIa(Selection)
				EndIf; 
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = DetailErrorDescription(ErrorInfo());
				
				Break;
				
			EndTry;
			
		EndDo;
		
		If ErrorText <> Undefined Then
			Break;
		EndIf;
		
	EndDo;
	
	If Not UseCostAccounting Then
		DeleteCostCalculationTasks();
	EndIf; 
	
	PutToTempStorage(ErrorText, StorageAddress);
	
EndProcedure

Procedure UpdateFAAccountingAcceptanceDocument(SampleDocument)

	Block = New DataLock;
	
	LockItem = Block.Add("Document.FixedAssetsInitialRecognition2_4");
	LockItem.SetValue("Ref", SampleDocument.Recorder);
	
	LockItem = Block.Add("AccumulationRegister.FACost.RecordSet");
	LockItem.SetValue("Recorder", SampleDocument.Recorder);
	
	Block.Lock(); 
	
	QueryText = 
	"SELECT
	|	FACost.FixedAsset AS FixedAsset,
	|	SUM(FACost.LocalCost + FACost.CostTargetFinancing) AS CostInAccounting,
	|	SUM(FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA) AS CostInTaxAccounting,
	|	SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD) AS CostPermanentDifference,
	|	SUM(FACost.CostTemporaryDifference + FACost.CostTargetFinancingTD) AS CostTemporaryDifference,
	|	SUM(FACost.Cost) AS CostInManagementAccounting
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|WHERE
	|	FACost.CostCalculation
	|	AND FACost.Active
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND FACost.Recorder = &Recorder
	|
	|GROUP BY
	|	FACost.FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", SampleDocument.Recorder);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	DocumentObject = SampleDocument.Recorder.GetObject(); // DocumentObject.FixedAssetsInitialRecognition2_4 - 
	
	While Selection.Next() Do
		
		RowData = DocumentObject.FA.Find(Selection.FixedAsset, "FixedAsset");
		FillPropertyValues(RowData, Selection);
		
	EndDo;
	
	DocumentObject.Write();
	
EndProcedure

Procedure UpdateFAUpgradeDocument(SampleDocument)

	Block = New DataLock;
	
	LockItem = Block.Add("Document.FixedAssetsCostAdditions2_4");
	LockItem.SetValue("Ref", SampleDocument.Recorder);
	
	LockItem = Block.Add("AccumulationRegister.FACost.RecordSet");
	LockItem.SetValue("Recorder", SampleDocument.Recorder);
	
	Block.Lock(); 
	
	QueryText = 
	"SELECT
	|	FACost.FixedAsset AS FixedAsset,
	|	SUM(FACost.LocalCost + FACost.CostTargetFinancing) AS CostInAccounting,
	|	SUM(FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA) AS CostInTaxAccounting,
	|	SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD) AS CostPermanentDifference,
	|	SUM(FACost.CostTemporaryDifference + FACost.CostTargetFinancingTD) AS CostTemporaryDifference,
	|	SUM(FACost.Cost) AS CostInManagementAccounting
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|WHERE
	|	FACost.CostCalculation
	|	AND FACost.Active
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND FACost.Recorder = &Recorder
	|
	|GROUP BY
	|	FACost.FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", SampleDocument.Recorder);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	DocumentObject = SampleDocument.Recorder.GetObject(); // DocumentObject.FixedAssetsCostAdditions2_4 - 
	
	While Selection.Next() Do
		
		RowData = DocumentObject.FA.Find(Selection.FixedAsset, "FixedAsset");
		FillPropertyValues(RowData, Selection);
		
	EndDo;
	
	DocumentObject.Write();
	
EndProcedure

Procedure UpdateDocumentAttributionOfDeviationsToCostOfFA(SampleDocument)

	Block = New DataLock;
	
	LockItem = Block.Add("Document.AllocateVariancesToFixedAssetCost");
	LockItem.SetValue("Ref", SampleDocument.Recorder);
	
	LockItem = Block.Add("AccumulationRegister.FACost.RecordSet");
	LockItem.SetValue("Recorder", SampleDocument.Recorder);
	
	Block.Lock(); 
	
	QueryText = 
	"SELECT
	|	FACost.FixedAsset AS FixedAsset,
	|	SUM(FACost.LocalCost + FACost.CostTargetFinancing) AS AmountAccounting,
	|	SUM(FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA) AS AmountFA,
	|	SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD) AS AmountPermanentDifferences,
	|	SUM(FACost.Cost) AS AmountOfUU
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|WHERE
	|	FACost.CostCalculation
	|	AND FACost.Active
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND FACost.Recorder = &Recorder
	|
	|GROUP BY
	|	FACost.FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", SampleDocument.Recorder);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	DocumentObject = SampleDocument.Recorder.GetObject(); // DocumentObject.AllocateVariancesToFixedAssetCost - 
	
	While Selection.Next() Do
		
		RowData = DocumentObject.FA.Find(Selection.FixedAsset, "FixedAsset");
		FillPropertyValues(RowData, Selection);
		
	EndDo;
	
	DocumentObject.Write();
	
EndProcedure

Procedure UpdateDocumentAcceptanceForAccountingOfIa(SampleDocument)

	Block = New DataLock;
	
	LockItem = Block.Add("Document.IntangibleAssetsInitialRecognition2_4");
	LockItem.SetValue("Ref", SampleDocument.Recorder);
	
	LockItem = Block.Add("AccumulationRegister.IACost.RecordSet");
	LockItem.SetValue("Recorder", SampleDocument.Recorder);
	
	Block.Lock(); 
	
	QueryText = 
	"SELECT
	|	SUM(IACost.LocalCost + IACost.CostTargetFinancing) AS InitialCostLocalAccounting,
	|	SUM(IACost.CostInTaxAccounting + IACost.CostTargetFinancingTA) AS InitialCostTA,
	|	SUM(IACost.CostPermanentDifference + IACost.CostTargetFinancingPD) AS InitialCostPD,
	|	SUM(IACost.CostTemporaryDifference + IACost.CostTargetFinancingTD) AS InitialCostTD,
	|	SUM(IACost.Cost) AS InitialCostMA
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|WHERE
	|	IACost.CostCalculation
	|	AND IACost.Active
	|	AND IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND IACost.Recorder = &Recorder
	|
	|GROUP BY
	|	IACost.IntangibleAsset
	|
	|HAVING
	|	(SUM(IACost.LocalCost + IACost.CostTargetFinancing) <> 0
	|		OR SUM(IACost.CostInTaxAccounting + IACost.CostTargetFinancingTA) <> 0
	|		OR SUM(IACost.CostPermanentDifference + IACost.CostTargetFinancingPD) <> 0
	|		OR SUM(IACost.CostTemporaryDifference + IACost.CostTargetFinancingTD) <> 0
	|		OR SUM(IACost.Cost) <> 0)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", SampleDocument.Recorder);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf; 
	
	Selection = Result.Select();
	Selection.Next();
	
	DocumentObject = SampleDocument.Recorder.GetObject(); // DocumentObject.IntangibleAssetsInitialRecognition2_4 - 
	FillPropertyValues(DocumentObject, Selection);

	DocumentObject.Write();
	
EndProcedure

Procedure DeleteCostCalculationTasks()

	RecordSet = InformationRegisters.JobsForCalculatingNonCurrentAssetCost.CreateRecordSet();
	RecordSet.Write();
	
EndProcedure
 
#EndRegion

#EndIf