#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If IsFolder Then
		Return
	EndIf;
	
	InitializeCatalog(FillingData);
	
	AssignmentOption = Enums.AssignmentOptionsOfGoodsResearchSheet.ProductKind;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;

	If Control = Enums.QualityControl.Solid And Status <> Enums.StatusesOfGoodsResearchSheet.Draft Then
		NotCheckedAttributeArray.Add("TemplatesFilterOption");
	EndIf;
	
	If Status = Enums.StatusesOfGoodsResearchSheet.Draft Then
		NotCheckedAttributeArray.Add("TemplatesFilterOption");
		NotCheckedAttributeArray.Add("Control");
	EndIf;
	
	If Checks.Count() = 0 Or Status <> Enums.StatusesOfGoodsResearchSheet.Valid Then
		NotCheckedAttributeArray.Add("Checks.QualityIndicator");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If IsFolder Then
		Return
	EndIf;

	InitializeCatalog();

EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		
		If DeletionMark Then
			Status = Enums.StatusesOfGoodsResearchSheet.Closed_;
		EndIf;
		
	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then

		InformationRegisters.GoodsResearchSheets.RecordQualityControlCards(Ref, Status
			<> Enums.StatusesOfGoodsResearchSheet.Valid);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

// Initializes the Attributes of the Catalog of "Product Research Maps" with default values.
//
// Parameters:
//   FillingData - Undefined - Data for filling out the Catalog
Procedure InitializeCatalog(FillingData = Undefined) Export
	
	Date = CurrentSessionDate();
	Status = Enums.StatusesOfGoodsResearchSheet.Draft;
	Author = Users.CurrentUser();
	If Not ValueIsFilled(Control) Then
		Control = Enums.QualityControl.Selective;
	EndIf;
	If Not ValueIsFilled(TemplatesFilterOption) Then
		TemplatesFilterOption = Enums.FilterOptionsOfGoodsResearchTemplates.Count;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
