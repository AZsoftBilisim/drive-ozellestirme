#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Workplace data.
// 
// Parameters:
//  WorkplaceParameters - Structure - Workplace Parameters:
//  	* FilterPeriod - StandardPeriod -
//  	* FilterFixedAsset - CatalogRef.Assets -
//  	* FilterOrganization - CatalogRef.Companies -
// 
// Returns:
//  Structure - Workplace data, contains:
//		* ListData - ValueTable -
//		* DocumentsData - Map of KeyAndValue - Contains:
//			** Key - CatalogRef.Assets - 
//			** Value - Structure -
//
Function WorkplaceData(WorkplaceParameters) Export

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("CorrectAccountingErrors.WorkplaceData");

	ListData = New ValueTable();
	ListData.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	ListData.Columns.Add("FixedAsset", New TypeDescription("CatalogRef.Assets"));
	ListData.Columns.Add("RecognitionPresentation", Common.StringTypeDetails(100));
	ListData.Columns.Add("ChangingParametersPresentation", Common.StringTypeDetails(100));
	ListData.Columns.Add("WriteOffPresentation", Common.StringTypeDetails(100));
	ListData.Columns.Add("AdjustingPresentation", Common.StringTypeDetails(100));
	ListData.Columns.Add("TaxAccrualParametersPresentation", Common.StringTypeDetails(100));
	ListData.Columns.Add("DeRegistrationPresentation", Common.StringTypeDetails(100));
	ListData.Columns.Add("RecalculatePropertyTaxesPresentation", Common.StringTypeDetails(100));
	ListData.Columns.Add("Information", Common.StringTypeDetails(1000));
	ListData.Columns.Add("DocumentsData", New TypeDescription("Structure"));
	

	DocumentsData = New Map;
	
	QueryText =
	"SELECT ALLOWED
	|	FixedAssetsDocuments.Ref AS Ref,
	|	FixedAssetsDocuments.Organization AS Organization,
	|	FixedAssetsDocuments.FixedAsset AS FixedAsset,
	|	FixedAssetsDocuments.FixedAsset.Presentation AS FixedAssetPresentation,
	|	FixedAssetsDocuments.FixedAsset.AssetID AS AssetID,
	|	FixedAssetsDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	FixedAssetsDocuments.RecordInManAccounting AS RecordInManAccounting,
	|
	|	DocumentsRegistry.IBDocumentNumber AS Number,
	|	DocumentsRegistry.IBDocumentDate AS Date,
	|	DocumentsRegistry.Comment AS Comment
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.Ref = FixedAssetsDocuments.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	FixedAssetsDocuments.IsPatch
	|	AND DocumentsRegistry.Posted
	|
	|	AND (FixedAssetsDocuments.Date >= &StartDate
	|			OR &StartDate = DATETIME(1,1,1))
	|	AND (FixedAssetsDocuments.Date <= &EndDate
	|			OR &EndDate = DATETIME(1,1,1))
	|
	|	AND (FixedAssetsDocuments.Organization = &FilterOrganization
	|			OR &FilterOrganization = VALUE(Catalog.Companies.EmptyRef))
	|
	|	AND (FixedAssetsDocuments.FixedAsset = &FilterFixedAsset
	|			OR &FilterFixedAsset = VALUE(Catalog.Assets.EmptyRef))
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTListOfDocuments.FixedAsset AS FixedAsset
	|
	|INTO TTFAList
	|
	|FROM 
	|	TTListOfDocuments AS TTListOfDocuments
	|	
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALocation.Organization AS Organization,
	|	FALocation.FixedAsset AS FixedAsset
	|
	|INTO TTLocationOfFA
	|
	|FROM
	|	InformationRegister.FALocation.SliceLast(
	|			,
	|			FixedAsset IN (
	|				SELECT 
	|					TTFAList.FixedAsset 
	|				FROM 
	|					TTFAList AS TTFAList)) AS FALocation
	|	
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InitialFixedAssetsInformation.Organization AS Organization,
	|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
	|
	|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
	|	InitialFixedAssetsInformation.CommissioningDocumentTA AS CommissioningDocumentTA,
	|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA
	|
	|INTO TTInitialInformationFA
	|
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|			,
	|			(Organization, FixedAsset) IN (
	|				SELECT 
	|					TTLocationOfFA.Organization, 
	|					TTLocationOfFA.FixedAsset 
	|				FROM 
	|					TTLocationOfFA AS TTLocationOfFA)) AS InitialFixedAssetsInformation
	|	
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FACost.Recorder AS Ref,
	|	FACost.FixedAsset AS FixedAsset,
	|
	|	SUM(CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.Cost
	|		ELSE -FACost.Cost
	|	END) AS CostInManagementAccounting,
	|
	|	SUM(CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.LocalCost
	|		ELSE -FACost.LocalCost
	|	END) AS CostInAccounting,
	|
	|	SUM(CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostInTaxAccounting
	|		ELSE -FACost.CostInTaxAccounting
	|	END) AS CostInTaxAccounting,
	|
	|	SUM(CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancing
	|		ELSE -FACost.CostTargetFinancing
	|	END) AS CostTargetFinancing
	|
	|INTO CostTTOfFA
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|WHERE
	|	FACost.Active
	|	AND FACost.Recorder IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|GROUP BY
	|	FACost.Recorder,
	|	FACost.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FixedAssetsDepreciationCharge.Recorder AS Ref,
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|	SUM(CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.Depreciation
	|		ELSE FixedAssetsDepreciationCharge.Depreciation
	|	END) AS DepreciationManagementAccounting,
	|
	|	SUM(CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.DepreciationLocal
	|		ELSE FixedAssetsDepreciationCharge.DepreciationLocal
	|	END) AS DepreciationInAccounting,
	|
	|	SUM(CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|		ELSE FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|	END) AS DepreciationInTaxAccounting,
	|
	|	SUM(CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|		ELSE FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|	END) AS FixedAssetDepreciationTargetFinancing
	|
	|INTO TTDepreciationFA
	|
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|
	|WHERE
	|	FixedAssetsDepreciationCharge.Active
	|	AND FixedAssetsDepreciationCharge.Recorder IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|GROUP BY
	|	FixedAssetsDepreciationCharge.Recorder,
	|	FixedAssetsDepreciationCharge.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTFAList.FixedAsset AS FixedAsset,
	|	TTFAList.FixedAsset.OSGroup AS OSGroup,
	|	ISNULL(TTLocationOfFA.Organization, VALUE(Catalog.Companies.EmptyRef)) AS Organization,
	|
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentMA, UNDEFINED) AS CommissioningDocumentMA,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentAC, UNDEFINED) AS CommissioningDocumentAC,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentTA, UNDEFINED) AS CommissioningDocumentTA,
	|
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentMA.Number, UNDEFINED) AS CommissioningDocumentMANumber,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentAC.Number, UNDEFINED) AS CommissioningDocumentACNumber,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentTA.Number, UNDEFINED) AS CommissioningDocumentNumberTA,
	|
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentMA.Date, UNDEFINED) AS CommissioningDocumentMADate,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentAC.Date, UNDEFINED) AS CommissioningDocumentACDate,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentTA.Date, UNDEFINED) AS CommissioningDocumentDateTA,
	|
	|	ISNULL(AcceptanceOfMAForAccounting.AdjustmentModeFromPreviousDate, FALSE) AS CorrectionModeFromLastDateMA,
	|	ISNULL(AcceptanceOfACForAccounting.AdjustmentModeFromPreviousDate, FALSE) AS CorrectionModeFromLastACDate,
	|	ISNULL(AcceptanceForAccountingTA.AdjustmentModeFromPreviousDate, FALSE) AS CorrectionModeFromLastDateTA,
	|	ISNULL(AcceptanceOfMAForAccounting.DepreciationAdjustmentOption, UNDEFINED) = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically) AS AddAdditionalDepreciationForPreviousPeriodMA,
	|	ISNULL(AcceptanceOfACForAccounting.DepreciationAdjustmentOption, UNDEFINED) = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically) AS AddAdditionalDepreciationForPreviousACPeriod,
	|	ISNULL(AcceptanceForAccountingTA.DepreciationAdjustmentOption, UNDEFINED) = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically) AS AddAdditionalDepreciationForPreviousPeriodTA,
	|
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentMA.Comment, """") AS CommentMA,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentAC.Comment, """") AS ACSComment,
	|	ISNULL(TTInitialInformationFA.CommissioningDocumentTA.Comment, """") AS CommentTA
	|
	|FROM 
	|	TTFAList AS TTFAList
	|
	|		LEFT JOIN TTLocationOfFA AS TTLocationOfFA
	|		ON TTLocationOfFA.FixedAsset = TTFAList.FixedAsset
	|
	|		LEFT JOIN TTInitialInformationFA AS TTInitialInformationFA
	|		ON TTInitialInformationFA.FixedAsset = TTFAList.FixedAsset
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS AcceptanceOfMAForAccounting
	|		ON AcceptanceOfMAForAccounting.Ref = TTInitialInformationFA.CommissioningDocumentMA
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS AcceptanceOfACForAccounting
	|		ON AcceptanceOfACForAccounting.Ref = TTInitialInformationFA.CommissioningDocumentAC
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS AcceptanceForAccountingTA
	|		ON AcceptanceForAccountingTA.Ref = TTInitialInformationFA.CommissioningDocumentTA
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTListOfDocuments.Ref AS Ref,
	|	TTListOfDocuments.Organization AS Organization,
	|	TTListOfDocuments.FixedAsset AS FixedAsset,
	|	TTListOfDocuments.FixedAsset.OSGroup AS OSGroup,
	|	TTListOfDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TTListOfDocuments.RecordInManAccounting AS RecordInManAccounting,
	|
	|	TTListOfDocuments.Number AS Number,
	|	TTListOfDocuments.Date AS Date,
	|	TTListOfDocuments.Comment AS Comment,
	|
	|	ISNULL(ChangeFixedAssetFinancialDetails.UsefulLifeManagementAccountingFlag, FALSE) AS UsefulLifeManagementAccountingFlag,
	|	ISNULL(ChangeFixedAssetFinancialDetails.UsefulLifeAccountingFlag, FALSE) AS UsefulLifeAccountingFlag,
	|	ISNULL(ChangeFixedAssetFinancialDetails.UsefulLifeTaxAccountingFlag, FALSE) AS UsefulLifeTaxAccountingFlag,
	|	ISNULL(ChangeFixedAssetFinancialDetails.UsefulLifeManagementAccounting, 0) AS UsefulLifeManagementAccounting,
	|	ISNULL(ChangeFixedAssetFinancialDetails.UsefulLifeAccounting, 0) AS UsefulLifeAccounting,
	|	ISNULL(ChangeFixedAssetFinancialDetails.UsefulLifeTaxAccounting, 0) AS UsefulLifeTaxAccounting,
	|
	|	ISNULL(ChangeFixedAssetFinancialDetails.DepreciationAccrualManagementAccountingFlag, FALSE) AS DepreciationAccrualManagementAccountingFlag,
	|	ISNULL(ChangeFixedAssetFinancialDetails.DepreciationAccrualAccountingFlag, FALSE) AS DepreciationAccrualAccountingFlag,
	|	ISNULL(ChangeFixedAssetFinancialDetails.DepreciationAccrualTaxAccountingFlag, FALSE) AS DepreciationAccrualTaxAccountingFlag,
	|	ISNULL(ChangeFixedAssetFinancialDetails.DepreciationAccrualManagementAccounting, FALSE) AS DepreciationAccrualManagementAccounting,
	|	ISNULL(ChangeFixedAssetFinancialDetails.DepreciationAccrualAccounting, FALSE) AS DepreciationAccrualAccounting,
	|	ISNULL(ChangeFixedAssetFinancialDetails.DepreciationAccrualTaxAccounting, FALSE) AS DepreciationAccrualTaxAccounting,
	|
	|	ISNULL(FixedAssetCostAndDepreciationAdjustment.CostAdjustment, FALSE) AS CostAdjustment,
	|	ISNULL(FixedAssetCostAndDepreciationAdjustment.DepreciationAdjustment, FALSE) AS DepreciationAdjustment,
	|	ISNULL(FixedAssetCostAndDepreciationAdjustment.BonusDepreciationAdjustment, FALSE) AS BonusDepreciationAdjustment,
	|	ISNULL(FixedAssetCostAndDepreciationAdjustment.SeparateAdjustmentOfCurrentAndPreviousPeriods, FALSE) AS SeparateAdjustmentOfCurrentAndPreviousPeriods,
	|	ISNULL(FixedAssetCostAndDepreciationAdjustment.RecordCostDecreaseByReversal, FALSE) AS RecordCostDecreaseByReversal,
	|	ISNULL(FixedAssetCostAndDepreciationAdjustment.RecordThisYearDepreciationDecreaseAsStorno, FALSE) AS RecordThisYearDepreciationDecreaseAsStorno,
	|	ISNULL(FixedAssetCostAndDepreciationAdjustment.RecordingOfBonusDepreciationDecreaseStorno, FALSE) AS RecordingOfBonusDepreciationDecreaseStorno,
	|	
	|	CASE
	|		WHEN ISNULL(FixedAssetCostAndDepreciationAdjustment.BonusDepreciationDecreaseRecording, FALSE)
	|			THEN -ISNULL(AdjustingFixedAssetCostsAndDepreciationFATable.DepreciationAllowance, 0)
	|		ELSE ISNULL(AdjustingFixedAssetCostsAndDepreciationFATable.DepreciationAllowance, 0) 
	|	END AS DepreciationAllowance,
	|
	|	ISNULL(CostTTOfFA.CostInManagementAccounting, 0) AS CostInManagementAccounting,
	|	ISNULL(CostTTOfFA.CostInAccounting, 0) AS CostInAccounting,
	|	ISNULL(CostTTOfFA.CostInTaxAccounting, 0) AS CostInTaxAccounting,
	|	ISNULL(CostTTOfFA.CostTargetFinancing, 0) AS CostTargetFinancing,
	|
	|	ISNULL(TTDepreciationFA.DepreciationManagementAccounting, 0) AS DepreciationManagementAccounting,
	|	ISNULL(TTDepreciationFA.DepreciationInAccounting, 0) AS DepreciationInAccounting,
	|	ISNULL(TTDepreciationFA.DepreciationInTaxAccounting, 0) AS DepreciationInTaxAccounting,
	|	ISNULL(TTDepreciationFA.FixedAssetDepreciationTargetFinancing, 0) AS FixedAssetDepreciationTargetFinancing
	|
	|
	|FROM
	|	TTListOfDocuments AS TTListOfDocuments
	|
	|		LEFT JOIN Document.ChangeFixedAssetFinancialDetails2_4 AS ChangeFixedAssetFinancialDetails
	|		ON ChangeFixedAssetFinancialDetails.Ref = TTListOfDocuments.Ref
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS FixedAssetCostAndDepreciationAdjustment
	|		ON FixedAssetCostAndDepreciationAdjustment.Ref = TTListOfDocuments.Ref
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS AdjustingFixedAssetCostsAndDepreciationFATable
	|		ON AdjustingFixedAssetCostsAndDepreciationFATable.Ref = TTListOfDocuments.Ref
	|			AND AdjustingFixedAssetCostsAndDepreciationFATable.FixedAsset = TTListOfDocuments.FixedAsset
	|
	|
	|		LEFT JOIN CostTTOfFA AS CostTTOfFA
	|		ON CostTTOfFA.Ref = TTListOfDocuments.Ref
	|			AND CostTTOfFA.FixedAsset = TTListOfDocuments.FixedAsset
	|
	|		LEFT JOIN TTDepreciationFA AS TTDepreciationFA
	|		ON TTDepreciationFA.Ref = TTListOfDocuments.Ref
	|			AND TTDepreciationFA.FixedAsset = TTListOfDocuments.FixedAsset
	|
	|ORDER BY
	|	TTListOfDocuments.Date,
	|	TTListOfDocuments.Ref
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("StartDate", WorkplaceParameters.FilterPeriod.StartDate);
	Query.SetParameter("EndDate", WorkplaceParameters.FilterPeriod.EndDate);
	Query.SetParameter("FilterOrganization", WorkplaceParameters.FilterOrganization);
	Query.SetParameter("FilterFixedAsset", WorkplaceParameters.FilterFixedAsset);
	
	Result = Query.ExecuteBatch();
	
	DocumentsList = Result[Result.UBound()].Unload();
	IndexOfListOfDocuments = New Map();
	For Each SampleDocument In DocumentsList Do
		
		DocumentsSelection = IndexOfListOfDocuments.Get(SampleDocument.FixedAsset);
		If DocumentsSelection = Undefined Then
			DocumentsSelection = New Array;
		EndIf;
		
		DocumentsSelection.Add(SampleDocument);
		
		IndexOfListOfDocuments.Insert(SampleDocument.FixedAsset, DocumentsSelection);
		
	EndDo;
	
	Selection = Result[Result.UBound()-1].Select();
	While Selection.Next() Do
		
		RowData = ListData.Add();
		FillPropertyValues(RowData, Selection);
		
		FADocumentData = New Structure;

		FillInInformationAcceptanceForRegistration(FADocumentData, Selection);
		
		DocumentsSelection = IndexOfListOfDocuments.Get(Selection.FixedAsset);
		For Each SampleDocument In DocumentsSelection Do
			
			FillInInformationChangeParameters(FADocumentData, SampleDocument);
			FillInInformationWriteOff(FADocumentData, SampleDocument);
			FillInInformationCostAdjustmentAndDepreciation(FADocumentData, SampleDocument);
			
			
		EndDo;
		
		DocumentsData.Insert(Selection.FixedAsset, FADocumentData);
		
	EndDo;
	
	For Each RowData In ListData Do
		
		FADocumentData = DocumentsData.Get(RowData.FixedAsset);

		RowData.RecognitionPresentation = 
			SubmissionOfDocuments(FADocumentData, "FixedAssetsInitialRecognition2_4");
		
		RowData.ChangingParametersPresentation = 
			SubmissionOfDocuments(FADocumentData, "ChangeFixedAssetFinancialDetails2_4");
			
		RowData.WriteOffPresentation = 
			SubmissionOfDocuments(FADocumentData, "DisposeFixedAssets2_4");
			
		RowData.AdjustingPresentation = 
			SubmissionOfDocuments(FADocumentData, "FixedAssetCostAndDepreciationAdjustment");
		
		
		FillIn_Information(RowData, FADocumentData);
		
	EndDo;
	
	// Deleting service columns
	ListData.Columns.Delete("DocumentsData");

	WorkplaceData = New Structure;
	WorkplaceData.Insert("ListData", ListData);
	WorkplaceData.Insert("DocumentsData", DocumentsData);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ListData.Count() / 100);
	
	Return WorkplaceData;

EndFunction

Procedure FillInInformationAcceptanceForRegistration(FADocumentData, Selection)

	If Not ValueIsFilled(Selection.CommissioningDocumentMA)
		And Not ValueIsFilled(Selection.CommissioningDocumentAC)
		And Not ValueIsFilled(Selection.CommissioningDocumentTA) Then
		Return;
	EndIf;
	
	If Not FADocumentData.Property("FixedAssetsInitialRecognition2_4") Then
		DocumentsList = New Array;
	Else
		DocumentsList = FADocumentData.FixedAssetsInitialRecognition2_4; // Array
	EndIf;
	
	Comment = "";
	If ValueIsFilled(Selection.CommentMA)
		And (Not ValueIsFilled(Selection.ACSComment)
			Or Selection.CommissioningDocumentMA = Selection.CommissioningDocumentAC)
		And (Not ValueIsFilled(Selection.CommentTA)
			Or Selection.CommissioningDocumentMA = Selection.CommissioningDocumentTA) Then
				
		Comment = Selection.CommentMA;
		
	ElsIf ValueIsFilled(Selection.ACSComment)
		And (Not ValueIsFilled(Selection.CommentMA)
			Or Selection.CommissioningDocumentAC = Selection.CommissioningDocumentMA)
		And (Not ValueIsFilled(Selection.CommentTA)
			Or Selection.CommissioningDocumentMA = Selection.CommissioningDocumentTA) Then
				
		Comment = Selection.ACSComment;
		
	ElsIf ValueIsFilled(Selection.CommentTA)
		And (Not ValueIsFilled(Selection.CommentMA)
			Or Selection.CommissioningDocumentTA = Selection.CommissioningDocumentMA)
		And (Not ValueIsFilled(Selection.ACSComment)
			Or Selection.CommissioningDocumentTA = Selection.CommissioningDocumentAC) Then
				
		Comment = Selection.CommentTA;
		
	EndIf;
	
	If ValueIsFilled(Selection.CommissioningDocumentMA)  Then
			
		AddDocumentData(
			DocumentsList, 
			Selection.CommissioningDocumentMA, 
			Selection.CommissioningDocumentMANumber, 
			Selection.CommissioningDocumentMADate,
			Comment);
			
	EndIf;
	
	If ValueIsFilled(Selection.CommissioningDocumentAC)
		And Selection.CommissioningDocumentAC <> Selection.CommissioningDocumentMA Then
		
		AddDocumentData(
			DocumentsList, 
			Selection.CommissioningDocumentAC, 
			Selection.CommissioningDocumentACNumber, 
			Selection.CommissioningDocumentACDate,
			Comment);
			
	EndIf;
	
	If ValueIsFilled(Selection.CommissioningDocumentTA)
		And Selection.CommissioningDocumentTA <> Selection.CommissioningDocumentMA
		And Selection.CommissioningDocumentTA <> Selection.CommissioningDocumentAC Then
		
		AddDocumentData(
			DocumentsList, 
			Selection.CommissioningDocumentTA, 
			Selection.CommissioningDocumentNumberTA, 
			Selection.CommissioningDocumentDateTA,
			Comment);
			
	EndIf;

	AddDocumentParameter(
		FADocumentData, 
		"AdjustmentModeFromPreviousDate", 
		Selection.CorrectionModeFromLastDateMA Or Selection.CorrectionModeFromLastACDate Or Selection.CorrectionModeFromLastDateTA);
	
	AddDocumentParameter(
		FADocumentData, 
		"AccrueAdditionalDepreciationForPreviousPeriod", 
		Selection.AddAdditionalDepreciationForPreviousPeriodMA Or Selection.AddAdditionalDepreciationForPreviousACPeriod Or Selection.AddAdditionalDepreciationForPreviousPeriodTA);
	
	FADocumentData.Insert("FixedAssetsInitialRecognition2_4", DocumentsList);
	
EndProcedure

Procedure FillInInformationChangeParameters(FADocumentData, SampleDocument)
	
	If TypeOf(SampleDocument.Ref) <> Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4") Then
		Return;
	EndIf;
	
	If Not FADocumentData.Property("ChangeFixedAssetFinancialDetails2_4") Then
		DocumentsList = New Array;
	Else
		DocumentsList = FADocumentData.ChangeFixedAssetFinancialDetails2_4; // Array
	EndIf;
	
	AddDocumentData(
		DocumentsList, 
		SampleDocument.Ref, 
		SampleDocument.Number, 
		SampleDocument.Date,
		SampleDocument.Comment,
		SampleDocument.RecordInLocalAccounting,
		SampleDocument.RecordInManAccounting);
	
	If SampleDocument.UsefulLifeManagementAccountingFlag Then
		AddDocumentParameter(FADocumentData, "UsefulLifeManagementAccounting", SampleDocument.UsefulLifeManagementAccounting);
	EndIf;

	If SampleDocument.UsefulLifeAccountingFlag Then
		AddDocumentParameter(FADocumentData, "UsefulLifeAccounting", SampleDocument.UsefulLifeAccounting);
	EndIf;

	If SampleDocument.UsefulLifeTaxAccountingFlag Then
		AddDocumentParameter(FADocumentData, "UsefulLifeTaxAccounting", SampleDocument.UsefulLifeTaxAccounting);
	EndIf;

	If SampleDocument.DepreciationAccrualManagementAccountingFlag Then
		AddDocumentParameter(FADocumentData, "DepreciationAccrualManagementAccounting", SampleDocument.DepreciationAccrualManagementAccounting);
	EndIf;

	If SampleDocument.DepreciationAccrualAccountingFlag Then
		AddDocumentParameter(FADocumentData, "DepreciationAccrualAccounting", SampleDocument.DepreciationAccrualAccounting);
	EndIf;

	If SampleDocument.DepreciationAccrualTaxAccountingFlag Then
		AddDocumentParameter(FADocumentData, "DepreciationAccrualTaxAccounting", SampleDocument.DepreciationAccrualTaxAccounting);
	EndIf;

	FADocumentData.Insert("ChangeFixedAssetFinancialDetails2_4", DocumentsList);
	
EndProcedure

Procedure FillInInformationWriteOff(FADocumentData, SampleDocument)
	
	If TypeOf(SampleDocument.Ref) <> Type("DocumentRef.DisposeFixedAssets2_4") Then
		Return;
	EndIf;
		
	If Not FADocumentData.Property("DisposeFixedAssets2_4") Then
		DocumentsList = New Array;
	Else
		DocumentsList = FADocumentData.DisposeFixedAssets2_4; // Array
	EndIf;
	
	AddDocumentData(
		DocumentsList, 
		SampleDocument.Ref, 
		SampleDocument.Number, 
		SampleDocument.Date,
		SampleDocument.Comment,
		SampleDocument.RecordInLocalAccounting,
		SampleDocument.RecordInManAccounting);
	
	FADocumentData.Insert("DisposeFixedAssets2_4", DocumentsList);
	
EndProcedure

Procedure FillInInformationCostAdjustmentAndDepreciation(FADocumentData, SampleDocument)
	
	If TypeOf(SampleDocument.Ref) <> Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment") Then
		Return;
	EndIf;
		
	If Not FADocumentData.Property("FixedAssetCostAndDepreciationAdjustment") Then
		DocumentsList = New Array;
	Else
		DocumentsList = FADocumentData.FixedAssetCostAndDepreciationAdjustment; // Array
	EndIf;
	
	DocumentData = AddDocumentData(
		DocumentsList, 
		SampleDocument.Ref, 
		SampleDocument.Number, 
		SampleDocument.Date,
		SampleDocument.Comment,
		SampleDocument.RecordInLocalAccounting,
		SampleDocument.RecordInManAccounting);
		
	DocumentData.Insert("CostAdjustment", SampleDocument.CostAdjustment);
	DocumentData.Insert("CostInManagementAccounting", SampleDocument.CostInManagementAccounting);
	DocumentData.Insert("CostInAccounting", SampleDocument.CostInAccounting);
	DocumentData.Insert("CostInTaxAccounting", SampleDocument.CostInTaxAccounting);
	DocumentData.Insert("CostTargetFinancing", SampleDocument.CostTargetFinancing);
	DocumentData.Insert("RecordCostDecreaseByReversal", SampleDocument.RecordCostDecreaseByReversal);
	
	DocumentData.Insert("DepreciationAdjustment", SampleDocument.DepreciationAdjustment);
	DocumentData.Insert("DepreciationManagementAccounting", SampleDocument.DepreciationManagementAccounting);
	DocumentData.Insert("DepreciationInAccounting", SampleDocument.DepreciationInAccounting);
	DocumentData.Insert("DepreciationInTaxAccounting", SampleDocument.DepreciationInTaxAccounting);
	DocumentData.Insert("FixedAssetDepreciationTargetFinancing", SampleDocument.FixedAssetDepreciationTargetFinancing);
	DocumentData.Insert("SeparateAdjustmentOfCurrentAndPreviousPeriods", SampleDocument.SeparateAdjustmentOfCurrentAndPreviousPeriods);
	DocumentData.Insert("RecordThisYearDepreciationDecreaseAsStorno", SampleDocument.RecordThisYearDepreciationDecreaseAsStorno);
	
	DocumentData.Insert("BonusDepreciationAdjustment", SampleDocument.BonusDepreciationAdjustment);
	DocumentData.Insert("DepreciationAllowance", SampleDocument.DepreciationAllowance);
	DocumentData.Insert("RecordingOfBonusDepreciationDecreaseStorno", SampleDocument.RecordingOfBonusDepreciationDecreaseStorno);
		
	FADocumentData.Insert("FixedAssetCostAndDepreciationAdjustment", DocumentsList);
		
EndProcedure


Procedure FillIn_Information(RowData, FADocumentData)
	
	CurrencyOfMan = String(Constants.ManagementAccountingCurrency.Get());
	ComplCurrency = String(SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(RowData.Organization));
	
	StringsInformation = New Array;
	
	StyleNameSlantedFont = Metadata.StyleItems.ItalicFontEM.Name;
	
	#Region Recognition
	
	If FADocumentData.Property("AdjustmentModeFromPreviousDate")
		And FADocumentData.AdjustmentModeFromPreviousDate Then
			
		Text = NStr("vi = 'Tài sản cố định hữu hình được tiếp nhận vào kế toán từ ngày trước.';
					|ru = 'Основное средство принято к учету с прошлой даты.';
					|en = 'The fixed asset is recognized from the previous period.'; fa = 'The fixed asset is recognized from the previous period.';
					|it = 'Основное средство принято к учету с прошлой даты.';
					|pl = 'The fixed asset is recognized from the previous period.';
					|tr = 'Sabit kıymet önceki tarihten itibaren muhasebeye kabul edildi'");
		StringsInformation.Add(Text);
	
		If FADocumentData.AccrueAdditionalDepreciationForPreviousPeriod Then
			Text = NStr("vi = 'KHấu hao được tính thêm tự động khi tính khấu hao.';
						|ru = 'Амортизация доначисляется автоматически при расчете амортизации.';
						|en = 'Depreciation is additionally accrued automatically upon calculation.'; fa = 'Depreciation is additionally accrued automatically upon calculation.';
						|it = 'Амортизация доначисляется автоматически при расчете амортизации.';
						|pl = 'Depreciation is additionally accrued automatically upon calculation.';
						|tr = 'Amortisman hesaplanırken amortisman otomatik olarak eklenir.'");
			StringsInformation.Add(Text);
		Else
			Text = NStr("vi = 'Khấu hao được tính thêm thủ công thông qua điều chỉnh.';
						|ru = 'Амортизация доначисляется вручную при помощи корректировки.';
						|en = 'Depreciation is additionally accrued manually by adjusting.'; fa = 'Depreciation is additionally accrued manually by adjusting.';
						|it = 'Амортизация доначисляется вручную при помощи корректировки.';
						|pl = 'Depreciation is additionally accrued manually by adjusting.';
						|tr = 'Amortisman bir ayarlama kullanılarak manuel olarak eklenir.'");
			StringsInformation.Add(Text);
		EndIf;
	
	EndIf;
	
	#EndRegion

	#Region ChangingParameters
	
	If FADocumentData.Property("ChangeFixedAssetFinancialDetails2_4") Then
		
		ThereIsChangeToSLEEP = 
			FADocumentData.Property("UsefulLifeManagementAccounting")
			Or FADocumentData.Property("UsefulLifeAccounting")
			Or FADocumentData.Property("UsefulLifeTaxAccounting");
			
		ThereIsChangeInDepreciation = 
			FADocumentData.Property("DepreciationAccrualManagementAccounting")
				And FADocumentData.DepreciationAccrualManagementAccounting
			Or FADocumentData.Property("DepreciationAccrualAccounting")
				And FADocumentData.DepreciationAccrualAccounting
			Or FADocumentData.Property("DepreciationAccrualTaxAccounting");
			
		If ThereIsChangeToSLEEP And ThereIsChangeInDepreciation Then
			
			Text = NStr("vi = 'Thời hạn sử dụng mới và tính khấu hao được thiết lập bằng cách thay đổi tham số.';
						|ru = 'Изменением параметров установлен новый срок использования и начисление амортизации.';
						|en = 'A new useful life and depreciation charge are set by the financial details adjustment document.'; fa = 'A new useful life and depreciation charge are set by the financial details adjustment document.';
						|it = 'Изменением параметров установлен новый срок использования и начисление амортизации.';
						|pl = 'A new useful life and depreciation charge are set by the financial details adjustment document.';
						|tr = 'Parametreler değiştirilerek yeni bir hizmet ömrü ve amortisman hesaplaması oluşturuldu.'");
			StringsInformation.Add(Text);
		
		ElsIf ThereIsChangeToSLEEP Then
			
			Text = NStr("vi = 'Thời hạn sử dụng mới được thiết lập bằng cách thay đổi tham số.';
						|ru = 'Изменением параметров установлен новый срок использования.';
						|en = 'A new useful life is set by the financial details adjustment document.'; fa = 'A new useful life is set by the financial details adjustment document.';
						|it = 'Изменением параметров установлен новый срок использования.';
						|pl = 'A new useful life is set by the financial details adjustment document.';
						|tr = 'Parametreler değiştirilerek yeni bir hizmet ömrü oluşturuldu.'");
			StringsInformation.Add(Text);
			
		ElsIf FADocumentData.Property("DepreciationAccrualManagementAccounting")
				And FADocumentData.DepreciationAccrualManagementAccounting
			Or FADocumentData.Property("DepreciationAccrualAccounting")
				And FADocumentData.DepreciationAccrualAccounting
			Or FADocumentData.Property("DepreciationAccrualTaxAccounting")
				And FADocumentData.DepreciationAccrualTaxAccounting Then
			
			Text = NStr("vi = 'Khấu hao được tiếp tục tính bằng cách thay đổi tham số.';
						|ru = 'Изменением параметров возобновлено начисление амортизации.';
						|en = 'The depreciation charge is resumed by the financial details adjustment document.'; fa = 'The depreciation charge is resumed by the financial details adjustment document.';
						|it = 'Изменением параметров возобновлено начисление амортизации.';
						|pl = 'The depreciation charge is resumed by the financial details adjustment document.';
						|tr = 'Parametreler değiştirilerek amortisman hesaplamasına devam edildi.'");
			StringsInformation.Add(Text);
			
		ElsIf FADocumentData.Property("DepreciationAccrualManagementAccounting")
				And Not FADocumentData.DepreciationAccrualManagementAccounting
			Or FADocumentData.Property("DepreciationAccrualAccounting")
				And Not FADocumentData.DepreciationAccrualAccounting
			Or FADocumentData.Property("DepreciationAccrualTaxAccounting")
				And Not FADocumentData.DepreciationAccrualTaxAccounting Then
			
			Text = NStr("vi = 'Khấu hao được tạm dừng tính bằng cách thay đổi tham số.';
						|ru = 'Изменением параметров остановлено начисление амортизации.';
						|en = 'The depreciation charge is stopped by the financial details adjustment document.'; fa = 'The depreciation charge is stopped by the financial details adjustment document.';
						|it = 'Изменением параметров остановлено начисление амортизации.';
						|pl = 'The depreciation charge is stopped by the financial details adjustment document.';
						|tr = 'Parametreler değiştirilerek amortisman hesaplamasına devam edildi.'");
			StringsInformation.Add(Text);
			
		EndIf;
		
	Else
			
		Text = NStr("vi = 'Từ ngày tiếp nhận vào kế toán, nếu tham số kế toán thay đổi, thì cần lập chứng từ thay đổi tham số (có thể lập nhiều chứng từ).';
					|ru = 'Если с даты принятия к учету параметры учета изменялись, то необходимо оформить изменение параметров (можно оформить несколько документов).';
					|en = 'If accounting parameters changed since the recognition date, create the financial details adjustment. You can create multiple documents.'; fa = 'If accounting parameters changed since the recognition date, create the financial details adjustment. You can create multiple documents.';
					|it = 'Если с даты принятия к учету параметры учета изменялись, то необходимо оформить изменение параметров (можно оформить несколько документов).';
					|pl = 'If accounting parameters changed since the recognition date, create the financial details adjustment. You can create multiple documents.';
					|tr = 'Muhasebe parametreleri, muhasebe için kabul tarihinden bu yana değiştiyse, parametrelerdeki değişikliğin resmileştirilmesi gerekir (birkaç belge yürütülebilir).'");
		StringsInformation.Add(Text);
		
	EndIf;
	
	#EndRegion

	#Region CostAndDepreciationAdjustments
	
	If FADocumentData.Property("FixedAssetCostAndDepreciationAdjustment") Then
	
		CostInManagementAccounting = 0;
		CostInAccounting = 0;
		CostInTaxAccounting = 0;
		CostTargetFinancing = 0;
		
		DepreciationManagementAccounting = 0;
		DepreciationInAccounting = 0;
		DepreciationInTaxAccounting = 0;
		FixedAssetDepreciationTargetFinancing = 0;
		
		DepreciationAllowance = 0;
		
		DocumentsList = FADocumentData.FixedAssetCostAndDepreciationAdjustment; // Array
		For Each DocumentData In DocumentsList Do
			
			If DocumentData.CostAdjustment
				And CostInManagementAccounting = 0
				And CostInAccounting = 0
				And CostInTaxAccounting = 0
				And CostTargetFinancing = 0 Then
			
				If DocumentData.RecordInManAccounting
					And DocumentData.CostInManagementAccounting <> 0 Then
							
					CostInManagementAccounting = DocumentData.CostInManagementAccounting;
				EndIf;
				
				If DocumentData.RecordInLocalAccounting
					And (DocumentData.CostInAccounting <> 0 
						Or DocumentData.CostInTaxAccounting <> 0 
						Or DocumentData.CostTargetFinancing <> 0) Then
							
					CostInAccounting = DocumentData.CostInAccounting;
					CostInTaxAccounting = DocumentData.CostInTaxAccounting;
					CostTargetFinancing = DocumentData.CostTargetFinancing;
					
				EndIf;
			
			EndIf;
			
			If DocumentData.DepreciationAdjustment
				And DepreciationManagementAccounting = 0
				And DepreciationInAccounting = 0
				And DepreciationInTaxAccounting = 0
				And FixedAssetDepreciationTargetFinancing = 0 Then
			
				If DocumentData.RecordInManAccounting
					And DocumentData.DepreciationManagementAccounting <> 0 Then
							
					DepreciationManagementAccounting = DocumentData.DepreciationManagementAccounting;
				EndIf;
				
				If DocumentData.RecordInLocalAccounting
					And (DocumentData.DepreciationInAccounting <> 0 
						Or DocumentData.DepreciationInTaxAccounting <> 0 
						Or DocumentData.FixedAssetDepreciationTargetFinancing <> 0) Then
							
					DepreciationInAccounting = DocumentData.DepreciationInAccounting;
					DepreciationInTaxAccounting = DocumentData.DepreciationInTaxAccounting;
					FixedAssetDepreciationTargetFinancing = DocumentData.FixedAssetDepreciationTargetFinancing;
					
				EndIf;
			
			EndIf;
			
			If DocumentData.BonusDepreciationAdjustment
				And DepreciationAllowance = 0 Then
				
				DepreciationAllowance = DocumentData.DepreciationAllowance;
					
			EndIf;
			
		EndDo;
		
		If CostInManagementAccounting <> 0
			Or CostInAccounting <> 0
			Or CostInTaxAccounting <> 0
			Or CostTargetFinancing <> 0 Then
			
			If DocumentsList.Count() > 1 Then
				Text = StrTemplate(NStr("vi = 'Thông tin thay đổi giá trị theo dữ liệu của chứng từ đầu tiên:<span style=""font:%1"">';
										|ru = 'Сведения об изменении стоимости по данным первого документа:<span style=""font:%1"">';
										|en = 'Cost change information according to the first document data:<span style=""font:%1"">'; fa = 'Cost change information according to the first document data:<span style=""font:%1"">';
										|it = 'Сведения об изменении стоимости по данным первого документа:<span style=""font:%1"">';
										|pl = 'Cost change information according to the first document data:<span style=""font:%1"">';
										|tr = 'İlk belgeye göre değerdeki değişikliklere ilişkin bilgiler:<span style=""font:%1"">'"), StyleNameSlantedFont);
				StringsInformation.Add(Text);
			Else
				Text = StrTemplate(NStr("vi = 'Thông tin thay đổi giá trị:<span style=""font:%1"">';
										|ru = 'Сведения об изменении стоимости:<span style=""font:%1"">';
										|en = 'Cost change information:<span style=""font:%1"">'; fa = 'Cost change information:<span style=""font:%1"">';
										|it = 'Сведения об изменении стоимости:<span style=""font:%1"">';
										|pl = 'Cost change information:<span style=""font:%1"">';
										|tr = 'Fiyat değişiklikleri hakkında bilgi: <span style=""font:%1"">'"), StyleNameSlantedFont);
				StringsInformation.Add(Text);
			EndIf;
			
			If CostInManagementAccounting <> 0 Then
				Text = StrTemplate(NStr("vi = 'KTQT: %1 (%2)';
										|ru = 'УУ: %1 (%2)';
										|en = 'MA: %1 (%2)'; fa = 'MA: %1 (%2)';
										|it = 'УУ: %1 (%2)';
										|pl = 'MA: %1 (%2)';
										|tr = 'YM: %1 (%2)'"), Format(CostInManagementAccounting, "NFD=2;"), CurrencyOfMan);
				StringsInformation.Add(Text);
			EndIf;
			
			If CostInAccounting <> 0 Then
				Text = StrTemplate(NStr("vi = 'KTDN: %1 (%2)';
										|ru = 'БУ: %1 (%2)';
										|en = 'LA: %1 (%2)'; fa = 'LA: %1 (%2)';
										|it = 'БУ: %1 (%2)';
										|pl = 'LA: %1 (%2)';
										|tr = 'GM: %1 (%2)'"), Format(CostInAccounting, "NFD=2;"), ComplCurrency);
				StringsInformation.Add(Text);
			EndIf;
			
			If CostInTaxAccounting <> 0 Then
				Text = StrTemplate(NStr("vi = 'KTTh: %1 (%2)';
										|ru = 'НУ: %1 (%2)';
										|en = 'TA: %1 (%2)'; fa = 'TA: %1 (%2)';
										|it = 'НУ: %1 (%2)';
										|pl = 'TA: %1 (%2)';
										|tr = 'VM: %1 (%2)'"), Format(CostInTaxAccounting, "NFD=2;"), ComplCurrency);
				StringsInformation.Add(Text);
			EndIf;
			
			If CostTargetFinancing <> 0 Then
				Text = StrTemplate(NStr("vi = 'CF: %1 (%2)';
										|ru = 'ЦФ: %1 (%2)';
										|en = 'TF: %1 (%2)'; fa = 'TF: %1 (%2)';
										|it = 'ЦФ: %1 (%2)';
										|pl = 'TF: %1 (%2)';
										|tr = 'HF: %1 (%2)'"), Format(CostTargetFinancing, "NFD=2;"), ComplCurrency);
				StringsInformation.Add(Text);
			EndIf;
			
			StringsInformation.Add("</span>");
			
		EndIf;
		
		If DepreciationManagementAccounting <> 0
			Or DepreciationInAccounting <> 0
			Or DepreciationInTaxAccounting <> 0
			Or FixedAssetDepreciationTargetFinancing <> 0 Then
			
			If DocumentsList.Count() > 1 Then
				Text = StrTemplate(NStr("vi = 'Thông tin thay đổi khấu hao theo dữ liệu của chứng từ đầu tiên:<span style=""font:%1"">';
										|ru = 'Сведения об изменении амортизации по данным первого документа:<span style=""font:%1"">';
										|en = 'Depreciation change information according to the first document data:<span style=""font:%1"">'; fa = 'Depreciation change information according to the first document data:<span style=""font:%1"">';
										|it = 'Сведения об изменении амортизации по данным первого документа:<span style=""font:%1"">';
										|pl = 'Depreciation change information according to the first document data:<span style=""font:%1"">';
										|tr = 'İlk belgeye göre amortisman değişiklikleri hakkında bilgi:<span style=""font:%1"">'"), StyleNameSlantedFont);
				StringsInformation.Add(Text);
			Else
				Text = StrTemplate(NStr("vi = 'Thông tin thay đổi khấu hao:<span style=""font:%1"">';
										|ru = 'Сведения об изменении амортизации:<span style=""font:%1"">';
										|en = 'Depreciation change information:<span style=""font:%1"">'; fa = 'Depreciation change information:<span style=""font:%1"">';
										|it = 'Сведения об изменении амортизации:<span style=""font:%1"">';
										|pl = 'Depreciation change information:<span style=""font:%1"">';
										|tr = 'Amortisman değişiklikleri hakkında bilgi: <span style=""font:%1"">'"), StyleNameSlantedFont);
				StringsInformation.Add(Text);
			EndIf;
			
			If DepreciationManagementAccounting <> 0 Then
				Text = StrTemplate(NStr("vi = 'KTQT: %1 (%2)';
										|ru = 'УУ: %1 (%2)';
										|en = 'MA: %1 (%2)'; fa = 'MA: %1 (%2)';
										|it = 'УУ: %1 (%2)';
										|pl = 'MA: %1 (%2)';
										|tr = 'YM: %1 (%2)'"), Format(DepreciationManagementAccounting, "NFD=2;"), CurrencyOfMan);
				StringsInformation.Add(Text);
			EndIf;
			
			If DepreciationInAccounting <> 0 Then
				Text = StrTemplate(NStr("vi = 'KTDN: %1 (%2)';
										|ru = 'БУ: %1 (%2)';
										|en = 'LA: %1 (%2)'; fa = 'LA: %1 (%2)';
										|it = 'БУ: %1 (%2)';
										|pl = 'LA: %1 (%2)';
										|tr = 'GM: %1 (%2)'"), Format(DepreciationInAccounting, "NFD=2;"), ComplCurrency);
				StringsInformation.Add(Text);
			EndIf;
			
			If DepreciationInTaxAccounting <> 0 Then
				Text = StrTemplate(NStr("vi = 'KTTh: %1 (%2)';
										|ru = 'НУ: %1 (%2)';
										|en = 'TA: %1 (%2)'; fa = 'TA: %1 (%2)';
										|it = 'НУ: %1 (%2)';
										|pl = 'TA: %1 (%2)';
										|tr = 'VM: %1 (%2)'"), Format(DepreciationInTaxAccounting, "NFD=2;"), ComplCurrency);
				StringsInformation.Add(Text);
			EndIf;
			
			If FixedAssetDepreciationTargetFinancing <> 0 Then
				Text = StrTemplate(NStr("vi = 'CF: %1 (%2)';
										|ru = 'ЦФ: %1 (%2)';
										|en = 'TF: %1 (%2)'; fa = 'TF: %1 (%2)';
										|it = 'ЦФ: %1 (%2)';
										|pl = 'TF: %1 (%2)';
										|tr = 'HF: %1 (%2)'"), Format(FixedAssetDepreciationTargetFinancing, "NFD=2;"), ComplCurrency);
				StringsInformation.Add(Text);
			EndIf;
			
			StringsInformation.Add("</span>");

		EndIf;
		
		If DepreciationAllowance <> 0 Then
			
			If DocumentsList.Count() > 1 Then
				Text = NStr("vi = 'Thông tin thay đổi khấu hao theo dữ liệu của chứng từ đầu tiên: %1 (%2)';
							|ru = 'Сведения об изменении амортизационной премии по данным первого документа: %1 (%2)';
							|en = 'Bonus depreciation change information according to the first document data: %1 (%2)'; fa = 'Bonus depreciation change information according to the first document data: %1 (%2)';
							|it = 'Сведения об изменении амортизационной премии по данным первого документа: %1 (%2)';
							|pl = 'Bonus depreciation change information according to the first document data: %1 (%2)';
							|tr = 'İlk belgeye göre amortisman ikramiyesindeki değişikliklere ilişkin bilgiler:%1 (%2)'");
			Else
				Text = NStr("vi = 'Thông tin thay đổi khấu hao: %1 (%2)';
							|ru = 'Сведения об изменении амортизационной премии: %1 (%2)';
							|en = 'Bonus depreciation change information: %1 (%2)'; fa = 'Bonus depreciation change information: %1 (%2)';
							|it = 'Сведения об изменении амортизационной премии: %1 (%2)';
							|pl = 'Bonus depreciation change information: %1 (%2)';
							|tr = 'Amortisman ikramiyesindeki değişiklikler hakkında bilgi:%1 (%2)'");
			EndIf;
			
			Text = StrTemplate(Text, Format(DepreciationAllowance, "NFD=2;"), ComplCurrency);
			StringsInformation.Add(Text);
			
		EndIf;
				
	EndIf;
	
	#EndRegion

	
	If StringsInformation.Count() <> 0 Then
		RowData.Information = StrConcat(StringsInformation, Chars.LF);
	EndIf;
	
EndProcedure

Function SubmissionOfDocuments(FADocumentData, DocumentName)

	If Not FADocumentData.Property(DocumentName) Then
		Return "";
	EndIf;
	
	DocumentData = FADocumentData[DocumentName]; // Array
	If DocumentData.Count() = 0 Then
		Return "";
	EndIf;
	
	DocumentsList = New Array;
	
	If DocumentData.Count() = 1 
		And ValueIsFilled(DocumentData[0].Comment) Then
		
		Presentation = StrTemplate(NStr("vi = 'Số %1 ngày %2 (%3)';
										|ru = '№%1 от %2 (%3)';
										|en = 'No.%1 dated %2 (%3)'; fa = 'No.%1 dated %2 (%3)';
										|it = '№%1 от %2 (%3)';
										|pl = 'nr%1 z dn. %2 (%3)';
										|tr = '%1 %2 itibaren %3'"), 
			DocumentData[0].Number, Format(DocumentData[0].Date, "DLF=D;"), Left(DocumentData[0].Comment, 50));
		DocumentsList.Add(Presentation);
	Else
		Presentation = StrTemplate(NStr("vi = 'Số %1 ngày %2';
										|ru = '№%1 от %2';
										|en = '#%1, %2'; fa = '#%1, %2';
										|it = '№%1 от %2';
										|pl = 'Nr%1 z dnia %2';
										|tr = '%2 itibarıyla № %1'"), DocumentData[0].Number, Format(DocumentData[0].Date, "DLF=D;"));
		DocumentsList.Add(Presentation);
	EndIf;
	
	If DocumentData.Count() > 1 Then
		
		Presentation = StrTemplate(NStr("vi = 'Số %1 ngày %2';
										|ru = '№%1 от %2';
										|en = '#%1, %2'; fa = '#%1, %2';
										|it = '№%1 от %2';
										|pl = 'Nr%1 z dnia %2';
										|tr = '%2 itibarıyla № %1'"), DocumentData[1].Number, Format(DocumentData[1].Date, "DLF=D;"));
		DocumentsList.Add(Presentation);
		
	EndIf;
	
	If DocumentData.Count() = 3 Then
		
		Presentation = StrTemplate(NStr("vi = 'Số %1 ngày %2';
										|ru = '№%1 от %2';
										|en = '#%1, %2'; fa = '#%1, %2';
										|it = '№%1 от %2';
										|pl = 'Nr%1 z dnia %2';
										|tr = '%2 itibarıyla № %1'"), DocumentData[2].Number, Format(DocumentData[2].Date, "DLF=D;"));
		DocumentsList.Add(Presentation);
		
	ElsIf DocumentData.Count() > 3 Then
		
		Presentation = StrTemplate(NStr("vi = '(hơn nữa %1)';
										|ru = '(еще %1)';
										|en = '(and %1)'; fa = '(and %1)';
										|it = '(еще %1)';
										|pl = '(and %1)';
										|tr = '(%1 daha)'"), DocumentData.Count() - 2);
		DocumentsList.Add(Presentation);
		
	EndIf;

	Presentation = StrConcat(DocumentsList, Chars.LF);
	
	Return Presentation;
	
EndFunction

Function AddDocumentData(DocumentsList, Ref, Number, Date, Comment, RecordInLocalAccounting = Undefined, RecordInManAccounting = Undefined)
	
	DocumentData = New Structure;
	DocumentData.Insert("DocumentRef", Ref);
	DocumentData.Insert("Number", ObjectsPrefixesClientServer.NumberForPrinting(Number));
	DocumentData.Insert("Date", Date);
	DocumentData.Insert("Comment", Comment);
	DocumentData.Insert("RecordInLocalAccounting", RecordInLocalAccounting);
	DocumentData.Insert("RecordInManAccounting", RecordInManAccounting);
	
	DocumentsList.Add(DocumentData);
	
	Return DocumentData;
	
EndFunction

Procedure AddDocumentParameter(FADocumentData, ParameterName, ParameterValue)
	
	If FADocumentData.Property(ParameterName) Then
		FADocumentData.Insert(ParameterName, ParameterValue Or FADocumentData[ParameterName]);
	Else
		FADocumentData.Insert(ParameterName, ParameterValue);
	EndIf;	
	
EndProcedure

#EndRegion

#EndIf