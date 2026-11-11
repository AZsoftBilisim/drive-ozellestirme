////////////////////////////////////////////////////////////////////////////////
// Procedures of the repair management subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function EstablishStatusOfObjectsOfOperation(HighlightedLinks, StatusValue) Export

	NewStatus = Enums.AssetStatuses[StatusValue];
	
	QueryText =
	"SELECT ALLOWED
	|	Assets.Ref,
	|	Assets.Description,
	|	Assets.DeletionMark
	|FROM
	|	Catalog.Assets AS Assets
	|WHERE
	|	Assets.Status <> &NewStatus
	|	AND Assets.Ref IN(&HighlightedLinks)
	|	AND NOT Assets.IsFolder";
	
	Query = New Query(QueryText);
	Query.SetParameter("HighlightedLinks", HighlightedLinks);
	Query.SetParameter("NewStatus", NewStatus);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ProcessedItemsCount = 0;
	ThereAreFillCheckingErrors = False;
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.Assets");
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock(); 
			
			CatObject = Selection.Ref.GetObject(); // CatalogObject.Assets - 
			CatObject.Status = NewStatus;
			
			CheckParameters = Catalogs.Assets.FillVerificationParameters();
			CheckParameters.Report_Errors = False;
			
			HasErrors = False;
			
			If CatObject.Status = Enums.AssetStatuses.InOperation
				Or CatObject.Status = Enums.AssetStatuses.Disposed Then
				
				Catalogs.Assets.CheckFillingOfObjectOfOperation(CatObject, CheckParameters, HasErrors);
			EndIf;

			If CatObject.CheckFilling() And Not HasErrors Then
				CatObject.Write();
				ProcessedItemsCount = ProcessedItemsCount + 1;
			Else
				ThereAreFillCheckingErrors = True;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("ThereAreFillCheckingErrors", ThereAreFillCheckingErrors);
	Result.Insert("ProcessedItemsCount", ProcessedItemsCount);
	
	Return Result;

EndFunction

Function ChangeClassOfOperationalObjects(HighlightedLinks, Class, Subclass) Export

	QueryText =
	"SELECT ALLOWED
	|	Assets.Ref
	|FROM
	|	Catalog.Assets AS Assets
	|WHERE
	|	Assets.Ref IN(&HighlightedLinks)
	|	AND NOT Assets.IsFolder
	|	AND (Assets.Class <> &Class
	|		OR Assets.Subclass <> &Subclass)";
	
	Query = New Query(QueryText);
	Query.SetParameter("HighlightedLinks", HighlightedLinks);
	Query.SetParameter("Class", Class);
	Query.SetParameter("Subclass", Subclass);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ProcessedItemsCount = 0;
	ThereAreFillCheckingErrors = False;
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.Assets");
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock(); 
			
			CatObject = Selection.Ref.GetObject(); // CatalogObject.Assets -
			 
			If CatObject.Class <> Class Then
				CatObject.Class = Class;
				Catalogs.Assets.WhenChangingClass(CatObject);
			EndIf;
			
			CatObject.Subclass = Subclass;

			If CatObject.CheckFilling() Then
				CatObject.Write();
				ProcessedItemsCount = ProcessedItemsCount + 1;
			Else
				ThereAreFillCheckingErrors = True;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("ThereAreFillCheckingErrors", ThereAreFillCheckingErrors);
	Result.Insert("ProcessedItemsCount", ProcessedItemsCount);
	Result.Insert("ClassPresentation", String(Class));
	
	Return Result;
	
EndFunction

Function UseOfSubclasses(OperatingObjectClass) Export
	
	If ValueIsFilled(OperatingObjectClass) Then
		Return Common.ObjectAttributeValue(OperatingObjectClass, "UseOfSubclasses");
	Else
		Return False;
	EndIf;
	
EndFunction

// 
// Parameters:
// 	NodesList - Array of CatalogRef.SubAssets -
// 	OnlyNew - Boolean - Generate a barcode only if it is not specified
// 	 
// Returns:
// 	Number - the number of nodes for which the barcode was generated
Function GenerateNodeBarcodes(NodesList, OnlyNew = False) Export

	ProcessedItemsCount = 0;
	
	BeginTransaction();
		
	Try
	
		Block = New DataLock;
		
		Block.Add("Catalog.SubAssets");
		Block.Lock(); 
		
		Barcode = RMManagement.CurMaximumNodeBarcode() + 1;
		For Each NodeRef1 In NodesList Do
			
			ObjectNode = NodeRef1.GetObject();
			
			If ValueIsFilled(ObjectNode.Barcode) And OnlyNew Then
				Continue;
			EndIf;
			
			ObjectNode.Barcode = RMManagement.GetNodeBarcodeByCode(Barcode);
			ObjectNode.Write();
			
			Barcode = Barcode + 1;
			ProcessedItemsCount = ProcessedItemsCount + 1;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ProcessedItemsCount = 0;
		ErrorText = BriefErrorDescription(ErrorInfo());
		
		Raise ErrorText;
		
	EndTry;

	Return ProcessedItemsCount;
	
EndFunction

// Finds nodes of operational objects by barcodes.
//
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
// 
// Returns:
//  See RMManagement.FindNodesByBarcodes
//
Function FindNodesByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export

	Return RMManagement.FindNodesByBarcodes(BarcodeData_5, PickingParameters);
	
EndFunction

// Finds operational objects or nodes by barcodes.
//
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
// 
// Returns:
//  See RMManagement.FindObjectsOfOperationOrNodesByBarcodes
//
Function FindObjectsOfOperationOrNodesByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export

	Return RMManagement.FindObjectsOfOperationOrNodesByBarcodes(BarcodeData_5, PickingParameters);
	
EndFunction

#EndRegion
