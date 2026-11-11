
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	EmployeeResponsible = Users.CurrentUser();
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	NotCheckedAttributeArray = New Array;
	
	Documents.MovementOfOtherAssetsAndLiabilities.FillInNamesOfBusinessTransactionDetails(
		Source,
		Recipient,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If Source = Enums.TypesOfAssetAndLiabilityItems.AssetItem
		Or Source = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem Then
		NotCheckedAttributeArray.Add("PostingData.BusinessUnitSource");
	EndIf;
		
	ItemsAndDimensionsSelectionParameters = Documents.MovementOfOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters(Source, Recipient);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocument(FillingData);
	ItemsAndDimensionsSelectionParameters = Documents.MovementOfOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters(Source, Recipient);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.MovementOfOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters(Source, Recipient);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure InitializeDocument(FillingData = Undefined)

	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	Currency			= Constants.ManagementAccountingCurrency.Get();
	EmployeeResponsible	= Users.CurrentUser();
	Source		= Enums.TypesOfAssetAndLiabilityItems.AssetItem;
	Recipient		= Enums.TypesOfAssetAndLiabilityItems.AssetItem;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf